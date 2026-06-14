import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/reset_password_screen.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  
  // Verificar si ya existe una sesión activa al arrancar
  final bool loggedIn = await ApiService.hasSession();

  String startRoute = loggedIn ? '/profile' : '/login';
  String? accessToken;
  String? refreshToken;

  final uri = Uri.base;
  if (uri.path == '/reset-password' && uri.fragment.contains('access_token=')) {
    startRoute = '/reset-password';
    final fragmentParams = Uri.splitQueryString(uri.fragment);
    accessToken = fragmentParams['access_token'];
    refreshToken = fragmentParams['refresh_token'];
  }

  runApp(MyApp(
    startRoute: startRoute,
    accessToken: accessToken,
    refreshToken: refreshToken,
  ));
}

class MyApp extends StatelessWidget {
  final String startRoute;
  final String? accessToken;
  final String? refreshToken;

  const MyApp({
    super.key, 
    required this.startRoute,
    this.accessToken,
    this.refreshToken,
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
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/reset-password': (context) => ResetPasswordScreen(
              accessToken: accessToken ?? '',
              refreshToken: refreshToken ?? '',
            ),
      },
    );
  }
}
