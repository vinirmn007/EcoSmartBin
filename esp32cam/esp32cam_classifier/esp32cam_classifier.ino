/*
 * EcoSmartBin - ESP32-CAM Garbage Classifier
 * 
 * Captura una foto con la cámara y la envía al servicio de IA
 * para clasificar el tipo de basura (cardboard, glass, metal, paper, plastic, trash).
 * 
 * Conexiones:
 *   - ESP32-CAM AI-Thinker
 *   - Botón en GPIO 12 (o sensor de proximidad) para disparar la captura
 *   - LED flash en GPIO 4 (built-in)
 * 
 * Configurar abajo: WiFi y URL del servidor de IA.
 */

#include "esp_camera.h"
#include <WiFi.h>
#include <HTTPClient.h>

// ===========================
// CONFIGURACIÓN - EDITAR AQUÍ
// ===========================

// WiFi
const char* ssid     = "Marco_Omar";
const char* password = "1720500Mm.";

// URL del servicio de IA
// LOCAL (Docker en tu PC):  "http://192.168.X.X:8080/predict"  ← IP de tu PC en la red local
// NUBE  (Cloud Run):        "https://servicio-ia-XXXXX.run.app/predict"
const char* serverUrl = "http://192.168.110.127:8080/predict";

// Pin del botón para disparar captura (GPIO 13 — seguro en ESP32-CAM)
#define BUTTON_PIN    13
// LED Flash integrado del ESP32-CAM
#define FLASH_LED_PIN 4

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
// VARIABLES GLOBALES
// ===========================
bool captureRequested = false;

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
  config.xclk_freq_hz = 10000000;  // 10 MHz — menos consumo de energía
  config.pixel_format = PIXFORMAT_JPEG;
  config.grab_mode    = CAMERA_GRAB_LATEST;

  // Resolución baja + 1 solo buffer = funciona con energía limitada (Arduino Nano)
  config.frame_size   = FRAMESIZE_VGA;    // 640x480 — suficiente para la IA
  config.jpeg_quality = 12;
  config.fb_count     = 1;                // Solo 1 buffer = menos RAM
  Serial.println("Usando VGA (640x480), 1 buffer, XCLK 10MHz.");

  // Inicializar cámara
  esp_err_t err = esp_camera_init(&config);
  if (err != ESP_OK) {
    Serial.printf("ERROR: Cámara no inicializada. Código: 0x%x\n", err);
    ESP.restart();
  }

  // Ajustes opcionales del sensor
  sensor_t *s = esp_camera_sensor_get();
  s->set_brightness(s, 1);   // Brillo ligeramente alto
  s->set_saturation(s, 0);   // Saturación normal

  Serial.println("✅ Cámara inicializada correctamente.");
}

void connectWiFi() {
  Serial.printf("Conectando a WiFi: %s", ssid);
  WiFi.mode(WIFI_STA);
  WiFi.setTxPower(WIFI_POWER_8_5dBm);  // Potencia baja = menos consumo
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

/*
 * Captura una foto y la envía al servidor de IA como multipart/form-data.
 * Retorna el JSON de respuesta o un string de error.
 */
String captureAndClassify() {
  Serial.println("\n📸 Capturando foto...");

  // Encender flash brevemente
  digitalWrite(FLASH_LED_PIN, HIGH);
  delay(100);

  // Capturar frame
  camera_fb_t *fb = esp_camera_fb_get();

  // Apagar flash
  digitalWrite(FLASH_LED_PIN, LOW);

  if (!fb) {
    Serial.println("❌ Error al capturar foto.");
    return "{\"error\": \"capture_failed\"}";
  }

  Serial.printf("📷 Foto capturada: %d bytes (%dx%d)\n", fb->len, fb->width, fb->height);

  // Verificar WiFi
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("❌ WiFi desconectado. Reconectando...");
    esp_camera_fb_return(fb);
    connectWiFi();
    return "{\"error\": \"wifi_disconnected\"}";
  }

  // ─── Enviar foto al servidor de IA ───
  HTTPClient http;
  http.begin(serverUrl);
  http.setTimeout(15000);  // 15 segundos timeout

  // Construir el body multipart manualmente
  String boundary = "----ESP32CamBoundary";
  String head = "--" + boundary + "\r\n"
                "Content-Disposition: form-data; name=\"file\"; filename=\"capture.jpg\"\r\n"
                "Content-Type: image/jpeg\r\n\r\n";
  String tail = "\r\n--" + boundary + "--\r\n";

  uint32_t totalLen = head.length() + fb->len + tail.length();

  http.addHeader("Content-Type", "multipart/form-data; boundary=" + boundary);
  http.addHeader("Content-Length", String(totalLen));

  // Crear buffer completo
  uint8_t *payload = (uint8_t *)malloc(totalLen);
  if (!payload) {
    Serial.println("❌ Sin memoria para payload.");
    esp_camera_fb_return(fb);
    http.end();
    return "{\"error\": \"out_of_memory\"}";
  }

  // Copiar: head + imagen JPEG + tail
  memcpy(payload, head.c_str(), head.length());
  memcpy(payload + head.length(), fb->buf, fb->len);
  memcpy(payload + head.length() + fb->len, tail.c_str(), tail.length());

  Serial.printf("📤 Enviando %d bytes a %s ...\n", totalLen, serverUrl);

  int httpCode = http.POST(payload, totalLen);

  // Liberar recursos
  free(payload);
  esp_camera_fb_return(fb);

  String response = "";

  if (httpCode > 0) {
    response = http.getString();
    Serial.printf("✅ Respuesta del servidor (HTTP %d):\n", httpCode);
    Serial.println(response);
  } else {
    response = "{\"error\": \"http_error\", \"code\": " + String(httpCode) + "}";
    Serial.printf("❌ Error HTTP: %s\n", http.errorToString(httpCode).c_str());
  }

  http.end();
  return response;
}

void setup() {
  Serial.begin(115200);
  Serial.println("\n\n🌿 EcoSmartBin - ESP32-CAM Classifier");
  Serial.println("=====================================");

  // Configurar LED flash
  pinMode(FLASH_LED_PIN, OUTPUT);
  digitalWrite(FLASH_LED_PIN, LOW);

  // Configurar botón de captura (con pull-up interno)
  pinMode(BUTTON_PIN, INPUT_PULLUP);

  // Inicializar cámara y WiFi
  initCamera();
  connectWiFi();

  Serial.println("\n🟢 Sistema listo. Presiona el botón (GPIO 13) para clasificar basura.\n");
}

void loop() {
  // ─── Disparo SOLO por botón físico (GPIO 13) ───
  int btnState = digitalRead(BUTTON_PIN);
  
  if (btnState == LOW) {
    delay(200);  // Debounce — esperar 200ms
    if (digitalRead(BUTTON_PIN) == LOW) {
      Serial.println("📸 Botón presionado! Capturando...");
      
      // Parpadear flash para indicar captura
      digitalWrite(FLASH_LED_PIN, HIGH);
      delay(100);
      digitalWrite(FLASH_LED_PIN, LOW);

      captureAndClassify();

      // Esperar a que suelte el botón
      while (digitalRead(BUTTON_PIN) == LOW) delay(50);
      Serial.println("✅ Listo. Presiona el botón de nuevo para otra foto.\n");
    }
  }

  delay(50);
}
