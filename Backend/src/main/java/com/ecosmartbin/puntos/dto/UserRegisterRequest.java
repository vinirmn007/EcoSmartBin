package com.ecosmartbin.puntos.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public record UserRegisterRequest(
        @NotBlank @Email String email,
        @NotBlank String password,
        @NotBlank String nombres,
        @NotBlank String apellidos,
        @NotBlank String cedula,
        String facultad
) {}
