package com.ecosmartbin.puntos.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

/**
 * Registro de cada canje de recompensa realizado por un usuario.
 */
@Entity
@Table(name = "canjes")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Canje {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "usuario_id", nullable = false)
    private String usuarioId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "recompensa_id", nullable = false)
    private Recompensa recompensa;

    @Column(name = "puntos_gastados", nullable = false)
    private Integer puntosGastados;

    @Column(nullable = false)
    private LocalDateTime fecha;

    /**
     * Estado del canje: PENDIENTE, ENTREGADO o CANCELADO
     */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private EstadoCanje estado;

    @PrePersist
    protected void onCreate() {
        if (fecha == null) {
            fecha = LocalDateTime.now();
        }
        if (estado == null) {
            estado = EstadoCanje.PENDIENTE;
        }
    }

    public enum EstadoCanje {
        PENDIENTE,
        ENTREGADO,
        CANCELADO
    }
}
