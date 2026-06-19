package com.ecosmartbin.gateway.service;

import com.ecosmartbin.gateway.config.GatewayConfig;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;

/**
 * Rastrea el estado de los nodos del cluster Bully haciendo polling periódico
 * al endpoint /api/bully/status de cada nodo.
 * Determina cuál es el líder actual y qué nodos están vivos.
 */
@Service
public class LeaderTrackerService {

    private static final Logger log = LoggerFactory.getLogger(LeaderTrackerService.class);

    private final GatewayConfig config;
    private final RestTemplate restTemplate = new RestTemplate();

    /** URL actual del nodo líder (null si desconocido). */
    private final AtomicReference<String> currentLeaderUrl = new AtomicReference<>(null);

    /** ID del nodo líder actual (-1 si desconocido). */
    private final AtomicInteger currentLeaderId = new AtomicInteger(-1);

    /** Mapa: url → {nodeId, alive, isLeader} */
    private final Map<String, NodeInfo> nodeInfoMap = new ConcurrentHashMap<>();

    public LeaderTrackerService(GatewayConfig config) {
        this.config = config;
        // Inicializar mapa de nodos
        List<String> urls = config.getNodeUrls();
        for (int i = 0; i < urls.size(); i++) {
            nodeInfoMap.put(urls.get(i), new NodeInfo(i + 1, urls.get(i), false, false));
        }
    }

    @PostConstruct
    public void init() {
        log.info("[GATEWAY] Iniciando LeaderTrackerService — nodos: {}", config.getNodeUrls());
        pollNodes(); // primer sondeo inmediato
    }

    @Scheduled(fixedDelayString = "${gateway.poll-interval-ms:3000}")
    public void pollNodes() {
        // --- Paso 1: sondear a todos los nodos y guardar su estado ---
        // Mapa temporal: nodeId → {url, alive, autoReportLeader}
        Map<String, NodeInfo> tempMap = new java.util.LinkedHashMap<>();

        for (String url : config.getNodeUrls()) {
            try {
                @SuppressWarnings("unchecked")
                Map<String, Object> status = restTemplate.getForObject(
                        url + "/api/bully/status", Map.class);

                if (status != null) {
                    int nodeId = (Integer) status.get("nodeId");
                    boolean selfReportsLeader = Boolean.TRUE.equals(status.get("isLeader"));
                    // Guardamos temporalmente con isLeader=false; lo corregiremos luego.
                    tempMap.put(url, new NodeInfo(nodeId, url, true, selfReportsLeader));
                }
            } catch (Exception e) {
                // Nodo caído
                NodeInfo prev = nodeInfoMap.get(url);
                int id = (prev != null) ? prev.nodeId() : -1;
                tempMap.put(url, new NodeInfo(id, url, false, false));
                log.debug("[GATEWAY] Nodo {} no responde: {}", url, e.getMessage());
            }
        }

        // --- Paso 2: determinar el líder real (mayor nodeId que se auto-reporta líder y está vivo) ---
        // Esto evita el split-brain visual: aunque varios nodos crean ser líder, solo
        // el Gateway elige a uno como canónico.
        int trueLeaderId = -1;
        String trueLeaderUrl = null;

        for (NodeInfo info : tempMap.values()) {
            if (info.alive() && info.isLeader() && info.nodeId() > trueLeaderId) {
                trueLeaderId = info.nodeId();
                trueLeaderUrl = info.url();
            }
        }

        // --- Paso 3: reescribir el mapa marcando SOLO al verdadero líder ---
        for (Map.Entry<String, NodeInfo> entry : tempMap.entrySet()) {
            NodeInfo n = entry.getValue();
            boolean isCanonicalLeader = (trueLeaderUrl != null) && trueLeaderUrl.equals(n.url());
            nodeInfoMap.put(entry.getKey(), new NodeInfo(n.nodeId(), n.url(), n.alive(), isCanonicalLeader));
        }

        // --- Paso 4: actualizar referencias del gateway ---
        if (trueLeaderUrl != null) {
            String prevLeader = currentLeaderUrl.get();
            currentLeaderUrl.set(trueLeaderUrl);
            currentLeaderId.set(trueLeaderId);

            if (!trueLeaderUrl.equals(prevLeader)) {
                log.info("[GATEWAY] *** CAMBIO DE LÍDER *** Nuevo líder: Nodo {} ({})",
                        trueLeaderId, trueLeaderUrl);
            }
        } else {
            log.warn("[GATEWAY] No se detectó ningún líder activo — esperando elección Bully...");
        }
    }

    public String getCurrentLeaderUrl() { return currentLeaderUrl.get(); }
    public int getCurrentLeaderId()     { return currentLeaderId.get(); }

    public List<NodeInfo> getAllNodeInfos() {
        return new ArrayList<>(nodeInfoMap.values());
    }

    /** Información de un nodo del cluster. */
    public record NodeInfo(int nodeId, String url, boolean alive, boolean isLeader) {}
}
