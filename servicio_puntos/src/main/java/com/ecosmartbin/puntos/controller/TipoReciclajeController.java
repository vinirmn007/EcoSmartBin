package com.ecosmartbin.puntos.controller;

import com.ecosmartbin.puntos.model.TipoReciclaje;
import com.ecosmartbin.puntos.repository.TipoReciclajeRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Controlador REST para consultar el catálogo de tipos de reciclaje.
 */
@RestController
@RequestMapping("/points/tipos-reciclaje")
public class TipoReciclajeController {

    private final TipoReciclajeRepository tipoReciclajeRepository;

    public TipoReciclajeController(TipoReciclajeRepository tipoReciclajeRepository) {
        this.tipoReciclajeRepository = tipoReciclajeRepository;
    }

    /**
     * GET /api/tipos-reciclaje
     * Lista todos los tipos de reciclaje disponibles (público).
     */
    @GetMapping
    public ResponseEntity<List<TipoReciclaje>> listarTodos() {
        return ResponseEntity.ok(tipoReciclajeRepository.findAll());
    }

    /**
     * GET /api/tipos-reciclaje/{id}
     * Obtener un tipo de reciclaje por ID (público).
     */
    @GetMapping("/{id}")
    public ResponseEntity<TipoReciclaje> obtenerPorId(@PathVariable Long id) {
        return tipoReciclajeRepository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

}
