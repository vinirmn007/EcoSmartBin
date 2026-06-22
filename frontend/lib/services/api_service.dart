import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class ApiService {
  // ── URL del servicio de usuarios (producción) ──
  static String get baseUrl {
    if (kIsWeb) {
      return 'https://ecosmartbin-229724129072.southamerica-west1.run.app';
    } else {
      try {
        if (Platform.isAndroid) {
          return 'https://ecosmartbin-229724129072.southamerica-west1.run.app';
        }
      } catch (_) {}
      return 'https://ecosmartbin-229724129072.southamerica-west1.run.app';
    }
  }

  // ── Gateway local (Bully + servicio_puntos) ──
  static String get gatewayUrl {
    if (kIsWeb) return 'http://localhost:8080';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8080';
    } catch (_) {}
    return 'http://localhost:8080';
  }

  // Clave para guardar el token en SharedPreferences
  static const String _tokenKey = 'auth_token';

  // Registrar un nuevo usuario
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String nombres,
    required String apellidos,
    required String cedula,
    String? facultad,
  }) async {
    final url = Uri.parse('$baseUrl/auth/register');

    final Map<String, dynamic> body = {
      'email': email,
      'password': password,
      'nombres': nombres,
      'apellidos': apellidos,
      'cedula': cedula,
    };

    if (facultad != null && facultad.isNotEmpty) {
      body['facultad'] = facultad;
    }

    try {
      print('DEBUG: Enviando registro POST a $url');
      print('DEBUG: Body de registro: $body');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print('DEBUG: Respuesta de registro - Código: ${response.statusCode}');
      print('DEBUG: Respuesta de registro - Body: ${response.body}');

      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': decodedData['message'] ?? 'Registro exitoso',
        };
      } else {
        return {
          'success': false,
          'message': decodedData['detail'] ?? 'Error desconocido en registro',
        };
      }
    } catch (e) {
      print('DEBUG: Error en petición de registro: $e');
      return {
        'success': false,
        'message': 'No se pudo conectar al servidor: $e',
      };
    }
  }

  // Iniciar sesión
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final url = Uri.parse('$baseUrl/auth/login');

    try {
      print('DEBUG: Enviando login POST a $url');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('DEBUG: Respuesta de login - Código: ${response.statusCode}');
      print('DEBUG: Respuesta de login - Body: ${response.body}');

      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final token = decodedData['access_token'];
        print('DEBUG: Login exitoso. Guardando token...');

        // Guardar token localmente
        final prefs = await SharedPreferences.getInstance();
        final success = await prefs.setString(_tokenKey, token);
        print(
          'DEBUG: ¿Token guardado exitosamente en SharedPreferences?: $success',
        );

        return {'success': true, 'token': token};
      } else {
        return {
          'success': false,
          'message': decodedData['detail'] ?? 'Credenciales incorrectas',
        };
      }
    } catch (e) {
      print('DEBUG: Error en petición de login: $e');
      return {
        'success': false,
        'message': 'No se pudo conectar al servidor: $e',
      };
    }
  }

  // Obtener perfil del usuario autenticado
  static Future<UserProfile?> getProfile() async {
    final token = await getToken();
    print(
      'DEBUG: getProfile convocado. Token en memoria: ${token != null ? "PRESENTE (longitud: ${token.length})" : "NULO"}',
    );
    if (token == null) {
      print('DEBUG: getProfile cancelado porque el token es nulo.');
      return null;
    }

    final url = Uri.parse('$baseUrl/auth/me');
    print('DEBUG: Enviando GET a $url');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('DEBUG: Respuesta de getProfile - Código: ${response.statusCode}');
      print('DEBUG: Respuesta de getProfile - Body: ${response.body}');

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        return UserProfile.fromJson(decodedData);
      } else {
        // Si el token es inválido o expiró, borramos el token guardado
        if (response.statusCode == 401) {
          print(
            'DEBUG: Token no autorizado (401). Eliminando token local y cerrando sesión.',
          );
          await logout();
        }
        return null;
      }
    } catch (e) {
      print('DEBUG: Error en petición de getProfile: $e');
      // Retorna null si hay error de conexión para manejarlo en UI
      return null;
    }
  }

  // Obtener el token guardado
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    print(
      'DEBUG: SharedPreferences leyó token: ${token != null ? "ENCONTRADO" : "NULO"}',
    );
    return token;
  }

  // Cerrar sesión (eliminar token)
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // Verificar si hay sesión iniciada
  static Future<bool> hasSession() async {
    final token = await getToken();
    return token != null;
  }

  // Enviar correo de recuperación de contraseña
  static Future<Map<String, dynamic>> recoverPassword(
    String email, {
    String? redirectUrl,
  }) async {
    final url = Uri.parse('$baseUrl/auth/recover-password');
    try {
      print('DEBUG: Enviando recuperación de contraseña a $url');
      final Map<String, dynamic> body = {'email': email};
      if (redirectUrl != null) {
        body['redirect_url'] = redirectUrl;
      }
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print(
        'DEBUG: Respuesta de recuperación - Código: ${response.statusCode}',
      );
      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message':
              decodedData['message'] ??
              'Correo de recuperación enviado exitosamente',
        };
      } else {
        return {
          'success': false,
          'message':
              decodedData['detail'] ?? 'Error al enviar correo de recuperación',
        };
      }
    } catch (e) {
      print('DEBUG: Error en petición de recuperación: $e');
      return {
        'success': false,
        'message': 'No se pudo conectar al servidor: $e',
      };
    }
  }

  // Restablecer contraseña con el token JWT de recuperación
  static Future<Map<String, dynamic>> resetPassword(
    String newPassword,
    String token,
  ) async {
    final url = Uri.parse('$baseUrl/auth/reset-password');
    try {
      print('DEBUG: Enviando restablecimiento de contraseña a $url');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'new_password': newPassword}),
      );

      print(
        'DEBUG: Respuesta de restablecimiento - Código: ${response.statusCode}',
      );
      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message':
              decodedData['message'] ?? 'Contraseña restablecida exitosamente',
        };
      } else {
        return {
          'success': false,
          'message':
              decodedData['detail'] ?? 'Error al restablecer la contraseña',
        };
      }
    } catch (e) {
      print('DEBUG: Error en petición de restablecimiento: $e');
      return {
        'success': false,
        'message': 'No se pudo conectar al servidor: $e',
      };
    }
  }

  // ══════════════════════════════════════════════════
  //  PUNTOS ECOLÓGICOS — via Gateway local (Bully)
  // ══════════════════════════════════════════════════

  /// Obtiene el balance de puntos del usuario autenticado.
  static Future<Map<String, dynamic>> getBalance() async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'No autenticado'};

    try {
      final response = await http.get(
        Uri.parse('$gatewayUrl/api/puntos/balance'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {
        'success': false,
        'message': 'Error ${response.statusCode}: ${response.body}',
      };
    } catch (e) {
      return {'success': false, 'message': 'Sin conexión al gateway: $e'};
    }
  }

  /// Registra un evento de reciclaje y acumula puntos.
  static Future<Map<String, dynamic>> registrarReciclaje({
    required int tipoReciclajeId,
    required int cantidad,
    String? usuarioId,
  }) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'No autenticado'};

    final body = <String, dynamic>{
      'tipoReciclajeId': tipoReciclajeId,
      'cantidad': cantidad,
    };
    if (usuarioId != null) body['usuarioId'] = usuarioId;

    try {
      final response = await http.post(
        Uri.parse('$gatewayUrl/api/puntos/reciclar'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      final err = jsonDecode(response.body);
      return {
        'success': false,
        'message': err['message'] ?? 'Error al registrar reciclaje',
      };
    } catch (e) {
      return {'success': false, 'message': 'Sin conexión al gateway: $e'};
    }
  }

  /// Obtiene los tipos de reciclaje disponibles.
  static Future<List<dynamic>> getTiposReciclaje() async {
    try {
      final response = await http.get(
        Uri.parse('$gatewayUrl/api/tipos-reciclaje'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      print('DEBUG: Error getTiposReciclaje: $e');
      return [];
    }
  }

  /// Obtiene el historial de transacciones del usuario autenticado.
  static Future<List<dynamic>> getTransacciones() async {
    final token = await getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$gatewayUrl/api/transacciones/historial'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      print('DEBUG: Error getTransacciones: $e');
      return [];
    }
  }

  /// Obtiene el estado del cluster Bully desde el gateway.
  static Future<Map<String, dynamic>?> getGatewayStatus() async {
    try {
      final response = await http
          .get(
            Uri.parse('$gatewayUrl/gateway/status'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ══════════════════════════════════════════════════
  //  LABORATORIO DISTRIBUIDO — acceso directo a nodos
  // ══════════════════════════════════════════════════

  /// URLs directas de cada nodo (para el laboratorio distribuido).
  /// ⚠️ ACTUALIZAR con las IPs reales de la red cuando se use switch/router.
  static List<String> get nodeUrls => [
    'http://10.20.138.136:8081', // Nodo 1 — PC1 (Marco)
    'http://10.20.138.100:8082', // Nodo 2 — PC2 (Compañero)
    'http://10.20.138.138:8083', // Nodo 3 — PC3 (sin conectar aún)
  ];

  // NODE_URLS: "http://10.20.138.136:8081,http://10.20.138.100:8082,http://10.20.138.138:8083"

  // ── Lamport ───────────────────────────────────────

  /// Obtiene el estado del reloj de Lamport de un nodo específico.
  static Future<Map<String, dynamic>?> getLamportStatus(String nodeUrl) async {
    try {
      final response = await http
          .get(Uri.parse('$nodeUrl/api/lamport/status'))
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Dispara un evento interno de Lamport en un nodo específico.
  static Future<Map<String, dynamic>?> triggerLamportEvent(
    String nodeUrl,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$nodeUrl/api/lamport/event'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ── Mutex (Ricart-Agrawala) ───────────────────────

  /// Obtiene el estado del mutex de un nodo específico.
  static Future<Map<String, dynamic>?> getMutexStatus(String nodeUrl) async {
    try {
      final response = await http
          .get(Uri.parse('$nodeUrl/api/mutex/status'))
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Solicita la Sección Crítica desde un nodo específico.
  static Future<Map<String, dynamic>?> requestMutex(String nodeUrl) async {
    try {
      final response = await http
          .post(
            Uri.parse('$nodeUrl/api/mutex/request'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Fuerza la liberación de la Sección Crítica en un nodo.
  static Future<Map<String, dynamic>?> releaseMutex(String nodeUrl) async {
    try {
      final response = await http
          .post(
            Uri.parse('$nodeUrl/api/mutex/release'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
