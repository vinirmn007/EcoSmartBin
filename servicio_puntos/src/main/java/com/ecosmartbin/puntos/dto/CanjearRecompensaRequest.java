package com.ecosmartbin.puntos.dto;

import jakarta.validation.constraints.NotNull;
import lombok.*;

/**
 * Request para canjear una recompensa.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CanjearRecompensaRequest {

    @NotNull(message = "El ID de la recompensa es obligatorio")
    private Long recompensaId;
}
