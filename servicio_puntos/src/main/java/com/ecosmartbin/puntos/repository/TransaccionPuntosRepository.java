package com.ecosmartbin.puntos.repository;

import com.ecosmartbin.puntos.model.TransaccionPuntos;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TransaccionPuntosRepository extends JpaRepository<TransaccionPuntos, Long> {

    List<TransaccionPuntos> findByUsuarioIdOrderByLamportTimestampDescNodeIdDesc(String usuarioId);
}
