part of 'canjes_historial_screen.dart';

class _CanjesHistorialView extends StatelessWidget {
  final _CanjesHistorialScreenState state;

  const _CanjesHistorialView({required this.state});

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
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _textDark),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/profile', (route) => false),
        ),
        title: Text(
          'Historial de Canjes',
          style: GoogleFonts.poppins(
            color: _textDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _emerald),
            onPressed: state._loadHistorial,
          ),
          const SizedBox(width: 8),
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

  Widget _buildContentWithKPIs(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    // Calcular KPIs de canjes
    final totalPuntosGastados = state._historial.fold<int>(
      0,
      (sum, item) => sum + ((item['puntosGastados'] as int?) ?? 0),
    );
    final totalCanjes = state._historial.length;

    // Encontrar recompensa favorita o estado común
    final Map<String, int> frecuencia = {};
    for (final item in state._historial) {
      final nombre = item['recompensaNombre'] as String? ?? 'Recompensa';
      frecuencia[nombre] = (frecuencia[nombre] ?? 0) + 1;
    }
    final topRecompensa = frecuencia.isEmpty
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
                  'Resumen de Canjes',
                  style: GoogleFonts.poppins(
                    color: _textGray,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _KpiCard(
                        icon: Icons.local_activity_rounded,
                        value: '$totalPuntosGastados',
                        label: 'EcoPuntos\nCanjeados',
                        accentColor: AppColors.error,
                        delay: 0.ms,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _KpiCard(
                        icon: Icons.redeem_rounded,
                        value: '$totalCanjes',
                        label: 'Recompensas\nReclamadas',
                        accentColor: const Color(0xFF3B82F6),
                        delay: 80.ms,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _KpiCard(
                        icon: Icons.favorite_rounded,
                        value: topRecompensa,
                        label: 'Favorito\nReclamado',
                        accentColor: const Color(0xFFF59E0B),
                        delay: 160.ms,
                        isText: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  'Canjes realizados',
                  style: GoogleFonts.poppins(
                    color: _textGray,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
              ],
            ),
          ),
        ),

        // ── Lista de Canjes ────────────────────────────────────────
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            isDesktop ? 32 : 20, 0,
            isDesktop ? 32 : 20, 24,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = state._historial[index];
                final recompensaNombre = item['recompensaNombre'] as String? ?? 'Recompensa';
                final puntos = item['puntosGastados'] as int? ?? 0;
                final fecha = item['fecha'] as String? ?? '';
                final estado = item['estado'] as String? ?? 'PENDIENTE';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CanjeItemCard(
                    recompensaNombre: recompensaNombre,
                    puntos: puntos,
                    fecha: state._formatFecha(fecha),
                    estado: estado,
                    estadoColor: state._getEstadoColor(estado),
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
                  Icons.shopping_bag_outlined,
                  size: 52,
                  color: _textGray.withOpacity(0.3),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Sin canjes registrados',
                style: GoogleFonts.poppins(
                  color: _textGray,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '¡Canjea tus puntos por premios increíbles!',
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
        color: _CanjesHistorialView._cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _CanjesHistorialView._borderLight,
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
              color: _CanjesHistorialView._textDark,
              fontSize: isText ? 13 : 20,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: _CanjesHistorialView._textGray,
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

class _CanjeItemCard extends StatefulWidget {
  final String recompensaNombre;
  final int puntos;
  final String fecha;
  final String estado;
  final Color estadoColor;
  final Duration delay;

  const _CanjeItemCard({
    Key? key,
    required this.recompensaNombre,
    required this.puntos,
    required this.fecha,
    required this.estado,
    required this.estadoColor,
    required this.delay,
  }) : super(key: key);

  @override
  State<_CanjeItemCard> createState() => _CanjeItemCardState();
}

class _CanjeItemCardState extends State<_CanjeItemCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _CanjesHistorialView._cardLight,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _hovered
                ? widget.estadoColor.withOpacity(0.3)
                : _CanjesHistorialView._borderLight,
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
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: widget.estadoColor.withOpacity(_hovered ? 0.2 : 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.redeem_rounded, color: widget.estadoColor, size: 22),
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.recompensaNombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: _CanjesHistorialView._textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.fecha,
                    style: GoogleFonts.poppins(
                      color: _CanjesHistorialView._textGray,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: widget.estadoColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.estado.toUpperCase(),
                      style: GoogleFonts.poppins(
                        color: widget.estadoColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Text(
              '-${widget.puntos} pts',
              style: GoogleFonts.poppins(
                color: AppColors.error,
                fontWeight: FontWeight.w900,
                fontSize: 14,
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
