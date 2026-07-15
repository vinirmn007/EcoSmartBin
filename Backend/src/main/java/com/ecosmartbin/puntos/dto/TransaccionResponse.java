package com.ecosmartbin.puntos.dto;

import lombok.*;
import java.time.LocalDateTime;

/**
 * Response para una transacción de puntos (historial).
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TransaccionResponse {

    private Long id;
    private String usuarioId;
    private String tipoReciclaje;
    private Integer puntos;
    private String tipo; // ACUMULACION o CANJE
    private String descripcion;
    private LocalDateTime fecha;
}
