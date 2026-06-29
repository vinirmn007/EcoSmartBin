package com.ecosmartbin.puntos.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * Controlador raíz con endpoint de bienvenida/health check.
 */
@RestController
public class RootController {

    @GetMapping("/")
    public ResponseEntity<Map<String, String>> root() {
        return ResponseEntity.ok(Map.of(
                "message", "Bienvenido al Servicio de Puntos Ecológicos — EcoSmartBin API v1",
                "service", "servicio-puntos",
                "status", "online"));
    }
}
