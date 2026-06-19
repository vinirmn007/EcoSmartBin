package com.ecosmartbin.puntos.controller;

import com.ecosmartbin.puntos.service.BullyService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Controlador para los mensajes del Algoritmo Bully.
 * Estos endpoints son inter-nodo y NO requieren autenticación JWT.
 */
@RestController
@RequestMapping("/api/bully")
public class BullyController {

    private final BullyService bullyService;

    public BullyController(BullyService bullyService) {
        this.bullyService = bullyService;
    }

    /**
     * POST /api/bully/election
     * Recibe un mensaje ELECTION de un nodo con menor ID.
     * Responde OK si este nodo tiene mayor ID.
     */
    @PostMapping("/election")
    public ResponseEntity<Map<String, Object>> receiveElection(@RequestBody Map<String, Object> body) {
        int fromNodeId = (Integer) body.get("fromNodeId");
        Map<String, Object> result = bullyService.receiveElection(fromNodeId);
        return ResponseEntity.ok(result);
    }

    /**
     * POST /api/bully/victory
     * Recibe la proclamación de victoria del nuevo líder.
     */
    @PostMapping("/victory")
    public ResponseEntity<Map<String, String>> receiveVictory(@RequestBody Map<String, Object> body) {
        int leaderId = (Integer) body.get("leaderId");
        bullyService.receiveVictory(leaderId);
        return ResponseEntity.ok(Map.of("status", "ACCEPTED"));
    }

    /**
     * POST /api/bully/start-election
     * Permite forzar el inicio de una elección (útil para pruebas).
     */
    @PostMapping("/start-election")
    public ResponseEntity<Map<String, String>> startElection() {
        new Thread(bullyService::startElection).start();
        return ResponseEntity.ok(Map.of("status", "ELECTION_STARTED"));
    }

    /**
     * GET /api/bully/status
     * Retorna el estado actual de este nodo en el cluster Bully.
     * Este endpoint también sirve como heartbeat para el gateway y otros nodos.
     */
    @GetMapping("/status")
    public ResponseEntity<Map<String, Object>> status() {
        return ResponseEntity.ok(Map.of(
                "nodeId",              bullyService.getNodeId(),
                "currentLeaderId",     bullyService.getCurrentLeaderId(),
                "isLeader",            bullyService.isLeader(),
                "selfUrl",             bullyService.getSelfUrl(),
                "electionInProgress",  bullyService.isElectionInProgress(),
                "allNodeUrls",         bullyService.getAllNodeUrls()
        ));
    }
}
