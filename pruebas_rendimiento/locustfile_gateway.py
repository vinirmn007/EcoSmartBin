# ============================================================
#  locustfile_gateway.py — Pruebas de Rendimiento
#  Módulo: API Gateway (Kong)
#
#  Casos cubiertos:
#    GW-PERF-001: Latencia añadida por Kong (overhead < 100ms)
#    GW-PERF-002: Throughput del gateway (100 req/s, < 1% errores)
#
#  Ejecutar:
#    locust -f locustfile_gateway.py --host https://gateway-229724129072.southamerica-west1.run.app
# ============================================================

from locust import HttpUser, task, between, tag

class GatewayTest(HttpUser):
    """
    Prueba de throughput y latencia del API Gateway de Kong.
    Se prueba pasando peticiones al servicio de usuarios y midiendo el rendimiento.
    """
    # Esperas muy cortas para generar alta carga y probar el throughput
    wait_time = between(0.1, 0.5)

    @task(3)
    @tag("passthrough")
    def passthrough_auth(self):
        """
        GW-PERF-001 / GW-PERF-002:
        Llamar a un endpoint ligero del servicio de usuarios (ej. un registro inválido rápido
        o intentar logear con credenciales falsas) para medir la latencia pura de Kong.
        """
        self.client.post(
            "/auth/login",
            json={"email": "wrong@mail.com", "password": "123"},
            name="[GW-PERF] POST /auth/login (via Gateway)"
        )

    @task(1)
    @tag("cors")
    def preflight_cors(self):
        """
        Verifica el rendimiento del plugin CORS configurado en Kong.
        Kong debería responder al OPTIONS directamente sin pasar al backend.
        """
        headers = {
            "Origin": "https://ecosmartbin2.web.app",
            "Access-Control-Request-Method": "POST"
        }
        self.client.options(
            "/auth/login",
            headers=headers,
            name="[GW-PERF] OPTIONS /auth/login (CORS Plugin)"
        )
