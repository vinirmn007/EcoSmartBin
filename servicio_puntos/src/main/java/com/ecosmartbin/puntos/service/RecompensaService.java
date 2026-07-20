package com.ecosmartbin.puntos.service;

import com.ecosmartbin.puntos.dto.CanjeResponse;
import com.ecosmartbin.puntos.dto.RecompensaResponse;
import com.ecosmartbin.puntos.exception.RecursoNoEncontradoException;
import com.ecosmartbin.puntos.exception.SaldoInsuficienteException;
import com.ecosmartbin.puntos.model.*;
import com.ecosmartbin.puntos.repository.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Servicio para gestión de recompensas y canjes.
 */
@Service
public class RecompensaService {

    private final RecompensaRepository recompensaRepository;
    private final CanjeRepository canjeRepository;
    private final PerfilUsuarioRepository perfilRepository;
    private final TransaccionPuntosRepository transaccionRepository;

    public RecompensaService(RecompensaRepository recompensaRepository,
                             CanjeRepository canjeRepository,
                             PerfilUsuarioRepository perfilRepository,
                             TransaccionPuntosRepository transaccionRepository) {
        this.recompensaRepository = recompensaRepository;
        this.canjeRepository = canjeRepository;
        this.perfilRepository = perfilRepository;
        this.transaccionRepository = transaccionRepository;
    }

