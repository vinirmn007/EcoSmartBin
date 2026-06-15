package com.ecosmartbin.puntos.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.*;

/**
 * Request para registrar un evento de reciclaje y acumular puntos.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RegistrarReciclajeRequest {

    /** ID del tipo de reciclaje (de la tabla tipos_reciclaje) */
    @NotNull(message = "El tipo de reciclaje es obligatorio")
    private Long tipoReciclajeId;

    /** Cantidad de items reciclados (por defecto 1) */
    @Builder.Default
    @Min(value = 1, message = "La cantidad debe ser al menos 1")
    private Integer cantidad = 1;

    /** ID del usuario al que se le acumulan los puntos (opcional, si no se envía se usa el del JWT) */
    private String usuarioId;
}
