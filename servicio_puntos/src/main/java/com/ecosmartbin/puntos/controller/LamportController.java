package com.ecosmartbin.puntos.controller;

import com.ecosmartbin.puntos.service.LamportService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * Controlador para el Algoritmo de Relojes Lógicos de Lamport.
 * Endpoints inter-nodo y de consulta — NO requieren JWT.
 */
@RestController
@RequestMapping("/api/lamport")
public class LamportController {

    private final LamportService lamportService;

    public LamportController(LamportService lamportService) {
        this.lamportService = lamportService;
    }

    /**
     * GET /api/lamport/status
     * Retorna el estado actual del reloj de Lamport de este nodo.
     * El frontend hace polling a los 3 nodos directamente.
     */
    @GetMapping("/status")
    public ResponseEntity<Map<String, Object>> status() {
        return ResponseEntity.ok(lamportService.buildStatus());
    }

    /**
     * POST /api/lamport/event
     * Dispara un evento interno y lo propaga a los demás nodos.
     * El usuario lo activa desde el frontend.
     */
    @PostMapping("/event")
    public ResponseEntity<Map<String, Object>> triggerEvent() {
        Map<String, Object> result = lamportService.triggerInternalEvent();
        return ResponseEntity.ok(result);
    }

    /**
     * POST /api/lamport/receive
     * Recibe un timestamp de otro nodo (comunicación inter-nodo).
     * Body: { "timestamp": 5, "fromNodeId": 2 }
     */
    @PostMapping("/receive")
    public ResponseEntity<Map<String, Object>> receive(@RequestBody Map<String, Object> body) {
        long ts = ((Number) body.get("timestamp")).longValue();
        int fromNodeId = ((Number) body.get("fromNodeId")).intValue();
        Map<String, Object> result = lamportService.receive(ts, fromNodeId);
        return ResponseEntity.ok(result);
    }
}
