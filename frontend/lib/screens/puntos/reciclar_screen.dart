import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/background_gradient.dart';

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

  // Lógica de escaneo
  late AnimationController _scannerController;
  late Animation<double> _scannerAnimation;
  Timer? _scanTimer;
  String _detectedBinId = 'EcoSmartBin-Q04';
  String _rawBinPublicId = 'EcoSmartBin-Q04';
  final MobileScannerController _cameraController = MobileScannerController(autoStart: false);
  bool _cameraActive = false;

  Future<void> _startCamera() async {
    setState(() {
      _cameraActive = true;
    });
    try {
      await _cameraController.start();
    } catch (e) {
      print('DEBUG Error starting camera: $e');
    }
  }

  Future<void> _stopCamera() async {
    try {
      await _cameraController.stop();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _cameraActive = false;
      });
    }
  }

  // Control de conexión
  bool _connecting = false;

  // Temporizador de sesión
  Timer? _countdownTimer;
  int _secondsRemaining = 300;

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

    // Verificar si venimos con un código QR en la URL
    _checkExternalQRLink();
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _pollingTimer?.cancel();
    _countdownTimer?.cancel();
    _scannerController.dispose();
    _cameraController.dispose();
    
    // Desconectar al salir para liberar el basurero si la sesión está activa y no se ha completado
    if (_step > 0 && _step < 4) {
      ApiService.desconectarBasurero(_rawBinPublicId);
    }
    super.dispose();
  }

  void _checkExternalQRLink() {
    try {
      final uri = Uri.base;
      final binFromUrl = uri.queryParameters['bin'];
      if (binFromUrl != null && binFromUrl.isNotEmpty) {
        // Conectar automáticamente si se escaneó externamente
        _conectarABasureroReal(binFromUrl.toLowerCase().trim());
      }
    } catch (_) {
      // no-op
    }
  }

  String _parseBinId(String rawValue) {
    try {
      final uri = Uri.parse(rawValue.trim());
      final binParam = uri.queryParameters['bin'];
      if (binParam != null && binParam.isNotEmpty) {
        return binParam.toLowerCase().trim();
      }
    } catch (_) {
      // no-op
    }
    return rawValue.toLowerCase().trim();
  }

  void _mostrarInputManual() {
    final TextEditingController textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF131313),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: const Color(0xFF10B981).withOpacity(0.3),
              width: 1,
            ),
          ),
          title: Text(
            'Ingresar Código Manual',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ingresa el código identificador del basurero (ej. EcoSmartBin-Q04):',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                autofocus: true,
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Código del basurero',
                  hintStyle: GoogleFonts.poppins(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF10B981)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                final code = textController.text.trim();
                if (code.isNotEmpty) {
                  Navigator.pop(context);
                  _conectarABasureroReal(code.toLowerCase());
                }
              },
              child: Text(
                'Conectar',
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _conectarABasureroReal(String publicId) async {
    setState(() {
      _connecting = true;
      _rawBinPublicId = publicId;
    });

    final res = await ApiService.conectarBasurero(publicId);

    if (mounted) {
      setState(() {
        _connecting = false;
      });

      if (res['success'] == true) {
        _stopCamera();
        final expiresAtStr = res['data']['expires_at'];
        
        setState(() {
          _detectedBinId = res['data']['basurero_nombre'] ?? publicId;
          _step = 1; // Esperando clasificación de la IA
        });

        _loadTiposReciclaje();
        
        if (expiresAtStr != null) {
          final expiresAt = DateTime.tryParse(expiresAtStr.toString());
          if (expiresAt != null) {
            _startSessionCountdown(expiresAt);
          } else {
            _startSessionCountdown(DateTime.now().add(const Duration(minutes: 5)));
          }
        } else {
          _startSessionCountdown(DateTime.now().add(const Duration(minutes: 5)));
        }

        _startPollingClasificacion();
      } else {
        _showSnack(res['message'] ?? 'Error al conectar con el basurero', isError: true);
        setState(() {
          _step = 0;
        });
      }
    }
  }

  void _startSessionCountdown(DateTime expiresAt) {
    _countdownTimer?.cancel();
    final diff = expiresAt.toUtc().difference(DateTime.now().toUtc());
    _secondsRemaining = diff.inSeconds;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          timer.cancel();
          _onSessionExpired();
        }
      });
    });
  }

  void _onSessionExpired() {
    _pollingTimer?.cancel();
    _countdownTimer?.cancel();
    _showSnack("Tu sesión de reciclaje ha expirado. Por favor, escanea nuevamente.", isError: true);
    setState(() {
      _step = 0;
    });
  }

  Future<void> _extenderSesion() async {
    final res = await ApiService.extenderSesionBasurero(_rawBinPublicId);
    if (res['success'] == true && mounted) {
      final expiresAtStr = res['data']['expires_at'];
      if (expiresAtStr != null) {
        final expiresAt = DateTime.tryParse(expiresAtStr.toString());
        if (expiresAt != null) {
          _startSessionCountdown(expiresAt);
        }
      }
      _showSnack('Sesión extendida por 5 minutos más.');
    } else {
      _showSnack(res['message'] ?? 'No se pudo extender la sesión', isError: true);
    }
  }

  Future<void> _desconectarManual() async {
    await ApiService.desconectarBasurero(_rawBinPublicId);
    _pollingTimer?.cancel();
    _countdownTimer?.cancel();
    if (mounted) {
      setState(() {
        _step = 0;
      });
      _showSnack('Sesión terminada. El basurero ha sido liberado.');
    }
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
    _pollingAttempts = 0;
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      _pollingAttempts++;

      final clasificacion = await ApiService.getClasificacionPendiente(_rawBinPublicId);

      if (clasificacion != null && mounted) {
        timer.cancel();
        setState(() {
          _clasificacionIA = clasificacion;
          // Auto-seleccionar el tipo de reciclaje detectado
          final tipoReciclajeId = clasificacion['tipoReciclajeId'];
          if (tipoReciclajeId != null) {
            _tipoSeleccionado = (tipoReciclajeId is int)
                ? tipoReciclajeId
                : int.tryParse(tipoReciclajeId.toString());
          }
          _step = 2; // Mostrar resultado de la IA
        });
        return;
      }

      // Timeout: después de 30 segundos sin respuesta, ir a modo manual
      if (_pollingAttempts >= _maxPollingAttempts && mounted) {
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
    ApiService.limpiarClasificacionPendiente(_rawBinPublicId);
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
        ApiService.limpiarClasificacionPendiente(_rawBinPublicId);
        // Desconectar del basurero ya que la operación fue un éxito
        ApiService.desconectarBasurero(_rawBinPublicId);
        _countdownTimer?.cancel();
        
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
