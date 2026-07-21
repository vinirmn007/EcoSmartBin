package com.ecosmartbin.puntos.controller;

import com.ecosmartbin.puntos.dto.ClasificacionPendienteDTO;
import com.ecosmartbin.puntos.model.TipoReciclaje;
import com.ecosmartbin.puntos.repository.TipoReciclajeRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Controlador REST para manejar las clasificaciones pendientes de la IA.
 * Almacena temporalmente en memoria el resultado de la clasificación
 * hasta que el usuario lo confirme desde el frontend.
 */
@RestController
@RequestMapping("/points/clasificacion-pendiente")
public class ClasificacionPendienteController {

    private final TipoReciclajeRepository tipoReciclajeRepository;

    /**
     * Almacenamiento en memoria: binId → clasificación pendiente.
     * Se limpia cuando el frontend confirma el reciclaje.
     */
    private final ConcurrentHashMap<String, ClasificacionPendienteDTO> pendientes = new ConcurrentHashMap<>();

    /**
     * Mapeo de labels de la IA (inglés) a nombres de tipos de reciclaje en la BD (español).
     */
    private static final Map<String, String> IA_LABEL_TO_DB_NOMBRE = Map.of(
            "plastic", "Plástico",
            "paper", "Papel",
            "glass", "Vidrio",
            "metal", "Metal",
            "cardboard", "Cartón",
            "trash", "Basura General"
    );

    public ClasificacionPendienteController(TipoReciclajeRepository tipoReciclajeRepository) {
        this.tipoReciclajeRepository = tipoReciclajeRepository;
    }

    /**
     * POST /points/clasificacion-pendiente
     * Recibe la clasificación de la IA (llamado internamente por el servicio de IA)
     * y la almacena como pendiente para el frontend.
     *
     * Body esperado: { "binId": "EcoSmartBin-Q04", "tipoDetectado": "plastic", "confianza": 0.93 }
     */
    @PostMapping
    public ResponseEntity<ClasificacionPendienteDTO> recibirClasificacion(
            @RequestBody ClasificacionPendienteDTO request) {

        // Buscar el tipo de reciclaje en la BD usando el mapeo IA → nombre español
        String nombreEnBD = IA_LABEL_TO_DB_NOMBRE.getOrDefault(
                request.getTipoDetectado(), "Basura General");

        List<TipoReciclaje> tipos = tipoReciclajeRepository.findAll();
        TipoReciclaje tipoEncontrado = tipos.stream()
                .filter(t -> t.getNombre().equalsIgnoreCase(nombreEnBD))
                .findFirst()
                .orElse(null);

        if (tipoEncontrado != null) {
            request.setTipoReciclajeId(tipoEncontrado.getId());
            request.setNombreTipo(tipoEncontrado.getNombre());
        } else {
            // Fallback: asignar Basura General
            tipos.stream()
                    .filter(t -> t.getNombre().equalsIgnoreCase("Basura General"))
                    .findFirst()
                    .ifPresent(t -> {
                        request.setTipoReciclajeId(t.getId());
                        request.setNombreTipo(t.getNombre());
                    });
        }

        request.setTimestamp(System.currentTimeMillis());

        request.setTimestamp(System.currentTimeMillis());

        // Guardar en memoria (normalizado a minúsculas para coincidencia insensible)
        String binId = request.getBinId() != null ? request.getBinId().toLowerCase().trim() : "default-bin";
        pendientes.put(binId, request);

        System.out.println("📥 Clasificación pendiente recibida: " + request.getTipoDetectado()
                + " → " + request.getNombreTipo() + " (bin: " + binId + ", usuario: " + request.getUsuarioId() + ")");

        return ResponseEntity.ok(request);
    }

    /**
     * GET /points/clasificacion-pendiente/{binId}
     * El frontend consulta si hay una clasificación pendiente para un basurero.
     */
    @GetMapping("/{binId}")
    public ResponseEntity<ClasificacionPendienteDTO> obtenerClasificacion(
            @PathVariable String binId) {

        String key = binId != null ? binId.toLowerCase().trim() : "";
        ClasificacionPendienteDTO pendiente = pendientes.get(key);

        if (pendiente == null) {
            return ResponseEntity.noContent().build(); // 204: no hay clasificación pendiente
        }

        return ResponseEntity.ok(pendiente);
    }

    /**
     * DELETE /points/clasificacion-pendiente/{binId}
     * Limpia la clasificación pendiente después de que el usuario confirma.
     */
    @DeleteMapping("/{binId}")
    public ResponseEntity<Void> limpiarClasificacion(@PathVariable String binId) {
        String key = binId != null ? binId.toLowerCase().trim() : "";
        pendientes.remove(key);
        System.out.println("🗑️ Clasificación pendiente limpiada para bin: " + key);
        return ResponseEntity.ok().build();
    }
}
