part of 'reciclaje_historial_screen.dart';

class _ReciclajeHistorialView extends StatelessWidget {
  final _ReciclajeHistorialScreenState state;

  const _ReciclajeHistorialView({required this.state});

  static const Color _emerald = AppColors.emeraldGlow;
  static const Color _bgLight = AppColors.background;
  static const Color _cardLight = AppColors.glassSurface;
  static const Color _textDark = AppColors.textPrimary;
  static const Color _textGray = AppColors.textSecondary;
  static const Color _borderLight = AppColors.glassBorder;

  // ── Mapeo de categoría a icono y color por descripción ──────────────────
  static IconData _getIconForDesc(String desc) {
    final d = desc.toLowerCase();
    if (d.contains('plástico') || d.contains('plastico')) {
      return Icons.local_drink_rounded;
    } else if (d.contains('papel')) {
      return Icons.description_rounded;
    } else if (d.contains('vidrio')) {
      return Icons.wine_bar_rounded;
    } else if (d.contains('metal')) {
      return Icons.hardware_rounded;
    } else if (d.contains('cartón') || d.contains('carton')) {
      return Icons.inventory_2_rounded;
    }
    return Icons.eco_rounded;
  }

  static Color _getColorForDesc(String desc) {
    final d = desc.toLowerCase();
    if (d.contains('plástico') || d.contains('plastico')) {
      return const Color(0xFF3B82F6);
    } else if (d.contains('papel')) {
      return const Color(0xFF8B5CF6);
    } else if (d.contains('vidrio')) {
      return const Color(0xFF06B6D4);
    } else if (d.contains('metal')) {
      return const Color(0xFFF59E0B);
    } else if (d.contains('cartón') || d.contains('carton')) {
      return const Color(0xFFD97706);
    }
    return _emerald;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _textDark),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/profile', (route) => false),
        ),
        title: Text(
          'Historial de Reciclaje',
          style: GoogleFonts.poppins(
            color: _textDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _HoverIconButton(
              icon: Icons.refresh_rounded,
              color: _emerald,
              onTap: state._loadHistorial,
            ),
          ),
        ],
      ),
      body: BackgroundGradient(
        child: state._loading
            ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: _emerald.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(18),
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(_emerald),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Cargando historial...',
                    style: GoogleFonts.poppins(
                      color: _textGray,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              color: _emerald,
              backgroundColor: _cardLight,
              onRefresh: state._loadHistorial,
              child: state._historial.isEmpty
                  ? _buildEmptyState()
                  : _buildContentWithKPIs(context),
            ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CONTENIDO PRINCIPAL (KPIs + Lista)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildContentWithKPIs(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    // Calcular KPIs del historial
    final totalPuntos = state._historial.fold<int>(
      0,
      (sum, item) => sum + ((item['puntos'] as int?) ?? 0),
    );
    final totalReciclajes = state._historial.length;

    // Encontrar material más frecuente
    final Map<String, int> frecuencia = {};
    for (final item in state._historial) {
      final desc = (item['descripcion'] as String? ?? '').toLowerCase();
      String mat = 'Eco';
      if (desc.contains('plástico') || desc.contains('plastico')) mat = 'Plástico';
      else if (desc.contains('papel')) mat = 'Papel';
      else if (desc.contains('vidrio')) mat = 'Vidrio';
      else if (desc.contains('metal')) mat = 'Metal';
      else if (desc.contains('cartón') || desc.contains('carton')) mat = 'Cartón';
      frecuencia[mat] = (frecuencia[mat] ?? 0) + 1;
    }
    final topMaterial = frecuencia.isEmpty
        ? '—'
        : frecuencia.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        // ── Dashboard KPIs ─────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              isDesktop ? 32 : 20, 8,
              isDesktop ? 32 : 20, 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumen',
                  style: GoogleFonts.poppins(
                    color: _textGray,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _KpiCard(
                        icon: Icons.eco_rounded,
                        value: '$totalPuntos',
                        label: 'EcoPuntos\nGanados',
                        accentColor: _emerald,
                        delay: 0.ms,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _KpiCard(
                        icon: Icons.recycling_rounded,
                        value: '$totalReciclajes',
                        label: 'Reciclajes\nRealizados',
                        accentColor: const Color(0xFF3B82F6),
                        delay: 80.ms,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _KpiCard(
                        icon: Icons.star_rounded,
                        value: topMaterial,
                        label: 'Material\nFavorito',
                        accentColor: const Color(0xFFF59E0B),
                        delay: 160.ms,
                        isText: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  'Actividad reciente',
                  style: GoogleFonts.poppins(
                    color: _textGray,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
              ],
            ),
          ),
        ),

        // ── Lista de reciclajes ────────────────────────────────────
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            isDesktop ? 32 : 20, 0,
            isDesktop ? 32 : 20, 24,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = state._historial[index];
                final puntos = item['puntos'] as int? ?? 0;
                final desc = item['descripcion'] as String? ??
                    'Reciclaje registrado';
                final fecha = item['fecha'] as String? ?? '';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _HistorialItemCard(
                    puntos: puntos,
                    desc: desc,
                    fecha: state._formatFecha(fecha),
                    delay: (index * 40).ms,
                  ),
                );
              },
              childCount: state._historial.length,
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ESTADO VACÍO
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(state.context).size.height * 0.28),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: _borderLight.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.eco_outlined,
                  size: 52,
                  color: _textGray.withOpacity(0.3),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Sin reciclajes registrados',
                style: GoogleFonts.poppins(
                  color: _textGray,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '¡Usa un basurero inteligente para empezar!',
                style: GoogleFonts.poppins(
                  color: _textGray.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
            ],
          ).animate().fadeIn(duration: 500.ms),
        ),
      ],
    );
  }
}

