package com.ecosmartbin.puntos.service;

import com.ecosmartbin.puntos.dto.BalancePuntosResponse;
import com.ecosmartbin.puntos.dto.RegistrarReciclajeRequest;
import com.ecosmartbin.puntos.dto.TransaccionResponse;
import com.ecosmartbin.puntos.exception.RecursoNoEncontradoException;
import com.ecosmartbin.puntos.model.PerfilUsuario;
import com.ecosmartbin.puntos.model.TipoReciclaje;
import com.ecosmartbin.puntos.model.TransaccionPuntos;
import com.ecosmartbin.puntos.repository.PerfilUsuarioRepository;
import com.ecosmartbin.puntos.repository.TipoReciclajeRepository;
import com.ecosmartbin.puntos.repository.TransaccionPuntosRepository;
import com.ecosmartbin.puntos.config.BullyConfig;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Servicio que centraliza la lógica de acumulación de puntos ecológicos.
 */
@Service
public class PuntosService {

    private final PerfilUsuarioRepository perfilRepository;
    private final TipoReciclajeRepository tipoReciclajeRepository;
    private final TransaccionPuntosRepository transaccionRepository;
    private final LamportService lamportService;
    private final BullyConfig config;

    public PuntosService(PerfilUsuarioRepository perfilRepository,
                         TipoReciclajeRepository tipoReciclajeRepository,
                         TransaccionPuntosRepository transaccionRepository,
                         LamportService lamportService,
                         BullyConfig config) {
        this.perfilRepository = perfilRepository;
        this.tipoReciclajeRepository = tipoReciclajeRepository;
        this.transaccionRepository = transaccionRepository;
        this.lamportService = lamportService;
        this.config = config;
    }

    /**
     * Registra un reciclaje, calcula los puntos y los acumula al usuario.
     * 
     * @param request datos del reciclaje
     * @param usuarioIdFromJwt ID del usuario autenticado (del JWT)
     * @return respuesta con la transacción creada
     */
    @Transactional
    public TransaccionResponse registrarReciclaje(RegistrarReciclajeRequest request, String usuarioIdFromJwt) {
        // Determinar el usuario destino (el del JWT o uno explícito si es admin)
        String usuarioId = (request.getUsuarioId() != null && !request.getUsuarioId().isBlank())
                ? request.getUsuarioId()
                : usuarioIdFromJwt;

        // Buscar el perfil del usuario
        PerfilUsuario perfil = perfilRepository.findById(usuarioId)
                .orElseThrow(() -> new RecursoNoEncontradoException("Usuario", usuarioId));

        // Buscar el tipo de reciclaje
        TipoReciclaje tipoReciclaje = tipoReciclajeRepository.findById(request.getTipoReciclajeId())
                .orElseThrow(() -> new RecursoNoEncontradoException("Tipo de reciclaje", request.getTipoReciclajeId()));

        // Calcular puntos: puntos_por_unidad * cantidad
        int cantidad = (request.getCantidad() != null && request.getCantidad() > 0) ? request.getCantidad() : 1;
        int puntosGanados = tipoReciclaje.getPuntosPorUnidad() * cantidad;

        // Acumular puntos al perfil
        perfil.setPuntosEcologicos(perfil.getPuntosEcologicos() + puntosGanados);
        perfilRepository.save(perfil);

        // Obtener y propagar timestamp de Lamport
        String desc = String.format("Reciclaje de %s (x%d) — +%d puntos", tipoReciclaje.getNombre(), cantidad, puntosGanados);
        long lamportTs = lamportService.incrementAndPropagate(desc);

        // Crear registro de transacción
        TransaccionPuntos transaccion = TransaccionPuntos.builder()
                .usuario(perfil)
                .tipoReciclaje(tipoReciclaje)
                .puntos(puntosGanados)
                .tipo(TransaccionPuntos.TipoTransaccion.ACUMULACION)
                .descripcion(desc)
                .lamportTimestamp(lamportTs)
                .nodeId(config.getNodeId())
                .build();
        transaccionRepository.save(transaccion);

        return TransaccionResponse.builder()
                .id(transaccion.getId())
                .usuarioId(perfil.getId())
                .tipoReciclaje(tipoReciclaje.getNombre())
                .puntos(puntosGanados)
                .tipo(transaccion.getTipo().name())
                .descripcion(transaccion.getDescripcion())
                .fecha(transaccion.getFecha())
                .lamportTimestamp(transaccion.getLamportTimestamp())
                .nodeId(transaccion.getNodeId())
                .build();
    }

    /**
     * Consulta el balance actual de puntos de un usuario.
     */
    public BalancePuntosResponse obtenerBalance(String usuarioId) {
        PerfilUsuario perfil = perfilRepository.findById(usuarioId)
                .orElseThrow(() -> new RecursoNoEncontradoException("Usuario", usuarioId));

        return BalancePuntosResponse.builder()
                .usuarioId(perfil.getId())
                .email(perfil.getEmail())
                .nombres(perfil.getNombres())
                .puntosEcologicos(perfil.getPuntosEcologicos())
                .build();
    }
}
