import 'package:flutter/material.dart';
import '../services/api_service.dart';

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
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Confirmar Canje'),
        content: Text(
          '¿Estás seguro de que deseas canjear "$nombre" por $costo EcoPuntos?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white70),
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
    return _CanjearView(state: this);
  }
}
