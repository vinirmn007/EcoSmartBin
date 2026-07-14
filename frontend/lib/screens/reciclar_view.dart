part of 'reciclar_screen.dart';

class _ReciclarView extends StatelessWidget {
  final _ReciclarScreenState state;

  const _ReciclarView({required this.state});

  // Mapeo de tipos de reciclaje a iconos y colores para la UI
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: (Navigator.canPop(context) && ModalRoute.of(context)?.settings.name == '/puntos/reciclar')
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'Reciclar y Acumular',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: _buildBodyForStep(context),
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

  // ── PASO 0: Cámara Escáner Simulado ──────────────────
  Widget _buildScanningStep() {
    return Column(
      key: const ValueKey('scanning'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Escaneando Basurero Inteligente',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Alinea el código QR del basurero en el recuadro',
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
        ),
        const SizedBox(height: 40),

        // Contenedor del visor de la cámara simulada
        Center(
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF10B981), width: 2),
            ),
            child: Stack(
              children: [
                // Esquinas del visor (diseño premium de escaneo)
                _buildCorner(top: 10, left: 10, angle: 0),
                _buildCorner(top: 10, right: 10, angle: 90),
                _buildCorner(bottom: 10, left: 10, angle: 270),
                _buildCorner(bottom: 10, right: 10, angle: 180),

                // Código QR simulado en el centro con opacidad
                Center(
                  child: Opacity(
                    opacity: 0.15,
                    child: Icon(
                      Icons.qr_code_2_rounded,
                      size: 160,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ),

                // Línea láser animada
                AnimatedBuilder(
                  animation: state._scannerAnimation,
                  builder: (context, child) {
                    final topOffset = state._scannerAnimation.value * 230 + 10;
                    return Positioned(
                      top: topOffset,
                      left: 20,
                      right: 20,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.8),
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
        ),
        const SizedBox(height: 45),

        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Color(0xFF10B981)),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Buscando basurero cercano...',
              style: TextStyle(color: Color(0xFF10B981), fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCorner({double? top, double? bottom, double? left, double? right, required double angle}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Transform.rotate(
        angle: angle * 3.14159 / 180,
        child: Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Color(0xFF10B981), width: 4),
              left: BorderSide(color: Color(0xFF10B981), width: 4),
            ),
          ),
        ),
      ),
    );
  }

