package com.ecosmartbin.puntos.dto;

import lombok.*;

/**
 * Response para una recompensa del catálogo.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RecompensaResponse {

    private Long id;
    private String nombre;
    private String descripcion;
    private Integer costoPuntos;
    private Integer stock;
    private String imagenUrl;
    private Boolean activa;
}
