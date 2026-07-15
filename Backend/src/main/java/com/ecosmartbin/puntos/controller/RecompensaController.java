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
@RequestMapping("/points")
public class RecompensaController {

    private final RecompensaService recompensaService;
    private final com.ecosmartbin.puntos.repository.PerfilUsuarioRepository perfilRepository;

    public RecompensaController(RecompensaService recompensaService, com.ecosmartbin.puntos.repository.PerfilUsuarioRepository perfilRepository) {
        this.recompensaService = recompensaService;
        this.perfilRepository = perfilRepository;
    }

    private boolean isAdmin(Authentication authentication) {
        if (authentication == null) return false;
        boolean hasAdminRole = authentication.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
        if (hasAdminRole) return true;

        try {
            return perfilRepository.findById(authentication.getName())
                    .map(p -> "admin".equalsIgnoreCase(p.getRole()))
                    .orElse(false);
        } catch (Exception e) {
            return false;
        }
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
    public ResponseEntity<?> crearRecompensa(
            @Valid @RequestBody RecompensaResponse request,
            Authentication authentication) {
        if (!isAdmin(authentication)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("detail", "No tienes permisos de administrador."));
        }
        RecompensaResponse response = recompensaService.crear(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    /**
     * PUT /api/recompensas/{id}
     * Actualizar recompensa existente (solo admin).
     */
    @PutMapping("/recompensas/{id}")
    public ResponseEntity<?> actualizarRecompensa(
            @PathVariable Long id,
            @Valid @RequestBody RecompensaResponse request,
            Authentication authentication) {
        if (!isAdmin(authentication)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("detail", "No tienes permisos de administrador."));
        }
        return ResponseEntity.ok(recompensaService.actualizar(id, request));
    }

    /**
     * DELETE /api/recompensas/{id}
     * Desactivar recompensa (soft delete, solo admin).
     */
    @DeleteMapping("/recompensas/{id}")
    public ResponseEntity<?> desactivarRecompensa(
            @PathVariable Long id,
            Authentication authentication) {
        if (!isAdmin(authentication)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("detail", "No tienes permisos de administrador."));
        }
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

        // TODO-DEV: userId desde token; en pruebas puede ser nulo si no hay autenticación
        String userId = (authentication != null) ? authentication.getName() : "test-user-id";
        CanjeResponse response = recompensaService.canjear(request.getRecompensaId(), userId);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    /**
     * GET /api/canjes/mis-canjes
     * Historial de canjes del usuario autenticado.
     */
    @GetMapping("/canjes/mis-canjes")
    public ResponseEntity<List<CanjeResponse>> misCanjes(Authentication authentication) {
        // TODO-DEV: userId desde token; en pruebas puede ser nulo si no hay autenticación
        String userId = (authentication != null) ? authentication.getName() : "test-user-id";
        return ResponseEntity.ok(recompensaService.misCanjes(userId));
    }

    /**
     * PUT /api/canjes/{id}/estado
     * Cambiar el estado de un canje (solo admin).
     * Body: { "estado": "ENTREGADO" } o { "estado": "CANCELADO" }
     */
    @PutMapping("/canjes/{id}/estado")
    public ResponseEntity<?> cambiarEstadoCanje(
            @PathVariable Long id,
            @RequestBody Map<String, String> body,
            Authentication authentication) {
        if (!isAdmin(authentication)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("detail", "No tienes permisos de administrador."));
        }

        String nuevoEstado = body.get("estado");
        if (nuevoEstado == null || nuevoEstado.isBlank()) {
            throw new IllegalArgumentException("El campo 'estado' es obligatorio (PENDIENTE, ENTREGADO, CANCELADO).");
        }
        return ResponseEntity.ok(recompensaService.cambiarEstado(id, nuevoEstado));
    }
}
