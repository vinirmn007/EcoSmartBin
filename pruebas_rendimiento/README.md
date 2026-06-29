# 🚀 Pruebas de Rendimiento - EcoSmartBin

Este directorio contiene los scripts automatizados para las pruebas de rendimiento descritas en el **Plan de Pruebas**, utilizando [Locust](https://locust.io/), una herramienta moderna basada en Python.

## 1. Requisitos e Instalación

Asegúrate de tener Python 3.9+ instalado en tu máquina. Instala las dependencias necesarias:

```bash
cd pruebas_rendimiento
pip install -r requirements.txt
```

## 2. Configuración (`config.py`)

El archivo `config.py` contiene las URLs de los servicios de Cloud Run y las credenciales de prueba. 
**Importante:** Modifica `TEST_USER_EMAIL` y `TEST_USER_PASSWORD` en `config.py` y `locustfile_usuarios.py` para usar una cuenta existente en tu Supabase Auth para que las pruebas de login sean exitosas.

## 3. Cómo ejecutar las pruebas

Locust permite ejecutar pruebas con una interfaz web (para monitoreo en tiempo real) o en modo "headless" (por consola, ideal para generar reportes HTML automáticos).

### Opción A: Interfaz Web (Recomendado para pruebas exploratorias)

**1. Servicio de Usuarios:**
```bash
locust -f locustfile_usuarios.py --host https://ecosmartbin-229724129072.southamerica-west1.run.app
```

**2. Servicio de IA:**
```bash
locust -f locustfile_ia.py --host http://136.68.254.51
```
*(Nota: Cambia la URL por la real del servicio IA)*

**3. Servicio de Puntos:**
```bash
locust -f locustfile_puntos.py --host https://servicio-puntos-229724129072.southamerica-west1.run.app
```

**4. API Gateway:**
```bash
locust -f locustfile_gateway.py --host https://gateway-229724129072.southamerica-west1.run.app
```

> Después de ejecutar el comando, abre tu navegador en [http://localhost:8089](http://localhost:8089). Ahí podrás definir el número de usuarios simultáneos (Spawn rate) e iniciar la prueba.

---

### Opción B: Modo Headless (Generar Reportes HTML Oficiales)

Para los reportes finales, ejecuta los comandos en modo headless. Esto correrá la prueba durante el tiempo especificado y generará un reporte HTML interactivo con las gráficas de rendimiento.

**Prueba 1: Login Concurrente y Perfiles (1 minuto, 50 usuarios):**
```bash
locust -f locustfile_usuarios.py --host https://ecosmartbin-229724129072.southamerica-west1.run.app --headless -u 50 -r 5 -t 60s --html reporte_usuarios.html
```

**Prueba 2: Inferencia IA Concurrente (1 minuto, 10 usuarios):**
```bash
locust -f locustfile_ia.py InferenciaConcurrente --host http://136.68.254.51 --headless -u 10 -r 2 -t 60s --html reporte_ia.html
```

**Prueba 3: Operaciones de Puntos (1 minuto, 30 usuarios):**
```bash
locust -f locustfile_puntos.py --host https://servicio-puntos-229724129072.southamerica-west1.run.app --headless -u 30 -r 5 -t 60s --html reporte_puntos.html
```

**Prueba 4: API Gateway Latencia (1 minuto, 100 usuarios):**
```bash
locust -f locustfile_gateway.py --host https://gateway-229724129072.southamerica-west1.run.app --headless -u 100 -r 10 -t 60s --html reporte_gateway.html
```

## 4. Notas sobre el Servicio de IA
El script `locustfile_ia.py` carga automáticamente las imágenes (prueba1.png, prueba2.webp, prueba3.jpg) de la carpeta `../servicio_AI/pruebas/`. Asegúrate de que esos archivos existan y sean imágenes válidas antes de iniciar la prueba.