    /**
     * Lista todas las recompensas activas.
     */
    public List<RecompensaResponse> listarActivas() {
        return recompensaRepository.findByActivaTrue().stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    /**
     * Lista todas las recompensas (activas e inactivas) — solo admin.
     */
    public List<RecompensaResponse> listarTodas() {
        return recompensaRepository.findAll().stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    /**
     * Obtiene el detalle de una recompensa por ID.
     */
    public RecompensaResponse obtenerPorId(Long id) {
        Recompensa r = recompensaRepository.findById(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("Recompensa", id));
        return toResponse(r);
    }

    /**
     * Crea una nueva recompensa (solo admin).
     */
    public RecompensaResponse crear(RecompensaResponse request) {
        Recompensa nueva = Recompensa.builder()
                .nombre(request.getNombre())
                .descripcion(request.getDescripcion())
                .costoPuntos(request.getCostoPuntos())
                .stock(request.getStock())
                .imagenUrl(request.getImagenUrl())
                .activa(true)
                .build();
        recompensaRepository.save(nueva);
        return toResponse(nueva);
    }

    /**
     * Actualiza una recompensa existente (solo admin).
     */
    public RecompensaResponse actualizar(Long id, RecompensaResponse request) {
        Recompensa r = recompensaRepository.findById(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("Recompensa", id));

        r.setNombre(request.getNombre());
        r.setDescripcion(request.getDescripcion());
        r.setCostoPuntos(request.getCostoPuntos());
        r.setStock(request.getStock());
        r.setImagenUrl(request.getImagenUrl());
        if (request.getActiva() != null) {
            r.setActiva(request.getActiva());
        }
        recompensaRepository.save(r);
        return toResponse(r);
    }

    /**
     * Desactiva una recompensa (soft delete, solo admin).
     */
    public void desactivar(Long id) {
        Recompensa r = recompensaRepository.findById(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("Recompensa", id));
        r.setActiva(false);
        recompensaRepository.save(r);
    }

    /**
     * Canjea una recompensa: descuenta puntos, reduce stock, crea registro de canje y transacción.
     */
    @Transactional
    public CanjeResponse canjear(Long recompensaId, String usuarioId) {
        // Obtener perfil y recompensa
        PerfilUsuario perfil = perfilRepository.findById(usuarioId)
                .orElseThrow(() -> new RecursoNoEncontradoException("Usuario", usuarioId));
        Recompensa recompensa = recompensaRepository.findById(recompensaId)
                .orElseThrow(() -> new RecursoNoEncontradoException("Recompensa", recompensaId));

        // Validaciones
        if (!recompensa.getActiva()) {
            throw new IllegalArgumentException("Esta recompensa no está disponible actualmente.");
        }
        if (recompensa.getStock() <= 0) {
            throw new IllegalArgumentException("La recompensa '" + recompensa.getNombre() + "' no tiene stock disponible.");
        }
        if (perfil.getPuntosEcologicos() < recompensa.getCostoPuntos()) {
            throw new SaldoInsuficienteException(perfil.getPuntosEcologicos(), recompensa.getCostoPuntos());
        }

        // Descontar puntos
        perfil.setPuntosEcologicos(perfil.getPuntosEcologicos() - recompensa.getCostoPuntos());
        perfilRepository.save(perfil);

        // Reducir stock
        recompensa.setStock(recompensa.getStock() - 1);
        recompensaRepository.save(recompensa);

        // Crear registro de canje
        Canje canje = Canje.builder()
                .usuarioId(usuarioId)
                .recompensa(recompensa)
                .puntosGastados(recompensa.getCostoPuntos())
                .estado(Canje.EstadoCanje.PENDIENTE)
                .build();
        canjeRepository.save(canje);

        // Registrar transacción de tipo CANJE
        TransaccionPuntos transaccion = TransaccionPuntos.builder()
                .usuarioId(usuarioId)
                .puntos(recompensa.getCostoPuntos())
                .tipo(TransaccionPuntos.TipoTransaccion.CANJE)
                .descripcion(String.format("Canje de recompensa: %s — -%d puntos",
                        recompensa.getNombre(), recompensa.getCostoPuntos()))
                .build();
        transaccionRepository.save(transaccion);

        return toCanjeResponse(canje);
    }

    /**
     * Historial de canjes de un usuario.
     */
    public List<CanjeResponse> misCanjes(String usuarioId) {
        return canjeRepository.findByUsuarioIdOrderByFechaDesc(usuarioId).stream()
                .map(this::toCanjeResponse)
                .collect(Collectors.toList());
    }

    /**
     * Lista todos los canjes de todos los usuarios — solo admin.
     */
    public List<CanjeResponse> todosLosCanjes() {
        return canjeRepository.findAllByOrderByFechaDesc().stream()
                .map(this::toCanjeResponse)
                .collect(Collectors.toList());
    }

    /**
     * Cambia el estado de un canje (solo admin).
     * Si se cancela, se devuelven los puntos y se restaura el stock.
     */
    @Transactional
    public CanjeResponse cambiarEstado(Long canjeId, String nuevoEstado) {
        Canje canje = canjeRepository.findById(canjeId)
                .orElseThrow(() -> new RecursoNoEncontradoException("Canje", canjeId));

        Canje.EstadoCanje estadoAnterior = canje.getEstado();
        Canje.EstadoCanje estado = Canje.EstadoCanje.valueOf(nuevoEstado.toUpperCase());
        canje.setEstado(estado);
        canjeRepository.save(canje);

        // Si se cancela un canje que estaba PENDIENTE, devolver puntos y stock
        if (estado == Canje.EstadoCanje.CANCELADO && estadoAnterior == Canje.EstadoCanje.PENDIENTE) {
            PerfilUsuario perfil = perfilRepository.findById(canje.getUsuarioId())
                    .orElseThrow(() -> new RecursoNoEncontradoException("Usuario", canje.getUsuarioId()));
            perfil.setPuntosEcologicos(perfil.getPuntosEcologicos() + canje.getPuntosGastados());
            perfilRepository.save(perfil);

            Recompensa recompensa = canje.getRecompensa();
            recompensa.setStock(recompensa.getStock() + 1);
            recompensaRepository.save(recompensa);

            // Registrar la devolución como transacción
            TransaccionPuntos devolucion = TransaccionPuntos.builder()
                    .usuarioId(canje.getUsuarioId())
                    .puntos(canje.getPuntosGastados())
                    .tipo(TransaccionPuntos.TipoTransaccion.ACUMULACION)
                    .descripcion(String.format("Devolución por canje cancelado #%d: +%d puntos",
                            canjeId, canje.getPuntosGastados()))
                    .build();
            transaccionRepository.save(devolucion);
        }

        return toCanjeResponse(canje);
    }

    // --- Mappers ---

    private RecompensaResponse toResponse(Recompensa r) {
        return RecompensaResponse.builder()
                .id(r.getId())
                .nombre(r.getNombre())
                .descripcion(r.getDescripcion())
                .costoPuntos(r.getCostoPuntos())
                .stock(r.getStock())
                .imagenUrl(r.getImagenUrl())
                .activa(r.getActiva())
                .build();
    }

    private CanjeResponse toCanjeResponse(Canje c) {
        return CanjeResponse.builder()
                .id(c.getId())
                .usuarioId(c.getUsuarioId())
                .recompensaNombre(c.getRecompensa().getNombre())
                .puntosGastados(c.getPuntosGastados())
                .fecha(c.getFecha())
                .estado(c.getEstado().name())
                .build();
    }
}
