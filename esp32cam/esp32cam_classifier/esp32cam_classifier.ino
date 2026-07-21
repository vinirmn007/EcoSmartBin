/*
 * EcoSmartBin - ESP32-CAM Garbage Classifier (Single Servo + Botón Físico)
 *
 * Captura una foto con la cámara cuando el usuario presiona el botón físico,
 * la envía al servicio de IA con el bin_id para validar la sesión QR,
 * y mueve el único servo selector al compartimento correspondiente.
 *
 *   SERVO SELECTOR — Selector de compartimento (GPIO 14)
 *     Rota para apuntar la rampa/placa al compartimento correcto:
 *       0°   → Basura General (trash, cardboard, paper, desconocido)
 *       45°  → Plástico
 *       90°  → Vidrio
 *       135° → Metal
 *
 *   BOTÓN FÍSICO (GPIO 13)
 *     Presionar para tomar foto y clasificar.
 *
 * Flujo completo:
 *   1. El usuario presiona el botón físico (GPIO 13).
 *   2. Enciende flash brevemente, captura foto y la envía a la IA con bin_id.
 *   3. La IA valida la sesión QR del basurero y clasifica la basura.
 *   4. El Servo Selector rota al compartimento correspondiente (0°, 45°, 90° o 135°).
 *   5. Espera a que la basura caiga/se deslice al compartimento.
 *   6. Confirma depósito por Serial Monitor.
 *   7. El Servo Selector regresa a la posición inicial (0°) y queda en espera.
 *
 * Conexiones:
 *   - ESP32-CAM AI-Thinker
 *   - Botón Físico          : GPIO 13 (INPUT_PULLUP, activo en LOW)
 *   - LED Flash              : GPIO 4  (built-in)
 *   - Servo Selector (Señal) : GPIO 14 (alimentación a 5V externa + GND común)
 */

#include "esp_camera.h"
#include <WiFi.h>
#include <HTTPClient.h>
#include <ESP32Servo.h>

// ===========================
// CONFIGURACIÓN - EDITAR AQUÍ
// ===========================

// WiFi
const char* ssid     = "Marco_Omar";
const char* password = "1720500Mm.";

// URL del servicio de IA
const char* serverUrl = "http://136.68.254.51/predict";

// ID del basurero (debe coincidir con el registrado en servicio_basureros)
const char* binId = "eco01";

// ===========================
// PINES
// ===========================
#define BUTTON_PIN      13   // Botón físico para disparar captura (activo LOW)
#define OBSTACLE_PIN    15   // Sensor de obstáculos (GPIO 15 es seguro para arranque, activo LOW)
#define FLASH_LED_PIN    4   // LED flash integrado del ESP32-CAM
#define SERVO_SELECTOR  14   // Servo Selector de compartimento (GPIO 14)

// ===========================
// TIEMPOS
// ===========================
#define TIEMPO_ESPERA_CAIDA_MS  5000   // Tiempo (ms) que el servo se queda en la posición de vertido
#define SERVO_MOVE_DELAY_MS      300   // Tiempo de espera tras movimiento del servo
#define SERVO_STEP_DELAY_MS        3   // Milisegundos por grado (3ms = movimiento rápido)

// ===========================
// ÁNGULOS — COMPARTIMENTOS
// ===========================
//   Compartimento 1: Basura General  →  0°   (trash, cardboard, paper, desconocido)
//   Compartimento 2: Plástico        →  45°
//   Compartimento 3: Vidrio          →  90°
//   Compartimento 4: Metal           →  135°
#define ANGLE_TRASH      0
#define ANGLE_PLASTICO   45
#define ANGLE_VIDRIO     90
#define ANGLE_METAL      135

// ===========================
// CONFIGURACIÓN CÁMARA AI-THINKER
// ===========================
#define PWDN_GPIO_NUM     32
#define RESET_GPIO_NUM    -1
#define XCLK_GPIO_NUM      0
#define SIOD_GPIO_NUM     26
#define SIOC_GPIO_NUM     27
#define Y9_GPIO_NUM       35
#define Y8_GPIO_NUM       34
#define Y7_GPIO_NUM       39
#define Y6_GPIO_NUM       36
#define Y5_GPIO_NUM       21
#define Y4_GPIO_NUM       19
#define Y3_GPIO_NUM       18
#define Y2_GPIO_NUM        5
#define VSYNC_GPIO_NUM    25
#define HREF_GPIO_NUM     23
#define PCLK_GPIO_NUM     22

