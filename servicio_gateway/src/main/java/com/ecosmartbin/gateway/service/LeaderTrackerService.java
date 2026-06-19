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
        String detectedLeaderUrl = null;
        int detectedLeaderId = -1;

        for (String url : config.getNodeUrls()) {
            try {
                @SuppressWarnings("unchecked")
                Map<String, Object> status = restTemplate.getForObject(
                        url + "/api/bully/status", Map.class);

                if (status != null) {
                    int nodeId = (Integer) status.get("nodeId");
                    boolean isLeader = Boolean.TRUE.equals(status.get("isLeader"));

                    nodeInfoMap.put(url, new NodeInfo(nodeId, url, true, isLeader));

                    if (isLeader) {
                        detectedLeaderUrl = url;
                        detectedLeaderId = nodeId;
                    }
                }
            } catch (Exception e) {
                // Nodo caído
                NodeInfo prev = nodeInfoMap.get(url);
                int id = (prev != null) ? prev.nodeId() : -1;
                nodeInfoMap.put(url, new NodeInfo(id, url, false, false));
                log.debug("[GATEWAY] Nodo {} no responde: {}", url, e.getMessage());
            }
        }

        // Actualizar líder conocido
        if (detectedLeaderUrl != null) {
            String prevLeader = currentLeaderUrl.get();
            currentLeaderUrl.set(detectedLeaderUrl);
            currentLeaderId.set(detectedLeaderId);

            if (!detectedLeaderUrl.equals(prevLeader)) {
                log.info("[GATEWAY] *** CAMBIO DE LÍDER *** Nuevo líder: Nodo {} ({})",
                        detectedLeaderId, detectedLeaderUrl);
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
