package com.ecosmartbin.puntos.controller;

import com.ecosmartbin.puntos.dto.TransaccionResponse;
import com.ecosmartbin.puntos.service.TransaccionService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Controlador REST para consultar el historial de transacciones de puntos.
 */
@RestController
@RequestMapping("/api/transacciones")
public class TransaccionController {

    private final TransaccionService transaccionService;

    public TransaccionController(TransaccionService transaccionService) {
        this.transaccionService = transaccionService;
    }

    /**
     * GET /api/transacciones/historial
     * Historial de movimientos de puntos del usuario autenticado.
     */
    @GetMapping("/historial")
    public ResponseEntity<List<TransaccionResponse>> historial(Authentication authentication) {
        String userId = authentication.getName();
        return ResponseEntity.ok(transaccionService.obtenerHistorial(userId));
    }
}
