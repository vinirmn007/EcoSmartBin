import 'package:flutter/material.dart';
import '../../services/api_service.dart';

part 'canjes_historial_view.dart';

class CanjesHistorialScreen extends StatefulWidget {
  const CanjesHistorialScreen({Key? key}) : super(key: key);

  @override
  State<CanjesHistorialScreen> createState() => _CanjesHistorialScreenState();
}

class _CanjesHistorialScreenState extends State<CanjesHistorialScreen> {
  List<dynamic> _historial = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistorial();
  }

  Future<void> _loadHistorial() async {
    setState(() => _loading = true);
    final canjes = await ApiService.getCanjes();
    if (mounted) {
      setState(() {
        _historial = canjes;
        _loading = false;
      });
    }
  }

  String _formatFecha(String fecha) {
    try {
      final dt = DateTime.parse(fecha).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return fecha;
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toUpperCase()) {
      case 'ENTREGADO':
        return const Color(0xFF10B981);
      case 'PENDIENTE':
        return const Color(0xFF3B82F6);
      case 'CANCELADO':
        return Colors.redAccent;
      default:
        return Colors.white54;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _CanjesHistorialView(state: this);
  }
}
