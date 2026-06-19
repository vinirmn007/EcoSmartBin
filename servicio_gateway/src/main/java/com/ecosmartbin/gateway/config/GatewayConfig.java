package com.ecosmartbin.gateway.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;

import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

@Configuration
public class GatewayConfig {

    @Value("${gateway.node-urls}")
    private String nodeUrlsRaw;

    @Value("${gateway.poll-interval-ms:3000}")
    private long pollIntervalMs;

    public List<String> getNodeUrls() {
        return Arrays.stream(nodeUrlsRaw.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .collect(Collectors.toList());
    }

    public long getPollIntervalMs() { return pollIntervalMs; }
}
