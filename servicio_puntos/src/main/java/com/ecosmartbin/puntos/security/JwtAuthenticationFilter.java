package com.ecosmartbin.puntos.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import javax.crypto.SecretKey;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Collections;
import java.util.List;
import java.util.Map;

/**
 * Filtro que intercepta cada request, extrae y valida el JWT de Supabase,
 * y establece la autenticación en el SecurityContext de Spring.
 */
@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    @Value("${app.jwt.secret}")
    private String jwtSecret;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {

        String authHeader = request.getHeader("Authorization");

        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }

        String token = authHeader.substring(7);

        try {
            SecretKey key = Keys.hmacShaKeyFor(jwtSecret.getBytes(StandardCharsets.UTF_8));

            Claims claims = Jwts.parser()
                    .verifyWith(key)
                    .build()
                    .parseSignedClaims(token)
                    .getPayload();

            // El campo "sub" del JWT de Supabase contiene el user_id
            String userId = claims.getSubject();

            // Extraer el rol desde user_metadata del JWT de Supabase
            String role = "user";
            Object userMetadata = claims.get("user_metadata");
            if (userMetadata instanceof Map) {
                @SuppressWarnings("unchecked")
                Map<String, Object> metadata = (Map<String, Object>) userMetadata;
                Object roleObj = metadata.get("role");
                if (roleObj != null) {
                    role = roleObj.toString();
                }
            }

            // Crear authorities basadas en el rol
            List<SimpleGrantedAuthority> authorities = Collections.singletonList(
                    new SimpleGrantedAuthority("ROLE_" + role.toUpperCase())
            );

            // Crear el token de autenticación de Spring con userId como principal
            UsernamePasswordAuthenticationToken authentication =
                    new UsernamePasswordAuthenticationToken(userId, null, authorities);

            SecurityContextHolder.getContext().setAuthentication(authentication);

        } catch (Exception e) {
            // Token inválido o expirado: se continúa sin autenticación (será 403 si el endpoint requiere auth)
            SecurityContextHolder.clearContext();
        }

        filterChain.doFilter(request, response);
    }
}
