import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'screens/landing_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/recover_password_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/email_verified_screen.dart';
import 'screens/puntos_screen.dart';
import 'screens/reciclaje_historial_screen.dart';
import 'screens/canjes_historial_screen.dart';
import 'screens/canjear_screen.dart';
import 'screens/reciclar_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/admin_basureros_screen.dart';
import 'services/api_service.dart';
import 'dart:html' as html;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Extraemos los tokens de la URL cruda ANTES de que Flutter limpie la URL
  final hash = html.window.location.hash;
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

  usePathUrlStrategy();
  
  // Verificar si ya existe una sesión activa al arrancar
  final bool loggedIn = await ApiService.hasSession();

  runApp(MyApp(
    startRoute: initialRouteOverride ?? (loggedIn ? '/profile' : '/'),
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
      
      // Tema Oscuro Minimalista Moderno
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF10B981), // Emerald Green
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate 900
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF10B981),
          secondary: Color(0xFF34D399),
          surface: Color(0xFF1E293B),
          background: Color(0xFF0F172A),
          error: Colors.redAccent,
        ),
        
        // Fuentes y Tipografía
        fontFamily: 'Roboto',
        
        // Estilo de botones
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
      
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
      },
    );
  }
}


