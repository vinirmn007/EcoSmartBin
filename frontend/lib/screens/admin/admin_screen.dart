import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/background_gradient.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/premium_button.dart';

part 'admin_view.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _isLoading = true;
  int _totalBasureros = 0;
  int _basurerosActivos = 0;
  int _basurerosInactivos = 0;
  int _basurerosOcupados = 0;
  int _totalUsuarios = 0;
  int _puntosTotales = 0;
  int _totalCanjes = 0;
  int _totalRecompensas = 0;
  double _eficiencia = 0.0;
  double _carga = 0.0;
  
  @override
  void initState() {
    super.initState();
    _fetchMetrics();
  }

  Future<void> _fetchMetrics() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getBasureros(),
        ApiService.getUsuarios(),
        ApiService.getTodasRecompensas(),
        ApiService.getTodosCanjes(),
      ]);

      final basureros = results[0] as List<dynamic>;
      final usuarios = results[1] as List<dynamic>;
      final recompensas = results[2] as List<dynamic>;
      final canjes = results[3] as List<dynamic>;

      _totalBasureros = basureros.length;
      _basurerosActivos = basureros.where((b) => (b['estado'] ?? '').toString().toLowerCase() == 'activo').length;
      _basurerosInactivos = basureros.where((b) => (b['estado'] ?? '').toString().toLowerCase() != 'activo').length;
      _basurerosOcupados = basureros.where((b) => b['is_occupied'] == true).length;

      _totalUsuarios = usuarios.length;
      _puntosTotales = usuarios.fold<int>(
        0,
        (sum, u) => sum + ((u['puntos_ecologicos'] as num?)?.toInt() ?? 0),
      );

      _totalRecompensas = recompensas.length;
      _totalCanjes = canjes.length;

      _eficiencia = _totalBasureros > 0
          ? (_basurerosActivos / _totalBasureros) * 100
          : 100.0;

      _carga = _totalBasureros > 0
          ? (_basurerosOcupados / _totalBasureros) * 100
          : 0.0;
    } catch (e) {
      debugPrint('Error al cargar métricas de admin: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pushNamedAndRemoveUntil(context, '/profile', (route) => false);
        }
      },
      child: _AdminView(state: this),
    );
  }
}
