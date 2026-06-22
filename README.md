# 🌿 EcoSmartBin — Sistema Distribuido

> Sistema de puntos ecológicos con algoritmos de computación distribuida implementados en tiempo real sobre un cluster de 3 computadoras.

---

## 📋 ¿Qué tiene el sistema?

| Componente | Tecnología | Descripción |
|---|---|---|
| `servicio_puntos` | Java / Spring Boot | Nodo del cluster (Bully + Lamport + Mutex) |
| `servicio_usuarios` | Python / FastAPI | Autenticación con Supabase |
| `servicio_gateway` | Java / Spring Boot | Proxy inteligente → redirige al líder |
| `frontend` | Flutter | App móvil/web con panel distribuido en tiempo real |

### Algoritmos implementados
- ⚡ **Bully** — Elección de líder distribuida
- 🕐 **Relojes Lógicos de Lamport** — Ordenamiento de eventos sin reloj global
- 🔒 **Exclusión Mutua (Ricart-Agrawala)** — Un solo nodo en sección crítica a la vez

---

## 🖥️ Distribución de computadoras

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   COMPUTADORA 1  │     │   COMPUTADORA 2  │     │   COMPUTADORA 3  │
│   (Marco)        │     │   (Compañero 2)  │     │   (Compañero 3)  │
│                  │     │                  │     │                  │
│ • Nodo 1 :8081   │     │ • Nodo 2 :8082   │     │ • Nodo 3 :8083   │
│ • Gateway :8080  │     │                  │     │ (Líder inicial)  │
│ • Frontend       │     │                  │     │                  │
└────────┬─────────┘     └────────┬─────────┘     └────────┬─────────┘
         └────────────────────────┼────────────────────────┘
                          Router / Switch
                        (misma red local)
