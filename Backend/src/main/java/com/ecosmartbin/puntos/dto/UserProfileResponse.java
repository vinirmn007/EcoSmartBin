package com.ecosmartbin.puntos.dto;

import java.time.LocalDateTime;

public record UserProfileResponse(
        String user_id,
        String email,
        String nombres,
        String apellidos,
        String cedula,
        String facultad,
        String role,
        Integer puntos_ecologicos,
        Boolean is_active,
        LocalDateTime created_at
) {}
