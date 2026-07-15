import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';

part 'reciclaje_historial_view.dart';

class ReciclajeHistorialScreen extends StatefulWidget {
  const ReciclajeHistorialScreen({Key? key}) : super(key: key);

  @override
  State<ReciclajeHistorialScreen> createState() => _ReciclajeHistorialScreenState();
}

class _ReciclajeHistorialScreenState extends State<ReciclajeHistorialScreen> {
  List<dynamic> _historial = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistorial();
  }

  Future<void> _loadHistorial() async {
    setState(() => _loading = true);
    final transacciones = await ApiService.getTransacciones();
    // Filtrar solo las de acumulación (reciclaje)
    final reciclajes = transacciones.where((t) => t['tipo'] == 'ACUMULACION').toList();
    if (mounted) {
      setState(() {
        _historial = reciclajes;
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

  @override
  Widget build(BuildContext context) {
    return _ReciclajeHistorialView(state: this);
  }
}
