part of 'reciclar_screen.dart';

class _ReciclarView extends StatelessWidget {
  final _ReciclarScreenState state;

  const _ReciclarView({required this.state});

  // ── Mapeo de tipos de reciclaje a iconos y colores para la UI ──────────────
  static const Map<String, Map<String, dynamic>> _tipoVisual = {
    'plastic': {'icon': Icons.local_drink_rounded, 'color': 0xFF3B82F6, 'emoji': '♻️'},
    'paper': {'icon': Icons.description_rounded, 'color': 0xFF8B5CF6, 'emoji': '📄'},
    'glass': {'icon': Icons.wine_bar_rounded, 'color': 0xFF06B6D4, 'emoji': '🫙'},
    'metal': {'icon': Icons.hardware_rounded, 'color': 0xFFF59E0B, 'emoji': '🥫'},
    'cardboard': {'icon': Icons.inventory_2_rounded, 'color': 0xFFD97706, 'emoji': '📦'},
    'trash': {'icon': Icons.delete_rounded, 'color': 0xFF6B7280, 'emoji': '🗑️'},
  };

  static const Map<String, String> _tipoNombreES = {
    'plastic': 'Plástico',
    'paper': 'Papel',
    'cardboard': 'Papel',
    'glass': 'Vidrio',
  };

