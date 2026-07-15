package com.ecosmartbin.puntos.service;

import com.ecosmartbin.puntos.dto.*;
import com.ecosmartbin.puntos.exception.RecursoNoEncontradoException;
import com.ecosmartbin.puntos.model.PerfilUsuario;
import com.ecosmartbin.puntos.repository.PerfilUsuarioRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.LocalDateTime;

/**
 * Servicio de Autenticación.
 * Delega login/registro/recuperación en Supabase GoTrue API y gestiona
 * el perfil de usuario en la base de datos PostgreSQL local.
 */
@Service
public class AuthService {

    private static final Logger log = LoggerFactory.getLogger(AuthService.class);

    private final PerfilUsuarioRepository perfilRepository;
    private final ObjectMapper mapper = new ObjectMapper();
    private final HttpClient httpClient = HttpClient.newHttpClient();

    @Value("${app.supabase.url}")
    private String supabaseUrl;

    @Value("${app.supabase.key}")
    private String supabaseKey;

    public AuthService(PerfilUsuarioRepository perfilRepository) {
        this.perfilRepository = perfilRepository;
    }

    // ── REGISTRO ──────────────────────────────────────────────────────────────

    public Object register(UserRegisterRequest req) {
        // 1. Verificar duplicados localmente
        if (perfilRepository.existsByCedula(req.cedula())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "La cédula ingresada ya se encuentra registrada.");
        }
        if (perfilRepository.existsByEmail(req.email())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "El correo electrónico ingresado ya se encuentra registrado.");
        }

        // 2. Registrar en Supabase Auth
        try {
            String body = mapper.writeValueAsString(java.util.Map.of(
                    "email", req.email(),
                    "password", req.password(),
                    "data", java.util.Map.of("role", "user")
            ));

            HttpRequest httpReq = HttpRequest.newBuilder()
                    .uri(URI.create(supabaseUrl + "/auth/v1/signup"))
                    .header("Content-Type", "application/json")
                    .header("apikey", supabaseKey)
                    .POST(HttpRequest.BodyPublishers.ofString(body))
                    .build();

            HttpResponse<String> resp = httpClient.send(httpReq,
                    HttpResponse.BodyHandlers.ofString());

            if (resp.statusCode() >= 400) {
                log.error("Error Supabase signup: {}", resp.body());
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                        "Error en el proceso de registro: " + resp.body());
            }

            JsonNode json = mapper.readTree(resp.body());
            String uid = json.path("id").asText();
            if (uid == null || uid.isBlank()) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                        "Supabase no devolvió un ID de usuario válido.");
            }

            // 3. Guardar perfil en PostgreSQL
            PerfilUsuario perfil = PerfilUsuario.builder()
                    .id(uid)
                    .email(req.email())
                    .nombres(req.nombres())
                    .apellidos(req.apellidos())
                    .cedula(req.cedula())
                    .facultad(req.facultad())
                    .role("user")
                    .puntosEcologicos(0)
                    .isActive(true)
                    .createdAt(LocalDateTime.now())
                    .build();

            perfilRepository.save(perfil);
            log.info("Nuevo usuario registrado: {} ({})", perfil.getEmail(), perfil.getId());

            return java.util.Map.of(
                    "message", "Usuario y perfil creados exitosamente en el ecosistema EcoSmartBin.",
                    "user_id", perfil.getId(),
                    "nombres", perfil.getNombres(),
                    "email", perfil.getEmail()
            );
        } catch (ResponseStatusException ex) {
            throw ex;
        } catch (Exception ex) {
            log.error("Error inesperado en registro: ", ex);
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR,
                    "Error en el proceso de registro: " + ex.getMessage());
        }
    }

    // ── LOGIN ─────────────────────────────────────────────────────────────────

    public UserLoginResponse login(UserLoginRequest req) {
        try {
            String body = mapper.writeValueAsString(java.util.Map.of(
                    "email", req.email(),
                    "password", req.password()
            ));

            HttpRequest httpReq = HttpRequest.newBuilder()
                    .uri(URI.create(supabaseUrl + "/auth/v1/token?grant_type=password"))
                    .header("Content-Type", "application/json")
                    .header("apikey", supabaseKey)
                    .POST(HttpRequest.BodyPublishers.ofString(body))
                    .build();

            HttpResponse<String> resp = httpClient.send(httpReq,
                    HttpResponse.BodyHandlers.ofString());

            if (resp.statusCode() >= 400) {
                throw new ResponseStatusException(HttpStatus.UNAUTHORIZED,
                        "Credenciales incorrectas o cuenta no verificada.");
            }

            JsonNode json = mapper.readTree(resp.body());
            String accessToken  = json.path("access_token").asText();
            String refreshToken = json.path("refresh_token").asText();
            JsonNode userNode   = json.path("user");
            String userId       = userNode.path("id").asText();
            String email        = userNode.path("email").asText();
            String role         = userNode.path("user_metadata").path("role").asText("user");

            log.info("Login exitoso para: {} ({})", email, userId);

            return new UserLoginResponse(
                    accessToken,
                    "bearer",
                    refreshToken,
                    new UserLoginResponse.UserInfo(userId, email, role)
            );
        } catch (ResponseStatusException ex) {
            throw ex;
        } catch (Exception ex) {
            log.error("Error en login: ", ex);
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED,
                    "Credenciales incorrectas o cuenta no verificada. Detalle: " + ex.getMessage());
        }
    }

    // ── PERFIL ────────────────────────────────────────────────────────────────

    public UserProfileResponse getProfile(String userId) {
        PerfilUsuario perfil = perfilRepository.findById(userId)
                .orElseThrow(() -> new RecursoNoEncontradoException(
                        "Perfil no encontrado para el usuario: " + userId));

        return new UserProfileResponse(
                perfil.getId(),
                perfil.getEmail(),
                perfil.getNombres(),
                perfil.getApellidos(),
                perfil.getCedula(),
                perfil.getFacultad(),
                perfil.getRole(),
                perfil.getPuntosEcologicos(),
                perfil.getIsActive(),
                perfil.getCreatedAt()
        );
    }

    // ── RECUPERACIÓN DE CONTRASEÑA ────────────────────────────────────────────

    public Object recoverPassword(RecoverPasswordRequest req) {
        try {
            java.util.Map<String, Object> bodyMap = new java.util.HashMap<>();
            bodyMap.put("email", req.email());
            if (req.redirect_url() != null && !req.redirect_url().isBlank()) {
                bodyMap.put("options", java.util.Map.of("redirectTo", req.redirect_url()));
            }
            String body = mapper.writeValueAsString(bodyMap);

            HttpRequest httpReq = HttpRequest.newBuilder()
                    .uri(URI.create(supabaseUrl + "/auth/v1/recover"))
                    .header("Content-Type", "application/json")
                    .header("apikey", supabaseKey)
                    .POST(HttpRequest.BodyPublishers.ofString(body))
                    .build();

            HttpResponse<String> resp = httpClient.send(httpReq,
                    HttpResponse.BodyHandlers.ofString());

            if (resp.statusCode() >= 400) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                        "Error al enviar correo de recuperación: " + resp.body());
            }

            log.info("Correo de recuperación enviado a: {}", req.email());
            return java.util.Map.of("message", "Correo de recuperación enviado exitosamente.");
        } catch (ResponseStatusException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Error al enviar correo de recuperación: " + ex.getMessage());
        }
    }

    // ── RESETEO DE CONTRASEÑA ─────────────────────────────────────────────────

    public Object resetPassword(ResetPasswordRequest req) {
        try {
            String body = mapper.writeValueAsString(
                    java.util.Map.of("password", req.new_password()));

            HttpRequest httpReq = HttpRequest.newBuilder()
                    .uri(URI.create(supabaseUrl + "/auth/v1/user"))
                    .header("Content-Type", "application/json")
                    .header("apikey", supabaseKey)
                    .header("Authorization", "Bearer " + req.access_token())
                    .method("PUT", HttpRequest.BodyPublishers.ofString(body))
                    .build();

            HttpResponse<String> resp = httpClient.send(httpReq,
                    HttpResponse.BodyHandlers.ofString());

            if (resp.statusCode() >= 400) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                        "Error al restablecer la contraseña: " + resp.body());
            }

            log.info("Contraseña restablecida exitosamente.");
            return java.util.Map.of("message", "Contraseña restablecida exitosamente.");
        } catch (ResponseStatusException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Error al restablecer la contraseña: " + ex.getMessage());
        }
    }
}
