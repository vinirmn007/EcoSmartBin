package com.ecosmartbin.puntos.controller;

import com.ecosmartbin.puntos.dto.BalancePuntosResponse;
import com.ecosmartbin.puntos.dto.RegistrarReciclajeRequest;
import com.ecosmartbin.puntos.dto.TransaccionResponse;
import com.ecosmartbin.puntos.service.PuntosService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

/**
 * Controlador REST para la gestión de puntos ecológicos.
 */
@RestController
@RequestMapping("/points")
public class PuntosController {

    private final PuntosService puntosService;

    public PuntosController(PuntosService puntosService) {
        this.puntosService = puntosService;
    }

    /**
     * POST /api/puntos/reciclar
     * Registra un evento de reciclaje y acumula puntos al usuario autenticado.
     */
    @PostMapping("/reciclar")
    public ResponseEntity<TransaccionResponse> registrarReciclaje(
            @Valid @RequestBody RegistrarReciclajeRequest request,
            Authentication authentication) {

        // TODO-DEV: userId desde token; en pruebas puede ser nulo si no hay autenticación
        String userId = (authentication != null) ? authentication.getName() : "test-user-id";
        TransaccionResponse response = puntosService.registrarReciclaje(request, userId);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    /**
     * GET /api/puntos/balance
     * Consulta el balance actual de puntos del usuario autenticado.
     */
    @GetMapping("/balance")
    public ResponseEntity<BalancePuntosResponse> miBalance(Authentication authentication) {
        // TODO-DEV: userId desde token; en pruebas puede ser nulo si no hay autenticación
        String userId = (authentication != null) ? authentication.getName() : "test-user-id";
        BalancePuntosResponse response = puntosService.obtenerBalance(userId);
        return ResponseEntity.ok(response);
    }

    /**
     * GET /api/puntos/balance/{userId}
     * Consulta el balance de un usuario específico (solo admin).
     */
    @GetMapping("/balance/{userId}")
    public ResponseEntity<BalancePuntosResponse> balanceDeUsuario(@PathVariable String userId) {
        BalancePuntosResponse response = puntosService.obtenerBalance(userId);
        return ResponseEntity.ok(response);
    }
}
