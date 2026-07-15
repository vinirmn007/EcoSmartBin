package com.ecosmartbin.puntos.repository;

import com.ecosmartbin.puntos.model.TipoReciclaje;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface TipoReciclajeRepository extends JpaRepository<TipoReciclaje, Long> {

    Optional<TipoReciclaje> findByNombreIgnoreCase(String nombre);
}
