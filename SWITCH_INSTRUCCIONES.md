# 🌐 Guía de Prueba con Switch/Router Real
## EcoSmartBin — Sistema Distribuido con 3 Computadoras

---

## ✅ Requisitos

| Qué | Dónde |
|-----|-------|
| 3 PCs con Docker Desktop instalado | Una por computadora |
| Router WiFi hogareño O red WiFi de universidad | El mismo router para las 3 |
| El código del proyecto | En las 3 PCs (copiar con USB o clonar desde git) |
| Acceso a internet | Para Supabase (base de datos en la nube) |

---

## 📡 PASO 1 — Conectar las 3 PCs a la misma red

**Opción A — Router propio (recomendado):**
```
PC1 ──cable──┐
PC2 ──cable──┼── Router WiFi ── Internet (Supabase)
PC3 ──cable──┘
```

**Opción B — Red WiFi de la universidad:**
```
PC1 ──WiFi──┐
PC2 ──WiFi──┼── AP Universidad ── Internet
PC3 ──WiFi──┘
             (Verificar que el firewall permita comunicación entre PCs)
```

**Opción C — Hotspot desde una PC:**
```
PC2 ──WiFi──┐
PC3 ──WiFi──┤── PC1 (Hotspot) ── [cable ethernet o WiFi con internet]
```
> PC1 crea un hotspot: `Configuración → Red e Internet → Zona con cobertura móvil`

---

## 🔍 PASO 2 — Obtener las IPs de cada PC

En cada computadora, abrir PowerShell o CMD y correr:

```powershell
ipconfig
```

Buscar **"Dirección IPv4"** en la sección del adaptador conectado al router.

Ejemplo:
```
PC1 → 192.168.1.10
PC2 → 192.168.1.11
PC3 → 192.168.1.12
```

---

## 🔌 PASO 3 — Verificar conectividad entre PCs

Desde **PC1**, ejecutar:
```powershell
ping 192.168.1.11    # debe responder desde PC2
ping 192.168.1.12    # debe responder desde PC3
```

> ⚠️ Si no responde: verificar que el **Firewall de Windows** permita ICMP (ping).
> ```
> Configuración → Windows Security → Firewall → Reglas de entrada → Habilitar "ICMPv4-In"
> ```

---

## ✏️ PASO 4 — Editar las IPs en cada docker-compose

### En **PC1** → editar `docker-compose-nodo1.yml`:
```yaml
NODE_URLS: "http://192.168.1.10:8081,http://192.168.1.11:8082,http://192.168.1.12:8083"
```
*(Reemplaza con las IPs reales que obtuviste en el Paso 2)*

### En **PC2** → editar `docker-compose-nodo2.yml`:
```yaml
NODE_URLS: "http://192.168.1.10:8081,http://192.168.1.11:8082,http://192.168.1.12:8083"
```

### En **PC3** → editar `docker-compose-nodo3.yml`:
```yaml
NODE_URLS: "http://192.168.1.10:8081,http://192.168.1.11:8082,http://192.168.1.12:8083"
```

> **Nota:** `NODE_URLS` es el mismo en los 3 archivos. Solo cambia la línea `NODE_ID` y `NODE_PORT` en cada uno.

---

## 🚀 PASO 5 — Arrancar los nodos

Ejecutar en **cada PC** en su docker-compose correspondiente:

**PC1:**
```powershell
docker-compose -f docker-compose-nodo1.yml up --build
```

**PC2:**
```powershell
docker-compose -f docker-compose-nodo2.yml up --build
```

**PC3:**
```powershell
docker-compose -f docker-compose-nodo3.yml up --build
```

> 💡 El primer build tarda ~2-3 minutos. Los siguientes arrancan en segundos.

---

## ✔️ PASO 6 — Verificar que todo funciona

### Verificar cada nodo (desde cualquier PC):
```powershell
# Nodo 1
curl http://192.168.1.10:8081/api/bully/status

# Nodo 2
curl http://192.168.1.11:8082/api/bully/status

# Nodo 3
curl http://192.168.1.12:8083/api/bully/status
```

Respuesta esperada:
```json
{
  "nodeId": 1,
  "currentLeaderId": 3,
  "isLeader": false,
  "electionInProgress": false
}
```