```

> **Nodo 3 tiene el ID más alto → es siempre el líder inicial.**

---

## ⚙️ Requisitos en CADA computadora

1. **Docker Desktop** — https://www.docker.com/products/docker-desktop/
   - Instalar y asegurarse que esté corriendo (ícono en la barra de tareas)
2. **Git** — para clonar el proyecto
3. **Conexión a internet** — para que Docker descargue imágenes y Supabase responda

---

## 🚀 Instalación paso a paso

### PASO 1 — Clonar el proyecto (en cada computadora)

```bash
git clone https://github.com/tu-usuario/EcoSmartBin.git
cd EcoSmartBin
```

> O copiar la carpeta del proyecto con USB si no tienen git.

---

### PASO 2 — Conectarse a la misma red

Las 3 PCs **deben estar en la misma red WiFi o router**.

Opciones:
- ✅ Router WiFi propio (el mejor)
- ✅ WiFi de la universidad (si permite comunicación entre dispositivos)
- ✅ Hotspot desde una PC: `Configuración → Zona con cobertura móvil`

---

### PASO 3 — Obtener la IP de cada computadora

En **PowerShell** o **CMD**, ejecutar:
```powershell
ipconfig
```
Buscar **"Dirección IPv4"** (algo como `192.168.x.x`).

Anotar las IPs de las 3 PCs:
```
PC1 (Marco)       → _______________
PC2 (Compañero 2) → _______________
PC3 (Compañero 3) → _______________
```

Verificar conectividad (desde PC1):
```powershell
ping IP_DE_PC2
ping IP_DE_PC3
```
Si no responde → ver sección [Problemas comunes](#-problemas-comunes).

---

### PASO 4 — Editar las IPs en el docker-compose de tu nodo

> ⚠️ **Cada persona edita SOLO el archivo de su nodo.**

#### Computadora 1 → edita `docker-compose-nodo1.yml`
```yaml
NODE_URLS: "http://IP_PC1:8081,http://IP_PC2:8082,http://IP_PC3:8083"
```

#### Computadora 2 → edita `docker-compose-nodo2.yml`
```yaml
NODE_URLS: "http://IP_PC1:8081,http://IP_PC2:8082,http://IP_PC3:8083"
```

#### Computadora 3 → edita `docker-compose-nodo3.yml`
```yaml
NODE_URLS: "http://IP_PC1:8081,http://IP_PC2:8082,http://IP_PC3:8083"
```

> Reemplaza `IP_PC1`, `IP_PC2`, `IP_PC3` con las IPs reales del Paso 3.

---

### PASO 5 — Abrir puertos en el Firewall de Windows

Ejecutar en **PowerShell como Administrador** en cada PC:

```powershell
netsh advfirewall firewall add rule name="EcoSmartBin-8081" protocol=TCP dir=in localport=8081 action=allow
netsh advfirewall firewall add rule name="EcoSmartBin-8082" protocol=TCP dir=in localport=8082 action=allow
netsh advfirewall firewall add rule name="EcoSmartBin-8083" protocol=TCP dir=in localport=8083 action=allow
netsh advfirewall firewall add rule name="EcoSmartBin-8080" protocol=TCP dir=in localport=8080 action=allow
```

---

### PASO 6 — Arrancar el nodo (en cada computadora)

> ⚠️ El primer `up --build` tarda **2-5 minutos** porque descarga dependencias.

#### Computadora 1:
```powershell
docker-compose -f docker-compose-nodo1.yml up --build
```

#### Computadora 2:
```powershell
docker-compose -f docker-compose-nodo2.yml up --build
```

#### Computadora 3:
```powershell
docker-compose -f docker-compose-nodo3.yml up --build
```

Cuando veas en los logs algo como:
```
[BULLY] Nodo X se proclama LÍDER
```
¡El cluster está listo!

---

### PASO 7 — Levantar el Gateway (solo Computadora 1)

El gateway es el punto de entrada para el frontend. Solo corre en **una computadora** (la de Marco):

```powershell
docker-compose -f docker-compose-gateway.yml up --build
```

> Si no tienes ese archivo, el gateway puede correrse con `start-cluster.bat` localmente.

---

### PASO 8 — Verificar que todo funciona

Desde cualquier computadora, abrir el navegador y probar:

```
http://IP_PC1:8081/api/bully/status   → Nodo 1
http://IP_PC2:8082/api/bully/status   → Nodo 2
http://IP_PC3:8083/api/bully/status   → Nodo 3
http://IP_PC1:8080/gateway/status     → Gateway
```

Respuesta esperada del Nodo 3 (líder):
```json
{
  "nodeId": 3,
  "currentLeaderId": 3,
  "isLeader": true,
  "electionInProgress": false
}
```

También verificar los nuevos algoritmos:
```
http://IP_PC1:8081/api/lamport/status
http://IP_PC1:8081/api/mutex/status
```

---

## 📱 Frontend (App Flutter)

El frontend puede correr en modo **web** directamente desde la PC 1.

### Requisitos:
- Flutter SDK instalado: https://docs.flutter.dev/get-started/install/windows

### Correr en el navegador:
```powershell
cd frontend
flutter run -d edge
```
o para Chrome:
```powershell
flutter run -d chrome
```

### ⚠️ Configurar las URLs del frontend

Si el frontend corre en PC1 pero los nodos están en distintas IPs, edita:

`frontend/lib/services/api_service.dart`:

```dart
// URL del Gateway
static String get gatewayUrl => 'http://IP_PC1:8080';

