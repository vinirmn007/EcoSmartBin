package com.ecosmartbin.puntos.repository;

import com.ecosmartbin.puntos.model.Recompensa;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface RecompensaRepository extends JpaRepository<Recompensa, Long> {

    List<Recompensa> findByActivaTrue();
}
