part of 'canjear_screen.dart';

class _CanjearView extends StatelessWidget {
  final _CanjearScreenState state;

  const _CanjearView({required this.state});

  static const Color _emerald = AppColors.emeraldGlow;
  static const Color _emeraldLight = Color(0xFF34D399);
  static const Color _bgLight = AppColors.background;
  static const Color _cardLight = AppColors.glassSurface;
  static const Color _textDark = AppColors.textPrimary;
  static const Color _textGray = AppColors.textSecondary;
  static const Color _borderLight = AppColors.glassBorder;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: _textDark),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          'Canjear EcoPuntos',
          style: GoogleFonts.poppins(
            color: _textDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
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
                    'Cargando recompensas...',
                    style: GoogleFonts.poppins(
                      color: _textGray,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                Column(
                  children: [
                    // ── Banner de Puntos Premium ──────────────────────
                    _buildPointsBanner(context),

                    // ── Grid/Lista de Recompensas ─────────────────────
                    Expanded(
                      child: state._recompensas.isEmpty
                          ? _buildEmptyState()
                          : isDesktop
                              ? _buildDesktopGrid(context)
                              : _buildMobileList(context),
                    ),
                  ],
                ),

                // ── Overlay de procesamiento ──────────────────────────
                if (state._submitting)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        margin: const EdgeInsets.symmetric(horizontal: 48),
                        decoration: BoxDecoration(
                          color: _cardLight,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: _borderLight),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 30,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(_emerald),
                              strokeWidth: 3,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Procesando canje...',
                              style: GoogleFonts.poppins(
                                color: _textDark,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BANNER DE PUNTOS (Glassmorphism)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildPointsBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF047857), Color(0xFF065F46)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _emerald.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icono con efecto circulo
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.eco_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tus EcoPuntos disponibles',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${state._userPoints}',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'pts',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1, end: 0);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ESTADO VACÍO
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
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
              Icons.card_giftcard_rounded,
              size: 52,
              color: _textGray.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Sin recompensas disponibles',
            style: GoogleFonts.poppins(
              color: _textGray,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vuelve pronto para descubrir nuevas ofertas.',
            style: GoogleFonts.poppins(
              color: _textGray.withOpacity(0.6),
              fontSize: 13,
            ),
          ),
        ],
      ).animate().fadeIn(duration: 500.ms),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LISTA MÓVIL (Grid de 2 columnas al estilo Stitch Movie Poster)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildMobileList(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 2 / 3.1, // Aspecto para Movie Poster
      ),
      itemCount: state._recompensas.length,
      itemBuilder: (context, index) {
        return _RecompensaCard(
          recompensa: state._recompensas[index],
          userPoints: state._userPoints,
          onCanjear: state._handleCanje,
          delay: (index * 60).ms,
          isDesktop: false,
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GRID DESKTOP (4 columnas al estilo Stitch Movie Poster)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildDesktopGrid(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(32, 4, 32, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 2 / 3.1, // Aspecto para Movie Poster
      ),
      itemCount: state._recompensas.length,
      itemBuilder: (context, index) {
        return _RecompensaCard(
          recompensa: state._recompensas[index],
          userPoints: state._userPoints,
          onCanjear: state._handleCanje,
          delay: (index * 60).ms,
          isDesktop: true,
        );
      },
    );
  }
}

// =============================================================================
// TARJETA DE RECOMPENSA (Estilo Movie Poster de Stitch)
// =============================================================================
class _RecompensaCard extends StatefulWidget {
  final Map<String, dynamic> recompensa;
  final int userPoints;
  final Function(int, String, int) onCanjear;
  final Duration delay;
  final bool isDesktop;

  const _RecompensaCard({
    Key? key,
    required this.recompensa,
    required this.userPoints,
    required this.onCanjear,
    required this.delay,
    required this.isDesktop,
  }) : super(key: key);

  @override
  State<_RecompensaCard> createState() => _RecompensaCardState();
}

