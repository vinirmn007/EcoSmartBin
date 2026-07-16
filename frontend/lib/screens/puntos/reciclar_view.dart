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
    'glass': 'Vidrio',
    'metal': 'Metal',
    'cardboard': 'Cartón',
    'trash': 'Basura General',
  };

  static const Color _emerald = AppColors.emeraldGlow;
  static const Color _bgLight = AppColors.background;
  static const Color _cardLight = AppColors.glassSurface;
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
        leading: (Navigator.canPop(context) &&
                ModalRoute.of(context)?.settings.name == '/puntos/reciclar')
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: _textDark),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Row(
          children: [
            if (!Navigator.canPop(context) ||
                ModalRoute.of(context)?.settings.name != '/puntos/reciclar') ...
              const [
                Icon(Icons.sensors_rounded, color: _emerald, size: 20),
                SizedBox(width: 8),
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
                    // Esquinas del visor
                    _buildCorner(top: 12, left: 12, angle: 0),
                    _buildCorner(top: 12, right: 12, angle: 90),
                    _buildCorner(bottom: 12, left: 12, angle: 270),
                    _buildCorner(bottom: 12, right: 12, angle: 180),

                    // QR simulado
                    Center(
                      child: Opacity(
                        opacity: 0.1,
                        child: Icon(
                          Icons.qr_code_2_rounded,
                          size: 180,
                          color: _textDark,
                        ),
                      ),
                    ),

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
            const SizedBox(height: 48),

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
                    'Buscando basurero cercano...',
                    style: GoogleFonts.poppins(
                      color: _emerald,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
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
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Banner basurero conectado
            _buildConnectedBanner(),
            const SizedBox(height: 48),

            // Lottie placeholder (usando el widget de lottie con URL pública)
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFF3B82F6).withOpacity(0.25),
                    width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    blurRadius: 30,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.psychology_rounded,
                color: Color(0xFF3B82F6),
                size: 64,
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(begin: 1.0, end: 1.05, duration: 900.ms)
                .then()
                .scaleXY(begin: 1.05, end: 1.0, duration: 900.ms),
            const SizedBox(height: 36),

            Text(
              'Analizando con IA...',
              style: GoogleFonts.poppins(
                color: _textDark,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'La cámara del basurero está clasificando\ntu residuo automáticamente',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: _textGray,
                fontSize: 13,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),

            // Contador de intentos
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _cardLight,
                borderRadius: BorderRadius.circular(20),
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
                      valueColor: const AlwaysStoppedAnimation(
                          Color(0xFF3B82F6)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Intento ${state._pollingAttempts}/${_ReciclarScreenState._maxPollingAttempts}',
                    style: GoogleFonts.poppins(
                      color: _textGray,
                      fontSize: 12,
                    ),
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
    final bool tieneIA =
        state._clasificacionIA != null && !state._modoManual;

    return SingleChildScrollView(
      key: const ValueKey('confirmation'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildConnectedBanner(),
          const SizedBox(height: 24),

          // ── Resultado IA ──
          if (tieneIA) ...[
            _buildIADetectionCard(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ActionChip(
                    icon: Icons.edit_rounded,
                    label: 'Cambiar manual',
                    onTap: state._switchToManualMode,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionChip(
                    icon: Icons.camera_alt_rounded,
                    label: 'Tomar otra foto',
                    onTap: state._retryScan,
                  ),
                ),
              ],
            ),
          ] else ...[
            // ── Modo Manual ──
            Text(
              'Selección Manual',
              style: GoogleFonts.poppins(
                color: _textDark,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Selecciona el residuo que vas a depositar en el basurero',
              style: GoogleFonts.poppins(
                color: _textGray,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            if (state._loadingTipos)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(_emerald),
                  ),
                ),
              )
            else ...[
              Text(
                'Material:',
                style: GoogleFonts.poppins(
                  color: _textGray,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: state._tipoSeleccionado,
                dropdownColor: _cardLight,
                style: GoogleFonts.poppins(
                    color: _textDark, fontSize: 14),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: _cardLight,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: _borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _emerald, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                items: state._tiposReciclaje
                    .map<DropdownMenuItem<int>>((t) {
                  return DropdownMenuItem<int>(
                    value: t['id'] as int,
                    child: Text(
                        '${t['nombre']} — ${t['puntosPorUnidad']} pts/ud'),
                  );
                }).toList(),
                onChanged: (v) =>
                    state.setState(() => state._tipoSeleccionado = v),
              ),
            ],
          ],

          const SizedBox(height: 28),

          // ── Selector de Cantidad ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _cardLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cantidad de unidades',
                  style: GoogleFonts.poppins(
                    color: _textGray,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _QuantityButton(
                      icon: Icons.remove_rounded,
                      onTap: () {
                        if (state._cantidad > 1) {
                          state.setState(() => state._cantidad--);
                        }
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        '${state._cantidad}',
                        style: GoogleFonts.poppins(
                          color: _textDark,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _QuantityButton(
                      icon: Icons.add_rounded,
                      onTap: () =>
                          state.setState(() => state._cantidad++),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ── Botón Confirmar ──
          _GradientButton(
            label:
                tieneIA ? 'Confirmar Clasificación IA' : 'Confirmar Depósito',
            icon: Icons.eco_rounded,
            onTap: state._submitReciclaje,
          ),
        ],
      ),
    );
  }

  /// Banner de basurero conectado reutilizable
  Widget _buildConnectedBanner() {
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
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: _emerald,
              shape: BoxShape.circle,
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fadeOut(duration: 800.ms),
        ],
      ),
    );
  }

  /// Card de resultado de la IA
  Widget _buildIADetectionCard() {
    final clasificacion = state._clasificacionIA!;
    final tipoDetectado =
        clasificacion['tipoDetectado'] as String? ?? 'trash';
    final confianza =
        (clasificacion['confianza'] as num?)?.toDouble() ?? 0.0;
    final nombreTipo = clasificacion['nombreTipo'] as String? ??
        _tipoNombreES[tipoDetectado] ?? 'Desconocido';

    final visual = _tipoVisual[tipoDetectado] ?? _tipoVisual['trash']!;
    final color = Color(visual['color'] as int);
    final icon = visual['icon'] as IconData;
    final confianzaPct = (confianza * 100).toStringAsFixed(1);

    final String? imagenBase64Full =
        clasificacion['imagenBase64'] as String?;
    String? base64Str;
    if (imagenBase64Full != null && imagenBase64Full.contains(',')) {
      base64Str = imagenBase64Full.split(',').last;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _borderLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Imagen capturada por ESP32
          if (base64Str != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: Image.memory(
                  base64Decode(base64Str),
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.broken_image_rounded,
                          color: Colors.white54, size: 44),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Icono del tipo con badge IA
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: color.withOpacity(0.3), width: 1),
                ),
                child: Icon(icon, color: color, size: 48),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: _cardLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 2),
                    ),
                    child: Icon(Icons.smart_toy_rounded,
                        color: color, size: 15),
                  ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Label "IA detectó"
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '🤖 Detectado por IA',
              style: GoogleFonts.poppins(
                color: _textGray,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Nombre del tipo
          Text(
            nombreTipo,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),

          // Confianza texto
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Confianza: ',
                style: GoogleFonts.poppins(
                  color: _textGray,
                  fontSize: 13,
                ),
              ),
              Text(
                '$confianzaPct%',
                style: GoogleFonts.poppins(
                  color: confianza >= 0.7
                      ? _emerald
                      : const Color(0xFFD97706),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Barra visual de confianza
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: confianza,
              minHeight: 6,
              backgroundColor: _borderLight,
              valueColor: AlwaysStoppedAnimation(
                confianza >= 0.7
                    ? _emerald
                    : const Color(0xFFD97706),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PASO 3: Enviando registro
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSubmittingStep() {
    return Center(
      key: const ValueKey('submitting'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _emerald.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(_emerald),
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .scaleXY(begin: 1.0, end: 1.08, duration: 700.ms)
              .then()
              .scaleXY(begin: 1.08, end: 1.0, duration: 700.ms),
          const SizedBox(height: 28),
          Text(
            'Registrando reciclaje...',
            style: GoogleFonts.poppins(
              color: _textDark,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enviando confirmación a la base de datos',
            style: GoogleFonts.poppins(
              color: _textGray,
              fontSize: 13,
            ),
          ),
        ],
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
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                ),
                borderColor: Colors.white.withOpacity(0.1),
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
                      ? [const Color(0xFF34D399), const Color(0xFF10B981)]
                      : [const Color(0xFF10B981), const Color(0xFF059669)],
                ),
            borderRadius: BorderRadius.circular(18),
            border: widget.borderColor != null
                ? Border.all(color: widget.borderColor!)
                : null,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981)
                    .withOpacity(widget.gradient == null
                        ? (_hovered ? 0.4 : 0.2)
                        : 0.0),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: Colors.white, size: 18),
                const SizedBox(width: 10),
              ],
              Text(
                widget.label,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
