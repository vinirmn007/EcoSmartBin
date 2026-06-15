package com.ecosmartbin.puntos.model;

import jakarta.persistence.*;
import lombok.*;

/**
 * Catálogo de tipos de reciclaje con la cantidad de puntos que otorga cada uno.
 */
@Entity
@Table(name = "tipos_reciclaje")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TipoReciclaje {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String nombre;

    @Column(name = "puntos_por_unidad", nullable = false)
    private Integer puntosPorUnidad;

    private String descripcion;

    private String icono;
}