class _RecompensaCardState extends State<_RecompensaCard> {
  bool _hovered = false;

  static const Color _emerald = AppColors.emeraldGlow;
  static const Color _cardLight = AppColors.glassSurface;
  static const Color _textGray = AppColors.textSecondary;
  static const Color _borderLight = AppColors.glassBorder;

  @override
  Widget build(BuildContext context) {
    final id = widget.recompensa['id'] as int;
    final nombre = widget.recompensa['nombre'] as String? ?? '';
    final desc = widget.recompensa['descripcion'] as String? ?? '';
    final costo = widget.recompensa['costoPuntos'] as int? ?? 0;
    final stock = widget.recompensa['stock'] as int? ?? 0;
    final imagenUrl = widget.recompensa['imagenUrl'] as String? ?? '';
    final canRedeem = widget.userPoints >= costo && stock > 0;
    final hasImage = imagenUrl.isNotEmpty && imagenUrl.startsWith('http');

    return MouseRegion(
      cursor: canRedeem ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..translate(0.0, _hovered ? -6.0 : 0.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _hovered ? _emerald.withOpacity(0.5) : _borderLight,
            width: _hovered ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_hovered ? 0.4 : 0.2),
              blurRadius: _hovered ? 20 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Imagen o fondo decorativo
              hasImage
                  ? Image.network(
                      imagenUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (c, o, s) => Container(
                        color: _emerald.withOpacity(0.05),
                        child: const Icon(Icons.broken_image_rounded, color: _emerald, size: 32),
                      ),
                    )
                  : Container(
                      color: _emerald.withOpacity(0.05),
                      child: Center(
                        child: Icon(
                          Icons.card_giftcard_rounded,
                          size: 36,
                          color: _emerald.withOpacity(0.4),
                        ),
                      ),
                    ),

              // 2. Cinematic Gradient (Capa de sombra de cine para legibilidad)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.35),
                        Colors.black.withOpacity(0.92),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              // 3. Badges Superiores (Puntos y Stock)
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Badge de costo en Ecopuntos
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withOpacity(0.12)),
                      ),
                      child: Text(
                        '$costo PTS',
                        style: GoogleFonts.poppins(
                          color: _emerald,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),

                    // Badge de alerta de stock
                    if (stock <= 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withOpacity(0.35)),
                        ),
                        child: Text(
                          'AGOTADO',
                          style: GoogleFonts.poppins(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w900,
                            fontSize: 8,
                          ),
                        ),
                      )
                    else if (stock < 5)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.warning.withOpacity(0.35)),
                        ),
                        child: Text(
                          'ÚLTIMOS',
                          style: GoogleFonts.poppins(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w900,
                            fontSize: 8,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // 4. Contenido e Información Inferior
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      nombre.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      desc,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: _textGray.withOpacity(0.85),
                        fontSize: 9.5,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Botón de Canje Integrado a lo ancho
                    SizedBox(
                      height: 34,
                      child: ElevatedButton(
                        onPressed: canRedeem
                            ? () => widget.onCanjear(id, nombre, costo)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          disabledBackgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: canRedeem
                                ? BorderSide.none
                                : BorderSide(color: Colors.white.withOpacity(0.08)),
                          ),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: canRedeem
                                ? const LinearGradient(
                                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: canRedeem ? null : Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            child: Text(
                              canRedeem
                                  ? 'CANJEAR'
                                  : (stock <= 0 ? 'SIN STOCK' : 'INSUFICIENTE'),
                              style: GoogleFonts.poppins(
                                color: canRedeem ? AppColors.deepObsidian : Colors.white.withOpacity(0.25),
                                fontWeight: FontWeight.w900,
                                fontSize: 9.5,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: widget.delay, duration: 500.ms)
        .scale(begin: const Offset(0.97, 0.97), end: const Offset(1, 1), delay: widget.delay, curve: Curves.easeOutBack);
  }
}

