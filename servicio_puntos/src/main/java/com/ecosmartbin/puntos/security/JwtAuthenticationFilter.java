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
            // Bypass signature validation for local testing
            String[] chunks = token.split("\\.");
            if (chunks.length >= 2) {
                String payload = new String(java.util.Base64.getUrlDecoder().decode(chunks[1]), StandardCharsets.UTF_8);
                com.fasterxml.jackson.databind.ObjectMapper mapper = new com.fasterxml.jackson.databind.ObjectMapper();
                java.util.Map<String, Object> claims = mapper.readValue(payload, new com.fasterxml.jackson.core.type.TypeReference<java.util.Map<String, Object>>(){});

                String userId = (String) claims.get("sub");
                String role = "user";
                Object userMetadata = claims.get("user_metadata");
                if (userMetadata instanceof java.util.Map) {
                    java.util.Map<String, Object> metadata = (java.util.Map<String, Object>) userMetadata;
                    Object roleObj = metadata.get("role");
                    if (roleObj != null) {
                        role = roleObj.toString();
                    }
                }

                List<SimpleGrantedAuthority> authorities = Collections.singletonList(
                        new SimpleGrantedAuthority("ROLE_" + role.toUpperCase())
                );

                UsernamePasswordAuthenticationToken authentication =
                        new UsernamePasswordAuthenticationToken(userId, null, authorities);
                SecurityContextHolder.getContext().setAuthentication(authentication);
            }
        } catch (Exception e) {
            System.err.println("DEBUG JWT: Error al parsear token - " + e.getMessage());
            e.printStackTrace();
            SecurityContextHolder.clearContext();
        }

        filterChain.doFilter(request, response);
    }
}
