# ============================================================
#  locustfile_puntos.py — Pruebas de Rendimiento
#  Módulo: servicio_puntos (Spring Boot + JPA)
#
#  Casos cubiertos:
#    PTS-PERF-001: Registrar reciclaje concurrente (30 simultáneos, p95 < 2s)
#    PTS-PERF-002: Consulta de balance concurrente (50 simultáneos, p95 < 500ms)
#    PTS-PERF-003: Canjeo concurrente (protección contra overselling)
#    PTS-PERF-004: Recepción de clasificaciones IA (20 simultáneas, p95 < 1s)
#    PTS-PERF-005: Cold start Spring Boot (< 15s)
#
#  Ejecutar:
#    locust -f locustfile_puntos.py --host https://servicio-puntos-229724129072.southamerica-west1.run.app
# ============================================================

import random
import requests
from locust import HttpUser, task, between, tag

# Importamos las variables desde config.py
from config import SERVICIO_USUARIOS_URL, TEST_USER_EMAIL, TEST_USER_PASSWORD


class PuntosAutenticado(HttpUser):
    """
    Simula peticiones al servicio de puntos como un usuario autenticado.
    Ahora obtiene un JWT válido del servicio de usuarios antes de empezar.
    """
    wait_time = between(1, 3)
    token = None

    def on_start(self):
        """
        Se ejecuta al inicio de cada usuario simulado.
        Hace una petición directa al servicio de usuarios para obtener el token JWT.
        """
        try:
            # Hacemos la petición con la librería `requests` pura al servicio de usuarios
            # ya que self.client apuntará al servicio de puntos (configurado en --host)
            response = requests.post(
                f"{SERVICIO_USUARIOS_URL}/auth/login",
                json={"email": TEST_USER_EMAIL, "password": TEST_USER_PASSWORD},
                timeout=10
            )
            
            if response.status_code == 200:
                data = response.json()
                self.token = data.get("access_token")
                # Preconfiguramos los headers para que todas las peticiones lleven el token
                self.client.headers.update({"Authorization": f"Bearer {self.token}"})
            else:
                print(f"⚠️ Error al obtener Token en Puntos: {response.status_code} - {response.text[:100]}")
        except Exception as e:
            print(f"⚠️ Falló la conexión al servicio de usuarios para login: {e}")

    @task(5)
    @tag("balance")
    def consultar_balance(self):
        """
        PTS-PERF-002: Consulta de balance concurrente.
        Objetivo: p95 < 500ms
        """
        if not self.token: return  # Evita errores si falló el login
        
        self.client.get(
            "/points/balance",
            name="[PTS-PERF-002] GET /points/balance"
        )

    @task(2)
    @tag("reciclar")
    def registrar_reciclaje(self):
        """
        PTS-PERF-001: Registrar reciclaje concurrente.
        Objetivo: p95 < 2s, sin pérdida de integridad
        """
        if not self.token: return
        
        payload = {
            "tipoReciclajeId": random.randint(1, 5),
            "cantidad": random.randint(1, 10),
            # Al no pasar usuarioId, el backend usará el del JWT
        }
        self.client.post(
            "/points/reciclar",
            json=payload,
            name="[PTS-PERF-001] POST /points/reciclar"
        )

    @task(1)
    @tag("canjes")
    def canjear_recompensa(self):
        """
        PTS-PERF-003: Simular canjes (Overselling test)
        """
        if not self.token: return
        
        payload = {
            "recompensaId": 1 # Asumimos que la recompensa 1 existe
        }
        self.client.post(
            "/points/canjes",
            json=payload,
            name="[PTS-PERF-003] POST /points/canjes"
        )

    @task(1)
    @tag("historial")
    def ver_transacciones(self):
        """Extra: Carga sobre la base de datos al listar historial"""
        if not self.token: return
        
        self.client.get(
            "/points/transacciones/historial",
            name="[PTS-PERF-X] GET /points/transacciones/historial"
        )


class ServicioIA_Mock(HttpUser):
    """
    Simula peticiones background enviadas por el servicio IA al servicio de puntos.
    Este endpoint en particular (/points/clasificacion-pendiente/**) está configurado como permitAll()
    en SecurityConfig.java, por lo que NO necesita token JWT.
    """
    wait_time = between(1, 2)

    @task
    @tag("clasificacion")
    def enviar_clasificacion_pendiente(self):
        """
        PTS-PERF-004: Recepción de clasificaciones concurrentes.
        Objetivo: p95 < 1s
        """
        bin_id = f"EcoSmartBin-Q{random.randint(1, 20):02d}"
        labels = ["plastic", "paper", "glass", "metal", "cardboard", "trash"]
        payload = {
            "binId": bin_id,
            "tipoDetectado": random.choice(labels),
            "confianza": random.uniform(0.6, 0.99)
        }
        self.client.post(
            "/points/clasificacion-pendiente",
            json=payload,
            name="[PTS-PERF-004] POST /points/clasificacion-pendiente"
        )


class ColdStartTest(HttpUser):
    """
    PTS-PERF-005: Prueba rápida para ver cuánto tarda en responder la raíz.
    El endpoint raíz ("/") también es permitAll().
    """
    wait_time = between(5, 10)
    
    @task
    @tag("health")
    def health_check(self):
        self.client.get(
            "/",
            name="[PTS-PERF-005] GET / (health/cold start)"
        )
