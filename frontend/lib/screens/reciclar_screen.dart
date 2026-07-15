import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
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
  // 1 = Esperando clasificación de la IA...
  // 2 = IA detectó el tipo, usuario confirma
  // 3 = Registrando reciclaje...
  // 4 = Éxito
  int _step = 0;

  // Lógica de escaneo simulado
  late AnimationController _scannerController;
  late Animation<double> _scannerAnimation;
  Timer? _scanTimer;
  String _detectedBinId = 'EcoSmartBin-Q04';

  // Datos de la IA
  Map<String, dynamic>? _clasificacionIA;
  Timer? _pollingTimer;
  int _pollingAttempts = 0;
  static const int _maxPollingAttempts = 15; // 15 intentos × 2s = 30s máx

  // Datos para registrar
  List<dynamic> _tiposReciclaje = [];
  int? _tipoSeleccionado;
  int _cantidad = 1;
  bool _loadingTipos = false;
  int _puntosGanados = 0;

  // Modo manual (fallback si la IA falla o clasifica mal)
  bool _modoManual = false;

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
    _pollingTimer?.cancel();
    _scannerController.dispose();
    super.dispose();
  }

  void _startSimulatedScan() {
    // Limpiar clasificación pendiente previa para asegurar datos nuevos
    ApiService.limpiarClasificacionPendiente('EcoSmartBin-Q04');

    _scanTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _detectedBinId = 'EcoSmartBin-Q04 (Ingeniería)';
          _step = 1; // Esperando clasificación de la IA
        });
        _loadTiposReciclaje();
        _startPollingClasificacion();
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

  /// Polling cada 2 segundos al servicio de puntos para ver si la IA ya clasificó
  void _startPollingClasificacion() {
    _pollingTimer?.cancel();
    _pollingAttempts = 0;
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      _pollingAttempts++;

      final clasificacion = await ApiService.getClasificacionPendiente('EcoSmartBin-Q04');

      if (clasificacion != null && mounted) {
        // Verificar si es una clasificación nueva comparando timestamps
        final int? newTimestamp = clasificacion['timestamp'] as int?;
        final int? currentTimestamp = _clasificacionIA?['timestamp'] as int?;

        // Actualizar si no hay clasificación actual o si la nueva es más reciente
        if (_clasificacionIA == null || (newTimestamp != null && currentTimestamp != null && newTimestamp > currentTimestamp)) {
          setState(() {
            _clasificacionIA = clasificacion;
            // Auto-seleccionar el tipo de reciclaje detectado
            final tipoReciclajeId = clasificacion['tipoReciclajeId'];
            if (tipoReciclajeId != null) {
              _tipoSeleccionado = (tipoReciclajeId is int)
                  ? tipoReciclajeId
                  : int.tryParse(tipoReciclajeId.toString());
            }
            if (_step == 1) {
              _step = 2; // Mostrar resultado de la IA
            }
          });
        }
        return;
      }

      // Timeout: después de 30 segundos sin respuesta, ir a modo manual
      if (_step == 1 && _pollingAttempts >= _maxPollingAttempts && mounted) {
        timer.cancel();
        setState(() {
          _modoManual = true;
          _step = 2; // Ir a selección, pero en modo manual
        });
        _showSnack(
          'La IA no respondió. Selecciona el tipo manualmente.',
          isError: true,
        );
      }
    });
  }

  /// Cambiar a modo manual (si la IA clasificó mal)
  void _switchToManualMode() {
    setState(() {
      _modoManual = true;
      _clasificacionIA = null;
    });
  }

  /// Descartar la clasificación actual y volver a esperar una nueva foto
  void _retryScan() {
    ApiService.limpiarClasificacionPendiente('EcoSmartBin-Q04');
    setState(() {
      _clasificacionIA = null;
      _modoManual = false;
      _step = 1; // Volver a "Esperando IA"
    });
    _startPollingClasificacion();
  }

  Future<void> _submitReciclaje() async {
    if (_tipoSeleccionado == null) {
      _showSnack('Por favor selecciona un tipo de material', isError: true);
      return;
    }

    _pollingTimer?.cancel();

    setState(() {
      _step = 3;
    });

    final result = await ApiService.registrarReciclaje(
      tipoReciclajeId: _tipoSeleccionado!,
      cantidad: _cantidad,
    );

    if (mounted) {
      if (result['success'] == true) {
        // Limpiar la clasificación pendiente en el backend
        ApiService.limpiarClasificacionPendiente('EcoSmartBin-Q04');
        setState(() {
          _puntosGanados = result['data']['puntos'] ?? 0;
          _step = 4;
        });
      } else {
        _showSnack(result['message'] ?? 'Error al procesar reciclaje', isError: true);
        setState(() {
          _step = 2;
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
