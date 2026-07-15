part of 'canjear_screen.dart';

class _CanjearView extends StatelessWidget {
  final _CanjearScreenState state;

  const _CanjearView({required this.state});

  static const Color _emerald = Color(0xFF10B981);
  static const Color _emeraldLight = Color(0xFF34D399);
  static const Color _bgLight = Color(0xFFF8FAFC);
  static const Color _cardLight = Color(0xFFFFFFFF);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textGray = Color(0xFF475569);
  static const Color _borderLight = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        backgroundColor: _cardLight,
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
      body: state._loading
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
  // LISTA MÓVIL (vertical)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildMobileList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      itemCount: state._recompensas.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _RecompensaCard(
            recompensa: state._recompensas[index],
            userPoints: state._userPoints,
            onCanjear: state._handleCanje,
            delay: (index * 60).ms,
            isDesktop: false,
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GRID DESKTOP (2 columnas)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildDesktopGrid(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(32, 4, 32, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 1.6,
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
// TARJETA DE RECOMPENSA con Hover y Glassmorphism
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

  static const Color _emerald = Color(0xFF10B981);
  static const Color _bgLight = Color(0xFFF8FAFC);
  static const Color _cardLight = Color(0xFFFFFFFF);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textGray = Color(0xFF475569);
  static const Color _borderLight = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    final id = widget.recompensa['id'] as int;
    final nombre = widget.recompensa['nombre'] as String? ?? '';
    final desc = widget.recompensa['descripcion'] as String? ?? '';
    final costo = widget.recompensa['costoPuntos'] as int? ?? 0;
    final stock = widget.recompensa['stock'] as int? ?? 0;
    final imagenUrl = widget.recompensa['imagenUrl'] as String? ?? '';
    final canRedeem = widget.userPoints >= costo && stock > 0;
    final hasImage =
        imagenUrl.isNotEmpty && imagenUrl.startsWith('http');

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..translate(0.0, _hovered ? -8.0 : 0.0),
        decoration: BoxDecoration(
          color: _cardLight,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _hovered
                ? _emerald.withOpacity(0.4)
                : _borderLight,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            if (_hovered)
              BoxShadow(
                color: _emerald.withOpacity(0.1),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Imagen del premio ──
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: widget.isDesktop ? 120 : 150,
                decoration: BoxDecoration(
                  color: hasImage
                      ? null
                      : _emerald.withOpacity(0.06),
                  image: hasImage
                      ? DecorationImage(
                          image: NetworkImage(imagenUrl),
                          fit: BoxFit.cover,
                          colorFilter: _hovered
                              ? null
                              : ColorFilter.mode(
                                  Colors.black.withOpacity(0.15),
                                  BlendMode.darken),
                        )
                      : null,
                ),
                child: hasImage
                    ? null
                    : Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _emerald.withOpacity(
                                _hovered ? 0.2 : 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.card_giftcard_rounded,
                            size: 44,
                            color:
                                _emerald.withOpacity(_hovered ? 0.8 : 0.5),
                          ),
                        ),
                      ),
              ),
            ),

            // ── Info del premio ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                nombre,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    color: _textDark,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Badge de costo
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _emerald.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: _emerald.withOpacity(0.25)),
                              ),
                              child: Text(
                                '$costo pts',
                                style: GoogleFonts.poppins(
                                  color: _emerald,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          desc,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: _textGray,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),

                    // ── Footer de la tarjeta ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Stock indicator
                        Row(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 12,
                              color: stock > 0
                                  ? _textGray.withOpacity(0.5)
                                  : Colors.redAccent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              stock > 0
                                  ? 'Stock: $stock'
                                  : 'Sin stock',
                              style: GoogleFonts.poppins(
                                color: stock > 0
                                    ? _textGray.withOpacity(0.5)
                                    : Colors.redAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),

                        // Botón Canjear
                        _CanjearButton(
                          canRedeem: canRedeem,
                          onTap: canRedeem
                              ? () => widget.onCanjear(id, nombre, costo)
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: widget.delay, duration: 500.ms)
        .slideY(begin: 0.15, end: 0, delay: widget.delay);
  }
}

/// Botón de canjear con micro-animación de color
class _CanjearButton extends StatefulWidget {
  final bool canRedeem;
  final VoidCallback? onTap;

  const _CanjearButton({required this.canRedeem, this.onTap});

  @override
  State<_CanjearButton> createState() => _CanjearButtonState();
}

class _CanjearButtonState extends State<_CanjearButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.canRedeem
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      onEnter: (_) =>
          widget.canRedeem ? setState(() => _hovered = true) : null,
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          decoration: BoxDecoration(
            gradient: widget.canRedeem
                ? LinearGradient(
                    colors: _hovered
                        ? [const Color(0xFF34D399), const Color(0xFF10B981)]
                        : [
                            const Color(0xFF10B981),
                            const Color(0xFF059669)
                          ],
                  )
                : null,
            color: widget.canRedeem
                ? null
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            boxShadow: widget.canRedeem && _hovered
                ? [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          transform: Matrix4.identity()
            ..translate(0.0, widget.canRedeem && _hovered ? -1.5 : 0.0),
          child: Text(
            'Canjear',
            style: GoogleFonts.poppins(
              color: widget.canRedeem
                  ? Colors.white
                  : Colors.white.withOpacity(0.2),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
