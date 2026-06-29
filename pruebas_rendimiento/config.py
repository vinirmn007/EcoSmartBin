# ============================================================
#  config.py — Configuración centralizada para pruebas de rendimiento
#  EcoSmartBin — Todos los servicios desplegados en GCP Cloud Run
# ============================================================

# ─── URLs de los servicios en Cloud Run ───
SERVICIO_USUARIOS_URL = "https://ecosmartbin-229724129072.southamerica-west1.run.app"
SERVICIO_PUNTOS_URL   = "https://servicio-puntos-229724129072.southamerica-west1.run.app"
API_GATEWAY_URL       = "https://gateway-229724129072.southamerica-west1.run.app"

# ─── Credenciales de prueba ───
# IMPORTANTE: Usa un usuario REAL registrado en tu sistema para las pruebas autenticadas
TEST_USER_EMAIL    = "marco.chiliguano@unl.edu.ec"
TEST_USER_PASSWORD = "1720500Mm."

# ─── Umbrales de rendimiento (en milisegundos) ───
THRESHOLDS = {
    # Servicio de Usuarios
    "login_p95_ms":              2000,   # USR-PERF-001
    "profile_p95_ms":            1000,   # USR-PERF-002
    "cold_start_max_ms":        10000,   # USR-PERF-004
    
    # Servicio de IA
    "inference_single_p95_ms":   3000,   # IA-PERF-001
    "inference_concurrent_p95_ms": 8000, # IA-PERF-002
    "ia_cold_start_max_ms":     30000,   # IA-PERF-003
    
    # Servicio de Puntos
    "reciclar_p95_ms":           2000,   # PTS-PERF-001
    "balance_p95_ms":             500,   # PTS-PERF-002
    "puntos_cold_start_max_ms": 15000,   # PTS-PERF-005
    
    # API Gateway
    "gateway_overhead_p95_ms":    100,   # GW-PERF-001
    "gateway_error_rate_pct":       1,   # GW-PERF-002
}