### Verificar Lamport:
```powershell
curl http://192.168.1.10:8081/api/lamport/status
curl -X POST http://192.168.1.10:8081/api/lamport/event
```

### Verificar Mutex:
```powershell
curl http://192.168.1.10:8081/api/mutex/status
curl -X POST http://192.168.1.11:8082/api/mutex/request
```

---

## 📱 PASO 7 — Configurar el Frontend (Flutter)

### Para prueba local (app apunta a localhost):
El frontend ya está configurado para `localhost`. Si el frontend corre en **PC1** y los nodos están en las 3 PCs, necesitas actualizar las URLs en `api_service.dart`:

```dart
// En frontend/lib/services/api_service.dart
static List<String> get nodeUrls => [
  'http://192.168.1.10:8081',   // Nodo 1 - PC1
  'http://192.168.1.11:8082',   // Nodo 2 - PC2
  'http://192.168.1.12:8083',   // Nodo 3 - PC3
];

static String get gatewayUrl {
  // Si el gateway está en PC1:
  return 'http://192.168.1.10:8080';
}
```

---

## 🎯 DEMOS para la Presentación

### Demo 1 — Bully (Elección de Líder)
1. Mostrar los 3 nodos activos en la pantalla del Laboratorio (Tab Bully)
2. Detener el contenedor del nodo con mayor ID (PC3): `docker stop bully-nodo3`
3. Esperar ~10 segundos → los demás detectan la caída → elección → nuevo líder
4. Reiniciar PC3: `docker start bully-nodo3` → reconoce al nuevo líder

### Demo 2 — Relojes de Lamport
1. Ir a Tab Lamport → mostrar los 3 relojes en 0
2. Presionar "Disparar Evento en Nodo 1" → reloj de Nodo 1 sube, los demás se actualizan
3. Presionar "Disparar Evento en Nodo 3" → ver cómo max(local, recibido)+1 sincroniza
4. Demostrar que el reloj nunca retrocede

### Demo 3 — Exclusión Mutua (Ricart-Agrawala)
1. Ir a Tab Mutex → los 3 nodos en RELEASED
2. Solicitar SC desde Nodo 1 → entra a HELD (verde) por 3 segundos
3. Mientras está en HELD, solicitar SC desde Nodo 2 → queda en WANTED (naranja)
4. Cuando Nodo 1 libera → Nodo 2 recibe el OK y entra a HELD
5. Demostrar que jamás dos nodos están en HELD al mismo tiempo

---

## ⚠️ Problemas Comunes

| Problema | Causa | Solución |
|----------|-------|----------|
| `Connection refused` entre nodos | Firewall de Windows bloqueando puertos | Abrir puertos 8081, 8082, 8083 en el firewall |
| Nodos no se ven entre sí | Red universitaria con aislamiento de clientes | Usar hotspot propio |
| Supabase no conecta | Sin internet | Verificar que el router tiene salida a internet |
| Bully no elige líder | Nodos no pueden comunicarse | Verificar con `ping` y `curl` primero |

### Abrir puertos en Windows Firewall:
```powershell
# Ejecutar como Administrador
netsh advfirewall firewall add rule name="EcoSmartBin-8081" protocol=TCP dir=in localport=8081 action=allow
netsh advfirewall firewall add rule name="EcoSmartBin-8082" protocol=TCP dir=in localport=8082 action=allow
netsh advfirewall firewall add rule name="EcoSmartBin-8083" protocol=TCP dir=in localport=8083 action=allow
netsh advfirewall firewall add rule name="EcoSmartBin-8080" protocol=TCP dir=in localport=8080 action=allow
```

---

## 📋 Checklist Final

- [ ] Las 3 PCs están conectadas al mismo router
- [ ] `ping` funciona entre todas las PCs
- [ ] Cada docker-compose tiene las IPs reales correctas
- [ ] Los 3 contenedores están corriendo (`docker ps`)
- [ ] `/api/bully/status` responde en los 3 nodos
- [ ] `/api/lamport/status` responde en los 3 nodos
- [ ] `/api/mutex/status` responde en los 3 nodos
- [ ] El frontend puede ver los 3 nodos en el Laboratorio Distribuido
