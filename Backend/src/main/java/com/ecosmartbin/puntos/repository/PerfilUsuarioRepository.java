package com.ecosmartbin.puntos.repository;

import com.ecosmartbin.puntos.model.PerfilUsuario;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface PerfilUsuarioRepository extends JpaRepository<PerfilUsuario, String> {
    boolean existsByEmail(String email);
    boolean existsByCedula(String cedula);
    Optional<PerfilUsuario> findByEmail(String email);
}
