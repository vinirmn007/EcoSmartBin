package com.ecosmartbin.puntos.controller;

import com.ecosmartbin.puntos.service.MutexService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * Controlador para el Algoritmo de Exclusión Mutua (Ricart-Agrawala).
 * Endpoints inter-nodo y de consulta — NO requieren JWT.
 */
@RestController
@RequestMapping("/api/mutex")
public class MutexController {

    private final MutexService mutexService;

    public MutexController(MutexService mutexService) {
        this.mutexService = mutexService;
    }

    /**
     * GET /api/mutex/status
     * Retorna el estado actual del mutex de este nodo.
     */
    @GetMapping("/status")
    public ResponseEntity<Map<String, Object>> status() {
        return ResponseEntity.ok(mutexService.buildStatus());
    }

    /**
     * POST /api/mutex/request
     * Puede ser llamado por el usuario (sin body) para pedir la SC,
     * O por otro nodo (con body {timestamp, fromNodeId}) para notificarnos su REQUEST.
     */
    @PostMapping("/request")
    public ResponseEntity<Map<String, Object>> request(
            @RequestBody(required = false) Map<String, Object> body) {

        // Si viene de otro nodo (tiene fromNodeId en el body)
        if (body != null && body.containsKey("fromNodeId")) {
            long ts = ((Number) body.get("timestamp")).longValue();
            int fromNodeId = ((Number) body.get("fromNodeId")).intValue();
            Map<String, Object> result = mutexService.receiveRequest(ts, fromNodeId);
            return ResponseEntity.ok(result);
        }

        // Si lo dispara el usuario desde el frontend
        Map<String, Object> result = mutexService.requestCriticalSection();
        return ResponseEntity.ok(result);
    }

    /**
     * POST /api/mutex/ok
     * Recibe un OK de un nodo que nos lo había diferido.
     * Body: { "fromNodeId": 2 }
     */
    @PostMapping("/ok")
    public ResponseEntity<Map<String, String>> receiveOk(@RequestBody Map<String, Object> body) {
        int fromNodeId = ((Number) body.get("fromNodeId")).intValue();
        mutexService.receiveOkDeferred(fromNodeId);
        return ResponseEntity.ok(Map.of("status", "OK_RECEIVED", "nodeId",
                String.valueOf(fromNodeId)));
    }

    /**
     * POST /api/mutex/release
     * Fuerza la salida de la SC (útil para pruebas y demos).
     */
    @PostMapping("/release")
    public ResponseEntity<Map<String, Object>> release() {
        mutexService.releaseCriticalSection();
        return ResponseEntity.ok(mutexService.buildStatus());
    }
}
