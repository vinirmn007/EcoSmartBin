package com.ecosmartbin.puntos.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;

import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Configuración del nodo Bully.
 * Se alimenta desde variables de entorno o application.properties.
 */
@Configuration
public class BullyConfig {

    /** ID único de este nodo (1, 2, 3…). Nodo con mayor ID gana la elección. */
    @Value("${bully.node-id}")
    private int nodeId;

    /** Puerto en que este nodo escucha (coincide con server.port). */
    @Value("${bully.node-port}")
    private int nodePort;

    /**
     * URLs de TODOS los nodos del cluster, separadas por coma.
     * Ejemplo: http://localhost:8081,http://localhost:8082,http://localhost:8083
     */
    @Value("${bully.node-urls}")
    private String nodeUrlsRaw;

    public int getNodeId() { return nodeId; }
    public int getNodePort() { return nodePort; }

    /** Lista de URLs de todos los nodos (incluye este mismo nodo). */
    public List<String> getAllNodeUrls() {
        return Arrays.stream(nodeUrlsRaw.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .collect(Collectors.toList());
    }

    /** URL de este nodo. Se construye a partir de la lista configurada usando su ID. */
    public String getSelfUrl() {
        List<String> all = getAllNodeUrls();
        if (nodeId >= 1 && nodeId <= all.size()) {
            return all.get(nodeId - 1);
        }
        return "http://localhost:" + nodePort;
    }

    /** URLs de nodos con ID mayor que el propio (candidatos a ganar elección). */
    public List<String> getHigherNodeUrls() {
        // Por convención, la URL del nodo i es la URL en la posición (i-1) de la lista.
        // Nodos con índice > (nodeId - 1) tienen mayor ID.
        List<String> all = getAllNodeUrls();
        return all.subList(Math.min(nodeId, all.size()), all.size());
    }
}
