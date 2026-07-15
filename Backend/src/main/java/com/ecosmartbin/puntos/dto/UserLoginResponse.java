package com.ecosmartbin.puntos.dto;

public record UserLoginResponse(
        String access_token,
        String token_type,
        String refresh_token,
        UserInfo user
) {
    public record UserInfo(String id, String email, String role) {}
}
