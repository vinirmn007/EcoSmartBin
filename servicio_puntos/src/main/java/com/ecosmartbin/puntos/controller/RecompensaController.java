package com.ecosmartbin.puntos.controller;

import com.ecosmartbin.puntos.dto.CanjearRecompensaRequest;
import com.ecosmartbin.puntos.dto.CanjeResponse;
import com.ecosmartbin.puntos.dto.RecompensaResponse;
import com.ecosmartbin.puntos.service.RecompensaService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Controlador REST para recompensas y canjes.
 */
@RestController
@RequestMapping("/api")
public class RecompensaController {

    private final RecompensaService recompensaService;

    public RecompensaController(RecompensaService recompensaService) {
        this.recompensaService = recompensaService;
    }

    // ===== RECOMPENSAS =====

    /**
     * GET /api/recompensas
     * Lista todas las recompensas activas (público).
     */
    @GetMapping("/recompensas")
    public ResponseEntity<List<RecompensaResponse>> listarRecompensas() {
        return ResponseEntity.ok(recompensaService.listarActivas());
    }

    /**
     * GET /api/recompensas/{id}
     * Detalle de una recompensa (público).
     */
    @GetMapping("/recompensas/{id}")
    public ResponseEntity<RecompensaResponse> obtenerRecompensa(@PathVariable Long id) {
        return ResponseEntity.ok(recompensaService.obtenerPorId(id));
    }

    /**
     * POST /api/recompensas
     * Crear nueva recompensa (solo admin).
     */
    @PostMapping("/recompensas")
    public ResponseEntity<RecompensaResponse> crearRecompensa(@Valid @RequestBody RecompensaResponse request) {
        RecompensaResponse response = recompensaService.crear(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    /**
     * PUT /api/recompensas/{id}
     * Actualizar recompensa existente (solo admin).
     */
    @PutMapping("/recompensas/{id}")
    public ResponseEntity<RecompensaResponse> actualizarRecompensa(
            @PathVariable Long id,
            @Valid @RequestBody RecompensaResponse request) {
        return ResponseEntity.ok(recompensaService.actualizar(id, request));
    }

    /**
     * DELETE /api/recompensas/{id}
     * Desactivar recompensa (soft delete, solo admin).
     */
    @DeleteMapping("/recompensas/{id}")
    public ResponseEntity<Map<String, String>> desactivarRecompensa(@PathVariable Long id) {
        recompensaService.desactivar(id);
        return ResponseEntity.ok(Map.of("message", "Recompensa desactivada exitosamente."));
    }

    // ===== CANJES =====

    /**
     * POST /api/canjes
     * Canjear una recompensa con puntos ecológicos.
     */
    @PostMapping("/canjes")
    public ResponseEntity<CanjeResponse> canjearRecompensa(
            @Valid @RequestBody CanjearRecompensaRequest request,
            Authentication authentication) {

        String userId = authentication.getName();
        CanjeResponse response = recompensaService.canjear(request.getRecompensaId(), userId);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    /**
     * GET /api/canjes/mis-canjes
     * Historial de canjes del usuario autenticado.
     */
    @GetMapping("/canjes/mis-canjes")
    public ResponseEntity<List<CanjeResponse>> misCanjes(Authentication authentication) {
        String userId = authentication.getName();
        return ResponseEntity.ok(recompensaService.misCanjes(userId));
    }

    /**
     * PUT /api/canjes/{id}/estado
     * Cambiar el estado de un canje (solo admin).
     * Body: { "estado": "ENTREGADO" } o { "estado": "CANCELADO" }
     */
    @PutMapping("/canjes/{id}/estado")
    public ResponseEntity<CanjeResponse> cambiarEstadoCanje(
            @PathVariable Long id,
            @RequestBody Map<String, String> body) {

        String nuevoEstado = body.get("estado");
        if (nuevoEstado == null || nuevoEstado.isBlank()) {
            throw new IllegalArgumentException("El campo 'estado' es obligatorio (PENDIENTE, ENTREGADO, CANCELADO).");
        }
        return ResponseEntity.ok(recompensaService.cambiarEstado(id, nuevoEstado));
    }
}