  static const Color _emerald = AppColors.emeraldGlow;
  static const Color _bgLight = AppColors.background;
  static const Color _cardLight = AppColors.glassSurface;
  static const Color _cardDark = Color(0xFF1A211D);
  static const Color _textDark = AppColors.textPrimary;
  static const Color _textGray = AppColors.textSecondary;
  static const Color _borderLight = AppColors.glassBorder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textDark),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/profile', (route) => false),
        ),
        title: Row(
          children: [
            if (!Navigator.canPop(context) ||
                ModalRoute.of(context)?.settings.name != '/puntos/reciclar') ...
              [
                Image.asset(
                  'assets/images/logo.png',
                  width: 22,
                  height: 22,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.sensors_rounded,
                    color: _emerald,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
              ],
            Text(
              'EcoSmartBin',
              style: GoogleFonts.poppins(
                color: _emerald,
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
      body: BackgroundGradient(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.06),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
          child: _buildBodyForStep(context),
        ),
      ),
    );
  }

  Widget _buildBodyForStep(BuildContext context) {
    switch (state._step) {
      case 0:
        return _buildScanningStep();
      case 1:
        return _buildWaitingIAStep();
      case 2:
        return _buildConfirmationStep();
      case 3:
        return _buildSubmittingStep();
      case 4:
        return _buildSuccessStep(context);
      default:
        return const SizedBox();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PASO 0: Escáner de Código QR
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildScanningStep() {
    return Center(
      key: const ValueKey('scanning'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Header
            Text(
              'Escaneando Basurero',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: _textDark,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ).animate().fadeIn(duration: 500.ms),
            const SizedBox(height: 8),
            Text(
              'Alinea el código QR del basurero en el recuadro',
              style: GoogleFonts.poppins(
                color: _textGray,
                fontSize: 13,
              ),
            ).animate().fadeIn(delay: 100.ms, duration: 500.ms),
            const SizedBox(height: 48),

            // Visor del escáner premium
            Center(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  color: _cardLight,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: _emerald.withOpacity(0.5), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 30,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Cámara en vivo con MobileScanner
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: MobileScanner(
                          controller: state._cameraController,
                          onDetect: (capture) {
                            final List<Barcode> barcodes = capture.barcodes;
                            for (final barcode in barcodes) {
                              final String? rawValue = barcode.rawValue;
                              if (rawValue != null && rawValue.isNotEmpty && !state._connecting && state._step == 0) {
                                final parsedId = state._parseBinId(rawValue);
                                state._conectarABasureroReal(parsedId);
                                break;
                              }
                            }
                          },
                          errorBuilder: (context, error, child) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.videocam_off_rounded, color: Colors.redAccent.withOpacity(0.7), size: 48),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Cámara no disponible',
                                    style: GoogleFonts.poppins(color: _textGray, fontSize: 12),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Esquinas del visor
                    _buildCorner(top: 12, left: 12, angle: 0),
                    _buildCorner(top: 12, right: 12, angle: 90),
                    _buildCorner(bottom: 12, left: 12, angle: 270),
                    _buildCorner(bottom: 12, right: 12, angle: 180),

                    // Línea láser animada
                    AnimatedBuilder(
                      animation: state._scannerAnimation,
                      builder: (context, child) {
                        final topOffset =
                            state._scannerAnimation.value * 246 + 16;
                        return Positioned(
                          top: topOffset,
                          left: 20,
                          right: 20,
                          child: Container(
                            height: 2.5,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _emerald.withOpacity(0),
                                  _emerald,
                                  _emerald.withOpacity(0),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color: _emerald.withOpacity(0.9),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
            const SizedBox(height: 36),

            // Indicador de búsqueda
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: _cardLight,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: _borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(_emerald),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    state._connecting ? 'Iniciando sesión con basurero...' : 'Buscando basurero cercano...',
                    style: GoogleFonts.poppins(
                      color: _emerald,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
            const SizedBox(height: 16),

            // Botón premium para ingreso manual
            TextButton.icon(
              onPressed: state._mostrarInputManual,
              icon: const Icon(Icons.keyboard_rounded, color: _emerald, size: 20),
              label: Text(
                'Ingresar código manualmente',
                style: GoogleFonts.poppins(
                  color: _emerald,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                  side: BorderSide(color: _emerald.withOpacity(0.2), width: 1.2),
                ),
                backgroundColor: _emerald.withOpacity(0.04),
              ),
            ).animate().fadeIn(delay: 500.ms, duration: 500.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildCorner(
      {double? top, double? bottom, double? left, double? right, required double angle}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Transform.rotate(
        angle: angle * 3.14159 / 180,
        child: Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: _emerald, width: 4),
              left: BorderSide(color: _emerald, width: 4),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PASO 1: Esperando que la IA clasifique
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildWaitingIAStep() {
    return Center(
      key: const ValueKey('waiting_ia'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildConnectedBanner(),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(32),
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: _cardLight,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _emerald.withOpacity(0.3),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _emerald.withOpacity(0.06),
                    blurRadius: 32,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.04),
                            width: 5,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: CircularProgressIndicator(
                          strokeWidth: 4,
                          valueColor: AlwaysStoppedAnimation<Color>(_emerald),
                        )
                            .animate(onPlay: (c) => c.repeat())
                            .rotate(duration: 2000.ms),
                      ),
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: _emerald.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.insights_rounded,
                          color: _emerald,
                          size: 28,
                        ),
                      )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scaleXY(begin: 0.95, end: 1.05, duration: 1200.ms),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Analizando con IA...',
                    style: GoogleFonts.poppins(
                      color: _textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'La cámara del basurero está clasificando tu residuo...',
                    style: GoogleFonts.poppins(
                      color: _textGray,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PASO 2: Confirmar Clasificación (IA o Manual)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildConfirmationStep() {
    final clasificacion = state._clasificacionIA;
    final String rawTipo = (clasificacion?['tipoDetectado'] ?? '').toString().toLowerCase();
    final bool isReciclable = (rawTipo == 'plastic' || rawTipo == 'paper' || rawTipo == 'cardboard' || rawTipo == 'glass');

    return SingleChildScrollView(
      key: const ValueKey('confirmation'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildConnectedBanner(),
              const SizedBox(height: 24),
              _buildIADetectionCard(),
              const SizedBox(height: 28),
              if (isReciclable)
                _GradientButton(
                  label: 'Confirmar Clasificación IA',
                  icon: Icons.eco_rounded,
                  onTap: state._submitReciclaje,
                )
              else
                _GradientButton(
                  label: 'No Reciclable — Toma otra foto',
                  icon: Icons.camera_alt_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                  ),
                  onTap: () {
                    state._showSnack(
                      'Este basurero inteligente solo acepta Papel, Plástico o Vidrio. Presiona el botón del basurero para capturar otro residuo.',
                      isError: true,
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Banner de basurero conectado reutilizable
  Widget _buildConnectedBanner() {
    final minutes = (state._secondsRemaining / 60).floor();
    final seconds = state._secondsRemaining % 60;
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _emerald.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: _emerald, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Basurero Conectado!',
                  style: GoogleFonts.poppins(
                    color: _textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  state._detectedBinId,
                  style: GoogleFonts.poppins(
                    color: _textGray,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.timer_outlined, size: 12, color: state._secondsRemaining < 60 ? Colors.redAccent : _emerald),
                    const SizedBox(width: 4),
                    Text(
                      'Tiempo restante: $timeStr',
                      style: GoogleFonts.poppins(
                        color: state._secondsRemaining < 60 ? Colors.redAccent : _textGray,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_alarm_rounded, color: _emerald, size: 20),
            tooltip: 'Extender +5 min',
            onPressed: state._extenderSesion,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent, size: 20),
            tooltip: 'Desconectar basurero',
            onPressed: state._desconectarManual,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  /// Card de resultado de la IA
  Widget _buildIADetectionCard() {
    final clasificacion = state._clasificacionIA!;
    final String rawTipo = (clasificacion['tipoDetectado'] ?? '').toString().toLowerCase();
    final bool isReciclable = (rawTipo == 'plastic' || rawTipo == 'paper' || rawTipo == 'cardboard' || rawTipo == 'glass');

    final String nombreTipo = isReciclable
        ? (_tipoNombreES[rawTipo] ?? 'Papel')
        : 'Basura General';

    final Color color = isReciclable
        ? Color((_tipoVisual[rawTipo] ?? _tipoVisual['paper']!)['color'] as int)
        : const Color(0xFFEF4444);

    final IconData icon = isReciclable
        ? (_tipoVisual[rawTipo] ?? _tipoVisual['paper']!)['icon'] as IconData
        : Icons.delete_forever_rounded;

    final confianza = (clasificacion['confianza'] as num?)?.toDouble() ?? 0.0;
    final confianzaPct = (confianza * 100).toStringAsFixed(1);
    final bytes = state._decodedImageBytes;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth > 650;

        Widget buildImageFrame() {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF09100C),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: (isReciclable ? _emerald : const Color(0xFFEF4444)).withOpacity(0.6),
                      width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: (isReciclable ? _emerald : const Color(0xFFEF4444)).withOpacity(0.25),
                      blurRadius: 24,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: isDesktop ? 320 : 260,
                      minHeight: 180,
                    ),
                    child: bytes != null
                        ? Image.memory(
                            bytes,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 180,
                                color: Colors.black54,
                                child: const Center(
                                  child: Icon(Icons.broken_image_rounded,
                                      color: Colors.white38, size: 44),
                                ),
                              );
                            },
                          )
                        : Container(
                            height: 180,
                            color: Colors.black54,
                            child: const Center(
                              child: Icon(Icons.camera_alt_rounded,
                                  color: Colors.white38, size: 44),
                            ),
                          ),
                  ),
                ),
              ),
              // Badge flotante "IA VERIFIED" o "NO RECICLABLE" estilo Stitch
              Positioned(
                top: -12,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isReciclable ? _emerald : const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: (isReciclable ? _emerald : const Color(0xFFEF4444)).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isReciclable ? Icons.verified_rounded : Icons.warning_rounded,
                          color: isReciclable ? const Color(0xFF003824) : Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        isReciclable ? 'IA VERIFIED' : 'NO RECICLABLE',
                        style: GoogleFonts.poppins(
                          color: isReciclable ? const Color(0xFF003824) : Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        Widget buildDetails() {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isReciclable ? 'DETECCIÓN FINALIZADA' : 'RESIDUO NO RECICLABLE',
                style: GoogleFonts.poppins(
                  color: isReciclable ? _emerald : const Color(0xFFEF4444),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withOpacity(0.4)),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      nombreTipo,
                      style: GoogleFonts.poppins(
                        color: color,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                isReciclable
                    ? 'Residuo identificado correctamente por la cámara inteligente del basurero.'
                    : 'Este basurero inteligente solo recicla Papel, Plástico y Vidrio. Por favor toma otra foto presionando el botón físico en el basurero.',
                style: GoogleFonts.poppins(
                  color: _textGray,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              // Medidor de Confianza Stitch
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Confianza de la IA',
                          style: GoogleFonts.poppins(
                            color: _textGray,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '$confianzaPct%',
                          style: GoogleFonts.poppins(
                            color: isReciclable ? _emerald : const Color(0xFFEF4444),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: confianza,
                        minHeight: 7,
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation(
                          isReciclable ? _emerald : const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Stack(
              children: [
                // Top Light Sweep
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 1.5,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          _emerald,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(flex: 6, child: buildImageFrame()),
                            const SizedBox(width: 32),
                            Expanded(flex: 6, child: buildDetails()),
                          ],
                        )
                      : Column(
                          children: [
                            buildImageFrame(),
                            const SizedBox(height: 28),
                            buildDetails(),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PASO 3: Enviando registro
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSubmittingStep() {
    return Center(
      key: const ValueKey('submitting'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(32),
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: _cardLight,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _emerald.withOpacity(0.3),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: _emerald.withOpacity(0.06),
                blurRadius: 32,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.04),
                        width: 5,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation<Color>(_emerald),
                    )
                        .animate(onPlay: (c) => c.repeat())
                        .rotate(duration: 2000.ms),
                  ),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _emerald.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.backup_rounded,
                      color: _emerald,
                      size: 28,
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scaleXY(begin: 0.95, end: 1.05, duration: 1200.ms),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Registrando reciclaje...',
                style: GoogleFonts.poppins(
                  color: _textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Enviando confirmación y sincronizando puntos...',
                style: GoogleFonts.poppins(
                  color: _textGray,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PASO 4: Éxito y Acumulación de Puntos
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSuccessStep(BuildContext context) {
    return Center(
      key: const ValueKey('success'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animación de éxito (Lottie placeholder)
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    _emerald.withOpacity(0.25),
                    _emerald.withOpacity(0.0),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: _emerald.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: _emerald.withOpacity(0.4), width: 2),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: _emerald,
                    size: 52,
                  ),
                ),
              ),
            )
                .animate()
                .scale(
                    begin: const Offset(0.3, 0.3),
                    end: const Offset(1.0, 1.0),
                    duration: 600.ms,
                    curve: Curves.elasticOut)
                .fadeIn(duration: 400.ms),
            const SizedBox(height: 36),

            Text(
              '¡Reciclaje Completado!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: _textDark,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
            const SizedBox(height: 12),
            Text(
              'Has acumulado con éxito:',
              style: GoogleFonts.poppins(
                color: _textGray,
                fontSize: 14,
              ),
            ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
            const SizedBox(height: 16),

            // Puntos ganados
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _emerald.withOpacity(0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.eco_rounded,
                      color: Colors.white, size: 28),
                  const SizedBox(width: 10),
                  Text(
                    '+${state._puntosGanados} EcoPuntos',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: 500.ms, duration: 600.ms)
                .slideY(begin: 0.3, end: 0, delay: 500.ms),
            const SizedBox(height: 56),

            SizedBox(
              width: double.infinity,
              child: _GradientButton(
                label: 'Volver al Panel',
                icon: Icons.home_rounded,
                onTap: () {
                  final isModal = ModalRoute.of(context)?.settings.name ==
                      '/puntos/reciclar';
                  if (isModal) {
                    Navigator.pop(context);
                  } else {
                    state.setState(() {
                      state._step = 0;
                      state._puntosGanados = 0;
                    });
                    Navigator.pushReplacementNamed(context, '/profile');
                  }
                },
              ),
            ).animate().fadeIn(delay: 700.ms, duration: 500.ms),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// COMPONENTES DE SOPORTE PARA RECICLAR
// =============================================================================

/// Botón de cantidad con hover
class _QuantityButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QuantityButton({required this.icon, required this.onTap});

  @override
  State<_QuantityButton> createState() => _QuantityButtonState();
}

class _QuantityButtonState extends State<_QuantityButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _hovered
                ? const Color(0xFF10B981).withOpacity(0.2)
                : const Color(0xFF10B981).withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF10B981)
                  .withOpacity(_hovered ? 0.5 : 0.25),
              width: 1.5,
            ),
          ),
          child: Icon(widget.icon,
              color: const Color(0xFF10B981), size: 22),
        ),
      ),
    );
  }
}

/// Chip de acción secundaria (Cambiar manual / Tomar otra foto)
class _ActionChip extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip(
      {required this.icon, required this.label, required this.onTap});

  @override
  State<_ActionChip> createState() => _ActionChipState();
}

class _ActionChipState extends State<_ActionChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered
                ? const Color(0xFFE2E8F0)
                : const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered
                  ? const Color(0xFF10B981).withOpacity(0.3)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon,
                  size: 14,
                  color: const Color(0xFF475569)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.label,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF475569),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón de gradiente premium reutilizable
class _GradientButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final Gradient? gradient;
  final Color? borderColor;

  const _GradientButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.gradient,
    this.borderColor,
  });

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()
            ..translate(0.0, _hovered ? -2.0 : 0.0),
          padding:
              const EdgeInsets.symmetric(horizontal: 28, vertical: 17),
          decoration: BoxDecoration(
            gradient: widget.gradient ??
                LinearGradient(
                  colors: _hovered
                      ? [const Color(0xFF6EE7B7), const Color(0xFF10B981)]
                      : [const Color(0xFF4EDEA3), const Color(0xFF10B981)],
                ),
            borderRadius: BorderRadius.circular(18),
            border: widget.borderColor != null
                ? Border.all(color: widget.borderColor!)
                : null,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4EDEA3)
                    .withOpacity(_hovered ? 0.5 : 0.25),
                blurRadius: _hovered ? 28 : 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: const Color(0xFF003824), size: 20),
                const SizedBox(width: 10),
              ],
              Text(
                widget.label,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF003824),
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
