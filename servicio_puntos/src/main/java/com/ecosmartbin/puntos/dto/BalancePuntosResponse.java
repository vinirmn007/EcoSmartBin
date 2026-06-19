package com.ecosmartbin.puntos.dto;

import lombok.*;

/**
 * Response con el balance actual de puntos del usuario.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BalancePuntosResponse {

    private String usuarioId;
    private String email;
    private String nombres;
    private Integer puntosEcologicos;
}
