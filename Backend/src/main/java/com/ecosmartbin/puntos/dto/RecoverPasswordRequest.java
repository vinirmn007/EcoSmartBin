package com.ecosmartbin.puntos.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public record RecoverPasswordRequest(
        @NotBlank @Email String email,
        String redirect_url
) {}