// ===========================
// OBJETOS GLOBALES
// ===========================
Servo servoSelector;
int anguloActualSelector = 0; // Guarda la posición actual del servo

// ===========================
// SERVO — FUNCIONES
// ===========================

/*
 * Mueve suavemente el servo al ángulo objetivo.
 * Velocidad controlada por SERVO_STEP_DELAY_MS (3ms por grado = ~3x más rápido).
 */
void moverServoSuave(int anguloObjetivo) {
  int paso = (anguloObjetivo > anguloActualSelector) ? 1 : -1;
  for (int ang = anguloActualSelector; ang != anguloObjetivo; ang += paso) {
    servoSelector.write(ang);
    delay(SERVO_STEP_DELAY_MS);
  }
  servoSelector.write(anguloObjetivo);
  anguloActualSelector = anguloObjetivo;
}

/*
 * Retorna el ángulo correspondiente a la categoría detectada por la IA.
 *
 * Mapeo:
 *   plastic              → Compartimento 2 (Plástico)       → 45°
 *   metal                → Compartimento 4 (Metal)          → 135°
 *   glass                → Compartimento 3 (Vidrio)         → 90°
 *   trash/cardboard/paper/otro → Compartimento 1 (Basura General) → 0°
 */
int obtenerAnguloCompartimento(String categoria) {
  categoria.toLowerCase();
  categoria.trim();

  if (categoria == "plastic") {
    Serial.println("♻️  Categoría: Plástico → Compartimento 2 → 45°");
    return ANGLE_PLASTICO;
  }
  else if (categoria == "metal") {
    Serial.println("🔩  Categoría: Metal → Compartimento 4 → 135°");
    return ANGLE_METAL;
  }
  else if (categoria == "glass") {
    Serial.println("🍶  Categoría: Vidrio → Compartimento 3 → 90°");
    return ANGLE_VIDRIO;
  }
  else if (categoria == "trash" || categoria == "cardboard" || categoria == "paper") {
    Serial.println("🗑️  Categoría: Basura General → Compartimento 1 → 0°");
    return ANGLE_TRASH;
  }
  else {
    Serial.printf("⚠️  Categoría no reconocida: '%s' → Basura General → 0°\n", categoria.c_str());
    return ANGLE_TRASH;
  }
}

/*
 * Mueve el servo selector a la categoría de basura, espera a que caiga y regresa a 0.
 */
void procesarDescarteBasura(String categoria) {
  int anguloDestino = obtenerAnguloCompartimento(categoria);

  // ─── Paso 1: Mover rampa/selector al compartimento ───
  if (anguloDestino != anguloActualSelector) {
    Serial.printf("⚙️  Girando selector a %d°...\n", anguloDestino);
    moverServoSuave(anguloDestino);
    delay(SERVO_MOVE_DELAY_MS);
  } else {
    Serial.println("⚙️  El selector ya está en la posición correcta.");
  }

  // ─── Paso 2: Mantener posición para la caída ───
  Serial.printf("⏳  Esperando %d segundos a que caiga la basura...\n", TIEMPO_ESPERA_CAIDA_MS / 1000);
  delay(TIEMPO_ESPERA_CAIDA_MS);

  // ─── Paso 3: Verificar depósito con sensor de obstáculos (GPIO 15) ───
  bool depositoDetectado = (digitalRead(OBSTACLE_PIN) == LOW);

  Serial.println("══════════════════════════════════════════════");
  if (depositoDetectado) {
    Serial.println("✅  DEPÓSITO CONFIRMADO — Sensor detectó la basura en el compartimento.");
  } else {
    Serial.println("⚠️  DEPÓSITO NO DETECTADO — El sensor no detectó la basura.");
  }
  Serial.printf("   📦 Categoría IA: %s\n", categoria.c_str());
  Serial.printf("   🎯 Compartimento: %d°\n", anguloDestino);
  Serial.printf("   🗑️ Basurero: %s\n", binId);
  Serial.printf("   📡 Sensor obstáculo: %s\n", depositoDetectado ? "ACTIVADO" : "SIN DETECCIÓN");
  Serial.println("══════════════════════════════════════════════");

  // ─── Paso 4: Regresar a reposo (0° = Basura General) ───
  if (anguloActualSelector != ANGLE_TRASH) {
    Serial.println("↩️  Regresando selector a posición de reposo (0°)...");
    moverServoSuave(ANGLE_TRASH);
    delay(SERVO_MOVE_DELAY_MS);
  }

  Serial.println("✅  Listo para la siguiente clasificación.\n");
}

// ===========================
// PARSEO JSON
// ===========================

