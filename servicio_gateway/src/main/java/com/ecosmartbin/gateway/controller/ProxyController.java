package com.ecosmartbin.gateway.controller;

import com.ecosmartbin.gateway.service.LeaderTrackerService;
import jakarta.servlet.http.HttpServletRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.HttpStatusCodeException;
import org.springframework.web.client.RestTemplate;

import java.net.URI;
import java.util.Collections;
import java.util.Enumeration;

/**
 * ProxyController — reenvía CUALQUIER petición /api/** al nodo líder actual.
 * El frontend siempre habla con este gateway; el cambio de líder es transparente.
 */
@RestController
public class ProxyController {

    private static final Logger log = LoggerFactory.getLogger(ProxyController.class);

    private final LeaderTrackerService leaderTracker;
    private final RestTemplate restTemplate = new RestTemplate();

    public ProxyController(LeaderTrackerService leaderTracker) {
        this.leaderTracker = leaderTracker;
    }

    /**
     * Captura TODAS las peticiones que comiencen con /api/
     * (excepto /api/bully/** que el gateway expone propio en StatusController).
     */
    @RequestMapping(value = "/api/**", method = {
            RequestMethod.GET, RequestMethod.POST, RequestMethod.PUT,
            RequestMethod.DELETE, RequestMethod.PATCH
    })
    public ResponseEntity<byte[]> proxy(HttpServletRequest request,
                                        @RequestBody(required = false) byte[] body) {

        String leaderUrl = leaderTracker.getCurrentLeaderUrl();
        if (leaderUrl == null) {
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                    .body("{\"error\":\"No hay líder disponible. El cluster está en proceso de elección.\"}".getBytes());
        }

        // Construir la URL de destino
        String path = request.getRequestURI();
        String queryString = request.getQueryString();
        String targetUrl = leaderUrl + path + (queryString != null ? "?" + queryString : "");

        log.info("[PROXY] {} {} → {}", request.getMethod(), path, targetUrl);

        // Copiar headers del request original
        HttpHeaders headers = new HttpHeaders();
        Enumeration<String> headerNames = request.getHeaderNames();
        if (headerNames != null) {
            for (String name : Collections.list(headerNames)) {
                if (!name.equalsIgnoreCase("host")) {
                    headers.set(name, request.getHeader(name));
                }
            }
        }

        HttpEntity<byte[]> entity = new HttpEntity<>(body, headers);

        try {
            return restTemplate.exchange(
                    URI.create(targetUrl),
                    HttpMethod.valueOf(request.getMethod()),
                    entity,
                    byte[].class
            );
        } catch (HttpStatusCodeException e) {
            // Propagar el código de error del nodo destino tal cual
            return ResponseEntity.status(e.getStatusCode())
                    .headers(e.getResponseHeaders())
                    .body(e.getResponseBodyAsByteArray());
        } catch (Exception e) {
            log.error("[PROXY] Error al contactar al líder {}: {}", leaderUrl, e.getMessage());
            // Puede que el líder acabe de caer — el tracker lo detectará en el siguiente poll
            return ResponseEntity.status(HttpStatus.BAD_GATEWAY)
                    .body(("{\"error\":\"El líder no responde: " + e.getMessage() + "\"}").getBytes());
        }
    }
}
