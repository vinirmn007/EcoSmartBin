import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../services/api_service.dart';
import '../puntos/reciclar_screen.dart';
import '../puntos/canjear_screen.dart';
import '../puntos/reciclaje_historial_screen.dart';
import '../puntos/canjes_historial_screen.dart';

import '../../theme/app_colors.dart';
import '../../widgets/background_gradient.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/premium_button.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/progress_gauge.dart';

part 'profile_view.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _currentIndex = 0;
  UserProfile? _profile;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final profile = await ApiService.getProfile();

    if (mounted) {
      if (profile != null) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      } else {
        // Si no hay sesión válida o falla la obtención del perfil:
        // Redirigir a Landing Page en Web, y a Login en Android.
        final bool isAndroid = !kIsWeb && Platform.isAndroid;
        final String unauthRoute = isAndroid ? '/login' : '/';
        Navigator.pushNamedAndRemoveUntil(context, unauthRoute, (route) => false);
      }
    }
  }

  Future<void> _handleLogout() async {
    await ApiService.logout();
    if (mounted) {
      final bool isAndroid = !kIsWeb && Platform.isAndroid;
      final String unauthRoute = isAndroid ? '/login' : '/';
      Navigator.pushNamedAndRemoveUntil(context, unauthRoute, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ProfileView(state: this);
  }
}
