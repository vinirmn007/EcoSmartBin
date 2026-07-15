package com.ecosmartbin.puntos.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

/**
 * Mapeo de la tabla "perfiles" existente (creada por servicio_usuarios).
 * Este servicio solo lee y actualiza el campo puntos_ecologicos.
 */
@Entity
@Table(name = "perfiles")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PerfilUsuario {

    @Id
    @Column(nullable = false)
    private String id;

    @Column(unique = true, nullable = false)
    private String email;

    @Column(nullable = false)
    private String nombres;

    @Column(nullable = false)
    private String apellidos;

    @Column(unique = true, nullable = false)
    private String cedula;

    private String facultad;

    @Column(nullable = false)
    private String role;

    @Builder.Default
    @Column(name = "puntos_ecologicos", nullable = false)
    private Integer puntosEcologicos = 0;

    @Builder.Default
    @Column(name = "is_active", nullable = false)
    private Boolean isActive = true;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;
}