String extraerCategoria(String json) {
  int idxKey = json.indexOf("\"class\"");
  if (idxKey == -1) {
    idxKey = json.indexOf("\"predicted_class\"");
  }
  if (idxKey == -1) return "";

  int idxColon = json.indexOf(":", idxKey);
  if (idxColon == -1) return "";

  int idxOpen = json.indexOf("\"", idxColon + 1);
  if (idxOpen == -1) return "";

  int idxClose = json.indexOf("\"", idxOpen + 1);
  if (idxClose == -1) return "";

  return json.substring(idxOpen + 1, idxClose);
}

// ===========================
// CÁMARA
// ===========================

void initCamera() {
  camera_config_t config;
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer   = LEDC_TIMER_0;
  config.pin_d0       = Y2_GPIO_NUM;
  config.pin_d1       = Y3_GPIO_NUM;
  config.pin_d2       = Y4_GPIO_NUM;
  config.pin_d3       = Y5_GPIO_NUM;
  config.pin_d4       = Y6_GPIO_NUM;
  config.pin_d5       = Y7_GPIO_NUM;
  config.pin_d6       = Y8_GPIO_NUM;
  config.pin_d7       = Y9_GPIO_NUM;
  config.pin_xclk     = XCLK_GPIO_NUM;
  config.pin_pclk     = PCLK_GPIO_NUM;
  config.pin_vsync    = VSYNC_GPIO_NUM;
  config.pin_href     = HREF_GPIO_NUM;
  config.pin_sccb_sda = SIOD_GPIO_NUM;
  config.pin_sccb_scl = SIOC_GPIO_NUM;
  config.pin_pwdn     = PWDN_GPIO_NUM;
  config.pin_reset    = RESET_GPIO_NUM;
  config.xclk_freq_hz = 10000000;
  config.pixel_format = PIXFORMAT_JPEG;
  config.grab_mode    = CAMERA_GRAB_LATEST;
  config.frame_size   = FRAMESIZE_VGA;
  config.jpeg_quality = 12;
  config.fb_count     = 1;

  esp_err_t err = esp_camera_init(&config);
  if (err != ESP_OK) {
    Serial.printf("ERROR: Cámara no inicializada. Código: 0x%x\n", err);
    ESP.restart();
  }

  sensor_t *s = esp_camera_sensor_get();
  s->set_brightness(s, 1);
  s->set_saturation(s, 0);

  Serial.println("✅ Cámara inicializada correctamente.");
}

// ===========================
// WIFI
// ===========================

void connectWiFi() {
  Serial.printf("Conectando a WiFi: %s", ssid);
  WiFi.mode(WIFI_STA);
  WiFi.setTxPower(WIFI_POWER_8_5dBm);
  WiFi.begin(ssid, password);
  WiFi.setSleep(false);

  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 30) {
    delay(500);
    Serial.print(".");
    attempts++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.printf("\n✅ WiFi conectado. IP: %s\n", WiFi.localIP().toString().c_str());
  } else {
    Serial.println("\n❌ No se pudo conectar a WiFi. Reiniciando...");
    ESP.restart();
  }
}

// ===========================
// CAPTURA + CLASIFICACIÓN
// ===========================

