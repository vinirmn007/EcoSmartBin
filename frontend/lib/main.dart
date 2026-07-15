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

  // Configura flutter_animate con duración predeterminada global
  Animate.defaultDuration = const Duration(milliseconds: 400);

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

      // ── Tema Premium Light con Poppins (Estilo Linear/Vercel) ──────────
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,

        // ── Paleta de colores central ───────────────────────────────
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF10B981),        // Verde esmeralda tecnológico vibrante
          onPrimary: Colors.white,
          primaryContainer: Color(0xFFD1FAE5),
          secondary: Color(0xFF34D399),       
          onSecondary: Colors.white,
          tertiary: Color(0xFF6EE7B7),        
          surface: Colors.white,              // Blanco puro para tarjetas
          onSurface: Color(0xFF0F172A),       // Gris grafito oscuro para textos principales
          surfaceContainerHighest: Color(0xFFF1F5F9),  
          error: Color(0xFFEF4444),
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Blanco roto premium

        // ── Tipografía Global: Poppins ───────────────────────────────
        textTheme: GoogleFonts.poppinsTextTheme(
          const TextTheme(
            displayLarge: TextStyle(
              color: Color(0xFF0F172A), fontSize: 56, fontWeight: FontWeight.w900,
              letterSpacing: -1.5, height: 1.1,
            ),
            displayMedium: TextStyle(
              color: Color(0xFF0F172A), fontSize: 42, fontWeight: FontWeight.w800,
              letterSpacing: -1.0, height: 1.15,
            ),
            displaySmall: TextStyle(
              color: Color(0xFF0F172A), fontSize: 32, fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
            headlineLarge: TextStyle(
              color: Color(0xFF0F172A), fontSize: 28, fontWeight: FontWeight.bold,
              letterSpacing: -1.0,
            ),
            headlineMedium: TextStyle(
              color: Color(0xFF0F172A), fontSize: 22, fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
            headlineSmall: TextStyle(
              color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.w600,
            ),
            titleLarge: TextStyle(
              color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
            bodyLarge: TextStyle(
              color: Color(0xFF475569), fontSize: 16, height: 1.6, // Gris plata
            ),
            bodyMedium: TextStyle(
              color: Color(0xFF475569), fontSize: 14, height: 1.5,
            ),
            bodySmall: TextStyle(
              color: Color(0xFF64748B), fontSize: 12,
            ),
            labelLarge: TextStyle(
              color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),

        // ── AppBar ──────────────────────────────────────────────────
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: GoogleFonts.poppins(
            color: const Color(0xFF0F172A),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        ),

        // ── Tarjetas (Extrusión Neumórfica Clara) ───────────────────
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(
              color: Color(0xFFE2E8F0), // Borde gris claro ultra fino
              width: 1,
            ),
          ),
          margin: EdgeInsets.zero,
        ),

        // ── Botones Elevados ───────────────────────────────────────
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              letterSpacing: 0.3,
            ),
          ),
        ),

        // ── Botones de Texto ────────────────────────────────────────
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF10B981),
            textStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),

        // ── Inputs / Formularios ───────────────────────────────────
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFEF4444)),
          ),
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
          labelStyle: const TextStyle(color: Color(0xFF475569)),
        ),

        // ── Divider ─────────────────────────────────────────────────
        dividerTheme: const DividerThemeData(
          color: Color(0xFFE2E8F0),
          thickness: 1,
        ),

        // ── Tooltips ────────────────────────────────────────────────
        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(color: Colors.white, fontSize: 12),
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


