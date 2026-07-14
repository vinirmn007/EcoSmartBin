package com.ecosmartbin.puntos.controller;

import com.ecosmartbin.puntos.dto.CanjeResponse;
import com.ecosmartbin.puntos.dto.RecompensaResponse;
import com.ecosmartbin.puntos.dto.UserProfileResponse;
import com.ecosmartbin.puntos.model.PerfilUsuario;
import com.ecosmartbin.puntos.repository.CanjeRepository;
import com.ecosmartbin.puntos.repository.PerfilUsuarioRepository;
import com.ecosmartbin.puntos.repository.RecompensaRepository;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Controlador REST para operaciones de administración global.
 * Prefijo: /points/admin
 */
@RestController
@RequestMapping("/points/admin")
public class AdminController {

    private final PerfilUsuarioRepository perfilRepository;
    private final CanjeRepository canjeRepository;
    private final RecompensaRepository recompensaRepository;

    public AdminController(PerfilUsuarioRepository perfilRepository,
                           CanjeRepository canjeRepository,
                           RecompensaRepository recompensaRepository) {
        this.perfilRepository = perfilRepository;
        this.canjeRepository = canjeRepository;
        this.recompensaRepository = recompensaRepository;
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

    /**
     * GET /points/admin/usuarios
     * Lista todos los perfiles de usuario registrados en la base de datos (con sus EcoPuntos).
     */
    @GetMapping("/usuarios")
    public ResponseEntity<?> listarUsuarios(Authentication authentication) {
        if (!isAdmin(authentication)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of("detail", "No tienes permisos de administrador."));
        }

        List<UserProfileResponse> users = perfilRepository.findAll().stream()
                .map(p -> new UserProfileResponse(
                        p.getId(),
                        p.getEmail(),
                        p.getNombres(),
                        p.getApellidos(),
                        p.getCedula(),
                        p.getFacultad(),
                        p.getRole(),
                        p.getPuntosEcologicos(),
                        p.getIsActive(),
                        p.getCreatedAt()
                ))
                .collect(Collectors.toList());
        return ResponseEntity.ok(users);
    }

    /**
     * GET /points/admin/canjes
     * Lista todos los canjes globales solicitados por los usuarios (incluye email y nombre completo),
     * ordenados por fecha descendente.
     */
    @GetMapping("/canjes")
    public ResponseEntity<?> listarCanjes(Authentication authentication) {
        if (!isAdmin(authentication)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of("detail", "No tienes permisos de administrador."));
        }

        List<CanjeResponse> canjes = canjeRepository.findAll().stream()
                .map(c -> {
                    String email = null;
                    String nombre = null;
                    try {
                        PerfilUsuario perfil = perfilRepository.findById(c.getUsuarioId()).orElse(null);
                        if (perfil != null) {
                            email = perfil.getEmail();
                            nombre = perfil.getNombres() + " " + perfil.getApellidos();
                        }
                    } catch (Exception e) {
                        // ignore
                    }
                    return CanjeResponse.builder()
                            .id(c.getId())
                            .usuarioId(c.getUsuarioId())
                            .usuarioEmail(email)
                            .usuarioNombre(nombre)
                            .recompensaNombre(c.getRecompensa().getNombre())
                            .puntosGastados(c.getPuntosGastados())
                            .fecha(c.getFecha())
                            .estado(c.getEstado().name())
                            .build();
                })
                .sorted((a, b) -> b.getFecha().compareTo(a.getFecha()))
                .collect(Collectors.toList());
        return ResponseEntity.ok(canjes);
    }

    /**
     * GET /points/admin/recompensas
     * Lista todas las recompensas registradas (activas e inactivas) para administración.
     */
    @GetMapping("/recompensas")
    public ResponseEntity<?> listarTodasRecompensas(Authentication authentication) {
        if (!isAdmin(authentication)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of("detail", "No tienes permisos de administrador."));
        }

        List<RecompensaResponse> recompensas = recompensaRepository.findAll().stream()
                .map(r -> RecompensaResponse.builder()
                        .id(r.getId())
                        .nombre(r.getNombre())
                        .descripcion(r.getDescripcion())
                        .costoPuntos(r.getCostoPuntos())
                        .stock(r.getStock())
                        .imagenUrl(r.getImagenUrl())
                        .activa(r.getActiva())
                        .build())
                .collect(Collectors.toList());
        return ResponseEntity.ok(recompensas);
    }
}
