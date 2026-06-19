package com.ecosmartbin.puntos.service;

import com.ecosmartbin.puntos.config.BullyConfig;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * Implementación del Algoritmo de Elección Bully.
 *
 * Reglas:
 * 1. El nodo con MAYOR nodeId es el líder.
 * 2. Al arrancar, cada nodo inicia una elección.
 * 3. Si el líder deja de responder al heartbeat → nuevo ciclo de elección.
 * 4. Un nodo que recibe ELECTION de un nodo con menor ID responde OK
 *    y lanza su propia elección si aún no la tiene activa.
 * 5. El primer nodo que no recibe OK de ninguno con mayor ID se proclama VICTORY.
 */
@Service
@EnableScheduling
public class BullyService {

    private static final Logger log = LoggerFactory.getLogger(BullyService.class);

    private final BullyConfig config;
    private final RestTemplate restTemplate;

    /** ID del líder conocido actualmente (-1 = desconocido). */
    private final AtomicInteger currentLeaderId = new AtomicInteger(-1);

    /** Flag para evitar elecciones concurrentes. */
    private final AtomicBoolean electionInProgress = new AtomicBoolean(false);

    /** Timestamp del último heartbeat recibido/enviado exitosamente. */
    private volatile long lastLeaderSeen = System.currentTimeMillis();

    public BullyService(BullyConfig config) {
        this.config = config;
        this.restTemplate = new RestTemplate();
    }

    @PostConstruct
    public void init() {
        log.info("[BULLY] Nodo {} arrancando en {} — iniciando elección inicial",
                config.getNodeId(), config.getSelfUrl());
        // Pequeña espera para que todos los nodos arranquen
        new Thread(() -> {
            try { Thread.sleep(4000); } catch (InterruptedException ignored) {}
            startElection();
        }).start();
    }

    // ─────────────────────────────────────────────
    //  Heartbeat: comprueba al líder cada 5 segundos
    // ─────────────────────────────────────────────

    @Scheduled(fixedDelay = 5000)
    public void heartbeatCheck() {
        int leaderId = currentLeaderId.get();

        // Si yo creo que soy el líder, verifico si hay algún nodo con mayor ID que esté activo.
        // Si lo hay, significa que hubo un split-brain o recuperacion, por lo que debo ceder el liderazgo e iniciar elección.
        if (leaderId == config.getNodeId()) {
            List<String> higherNodes = config.getHigherNodeUrls();
            for (String url : higherNodes) {
                try {
                    restTemplate.getForObject(url + "/api/bully/status", Map.class);
                    log.warn("[BULLY] Detectado nodo con mayor ID activo en {}. Cediendo liderazgo e iniciando eleccion.", url);
                    currentLeaderId.set(-1);
                    startElection();
                    break;
                } catch (Exception ignored) {
                    // El nodo con mayor ID está caído, continuamos
                }
            }
            return;
        }

        // Si no hay líder conocido y no hay elección activa → iniciar elección
        if (leaderId == -1) {
            if (!electionInProgress.get()) startElection();
            return;
        }

        // Intentar contactar al líder
        String leaderUrl = getUrlForNode(leaderId);
        if (leaderUrl == null) {
            log.warn("[BULLY] No se pudo determinar la URL del líder {}", leaderId);
            currentLeaderId.set(-1);
            startElection();
            return;
        }

        try {
            Map<?, ?> status = restTemplate.getForObject(leaderUrl + "/api/bully/status", Map.class);
            lastLeaderSeen = System.currentTimeMillis();
            if (status != null && status.get("currentLeaderId") != null) {
                int remoteLeaderId = ((Number) status.get("currentLeaderId")).intValue();
                if (remoteLeaderId != leaderId) {
                    log.warn("[BULLY] El líder reportado por {} es {}, pero mi líder registrado es {}. Corrigiendo.",
                            leaderId, remoteLeaderId, leaderId);
                    currentLeaderId.set(remoteLeaderId);
                }
            }
            log.debug("[BULLY] Heartbeat OK — líder {} sigue vivo", leaderId);
        } catch (Exception e) {
            log.warn("[BULLY] Líder {} no responde — iniciando elección", leaderId);
            currentLeaderId.set(-1);
            startElection();
        }
    }

    // ─────────────────────────────────────────────
    //  Inicio de elección (mensaje ELECTION)
    // ─────────────────────────────────────────────

