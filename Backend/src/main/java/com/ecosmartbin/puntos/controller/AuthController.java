package com.ecosmartbin.puntos.controller;

import com.ecosmartbin.puntos.dto.*;
import com.ecosmartbin.puntos.service.AuthService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

/**
 * Controlador REST de Autenticación y Usuarios.
 * Rutas equivalentes a las del antiguo servicio_usuarios (Python/FastAPI).
 * Prefijo: /auth
 */
@RestController
@RequestMapping("/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    /**
     * POST /auth/register
     * Registra un nuevo usuario en Supabase Auth y crea su perfil en PostgreSQL.
     */
    @PostMapping("/register")
    public ResponseEntity<Object> register(@Valid @RequestBody UserRegisterRequest req) {
        Object result = authService.register(req);
        return ResponseEntity.status(HttpStatus.CREATED).body(result);
    }

    /**
     * POST /auth/login
     * Autentica al usuario con Supabase y retorna su JWT.
     */
    @PostMapping("/login")
    public ResponseEntity<UserLoginResponse> login(@Valid @RequestBody UserLoginRequest req) {
        UserLoginResponse resp = authService.login(req);
        return ResponseEntity.ok(resp);
    }

    /**
     * GET /auth/me
     * Retorna el perfil del usuario autenticado (requiere Bearer JWT).
     */
    @GetMapping("/me")
    public ResponseEntity<UserProfileResponse> me(Authentication authentication) {
        String userId = authentication.getName();
        UserProfileResponse profile = authService.getProfile(userId);
        return ResponseEntity.ok(profile);
    }

    /**
     * POST /auth/email-reset-password
     * Envía el correo de recuperación de contraseña via Supabase.
     */
    @PostMapping("/email-reset-password")
    public ResponseEntity<Object> emailResetPassword(
            @Valid @RequestBody RecoverPasswordRequest req) {
        Object result = authService.recoverPassword(req);
        return ResponseEntity.ok(result);
    }

    /**
     * POST /auth/change-password
     * Actualiza la contraseña usando los tokens de recuperación de Supabase.
     */
    @PostMapping("/change-password")
    public ResponseEntity<Object> changePassword(
            @Valid @RequestBody ResetPasswordRequest req) {
        Object result = authService.resetPassword(req);
        return ResponseEntity.ok(result);
    }
}
