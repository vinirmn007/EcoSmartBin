import 'package:flutter/material.dart';
import 'screens/landing_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/profile_screen.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Verificar si ya existe una sesión activa al arrancar
  final bool loggedIn = await ApiService.hasSession();

  runApp(MyApp(startRoute: loggedIn ? '/profile' : '/'));
}

class MyApp extends StatelessWidget {
  final String startRoute;

  const MyApp({super.key, required this.startRoute});

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
      },
    );
  }
}

