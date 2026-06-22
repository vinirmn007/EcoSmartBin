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
 *  Algoritmo de Relojes Lógicos de Lamport
 * ════════════════════════════════════════════════════════════
 *
 *  Reglas de Lamport:
 *  1. EVENTO INTERNO: clock++
 *  2. ENVÍO de mensaje:  clock++ luego envía (ts=clock, nodeId)
 *  3. RECEPCIÓN:         clock = max(clock, ts_recibido) + 1
 *
 *  Implementación en este nodo:
 *  - El nodo puede disparar un "evento interno" (simulado)
 *  - Al disparar, propaga el timestamp a los demás nodos
 *  - Mantiene un log circular de los últimos 50 eventos
 */
@Service
public class LamportService {

    private static final Logger log = LoggerFactory.getLogger(LamportService.class);
    private static final int MAX_LOG = 50;
    private static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("HH:mm:ss.SSS");

    private final BullyConfig config;
    private final RestTemplate restTemplate;

    /** El reloj lógico de Lamport de este nodo. */
    private final AtomicLong clock = new AtomicLong(0);

    /** Log circular de eventos (tipo, clock, from, to, timestamp). */
    private final CopyOnWriteArrayList<Map<String, Object>> eventLog = new CopyOnWriteArrayList<>();

    public LamportService(BullyConfig config) {
        this.config = config;
        this.restTemplate = new RestTemplate();
    }

    @PostConstruct
    public void init() {
        log.info("[LAMPORT] Nodo {} — Reloj Lógico iniciado en 0", config.getNodeId());
        addEvent("INIT", clock.get(), config.getNodeId(), -1);
    }

    // ──────────────────────────────────────────────────────────
    //  EVENTO INTERNO — lo dispara el usuario o la simulación
    // ──────────────────────────────────────────────────────────

    /**
     * Dispara un evento interno y lo propaga a los demás nodos como SEND.
     * Retorna el mapa con el estado actual del nodo tras el evento.
     */
    public Map<String, Object> triggerInternalEvent() {
        // 1) Evento interno: clock++
        long ts = clock.incrementAndGet();
        addEvent("INTERNAL", ts, config.getNodeId(), -1);
        log.info("[LAMPORT] Nodo {} — INTERNAL event → clock={}", config.getNodeId(), ts);

        // 2) Enviar a los demás nodos (SEND)
        propagate(ts);

        return buildStatus();
    }

    /**
     * Incrementa el reloj lógico de Lamport para una transacción de negocio y lo propaga.
     * Retorna el timestamp definitivo asignado localmente antes de propagar.
     */
    public long incrementAndPropagate(String detail) {
        long ts = clock.incrementAndGet();
        addEvent("TRANSACTION", ts, config.getNodeId(), -1);
        log.info("[LAMPORT] Nodo {} — TRANSACTION event ({}) → clock={}", config.getNodeId(), detail, ts);
        propagate(ts);
        return ts;
    }

    // ──────────────────────────────────────────────────────────
    //  RECIBIR timestamp de otro nodo
    // ──────────────────────────────────────────────────────────

    /**
     * Recibe un mensaje de otro nodo con su timestamp.
     * Aplica: clock = max(clock, receivedTs) + 1
     */
    public Map<String, Object> receive(long receivedTs, int fromNodeId) {
        long newClock;
        synchronized (this) {
            long current = clock.get();
            newClock = Math.max(current, receivedTs) + 1;
            clock.set(newClock);
        }
        addEvent("RECEIVE", newClock, fromNodeId, config.getNodeId());
        log.info("[LAMPORT] Nodo {} — RECEIVE from={} ts={} → clock={}",
                config.getNodeId(), fromNodeId, receivedTs, newClock);
        return buildStatus();
    }

    // ──────────────────────────────────────────────────────────
    //  Propagar a todos los demás nodos
    // ──────────────────────────────────────────────────────────

    private void propagate(long ts) {
        List<String> allUrls = config.getAllNodeUrls();
        String selfUrl = config.getSelfUrl();

        for (String url : allUrls) {
            if (url.equals(selfUrl)) continue;
            try {
                long sendTs = clock.incrementAndGet();
                addEvent("SEND", sendTs, config.getNodeId(), nodeIdFromUrl(url, allUrls));
                restTemplate.postForObject(
                        url + "/api/lamport/receive",
                        Map.of("timestamp", sendTs, "fromNodeId", config.getNodeId()),
                        Map.class
                );
                log.info("[LAMPORT] Nodo {} — SEND to {} → ts={}", config.getNodeId(), url, sendTs);
            } catch (Exception e) {
                log.debug("[LAMPORT] Nodo {} no alcanzable: {}", url, e.getMessage());
                addEvent("SEND_FAILED", clock.get(), config.getNodeId(), nodeIdFromUrl(url, allUrls));
            }
        }
    }

    // ──────────────────────────────────────────────────────────
    //  Estado y consultas
    // ──────────────────────────────────────────────────────────

    public Map<String, Object> buildStatus() {
        List<Map<String, Object>> logs = new ArrayList<>(eventLog);
        // Retornar los últimos MAX_LOG en orden cronológico inverso
        if (logs.size() > MAX_LOG) {
            logs = logs.subList(logs.size() - MAX_LOG, logs.size());
        }
        Collections.reverse(logs);
        return Map.of(
                "nodeId",    config.getNodeId(),
                "clock",     clock.get(),
                "selfUrl",   config.getSelfUrl(),
                "eventLog",  logs
        );
    }

    public long getClock() { return clock.get(); }

    // ──────────────────────────────────────────────────────────
    //  Helpers
    // ──────────────────────────────────────────────────────────

    private void addEvent(String type, long ts, int from, int to) {
        Map<String, Object> event = new LinkedHashMap<>();
        event.put("type",      type);
        event.put("clock",     ts);
        event.put("from",      from);
        event.put("to",        to);
        event.put("timestamp", LocalDateTime.now().format(FMT));
        eventLog.add(event);
        // Mantener tamaño máximo
        while (eventLog.size() > MAX_LOG * 2) {
            eventLog.remove(0);
        }
    }

    private int nodeIdFromUrl(String url, List<String> allUrls) {
        int idx = allUrls.indexOf(url);
        return idx >= 0 ? idx + 1 : -1;
    }
}
