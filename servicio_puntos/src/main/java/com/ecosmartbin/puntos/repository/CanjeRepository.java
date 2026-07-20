package com.ecosmartbin.puntos.repository;

import com.ecosmartbin.puntos.model.Canje;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CanjeRepository extends JpaRepository<Canje, Long> {

    List<Canje> findByUsuarioIdOrderByFechaDesc(String usuarioId);

    List<Canje> findAllByOrderByFechaDesc();
}