    public synchronized void startElection() {
        if (!electionInProgress.compareAndSet(false, true)) {
            log.info("[BULLY] Elección ya en progreso, ignorando solicitud duplicada");
            return;
        }

        log.info("[BULLY] Nodo {} inicia elección", config.getNodeId());

        List<String> higherNodes = config.getHigherNodeUrls();
        boolean anyOk = false;

        for (String url : higherNodes) {
            try {
                Map<?, ?> response = restTemplate.postForObject(
                        url + "/api/bully/election",
                        Map.of("fromNodeId", config.getNodeId()),
                        Map.class
                );
                if (response != null && "OK".equals(response.get("status"))) {
                    anyOk = true;
                    log.info("[BULLY] Nodo {} recibió OK desde {}", config.getNodeId(), url);
                }
            } catch (Exception e) {
                log.debug("[BULLY] Nodo {} no responde a ELECTION desde {}: {}",
                        url, config.getNodeId(), e.getMessage());
            }
        }

        if (!anyOk) {
            // Soy el de mayor ID que responde → me proclamo líder
            log.info("[BULLY] Nodo {} se proclama LÍDER (nadie con mayor ID respondió)", config.getNodeId());
            proclaimVictory();
        }
        // Si hubo OK, algún nodo de mayor ID lanzó su propia elección; esperamos su VICTORY.

        electionInProgress.set(false);
    }

    // ─────────────────────────────────────────────
    //  Recibir mensaje ELECTION de un nodo de menor ID
    // ─────────────────────────────────────────────

    public Map<String, Object> receiveElection(int fromNodeId) {
        log.info("[BULLY] Nodo {} recibió ELECTION de nodo {}", config.getNodeId(), fromNodeId);
        // Respondo OK si tengo mayor ID (siempre, pues solo los de menor ID nos envían ELECTION)
        if (config.getNodeId() > fromNodeId) {
            // Lanzar nuestra propia elección en segundo plano
            new Thread(() -> {
                electionInProgress.set(false); // permitir que corra nueva
                startElection();
            }).start();
            return Map.of("status", "OK", "nodeId", config.getNodeId());
        }
        return Map.of("status", "IGNORE", "nodeId", config.getNodeId());
    }

    // ─────────────────────────────────────────────
    //  Recibir mensaje VICTORY
    // ─────────────────────────────────────────────

    public void receiveVictory(int winnerId) {
        log.info("[BULLY] Nodo {} acepta a nodo {} como nuevo LÍDER", config.getNodeId(), winnerId);
        currentLeaderId.set(winnerId);
        electionInProgress.set(false);
        lastLeaderSeen = System.currentTimeMillis();
    }

    // ─────────────────────────────────────────────
    //  Proclamar victoria: envía VICTORY a todos
    // ─────────────────────────────────────────────

    private void proclaimVictory() {
        currentLeaderId.set(config.getNodeId());
        List<String> allNodes = config.getAllNodeUrls();

        for (String url : allNodes) {
            if (url.equals(config.getSelfUrl())) continue;
            try {
                restTemplate.postForObject(
                        url + "/api/bully/victory",
                        Map.of("leaderId", config.getNodeId()),
                        Map.class
                );
                log.info("[BULLY] VICTORY enviado a {}", url);
            } catch (Exception e) {
                log.debug("[BULLY] No se pudo enviar VICTORY a {}: {}", url, e.getMessage());
            }
        }
    }

    // ─────────────────────────────────────────────
    //  Consultas de estado
    // ─────────────────────────────────────────────

    public int getNodeId()       { return config.getNodeId(); }
    public int getCurrentLeaderId() { return currentLeaderId.get(); }
    public boolean isLeader()    { return config.getNodeId() == currentLeaderId.get(); }
    public boolean isElectionInProgress() { return electionInProgress.get(); }
    public List<String> getAllNodeUrls()  { return config.getAllNodeUrls(); }
    public String getSelfUrl()   { return config.getSelfUrl(); }

    // ─────────────────────────────────────────────
    //  Helpers
    // ─────────────────────────────────────────────

    private String getUrlForNode(int targetId) {
        List<String> urls = config.getAllNodeUrls();
        int idx = targetId - 1; // nodeId 1 → índice 0
        if (idx >= 0 && idx < urls.size()) return urls.get(idx);
        return null;
    }
}
