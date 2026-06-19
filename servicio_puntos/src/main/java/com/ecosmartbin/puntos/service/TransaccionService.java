package com.ecosmartbin.puntos.service;

import com.ecosmartbin.puntos.dto.TransaccionResponse;
import com.ecosmartbin.puntos.model.TransaccionPuntos;
import com.ecosmartbin.puntos.repository.TransaccionPuntosRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Servicio para consultar el historial de transacciones de puntos.
 */
@Service
public class TransaccionService {

    private final TransaccionPuntosRepository transaccionRepository;

    public TransaccionService(TransaccionPuntosRepository transaccionRepository) {
        this.transaccionRepository = transaccionRepository;
    }

    /**
     * Obtiene el historial de transacciones de un usuario, ordenado por fecha descendente.
     */
    public List<TransaccionResponse> obtenerHistorial(String usuarioId) {
        return transaccionRepository.findByUsuarioIdOrderByFechaDesc(usuarioId).stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    private TransaccionResponse toResponse(TransaccionPuntos t) {
        return TransaccionResponse.builder()
                .id(t.getId())
                .usuarioId(t.getUsuario() != null ? t.getUsuario().getId() : null)
                .tipoReciclaje(t.getTipoReciclaje() != null ? t.getTipoReciclaje().getNombre() : null)
                .puntos(t.getPuntos())
                .tipo(t.getTipo().name())
                .descripcion(t.getDescripcion())
                .fecha(t.getFecha())
                .build();
    }
}
