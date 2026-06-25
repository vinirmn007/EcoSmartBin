part of 'reciclar_screen.dart';

class _ReciclarView extends StatelessWidget {
  final _ReciclarScreenState state;

  const _ReciclarView({required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context)
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
        return _buildSelectionStep();
      case 2:
        return _buildSubmittingStep();
      case 3:
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

  // ── PASO 1: Selección de Material y Cantidad ─────────
  Widget _buildSelectionStep() {
    return SingleChildScrollView(
      key: const ValueKey('selection'),
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

          // Título de la sección
          const Text(
            'Registrar Material Reciclado',
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
            // Selector de Materiales
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
              label: const Text('Confirmar Depósito'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── PASO 2: Enviando registro... ─────────────────────
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

  // ── PASO 3: Éxito y Acumulación ──────────────────────
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
                onPressed: () => Navigator.pop(context),
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
