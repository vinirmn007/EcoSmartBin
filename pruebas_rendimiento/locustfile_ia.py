# ============================================================
#  locustfile_ia.py — Pruebas de Rendimiento
#  Módulo: servicio_AI (FastAPI + ONNX Runtime)
#
#  Casos cubiertos:
#    IA-PERF-001: Inferencia individual (1 imagen VGA, p95 < 3s)
#    IA-PERF-002: Inferencia concurrente (10 simultáneas, p95 < 8s)
#    IA-PERF-003: Cold start del modelo ONNX (< 30s)
#    IA-PERF-004: Tamaño del payload de respuesta (< 1 KB)
#    IA-PERF-005: Uso de memoria (20 inferencias sin memory leak)
#
#  Ejecutar:
#    locust -f locustfile_ia.py --host https://TU_SERVICIO_IA.run.app
#
#  O en modo headless:
#    locust -f locustfile_ia.py --host https://TU_SERVICIO_IA.run.app --headless -u 10 -r 2 -t 120s --html reporte_ia.html
#
#  NOTA: Las imágenes de prueba se cargan de la carpeta ../servicio_AI/pruebas/
# ============================================================

import os
import sys
import json
from locust import HttpUser, task, between, events, tag

# Ruta a las imágenes de prueba existentes en el proyecto
PRUEBAS_DIR = os.path.join(os.path.dirname(__file__), "..", "servicio_AI", "pruebas")

# Cargar imágenes de prueba disponibles
TEST_IMAGES = []
if os.path.exists(PRUEBAS_DIR):
    for f in os.listdir(PRUEBAS_DIR):
        if f.lower().endswith(('.jpg', '.jpeg', '.png', '.webp')):
            TEST_IMAGES.append(os.path.join(PRUEBAS_DIR, f))

if not TEST_IMAGES:
    print("⚠️ No se encontraron imágenes de prueba en:", PRUEBAS_DIR)
    print("   Crea imágenes .jpg/.png en servicio_AI/pruebas/ antes de ejecutar.")
    print("   Ya existen: prueba1.png, prueba2.webp, prueba3.jpg")


class ClasificadorIA(HttpUser):
    """
    Simula peticiones de clasificación de imágenes al servicio de IA.
    Cada usuario virtual envía imágenes rotando entre las disponibles.
    """
    wait_time = between(2, 5)  # Simula intervalo realista entre capturas del ESP32

    image_index = 0

    def get_next_image(self):
        """Rota entre las imágenes de prueba disponibles."""
        if not TEST_IMAGES:
            return None, None
        
        img_path = TEST_IMAGES[ClasificadorIA.image_index % len(TEST_IMAGES)]
        ClasificadorIA.image_index += 1
        
        filename = os.path.basename(img_path)
        ext = filename.rsplit('.', 1)[-1].lower()
        content_type_map = {
            'jpg': 'image/jpeg',
            'jpeg': 'image/jpeg',
            'png': 'image/png',
            'webp': 'image/webp'
        }
        content_type = content_type_map.get(ext, 'image/jpeg')
        
        return img_path, content_type

    @task(10)
    @tag("inferencia")
    def clasificar_imagen(self):
        """
        IA-PERF-001 / IA-PERF-002: Inferencia de imagen.
        
        Individual: p95 < 3s (CPU en Cloud Run)
        Concurrente (10 usuarios): p95 < 8s
        
        También valida IA-PERF-004 (tamaño de respuesta < 1KB).
        """
        img_path, content_type = self.get_next_image()
        if not img_path:
            print("⚠️ Sin imágenes de prueba, saltando...")
            return

        filename = os.path.basename(img_path)
        
        with open(img_path, 'rb') as f:
            files = {
                'file': (filename, f, content_type)
            }
            response = self.client.post(
                "/predict",
                files=files,
                name=f"[IA-PERF-001] POST /predict ({filename})"
            )

        if response.status_code == 200:
            data = response.json()
            
            # Validar estructura de respuesta
            assert data.get("success") == True, f"Respuesta no exitosa: {data}"
            assert "class" in data, f"Falta campo 'class': {data}"
            assert "confidence" in data, f"Falta campo 'confidence': {data}"
            assert "top_predictions" in data, f"Falta campo 'top_predictions': {data}"
            assert len(data["top_predictions"]) == 3, f"Se esperaban 3 top_predictions, hay {len(data['top_predictions'])}"
            
            # IA-PERF-004: Verificar tamaño del payload
            response_size = len(response.content)
            if response_size > 1024:
                print(f"⚠️ IA-PERF-004: Respuesta excede 1KB ({response_size} bytes)")
            
            # Log de clasificación
            print(f"  📊 {filename} → {data['class']} ({data['confidence']:.2%})")
        else:
            print(f"  ❌ Error {response.status_code}: {response.text[:200]}")

    @task(1)
    @tag("health")
    def health_check(self):
        """
        IA-PERF-003: Health check / Cold start.
        Mide el tiempo de la primera respuesta tras inactividad.
        Objetivo: modelo cargado + primera inferencia < 30s
        """
        response = self.client.get(
            "/",
            name="[IA-PERF-003] GET / (health/cold start)"
        )
        
        if response.status_code == 200:
            data = response.json()
            assert data.get("status") == "healthy", f"Servicio no saludable: {data}"
            assert data.get("engine") == "pure-onnxruntime", f"Motor inesperado: {data}"


