package com.ecosmartbin.puntos.dto;

import lombok.*;
import java.time.LocalDateTime;

/**
 * Response para un canje realizado.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CanjeResponse {

    private Long id;
    private String usuarioId;
    private String usuarioEmail;
    private String usuarioNombre;
    private String recompensaNombre;
    private Integer puntosGastados;
    private LocalDateTime fecha;
    private String estado;
}
