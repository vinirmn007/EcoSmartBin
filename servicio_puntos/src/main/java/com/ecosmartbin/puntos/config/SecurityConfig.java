package com.ecosmartbin.puntos.config;

import com.ecosmartbin.puntos.security.JwtAuthenticationFilter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthenticationFilter;

    public SecurityConfig(JwtAuthenticationFilter jwtAuthenticationFilter) {
        this.jwtAuthenticationFilter = jwtAuthenticationFilter;
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                .csrf(AbstractHttpConfigurer::disable)
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        // Endpoints públicos
                        .requestMatchers("/", "/error").permitAll()
                        // Bully: inter-nodo y gateway — sin JWT
                        .requestMatchers("/api/bully/**").permitAll()
                        // Listar recompensas es público (para que el frontend las muestre)
                        .requestMatchers(HttpMethod.GET, "/api/recompensas", "/api/recompensas/**").permitAll()
                        // Listar tipos de reciclaje es público
                        .requestMatchers(HttpMethod.GET, "/api/tipos-reciclaje", "/api/tipos-reciclaje/**").permitAll()
                        // Endpoints de admin para recompensas
                        .requestMatchers(HttpMethod.POST, "/api/recompensas").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.PUT, "/api/recompensas/**").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.DELETE, "/api/recompensas/**").hasRole("ADMIN")
                        // Endpoint admin para cambiar estado de canje
                        .requestMatchers(HttpMethod.PUT, "/api/canjes/*/estado").hasRole("ADMIN")
                        // Balance de otro usuario (admin)
                        .requestMatchers(HttpMethod.GET, "/api/puntos/balance/*").hasRole("ADMIN")
                        // Todo lo demás requiere autenticación
                        .anyRequest().authenticated()
                )
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }
}