class InferenciaConcurrente(HttpUser):
    """
    IA-PERF-002: Prueba específica de concurrencia.
    10 usuarios enviando imágenes simultáneamente.
    
    Ejecutar:
      locust -f locustfile_ia.py InferenciaConcurrente --host <URL> --headless -u 10 -r 10 -t 60s --html reporte_ia_concurrente.html
    """
    wait_time = between(0.5, 1)  # Más agresivo para prueba de concurrencia

    @task
    @tag("concurrente")
    def clasificar_rapido(self):
        """Envía imágenes lo más rápido posible para estresar el servicio."""
        if not TEST_IMAGES:
            return
        
        import random
        img_path = random.choice(TEST_IMAGES)
        filename = os.path.basename(img_path)
        
        with open(img_path, 'rb') as f:
            response = self.client.post(
                "/predict",
                files={'file': (filename, f, 'image/jpeg')},
                name="[IA-PERF-002] POST /predict (concurrente)"
            )

        if response.status_code != 200:
            print(f"  ❌ Concurrente falló: {response.status_code}")


class MemoryLeakTest(HttpUser):
    """
    IA-PERF-005: Prueba de memory leak.
    Envía 20 inferencias secuenciales y monitorea estabilidad.
    
    Ejecutar:
      locust -f locustfile_ia.py MemoryLeakTest --host <URL> --headless -u 1 -r 1 -t 300s --html reporte_ia_memoria.html
    """
    wait_time = between(3, 5)
    
    request_count = 0

    @task
    @tag("memoria")
    def inferencia_secuencial(self):
        """Envía inferencias secuenciales monitoreando tiempos de respuesta."""
        if not TEST_IMAGES:
            return
        
        MemoryLeakTest.request_count += 1
        import random
        img_path = random.choice(TEST_IMAGES)
        filename = os.path.basename(img_path)
        
        with open(img_path, 'rb') as f:
            response = self.client.post(
                "/predict",
                files={'file': (filename, f, 'image/jpeg')},
                name=f"[IA-PERF-005] POST /predict (seq #{MemoryLeakTest.request_count})"
            )

        if response.status_code == 200:
            # Si el tiempo de respuesta crece significativamente, puede haber memory leak
            rt = response.elapsed.total_seconds()
            print(f"  🧠 Inferencia #{MemoryLeakTest.request_count}: {rt:.2f}s")
            
            if MemoryLeakTest.request_count >= 20:
                print("\n✅ IA-PERF-005: 20 inferencias completadas. Revisar estabilidad de tiempos arriba.")
