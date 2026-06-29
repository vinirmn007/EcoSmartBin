# ============================================================
#  locustfile_usuarios.py — Pruebas de Rendimiento
#  Módulo: servicio_usuarios (FastAPI + Supabase Auth)
#  
#  Casos cubiertos:
#    USR-PERF-001: Login concurrente (50 usuarios, p95 < 2s)
#    USR-PERF-002: Consulta de perfil /auth/me (100 usuarios, p95 < 1s)
#    USR-PERF-003: Registro masivo (20 registros secuenciales)
#    USR-PERF-004: Cold start en Cloud Run (primera petición)
#
#  Ejecutar:
#    locust -f locustfile_usuarios.py --host https://ecosmartbin-229724129072.southamerica-west1.run.app
#
#  O en modo headless (sin interfaz web):
#    locust -f locustfile_usuarios.py --host https://ecosmartbin-229724129072.southamerica-west1.run.app --headless -u 50 -r 5 -t 60s --html reporte_usuarios.html
# ============================================================

import time
import random
import string
from locust import HttpUser, task, between, events, tag


class UsuarioAutenticado(HttpUser):
    """
    Simula un usuario que inicia sesión y luego consulta su perfil repetidamente.
    """
    wait_time = between(1, 3)  # Espera 1-3 segundos entre peticiones

    # Token JWT obtenido tras login
    token = None

    def on_start(self):
        """
        Se ejecuta UNA VEZ al iniciar cada usuario virtual.
        Hace login para obtener el token JWT.
        """
        self.login()

    def login(self):
        """Autentica al usuario y almacena el token."""
        response = self.client.post(
            "/auth/login",
            json={
                "email": "marco.chiliguano@unl.edu.ec",  # ← Cambiar por usuario real
                "password": "1720500Mm."             # ← Cambiar por contraseña real
            },
            name="[USR-PERF-001] POST /auth/login"
        )
        if response.status_code == 200:
            data = response.json()
            self.token = data.get("access_token")
        else:
            print(f"⚠️ Login falló: {response.status_code} - {response.text[:200]}")

    @task(5)
    @tag("perfil")
    def consultar_perfil(self):
        """
        USR-PERF-002: Consulta de perfil (/auth/me) con token válido.
        Objetivo: p95 < 1s, throughput > 30 req/s
        
        Peso 5 = se ejecuta 5 veces más que otras tareas.
        """
        if not self.token:
            self.login()
            return

        response = self.client.get(
            "/auth/me",
            headers={"Authorization": f"Bearer {self.token}"},
            name="[USR-PERF-002] GET /auth/me"
        )
        
        if response.status_code == 401:
            # Token expirado, re-autenticar
            self.login()

    @task(1)
    @tag("login")
    def login_repetido(self):
        """
        USR-PERF-001: Login concurrente.
        Objetivo: 50 usuarios simultáneos, p95 < 2s
        """
        self.client.post(
            "/auth/login",
            json={
                "email": "prueba_rendimiento@test.com",
                "password": "TestPassword123"
            },
            name="[USR-PERF-001] POST /auth/login (repetido)"
        )

    @task(1)
    @tag("health")
    def health_check(self):
        """
        Verifica que el servicio esté respondiendo.
        Útil para medir cold start (USR-PERF-004).
        """
        self.client.get(
            "/",
            name="[USR-PERF-004] GET / (health check)"
        )


class RegistroMasivo(HttpUser):
    """
    USR-PERF-003: Registro masivo de usuarios.
    Simula 20 registros secuenciales con datos únicos.
    
    Ejecutar con pocos usuarios:
      locust -f locustfile_usuarios.py --host <URL> --headless -u 1 -r 1 -t 120s --tags registro
    """
    wait_time = between(2, 5)

    counter = 0

    @task
    @tag("registro")
    def registrar_usuario(self):
        """Registra un usuario con datos aleatorios únicos."""
        RegistroMasivo.counter += 1
        timestamp = int(time.time())
        random_suffix = ''.join(random.choices(string.ascii_lowercase, k=4))
        
        payload = {
            "email": f"perf_test_{timestamp}_{random_suffix}@test.com",
            "password": "TestPerf123456",
            "nombres": f"PerfTest_{RegistroMasivo.counter}",
            "apellidos": f"LoadTest_{random_suffix}",
            "cedula": f"9{timestamp % 1000000000:09d}",
            "facultad": "Ingeniería (Prueba de Carga)"
        }

        response = self.client.post(
            "/auth/register",
            json=payload,
            name="[USR-PERF-003] POST /auth/register"
        )

        if response.status_code == 201:
            print(f"✅ Registro #{RegistroMasivo.counter} exitoso")
        else:
            print(f"❌ Registro #{RegistroMasivo.counter} falló: {response.status_code}")
