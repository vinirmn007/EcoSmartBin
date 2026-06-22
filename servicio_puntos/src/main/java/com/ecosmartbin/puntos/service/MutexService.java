package com.ecosmartbin.puntos.service;

import com.ecosmartbin.puntos.config.BullyConfig;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.atomic.AtomicLong;

/**
 * ════════════════════════════════════════════════════════════
 *  Algoritmo de Exclusión Mutua — Ricart-Agrawala
 * ════════════════════════════════════════════════════════════
 *
 *  El algoritmo garantiza que solo UN nodo a la vez pueda
 *  estar en la Sección Crítica (SC).
 *
 *  Estados de un nodo:
 *    RELEASED — no quiere entrar a la SC
 *    WANTED   — quiere entrar, esperando OKs de todos
 *    HELD     — está dentro de la SC
 *
 *  Reglas:
 *  1. Para entrar: envía REQUEST(ts, nodeId) a todos.
 *  2. Nodo j al recibir REQUEST de i:
 *     - Si j está HELD, o está WANTED con prioridad (ts_j < ts_i, o mismo ts y j < i):
 *         → encola la respuesta
 *     - Si no: responde OK inmediatamente
 *  3. Cuando el nodo recibe OKs de TODOS:
 *     → entra a SC (HELD)
 *  4. Al salir: envía OK a todos los encolados, vuelve a RELEASED
 */
@Service
public class MutexService {

    private static final Logger log = LoggerFactory.getLogger(MutexService.class);
    private static final int MAX_LOG = 50;
    private static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("HH:mm:ss.SSS");

    /** Estados posibles del nodo */
    public enum State { RELEASED, WANTED, HELD }

    private final BullyConfig config;
    private final RestTemplate restTemplate;

    // Estado actual del nodo
    private volatile State state = State.RELEASED;

    // Timestamp de la solicitud actual (para comparar prioridad)
    private volatile long requestTs = 0;

    // Contador de OKs recibidos desde otros nodos
    private volatile int okCount = 0;

    // Número total de nodos en el cluster
    private volatile int totalNodes = 3;

    // Cola de nodos que esperan OK de este nodo (sus nodeIds)
    private final CopyOnWriteArrayList<Integer> deferredQueue = new CopyOnWriteArrayList<>();

    // Reloj lógico compartido con Lamport
    private final AtomicLong clock = new AtomicLong(0);

    // Log de eventos
    private final CopyOnWriteArrayList<Map<String, Object>> eventLog = new CopyOnWriteArrayList<>();

    public MutexService(BullyConfig config) {
        this.config = config;
        this.restTemplate = new RestTemplate();
    }

    @PostConstruct
    public void init() {
        totalNodes = config.getAllNodeUrls().size();
        log.info("[MUTEX] Nodo {} — Ricart-Agrawala iniciado. Total nodos: {}",
                config.getNodeId(), totalNodes);
        addEvent("INIT", 0, config.getNodeId(), -1, "Sistema iniciado en RELEASED");
    }

    // ──────────────────────────────────────────────────────────
    //  SOLICITAR entrada a la Sección Crítica
    // ──────────────────────────────────────────────────────────

    /**
     * Inicia el proceso para entrar a la SC.
     * Envía REQUEST a todos los demás nodos.
     */
    public synchronized Map<String, Object> requestCriticalSection() {
        if (state != State.RELEASED) {
            return Map.of(
                    "success", false,
                    "message", "Este nodo ya está en estado " + state,
                    "status",  buildStatus()
            );
        }

        // Incrementar reloj y solicitar
        requestTs = clock.incrementAndGet();
        state = State.WANTED;
        okCount = 0;

        log.info("[MUTEX] Nodo {} solicita SC con ts={}", config.getNodeId(), requestTs);
        addEvent("REQUEST", requestTs, config.getNodeId(), -1, "Solicitud enviada a todos");

        // Enviar REQUEST a todos los demás
        List<String> allUrls = config.getAllNodeUrls();
        String selfUrl = config.getSelfUrl();
        int pendingOks = 0;

        for (String url : allUrls) {
            if (url.equals(selfUrl)) continue;
            pendingOks++;
            try {
                Map<?, ?> resp = restTemplate.postForObject(
                        url + "/api/mutex/request",
                        Map.of("timestamp", requestTs, "fromNodeId", config.getNodeId()),
                        Map.class
                );
                if (resp != null && "OK".equals(resp.get("response"))) {
                    receiveOk(config.getNodeId());
                    log.info("[MUTEX] Nodo {} recibió OK inmediato de {}", config.getNodeId(), url);
                } else {
                    log.info("[MUTEX] Nodo {} respuesta DEFERRED de {}", config.getNodeId(), url);
                }
            } catch (Exception e) {
                // Nodo caído = cuenta como OK para no bloquear con 3 nodos y uno caído
                receiveOk(config.getNodeId());
                log.warn("[MUTEX] Nodo {} no alcanzable, contando como OK: {}", url, e.getMessage());
            }
        }

        return Map.of("success", true, "message", "REQUEST enviado", "status", buildStatus());
    }