// URLs de cada nodo (para el Laboratorio Distribuido)
static List<String> get nodeUrls => [
  'http://IP_PC1:8081',
  'http://IP_PC2:8082',
  'http://IP_PC3:8083',
];
```

---

## 🧪 Pantalla "Laboratorio Distribuido"

Desde la app, ve a **EcoPuntos → botón 🔬 (arriba a la derecha)** o navega directamente a `/lab`.

Tiene 3 tabs:

| Tab | Qué muestra | Cómo probar |
|-----|-------------|-------------|
| ⚡ Bully | Estado de los 3 nodos, líder actual | Detener un contenedor → ver nueva elección |
| 🕐 Lamport | Relojes de cada nodo | Presionar "Disparar Evento" → ver relojes actualizarse |
| 🔒 Mutex | Estado RELEASED/WANTED/HELD | Solicitar SC desde 2 nodos → uno espera al otro |

---

## 🧪 Demo para la presentación

### Demo 1 — Bully
1. Mostrar los 3 nodos activos (Nodo 3 = líder 👑)
2. Detener contenedor del Nodo 3: `docker stop bully-nodo3`
3. Esperar ~10 seg → nueva elección → Nodo 2 queda como líder
4. Reiniciar: `docker start bully-nodo3` → reconoce al líder actual

### Demo 2 — Lamport
1. Mostrar los 3 relojes en valores pequeños
2. Disparar evento desde Nodo 1 → reloj sube → propaga a los demás
3. Disparar desde Nodo 3 → ver `max(local, recibido)+1`

### Demo 3 — Exclusión Mutua
1. Los 3 nodos en RELEASED (gris)
2. Solicitar SC desde Nodo 1 → entra a HELD (verde) por 3 seg
3. Solicitar SC desde Nodo 2 mientras Nodo 1 está en HELD → Nodo 2 queda en WANTED (naranja)
4. Nodo 1 termina → libera → Nodo 2 entra a HELD automáticamente

---

## ⚠️ Problemas Comunes

### `ping` no responde entre PCs
- Habilitar ping en el firewall:
  `Panel de control → Firewall → Configuración avanzada → Reglas de entrada → Habilitar "Eco ICMPv4"`

### Contenedor no arranca
```powershell
docker logs bully-nodo1   # ver los logs completos
```

### Los nodos no se ven entre sí
- Verificar que `NODE_URLS` tiene las IPs correctas en el docker-compose
- Verificar que los puertos están abiertos (Paso 5)
- Verificar con: `curl http://IP_PC2:8082/api/bully/status` desde PC1

### El gateway no encuentra al líder
- Esperar 10-15 segundos para que los nodos elijan líder
- Verificar que los 3 nodos responden antes de arrancar el gateway

---

## 📁 Estructura del Proyecto

```
EcoSmartBin/
├── servicio_puntos/          ← Nodo del cluster (Bully + Lamport + Mutex)
│   └── src/main/java/...
│       ├── service/
│       │   ├── BullyService.java
│       │   ├── LamportService.java
│       │   └── MutexService.java
│       └── controller/
│           ├── BullyController.java
│           ├── LamportController.java
│           └── MutexController.java
├── servicio_usuarios/        ← Auth con Supabase (Python/FastAPI)
├── servicio_gateway/         ← Proxy inteligente al líder
├── frontend/                 ← App Flutter
│   └── lib/screens/
│       ├── puntos_screen.dart
│       └── distributed_lab_screen.dart   ← NUEVO
├── docker-compose-nodo1.yml  ← PC1 corre este
├── docker-compose-nodo2.yml  ← PC2 corre este
├── docker-compose-nodo3.yml  ← PC3 corre este
├── docker-compose-gateway.yml
├── SWITCH_INSTRUCCIONES.md   ← Guía detallada del switch
└── README.md                 ← Este archivo
```

---

## 👥 Asignación por persona

| Persona | Archivo docker-compose | Puerto | Rol |
|---------|----------------------|--------|-----|
| **Marco (tú)** | `docker-compose-nodo1.yml` | 8081 | Nodo 1 + Gateway + Frontend |
| **Compañero 2** | `docker-compose-nodo2.yml` | 8082 | Nodo 2 |
| **Compañero 3** | `docker-compose-nodo3.yml` | 8083 | Nodo 3 (Líder inicial) |

---

*Para instrucciones detalladas de red con switch físico, ver [SWITCH_INSTRUCCIONES.md](./SWITCH_INSTRUCCIONES.md)*