// =============================================================================
// COMPONENTES DE SOPORTE PARA EL HISTORIAL
// =============================================================================

/// Tarjeta KPI del dashboard superior
class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color accentColor;
  final Duration delay;
  final bool isText;

  const _KpiCard({
    Key? key,
    required this.icon,
    required this.value,
    required this.label,
    required this.accentColor,
    required this.delay,
    this.isText = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _ReciclajeHistorialView._cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _ReciclajeHistorialView._borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: accentColor.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: _ReciclajeHistorialView._textDark,
              fontSize: isText ? 15 : 22,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: _ReciclajeHistorialView._textGray,
              fontSize: 10,
              height: 1.4,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: delay, duration: 500.ms)
        .slideY(begin: 0.15, end: 0, delay: delay);
  }
}

/// Fila individual del historial con animación de cascada
class _HistorialItemCard extends StatefulWidget {
  final int puntos;
  final String desc;
  final String fecha;
  final Duration delay;

  const _HistorialItemCard({
    Key? key,
    required this.puntos,
    required this.desc,
    required this.fecha,
    required this.delay,
  }) : super(key: key);

  @override
  State<_HistorialItemCard> createState() => _HistorialItemCardState();
}

class _HistorialItemCardState extends State<_HistorialItemCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = _ReciclajeHistorialView._getColorForDesc(widget.desc);
    final icon = _ReciclajeHistorialView._getIconForDesc(widget.desc);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _ReciclajeHistorialView._cardLight,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _hovered
                ? color.withOpacity(0.3)
                : _ReciclajeHistorialView._borderLight,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icono del tipo de material
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(_hovered ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),

            // Descripción y fecha
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.desc,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: _ReciclajeHistorialView._textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.fecha,
                    style: GoogleFonts.poppins(
                      color: _ReciclajeHistorialView._textGray,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // Puntos ganados
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF10B981).withOpacity(0.2)),
              ),
              child: Text(
                '+${widget.puntos} pts',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF10B981),
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: widget.delay, duration: 400.ms)
        .slideX(begin: -0.08, end: 0, delay: widget.delay);
  }
}

/// Botón de icono con hover sutil
class _HoverIconButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HoverIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_HoverIconButton> createState() => _HoverIconButtonState();
}

class _HoverIconButtonState extends State<_HoverIconButton> {
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.color.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(widget.icon, color: widget.color, size: 22),
        ),
      ),
    );
  }
}