void captureAndClassify() {
  Serial.println("\n📸 Botón presionado. Capturando foto...");

  // Encender flash brevemente
  digitalWrite(FLASH_LED_PIN, HIGH);
  delay(100);

  camera_fb_t *fb = esp_camera_fb_get();
  digitalWrite(FLASH_LED_PIN, LOW);

  if (!fb) {
    Serial.println("❌ Error al capturar foto.");
    return;
  }

  Serial.printf("📷 Foto capturada: %d bytes\n", fb->len);

  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("❌ WiFi desconectado. Reconectando...");
    esp_camera_fb_return(fb);
    connectWiFi();
    return;
  }

  HTTPClient http;

  http.begin(serverUrl);
  http.setTimeout(15000);

  String boundary = "----ESP32CamBoundary";
  String head = "--" + boundary + "\r\n"
                "Content-Disposition: form-data; name=\"file\"; filename=\"capture.jpg\"\r\n"
                "Content-Type: image/jpeg\r\n\r\n";
  String tail = "\r\n--" + boundary + "--\r\n";

  uint32_t totalLen = head.length() + fb->len + tail.length();

  http.addHeader("Content-Type", "multipart/form-data; boundary=" + boundary);
  http.addHeader("Content-Length", String(totalLen));
  http.addHeader("X-Bin-Id", binId);

  uint8_t *payload = (uint8_t *)malloc(totalLen);
  if (!payload) {
    Serial.println("❌ Sin memoria para payload.");
    esp_camera_fb_return(fb);
    http.end();
    return;
  }

  memcpy(payload, head.c_str(), head.length());
  memcpy(payload + head.length(), fb->buf, fb->len);
  memcpy(payload + head.length() + fb->len, tail.c_str(), tail.length());

  Serial.printf("📤 Enviando a %s (X-Bin-Id: %s) ...\n", serverUrl, binId);
  int httpCode = http.POST(payload, totalLen);

  free(payload);
  esp_camera_fb_return(fb);

  if (httpCode == 200) {
    String response = http.getString();
    Serial.printf("✅ Clasificación exitosa (HTTP 200):\n%s\n", response.c_str());
    
    // Parpadeo de éxito (2 destellos cortos)
    for (int i = 0; i < 2; i++) {
      digitalWrite(FLASH_LED_PIN, HIGH);
      delay(100);
      digitalWrite(FLASH_LED_PIN, LOW);
      delay(100);
    }

    String categoria = extraerCategoria(response);
    if (categoria.length() > 0) {
      procesarDescarteBasura(categoria);
    } else {
      Serial.println("⚠️  No se pudo leer la categoría en la respuesta. Volviendo a reposo.");
    }
  } else if (httpCode == 403) {
    String response = http.getString();
    Serial.printf("⚠️ Sin sesión activa para bin '%s' (HTTP 403):\n%s\n", binId, response.c_str());
    Serial.println("👉 Escanee el código QR en la aplicación móvil antes de presionar el botón.");
    
    // Parpadeo de advertencia de sesión bloqueada (4 destellos rápidos)
    for (int i = 0; i < 4; i++) {
      digitalWrite(FLASH_LED_PIN, HIGH);
      delay(50);
      digitalWrite(FLASH_LED_PIN, LOW);
      delay(50);
    }
  } else {
    String response = httpCode > 0 ? http.getString() : "{\"error\": \"http_error\"}";
    Serial.printf("❌ Error de servidor/red (HTTP %d):\n%s\n", httpCode, response.c_str());
    
    // Destello de error de servidor/red (1 encendido largo)
    digitalWrite(FLASH_LED_PIN, HIGH);
    delay(1000);
    digitalWrite(FLASH_LED_PIN, LOW);
  }

  http.end();
}

// ===========================
// SETUP
// ===========================

void setup() {
  Serial.begin(115200);
  Serial.println("\n\n🌿 EcoSmartBin - ESP32-CAM (Single Servo + Botón Físico)");
  Serial.println("========================================================");
  Serial.printf("   Bin ID: %s\n", binId);

  // ─── LED Flash ───
  pinMode(FLASH_LED_PIN, OUTPUT);
  digitalWrite(FLASH_LED_PIN, LOW);

  // ─── Botón Físico ───
  pinMode(BUTTON_PIN, INPUT_PULLUP);

  // ─── Sensor de Obstáculos ───
  pinMode(OBSTACLE_PIN, INPUT);  // GPIO 15: sensor IR/obstáculo (LOW = detecta objeto)

  // ─── Servo ───
  ESP32PWM::allocateTimer(1); // Usar timer 1 para evitar conflicto con la cámara
  servoSelector.setPeriodHertz(50);
  servoSelector.attach(SERVO_SELECTOR, 500, 2400);
  servoSelector.write(0);
  anguloActualSelector = 0;

  delay(600); // Espera para que el servo tome posición de reposo
  Serial.println("✅ Servo selector (GPIO 14) iniciado en 0° (Basura General).");

  // ─── Cámara y WiFi ───
  initCamera();
  connectWiFi();

  Serial.println("\n🟢 Sistema Listo e Iniciado.");
  Serial.println("   Presiona el botón (GPIO 13) para clasificar basura...\n");
}

// ===========================
// LOOP
// ===========================

void loop() {
  // Disparo SOLO por botón físico (GPIO 13, activo en LOW con pull-up interno)
  if (digitalRead(BUTTON_PIN) == LOW) {
    delay(200);  // Debounce — esperar 200ms
    if (digitalRead(BUTTON_PIN) == LOW) {
      captureAndClassify();

      // Esperar a que suelte el botón para evitar capturas repetidas
      while (digitalRead(BUTTON_PIN) == LOW) {
        delay(50);
      }
      Serial.println("🟢 Listo. Presiona el botón de nuevo para otra clasificación.\n");
    }
  }

  delay(50);
}