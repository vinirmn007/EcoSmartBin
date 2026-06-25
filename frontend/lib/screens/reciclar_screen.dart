import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

part 'reciclar_view.dart';

class ReciclarScreen extends StatefulWidget {
  const ReciclarScreen({Key? key}) : super(key: key);

  @override
  State<ReciclarScreen> createState() => _ReciclarScreenState();
}

class _ReciclarScreenState extends State<ReciclarScreen>
    with SingleTickerProviderStateMixin {
  // Estados:
  // 0 = Escaneando basurero (Cámara simulada)
  // 1 = Basurero detectado, seleccionando residuo
  // 2 = Registrando reciclaje...
  // 3 = Éxito
  int _step = 0;

  // Lógica de escaneo simulado
  late AnimationController _scannerController;
  late Animation<double> _scannerAnimation;
  Timer? _scanTimer;
  String _detectedBinId = '';

  // Datos para registrar
  List<dynamic> _tiposReciclaje = [];
  int? _tipoSeleccionado;
  int _cantidad = 1;
  bool _loadingTipos = false;
  int _puntosGanados = 0;

  @override
  void initState() {
    super.initState();

    // Animación de la línea láser del escáner
    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scannerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scannerController, curve: Curves.easeInOut),
    );

    // Iniciar escaneo simulado automático
    _startSimulatedScan();
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _scannerController.dispose();
    super.dispose();
  }

  void _startSimulatedScan() {
    _scanTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _detectedBinId = 'EcoSmartBin-Q04 (Ingeniería)';
          _step = 1;
        });
        _loadTiposReciclaje();
      }
    });
  }

  Future<void> _loadTiposReciclaje() async {
    setState(() => _loadingTipos = true);
    final list = await ApiService.getTiposReciclaje();
    if (mounted) {
      setState(() {
        _tiposReciclaje = list;
        if (list.isNotEmpty) {
          _tipoSeleccionado = list.first['id'] as int;
        }
        _loadingTipos = false;
      });
    }
  }

  Future<void> _submitReciclaje() async {
    if (_tipoSeleccionado == null) {
      _showSnack('Por favor selecciona un tipo de material', isError: true);
      return;
    }

    setState(() {
      _step = 2;
    });

    final result = await ApiService.registrarReciclaje(
      tipoReciclajeId: _tipoSeleccionado!,
      cantidad: _cantidad,
    );

    if (mounted) {
      if (result['success'] == true) {
        setState(() {
          _puntosGanados = result['data']['puntos'] ?? 0;
          _step = 3;
        });
      } else {
        _showSnack(result['message'] ?? 'Error al procesar reciclaje', isError: true);
        setState(() {
          _step = 1;
        });
      }
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
    return _ReciclarView(state: this);
  }
}