  // ── PASO 1: Esperando que la IA clasifique ──────────
  Widget _buildWaitingIAStep() {
    return Center(
      key: const ValueKey('waiting_ia'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Banner de basurero conectado
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '¡Basurero Conectado!',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          state._detectedBinId,
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),

            // Animación de escáner IA
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
              ),
              child: const Icon(
                Icons.psychology_rounded,
                color: Color(0xFF3B82F6),
                size: 56,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Analizando con IA...',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'La cámara del basurero está clasificando\ntu residuo automáticamente',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(Color(0xFF3B82F6)),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Intento ${state._pollingAttempts}/${_ReciclarScreenState._maxPollingAttempts}',
                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── PASO 2: Confirmar Clasificación (IA o Manual) ────
  Widget _buildConfirmationStep() {
    final bool tieneIA = state._clasificacionIA != null && !state._modoManual;

    return SingleChildScrollView(
      key: const ValueKey('confirmation'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner de basurero conectado
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '¡Basurero Conectado!',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        state._detectedBinId,
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Resultado de la IA ──
          if (tieneIA) ...[
            _buildIADetectionCard(),
            const SizedBox(height: 12),
            // Botones secundarios
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: state._switchToManualMode,
                    icon: Icon(Icons.edit_rounded, size: 14, color: Colors.white.withOpacity(0.5)),
                    label: Text(
                      'Cambiar manual',
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: state._retryScan,
                    icon: Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white.withOpacity(0.5)),
                    label: Text(
                      'Tomar otra foto',
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // ── Modo manual (dropdown) ──
            const Text(
              'Selección Manual',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 6),
            Text(
              'Selecciona el residuo que vas a depositar en el basurero',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
            ),
            const SizedBox(height: 24),
            if (state._loadingTipos)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFF10B981))),
                ),
              )
            else ...[
              const Text(
                'Material:',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: state._tipoSeleccionado,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF10B981)),
                  ),
                ),
                items: state._tiposReciclaje.map<DropdownMenuItem<int>>((t) {
                  return DropdownMenuItem<int>(
                    value: t['id'] as int,
                    child: Text(
                      '${t['nombre']} — ${t['puntosPorUnidad']} pts/ud',
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (v) => state.setState(() => state._tipoSeleccionado = v),
              ),
            ],
          ],

          const SizedBox(height: 20),

          // Selector de Cantidad
          const Text(
            'Cantidad de unidades:',
            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  if (state._cantidad > 1) {
                    state.setState(() => state._cantidad--);
                  }
                },
                icon: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFF10B981), size: 28),
              ),
              Container(
                width: 60,
                alignment: Alignment.center,
                child: Text(
                  '${state._cantidad}',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: () {
                  state.setState(() => state._cantidad++);
                },
                icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF10B981), size: 28),
              ),
            ],
          ),
          const SizedBox(height: 40),

          // Botón para Confirmar Depósito
          ElevatedButton.icon(
            onPressed: state._submitReciclaje,
            icon: const Icon(Icons.eco_rounded),
            label: Text(tieneIA ? 'Confirmar Clasificación IA' : 'Confirmar Depósito'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  /// Card grande que muestra el resultado de la IA
  Widget _buildIADetectionCard() {
    final clasificacion = state._clasificacionIA!;
    final tipoDetectado = clasificacion['tipoDetectado'] as String? ?? 'trash';
    final confianza = (clasificacion['confianza'] as num?)?.toDouble() ?? 0.0;
    final nombreTipo = clasificacion['nombreTipo'] as String? ??
        _tipoNombreES[tipoDetectado] ?? 'Desconocido';

    final visual = _tipoVisual[tipoDetectado] ?? _tipoVisual['trash']!;
    final color = Color(visual['color'] as int);
    final icon = visual['icon'] as IconData;
    final confianzaPct = (confianza * 100).toStringAsFixed(1);

    final String? imagenBase64Full = clasificacion['imagenBase64'] as String?;
    String? base64Str;
    if (imagenBase64Full != null && imagenBase64Full.contains(',')) {
      base64Str = imagenBase64Full.split(',').last;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        children: [
          // Imagen capturada por ESP32
          if (base64Str != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: Image.memory(
                  base64Decode(base64Str),
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 180,
                      color: Colors.black26,
                      child: const Icon(Icons.broken_image_rounded, color: Colors.white54, size: 48),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Icono del tipo con badge de IA
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 48),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Label "IA detectó"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '🤖 Detectado por IA',
              style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),

          // Nombre del tipo
          Text(
            nombreTipo,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),

          // Barra de confianza
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Confianza: ',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
              ),
              Text(
                '$confianzaPct%',
                style: TextStyle(
                  color: confianza >= 0.7 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Barra visual de confianza
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: confianza,
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(
                confianza >= 0.7 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── PASO 3: Enviando registro... ─────────────────────
  Widget _buildSubmittingStep() {
    return Center(
      key: const ValueKey('submitting'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
          ),
          const SizedBox(height: 24),
          const Text(
            'Registrando reciclaje...',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Enviando confirmación a la base de datos',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── PASO 4: Éxito y Acumulación ──────────────────────
  Widget _buildSuccessStep(BuildContext context) {
    return Center(
      key: const ValueKey('success'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF10B981),
                size: 72,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              '¡Reciclaje Completado!',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Has acumulado con éxito:',
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              '+${state._puntosGanados} EcoPuntos 🌱',
              style: const TextStyle(
                color: Color(0xFF10B981),
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final isModal = ModalRoute.of(context)?.settings.name == '/puntos/reciclar';
                  if (isModal) {
                    Navigator.pop(context);
                  } else {
                    // Si estamos embebidos en el ProfileScreen (tab), forzamos
                    // el reemplazo al ProfileScreen para que actualice la info y cambie a la pestaña 0
                    state.setState(() {
                      state._step = 2;
                      state._puntosGanados = 0;
                      state._cantidad = 1;
                    });
                    Navigator.pushReplacementNamed(context, '/profile');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withOpacity(0.1)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Volver al Panel', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
