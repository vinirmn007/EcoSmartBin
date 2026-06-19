package com.ecosmartbin.gateway.controller;

import com.ecosmartbin.gateway.service.LeaderTrackerService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;
import java.util.stream.Collectors;

/**
 * Expone el estado del cluster Bully para que el frontend pueda
 * visualizar los nodos, el líder y los caídos en tiempo real.
 */
@RestController
@RequestMapping("/gateway")
public class StatusController {

    private final LeaderTrackerService leaderTracker;

    public StatusController(LeaderTrackerService leaderTracker) {
        this.leaderTracker = leaderTracker;
    }

    /**
     * GET /gateway/status
     * Devuelve el estado completo del cluster.
     *
     * Ejemplo de respuesta:
     * {
     *   "currentLeaderId": 3,
     *   "currentLeaderUrl": "http://localhost:8083",
     *   "nodes": [
     *     { "nodeId": 1, "url": "http://localhost:8081", "alive": true,  "isLeader": false },
     *     { "nodeId": 2, "url": "http://localhost:8082", "alive": true,  "isLeader": false },
     *     { "nodeId": 3, "url": "http://localhost:8083", "alive": true,  "isLeader": true  }
     *   ]
     * }
     */
    @GetMapping("/status")
    public ResponseEntity<Map<String, Object>> status() {
        List<Map<String, Object>> nodes = leaderTracker.getAllNodeInfos().stream()
                .sorted(Comparator.comparingInt(LeaderTrackerService.NodeInfo::nodeId))
                .map(n -> {
                    Map<String, Object> m = new LinkedHashMap<>();
                    m.put("nodeId",   n.nodeId());
                    m.put("url",      n.url());
                    m.put("alive",    n.alive());
                    m.put("isLeader", n.isLeader());
                    return m;
                })
                .collect(Collectors.toList());

        Map<String, Object> response = new LinkedHashMap<>();
        response.put("currentLeaderId",  leaderTracker.getCurrentLeaderId());
        response.put("currentLeaderUrl", leaderTracker.getCurrentLeaderUrl());
        response.put("nodes", nodes);

        return ResponseEntity.ok(response);
    }
}
