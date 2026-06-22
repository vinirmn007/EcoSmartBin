package com.ecosmartbin.puntos.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

/**
 * Historial de todas las transacciones de puntos (acumulaciones y canjes).
 */
@Entity
@Table(name = "transacciones_puntos")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TransaccionPuntos {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "usuario_id", nullable = false)
    private PerfilUsuario usuario;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "tipo_reciclaje_id")
    private TipoReciclaje tipoReciclaje;

    @Column(nullable = false)
    private Integer puntos;

    /**
     * Tipo de transacción: ACUMULACION o CANJE
     */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private TipoTransaccion tipo;

    @Column(nullable = false)
    private String descripcion;

    @Column(name = "fecha", nullable = false)
    private LocalDateTime fecha;

    @Column(name = "lamport_timestamp")
    private Long lamportTimestamp;

    @Column(name = "node_id")
    private Integer nodeId;

    @PrePersist
    protected void onCreate() {
        if (fecha == null) {
            fecha = LocalDateTime.now();
        }
    }

    public enum TipoTransaccion {
        ACUMULACION,
        CANJE
    }
}
