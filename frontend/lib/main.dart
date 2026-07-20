import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'screens/landing/landing_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/auth/recover_password_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/auth/email_verified_screen.dart';
import 'screens/puntos/puntos_screen.dart';
import 'screens/puntos/reciclaje_historial_screen.dart';
import 'screens/puntos/canjes_historial_screen.dart';
import 'screens/puntos/canjear_screen.dart';
import 'screens/puntos/reciclar_screen.dart';
import 'screens/admin/admin_screen.dart';
import 'screens/admin/admin_basureros_screen.dart';
import 'screens/admin/admin_usuarios_screen.dart';
import 'screens/admin/admin_recompensas_screen.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';
import 'utils/url_helper.dart';

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Extraemos los tokens de la URL cruda ANTES de que Flutter limpie la URL
  final hash = getHash();
  print('RAW HASH: $hash');
  
  String? extractedToken;
  String? extractedRefreshToken;
  String? initialRouteOverride;

  if (hash.isNotEmpty) {
    final fragment = hash.startsWith('#') ? hash.substring(1) : hash;
    
    // El fragmento en Supabase suele ser "access_token=xxx&refresh_token=yyy&type=recovery"
    // Pero si comienza con "/reset-password?", lo ajustamos.
    String queryStr = fragment;
    if (fragment.startsWith('/')) {
      final parts = fragment.split('?');
      if (parts.length > 1) queryStr = parts[1];
    }
    
    final params = Uri.splitQueryString(queryStr);
    extractedToken = params['access_token'] ?? params['token'];
    extractedRefreshToken = params['refresh_token'];
  }

  if (extractedToken != null) {
    initialRouteOverride = '/reset-password';
  }

  // Configura flutter_animate con duración predeterminada global
  Animate.defaultDuration = const Duration(milliseconds: 400);

  usePathUrlStrategy();
  
  // Verificar si ya existe una sesión activa al arrancar
  final bool loggedIn = await ApiService.hasSession();
  final bool isAndroid = !kIsWeb && Platform.isAndroid;

  String defaultStartRoute = '/';
  if (isAndroid) {
    defaultStartRoute = loggedIn ? '/profile' : '/login';
  } else {
    defaultStartRoute = loggedIn ? '/profile' : '/';
  }

  runApp(MyApp(
    startRoute: initialRouteOverride ?? defaultStartRoute,
    initialToken: extractedToken,
    initialRefreshToken: extractedRefreshToken,
  ));
}

class MyApp extends StatelessWidget {
  final String startRoute;
  final String? initialToken;
  final String? initialRefreshToken;

  const MyApp({
    super.key, 
    required this.startRoute,
    this.initialToken,
    this.initialRefreshToken,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoSmartBin',
      debugShowCheckedModeBanner: false,

      // ── Tema Obsidian Emerald (Stitch) ──────────
      theme: AppTheme.darkTheme,
      
      // Configuración de Rutas
      initialRoute: startRoute,
      routes: {
        '/': (context) => const LandingScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/recover-password': (context) => const RecoverPasswordScreen(),
        '/reset-password': (context) => ResetPasswordScreen(
              token: initialToken,
              refreshToken: initialRefreshToken,
            ),
        '/email-verified': (context) => const EmailVerifiedScreen(),
        '/puntos': (context) => const PuntosScreen(),
        '/puntos/historial-canjes': (context) => const CanjesHistorialScreen(),
        '/puntos/historial-reciclaje': (context) => const ReciclajeHistorialScreen(),
        '/puntos/canjear': (context) => const CanjearScreen(),
        '/puntos/reciclar': (context) => const ReciclarScreen(),
        '/admin': (context) => const AdminScreen(),
        '/admin/basureros': (context) => const AdminBasurerosScreen(),
        '/admin/usuarios': (context) => const AdminUsuariosScreen(),
        '/admin/recompensas': (context) => const AdminRecompensasScreen(),
      },
    );
  }
}


