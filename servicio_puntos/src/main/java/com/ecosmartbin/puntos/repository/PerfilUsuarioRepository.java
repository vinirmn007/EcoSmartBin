package com.ecosmartbin.puntos.repository;

import com.ecosmartbin.puntos.model.PerfilUsuario;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface PerfilUsuarioRepository extends JpaRepository<PerfilUsuario, String> {
}
