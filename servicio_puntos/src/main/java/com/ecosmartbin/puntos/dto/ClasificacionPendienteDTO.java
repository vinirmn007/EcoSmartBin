package com.ecosmartbin.puntos.dto;

import lombok.*;

/**
 * DTO para recibir y devolver la clasificación pendiente de la IA.
 * Se almacena temporalmente en memoria hasta que el usuario confirme en el frontend.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ClasificacionPendienteDTO {

    /** Identificador del basurero (ej: "EcoSmartBin-Q04") */
    private String binId;

    /** Tipo de basura detectado por la IA (ej: "plastic", "glass", "metal") */
    private String tipoDetectado;

    /** Porcentaje de confianza de la clasificación (0.0 a 1.0) */
    private Double confianza;

    /** ID del tipo de reciclaje correspondiente en la BD (mapeado automáticamente) */
    private Long tipoReciclajeId;

    /** Nombre del tipo de reciclaje en español */
    private String nombreTipo;

    /** Imagen capturada en base64 para mostrarla en el frontend */
    private String imagenBase64;

    /** ID del usuario que tiene la sesión activa en el basurero */
    private String usuarioId;

    /** Timestamp de cuándo se realizó la clasificación */
    private Long timestamp;
}
