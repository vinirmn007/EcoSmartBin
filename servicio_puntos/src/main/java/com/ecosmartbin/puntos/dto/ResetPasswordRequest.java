package com.ecosmartbin.puntos.dto;

import jakarta.validation.constraints.NotBlank;

public record ResetPasswordRequest(
        @NotBlank String access_token,
        @NotBlank String refresh_token,
        @NotBlank String new_password
) {}
