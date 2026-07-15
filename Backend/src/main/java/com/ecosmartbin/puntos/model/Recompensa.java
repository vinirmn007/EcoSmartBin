package com.ecosmartbin.puntos.model;

import jakarta.persistence.*;
import lombok.*;

/**
 * Catálogo de recompensas canjeables con puntos ecológicos.
 */
@Entity
@Table(name = "recompensas")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Recompensa {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String nombre;

    private String descripcion;

    @Column(name = "costo_puntos", nullable = false)
    private Integer costoPuntos;

    @Column(nullable = false)
    private Integer stock;

    @Column(name = "imagen_url")
    private String imagenUrl;

    @Builder.Default
    @Column(nullable = false)
    private Boolean activa = true;
}
