import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/background_gradient.dart';

part 'canjear_view.dart';

class CanjearScreen extends StatefulWidget {
  const CanjearScreen({Key? key}) : super(key: key);

  @override
  State<CanjearScreen> createState() => _CanjearScreenState();
}

class _CanjearScreenState extends State<CanjearScreen> {
  List<dynamic> _recompensas = [];
  int _userPoints = 0;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final balanceResult = await ApiService.getBalance();
    final recompList = await ApiService.getRecompensas();

    if (mounted) {
      setState(() {
        if (balanceResult['success'] == true) {
          _userPoints = balanceResult['data']['puntosEcologicos'] ?? 0;
        }
        _recompensas = recompList;
        _loading = false;
      });
    }
  }

  Future<void> _handleCanje(int recompensaId, String nombre, int costo) async {
    if (_userPoints < costo) {
      _showSnack(
        'No tienes suficientes EcoPuntos para esta recompensa.',
        isError: true,
      );
      return;
    }

      final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('Confirmar Canje',
          style: TextStyle(color: Color(0xFF0F172A)),
        ),
        content: Text(
          '¿Estás seguro de que deseas canjear "$nombre" por $costo EcoPuntos?',
          style: const TextStyle(color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Color(0xFF475569)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
            ),
            child: const Text('Canjear'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _submitting = true);
    final result = await ApiService.canjearRecompensa(recompensaId);
    setState(() => _submitting = false);

    if (result['success'] == true) {
      _showSnack('¡Canje exitoso! 🎉 Disfruta tu recompensa.');
      _loadData(); // Recargar balance y recompensas
    } else {
      _showSnack(
        result['message'] ?? 'Error al procesar el canje',
        isError: true,
      );
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
      child: _CanjearView(state: this),
    );
  }
}