    /**
     * Recibe un REQUEST de otro nodo.
     * Responde OK inmediatamente o difiere según Ricart-Agrawala.
     */
    public synchronized Map<String, Object> receiveRequest(long ts, int fromNodeId) {
        // Actualizar reloj lógico
        clock.set(Math.max(clock.get(), ts) + 1);

        boolean defer = false;

        if (state == State.HELD) {
            // Estamos dentro de SC → diferir
            defer = true;
        } else if (state == State.WANTED) {
            // Comparar prioridad: menor ts gana; si empate, menor nodeId gana
            if (requestTs < ts || (requestTs == ts && config.getNodeId() < fromNodeId)) {
                defer = true; // Nosotros tenemos prioridad
            }
        }

        if (defer) {
            deferredQueue.add(fromNodeId);
            addEvent("DEFERRED", ts, fromNodeId, config.getNodeId(),
                    "Diferido — nosotros tenemos prioridad (ts=" + requestTs + ")");
            log.info("[MUTEX] Nodo {} difiere OK a nodo {} (nuestra ts={}, su ts={})",
                    config.getNodeId(), fromNodeId, requestTs, ts);
            return Map.of("response", "DEFERRED", "nodeId", config.getNodeId());
        } else {
            addEvent("OK_SENT", ts, config.getNodeId(), fromNodeId, "OK enviado inmediatamente");
            log.info("[MUTEX] Nodo {} envía OK a nodo {}", config.getNodeId(), fromNodeId);
            return Map.of("response", "OK", "nodeId", config.getNodeId());
        }
    }

    /**
     * Registra un OK recibido. Si tenemos todos → entramos a SC.
     */
    public synchronized void receiveOk(int fromNodeId) {
        if (state != State.WANTED) return;
        okCount++;
        int needed = totalNodes - 1; // OKs de todos los demás
        addEvent("OK_RECEIVED", clock.get(), fromNodeId, config.getNodeId(),
                "OKs recibidos: " + okCount + "/" + needed);
        log.info("[MUTEX] Nodo {} recibió OK ({}/{})", config.getNodeId(), okCount, needed);

        if (okCount >= needed) {
            enterCriticalSection();
        }
    }

    /**
     * Entra a la sección crítica (simula trabajo).
     */
    private synchronized void enterCriticalSection() {
        state = State.HELD;
        addEvent("ENTER_SC", clock.incrementAndGet(), config.getNodeId(), -1,
                "¡ENTRÓ a la Sección Crítica!");
        log.info("[MUTEX] ████ Nodo {} ENTRÓ a la Sección Crítica ████", config.getNodeId());

        // Simular trabajo en SC (3 segundos)
        new Thread(() -> {
            try {
                Thread.sleep(3000);
            } catch (InterruptedException ignored) {}
            releaseCriticalSection();
        }).start();
    }

    /**
     * Sale de la sección crítica y envía OK a todos los diferidos.
     */
    public synchronized void releaseCriticalSection() {
        if (state != State.HELD) return;
        state = State.RELEASED;
        clock.incrementAndGet();
        addEvent("RELEASE_SC", clock.get(), config.getNodeId(), -1,
                "Salió de la SC — enviando OKs diferidos: " + deferredQueue);
        log.info("[MUTEX] Nodo {} SALIÓ de la SC — notificando {} nodos en cola",
                config.getNodeId(), deferredQueue.size());

        // Enviar OK a todos los que estaban esperando
        List<Integer> toNotify = new ArrayList<>(deferredQueue);
        deferredQueue.clear();
        List<String> allUrls = config.getAllNodeUrls();

        for (int nodeId : toNotify) {
            String url = getUrlForNode(nodeId, allUrls);
            if (url == null) continue;
            try {
                restTemplate.postForObject(
                        url + "/api/mutex/ok",
                        Map.of("fromNodeId", config.getNodeId()),
                        Map.class
                );
                addEvent("OK_SENT", clock.get(), config.getNodeId(), nodeId, "OK liberado a cola");
                log.info("[MUTEX] Nodo {} envió OK liberado a nodo {}", config.getNodeId(), nodeId);
            } catch (Exception e) {
                log.warn("[MUTEX] No se pudo notificar a nodo {}: {}", nodeId, e.getMessage());
            }
        }
    }

    /**
     * Recibe un OK de un nodo que nos lo había diferido.
     */
    public synchronized void receiveOkDeferred(int fromNodeId) {
        addEvent("OK_DEFERRED_RECEIVED", clock.incrementAndGet(), fromNodeId, config.getNodeId(),
                "OK deferred recibido");
        receiveOk(fromNodeId);
    }

    // ──────────────────────────────────────────────────────────
    //  Estado y consultas
    // ──────────────────────────────────────────────────────────

    public Map<String, Object> buildStatus() {
        List<Map<String, Object>> logs = new ArrayList<>(eventLog);
        if (logs.size() > MAX_LOG) {
            logs = logs.subList(logs.size() - MAX_LOG, logs.size());
        }
        Collections.reverse(logs);

        return Map.of(
                "nodeId",        config.getNodeId(),
                "state",         state.name(),
                "clock",         clock.get(),
                "requestTs",     requestTs,
                "okCount",       okCount,
                "totalNodes",    totalNodes,
                "deferredQueue", new ArrayList<>(deferredQueue),
                "selfUrl",       config.getSelfUrl(),
                "eventLog",      logs
        );
    }

    public State getState() { return state; }

    // ──────────────────────────────────────────────────────────
    //  Helpers
    // ──────────────────────────────────────────────────────────

    private void addEvent(String type, long ts, int from, int to, String detail) {
        Map<String, Object> event = new LinkedHashMap<>();
        event.put("type",      type);
        event.put("clock",     ts);
        event.put("from",      from);
        event.put("to",        to);
        event.put("detail",    detail);
        event.put("timestamp", LocalDateTime.now().format(FMT));
        eventLog.add(event);
        while (eventLog.size() > MAX_LOG * 2) {
            eventLog.remove(0);
        }
    }

    private String getUrlForNode(int targetId, List<String> allUrls) {
        int idx = targetId - 1;
        if (idx >= 0 && idx < allUrls.size()) return allUrls.get(idx);
        return null;
    }
}
