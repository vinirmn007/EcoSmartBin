import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class ApiService {

  // ── Puntos local o producción ──
  static String get gatewayUrl {
    if (kReleaseMode) {
      // TODO: Reemplazar con la URL real de Cloud Run del servicio de puntos cuando se despliegue
      return 'https://gateway-229724129072.southamerica-west1.run.app';
    }
    if (kIsWeb) return 'http://localhost:8081';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8081';
    } catch (_) {}
    return 'http://localhost:8081';
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
    final url = Uri.parse('$gatewayUrl/auth/register');

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
    final url = Uri.parse('$gatewayUrl/auth/login');

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

    final url = Uri.parse('$gatewayUrl/auth/me');
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
    final url = Uri.parse('$gatewayUrl/auth/email-reset-password');
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
    String refreshToken,
  ) async {
    final url = Uri.parse('$gatewayUrl/auth/change-password');
    try {
      print('DEBUG: Enviando restablecimiento de contraseña a $url');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'access_token': token,
          'refresh_token': refreshToken,
          'new_password': newPassword,
        }),
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
  //  PUNTOS ECOLÓGICOS — via Servicio Local
  // ══════════════════════════════════════════════════

  /// Obtiene el balance de puntos del usuario autenticado.
  static Future<Map<String, dynamic>> getBalance() async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'No autenticado'};

    try {
      final response = await http.get(
        Uri.parse('$gatewayUrl/points/balance'),
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
        Uri.parse('$gatewayUrl/points/reciclar'),
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
        Uri.parse('$gatewayUrl/points/tipos-reciclaje'),
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
        Uri.parse('$gatewayUrl/points/transacciones/historial'),
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

  /// Obtiene la lista de recompensas activas.
  static Future<List<dynamic>> getRecompensas() async {
    final token = await getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$gatewayUrl/points/recompensas'),
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
      print('DEBUG: Error getRecompensas: $e');
      return [];
    }
  }

  /// Canjea una recompensa.
  static Future<Map<String, dynamic>> canjearRecompensa(
    int recompensaId,
  ) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'No autenticado'};

    try {
      final response = await http.post(
        Uri.parse('$gatewayUrl/points/canjes'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'recompensaId': recompensaId}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      final err = jsonDecode(response.body);
      return {
        'success': false,
        'message': err['message'] ?? 'Error al canjear recompensa',
      };
    } catch (e) {
      return {'success': false, 'message': 'Sin conexión al gateway: $e'};
    }
  }

  /// Obtiene el historial de canjes del usuario autenticado.
  static Future<List<dynamic>> getCanjes() async {
    final token = await getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$gatewayUrl/points/canjes/mis-canjes'),
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
      print('DEBUG: Error getCanjes: $e');
      return [];
    }
  }

  // ══════════════════════════════════════════════════
  //  CLASIFICACIÓN IA — Consultar resultado pendiente
  // ══════════════════════════════════════════════════

  /// Consulta si hay una clasificación pendiente de la IA para un basurero.
  /// Retorna null si no hay clasificación pendiente (HTTP 204).
  static Future<Map<String, dynamic>?> getClasificacionPendiente(
    String binId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$gatewayUrl/points/clasificacion-pendiente/$binId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      // 204 = no hay clasificación pendiente
      return null;
    } catch (e) {
      print('DEBUG: Error getClasificacionPendiente: $e');
      return null;
    }
  }

  /// Limpia la clasificación pendiente después de confirmar el reciclaje.
  static Future<void> limpiarClasificacionPendiente(String binId) async {
    try {
      await http.delete(
        Uri.parse('$gatewayUrl/points/clasificacion-pendiente/$binId'),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('DEBUG: Error limpiarClasificacionPendiente: $e');
    }
  }

  // ══════════════════════════════════════════════════
  //  BASUREROS — via Gateway
  // ══════════════════════════════════════════════════

  static Future<List<dynamic>> getBasureros() async {
    final token = await getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$gatewayUrl/bins'),
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
      print('DEBUG: Error getBasureros: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> crearBasurero({
    required String publicId,
    required String nombre,
    String? ubicacion,
    double? latitud,
    double? longitud,
    String estado = 'activo',
  }) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'No autenticado'};

    try {
      final body = {
        'public_id': publicId,
        'nombre': nombre,
        'ubicacion': ubicacion,
        'latitud': latitud,
        'longitud': longitud,
        'estado': estado,
      };
      final response = await http.post(
        Uri.parse('$gatewayUrl/bins'),
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
        'message': err['detail'] ?? 'Error al crear basurero',
      };
    } catch (e) {
      return {'success': false, 'message': 'Sin conexión al servidor: $e'};
    }
  }

  // ══════════════════════════════════════════════════
  //  SESIONES DE BASURERO
  // ══════════════════════════════════════════════════

  /// Conecta al usuario autenticado con un basurero mediante su ID público.
  static Future<Map<String, dynamic>> conectarBasurero(String publicId) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'No autenticado'};

    try {
      final response = await http.post(
        Uri.parse('$gatewayUrl/bins/${publicId.toLowerCase().trim()}/connect'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': decoded};
      } else {
        return {
          'success': false,
          'message': decoded['detail'] ?? 'El basurero está ocupado o no disponible.'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Sin conexión al servidor: $e'};
    }
  }

  /// Desconecta al usuario del basurero y libera el recurso.
  static Future<Map<String, dynamic>> desconectarBasurero(String publicId) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'No autenticado'};

    try {
      final response = await http.post(
        Uri.parse('$gatewayUrl/bins/${publicId.toLowerCase().trim()}/disconnect'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Desconectado exitosamente'};
      } else {
        final decoded = jsonDecode(response.body);
        return {
          'success': false,
          'message': decoded['detail'] ?? 'Error al desconectarse'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Sin conexión al servidor: $e'};
    }
  }

  /// Extiende la sesión activa 5 minutos adicionales.
  static Future<Map<String, dynamic>> extenderSesionBasurero(String publicId) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'No autenticado'};

    try {
      final response = await http.post(
        Uri.parse('$gatewayUrl/bins/${publicId.toLowerCase().trim()}/extend'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': decoded};
      } else {
        return {
          'success': false,
          'message': decoded['detail'] ?? 'No se pudo extender la sesión'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Sin conexión al servidor: $e'};
    }
  }

  /// Consulta el estado actual del basurero y los segundos restantes de la sesión.
  static Future<Map<String, dynamic>?> obtenerEstadoBasurero(String publicId) async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$gatewayUrl/bins/${publicId.toLowerCase().trim()}/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('DEBUG: Error obtenerEstadoBasurero: $e');
      return null;
    }
  }

  // ══════════════════════════════════════════════════
  //  USUARIOS — via Gateway (Solo Admin)
  // ══════════════════════════════════════════════════

  static Future<List<dynamic>> getUsuarios() async {
    final token = await getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$gatewayUrl/auth/users'),
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
      print('DEBUG: Error getUsuarios: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> actualizarUsuario(
    String userId,
    Map<String, dynamic> data,
  ) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'No autenticado'};

    try {
      final response = await http.put(
        Uri.parse('$gatewayUrl/auth/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Usuario actualizado exitosamente'};
      }
      final err = jsonDecode(response.body);
      return {
        'success': false,
        'message': err['detail'] ?? 'Error al actualizar usuario',
      };
    } catch (e) {
      return {'success': false, 'message': 'Sin conexión al servidor: $e'};
    }
  }

  static Future<Map<String, dynamic>> eliminarUsuario(String userId) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'No autenticado'};

    try {
      final response = await http.delete(
        Uri.parse('$gatewayUrl/auth/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Usuario eliminado exitosamente'};
      }
      final err = jsonDecode(response.body);
      return {
        'success': false,
        'message': err['detail'] ?? 'Error al eliminar usuario',
      };
    } catch (e) {
      return {'success': false, 'message': 'Sin conexión al servidor: $e'};
    }
  }
}
