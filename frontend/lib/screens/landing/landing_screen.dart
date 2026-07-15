import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

part 'landing_view.dart';

// ── Paleta de colores constantes para reusar en toda la landing ──────────
const Color _emerald = Color(0xFF10B981);
const Color _emeraldLight = Color(0xFF34D399);
const Color _bgLight = Color(0xFFF8FAFC);
const Color _cardLight = Color(0xFFFFFFFF);
const Color _textDark = Color(0xFF0F172A);
const Color _textGray = Color(0xFF475569);
const Color _borderLight = Color(0xFFE2E8F0);


class LandingScreen extends StatefulWidget {
  const LandingScreen({Key? key}) : super(key: key);

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _navScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final scrolled = _scrollController.offset > 10;
      if (scrolled != _navScrolled) {
        setState(() => _navScrolled = scrolled);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _LandingView(state: this);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NAVBAR
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildNavbar(BuildContext context, bool isDesktop) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 64.0 : 24.0,
        vertical: 18.0,
      ),
      decoration: BoxDecoration(
        color: _navScrolled
            ? _bgLight.withOpacity(0.97)
            : _bgLight.withOpacity(0.0),
        border: Border(
          bottom: BorderSide(
            color: _navScrolled
                ? _borderLight
                : Colors.transparent,
            width: 1,
          ),
        ),
        boxShadow: _navScrolled
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── Brand Logo ──
          _HoverScale(
            onTap: () {},
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _emerald.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _emerald.withOpacity(0.3)),
                  ),
                  child: const Icon(
                    Icons.recycling_rounded,
                    color: _emerald,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'EcoSmartBin',
                  style: GoogleFonts.poppins(
                    color: _textDark,
                    fontSize: isDesktop ? 20 : 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),

          // ── Nav Actions ──
          Row(
            children: [
              _NavButton(
                label: 'Iniciar Sesión',
                onTap: () => Navigator.pushNamed(context, '/login'),
                isDesktop: isDesktop,
              ),
              const SizedBox(width: 10),
              _PrimaryButton(
                label: 'Registrarse',
                onTap: () => Navigator.pushNamed(context, '/register'),
                isDesktop: isDesktop,
                compact: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HERO SECTION
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHeroSection(BuildContext context, bool isDesktop, bool isTablet) {
    final content = Column(
      crossAxisAlignment:
          isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        // ── Badge ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: _emerald.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: _emerald.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome_rounded, color: _emerald, size: 13),
              const SizedBox(width: 6),
              Text(
                'Gestión Ecológica Inteligente',
                style: GoogleFonts.poppins(
                  color: _emerald,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: 100.ms, duration: 600.ms)
            .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),
        const SizedBox(height: 28),

        // ── Main Heading (Scrollytelling Split) ──
        Text(
          'El Futuro del\nReciclaje Inteligente',
          textAlign: isDesktop ? TextAlign.left : TextAlign.center,
          style: GoogleFonts.poppins(
            color: _textDark,
            fontSize: isDesktop ? 58 : (isTablet ? 44 : 34),
            fontWeight: FontWeight.w900,
            height: 1.12,
            letterSpacing: -1.0,
          ),
        )
            .animate()
            .fadeIn(delay: 200.ms, duration: 700.ms)
            .scale(begin: const Offset(0.8, 0.8), curve: Curves.elasticOut, duration: 1200.ms),
        const SizedBox(height: 22),

        // ── Subtitle ──
        Text(
          'EcoSmartBin conecta basureros inteligentes con recompensas reales. '
          'Escanea, deposita y acumula EcoPuntos por cada residuo que recicles.',
          textAlign: isDesktop ? TextAlign.left : TextAlign.center,
          style: GoogleFonts.poppins(
            color: _textGray,
            fontSize: isDesktop ? 17 : 14,
            height: 1.7,
          ),
        )
            .animate()
            .fadeIn(delay: 350.ms, duration: 700.ms)
            .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),
        const SizedBox(height: 44),

        // ── CTAs ──
        Row(
          mainAxisAlignment:
              isDesktop ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            _PrimaryButton(
              label: 'Comenzar Ahora',
              onTap: () => Navigator.pushNamed(context, '/register'),
              isDesktop: isDesktop,
              icon: Icons.arrow_forward_rounded,
            ),
            const SizedBox(width: 14),
            _OutlineButton(
              label: 'Saber Más',
              onTap: () => _scrollController.animateTo(
                isDesktop ? 650.0 : 850.0,
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeInOutCubic,
              ),
              isDesktop: isDesktop,
            ),
          ],
        )
            .animate()
            .fadeIn(delay: 500.ms, duration: 600.ms)
            .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),
      ],
    );

    if (isDesktop) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 100),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(flex: 55, child: content),
            const SizedBox(width: 60),
            Expanded(
              flex: 45,
              child: _buildHeroIllustration(),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 60),
      child: Column(
        children: [
          content,
          const SizedBox(height: 60),
          _buildHeroIllustration(),
        ],
      ),
    );
  }

  Widget _buildHeroIllustration() {
    const double cardSize = 260;
    const double pad = 40;
    final double total = cardSize + pad * 2;

    return SizedBox(
      width: total,
      height: total,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Glow de fondo
          Center(
            child: Container(
              width: total,
              height: total,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _emerald.withOpacity(0.12),
                    _emerald.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // Tarjeta central neumórfica blanca
          Positioned(
            left: pad,
            top: pad,
            right: pad,
            bottom: pad,
            child: Container(
              decoration: BoxDecoration(
                color: _cardLight,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: _borderLight,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 30,
                    spreadRadius: 2,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _emerald.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_sweep_rounded,
                      color: _emerald,
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'EcoSmartBin',
                    style: GoogleFonts.poppins(
                      color: _textDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: _emerald,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Conectado y Activo',
                        style: GoogleFonts.poppins(
                          color: _emerald,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Badge flotante "IA"
          Positioned(
            top: pad - 20,
            right: pad - 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF3B82F6).withOpacity(0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.smart_toy_rounded,
                      color: Color(0xFF3B82F6), size: 14),
                  const SizedBox(width: 5),
                  Text(
                    'IA Integrada',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF3B82F6),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: 0, end: -6, duration: 2000.ms, curve: Curves.easeInOut),
          ),
          // Badge flotante "Puntos"
          Positioned(
            bottom: pad + 20,
            left: pad - 25,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _emerald.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.eco_rounded, color: _emerald, size: 14),
                  const SizedBox(width: 5),
                  Text(
                    '+50 EcoPuntos',
                    style: GoogleFonts.poppins(
                      color: _emerald,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: 0, end: -6, duration: 2400.ms, curve: Curves.easeInOut),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 300.ms, duration: 800.ms)
        .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.0, 1.0), curve: Curves.easeOutCubic);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GAMIFIED ECO-DASHBOARD (Trend 7)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildEcoDashboard(BuildContext context, bool isDesktop) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isDesktop ? 80.0 : 24.0,
        vertical: 24,
      ),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
      decoration: BoxDecoration(
        color: _cardLight,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: _borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Tu Impacto Ambiental',
            style: GoogleFonts.poppins(
              color: _textDark,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Conviértete en un líder ecológico',
            style: GoogleFonts.poppins(
              color: _textGray,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 40),
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 600;
              final content = [
                // Medidor Radial
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: CircularProgressIndicator(
                        value: 0.85,
                        strokeWidth: 12,
                        backgroundColor: _borderLight,
                        valueColor: AlwaysStoppedAnimation<Color>(_emerald),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '85%',
                          style: GoogleFonts.poppins(
                            color: _textDark,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                        Text(
                          'Nivel Actual',
                          style: GoogleFonts.poppins(
                            color: _textGray,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    // Badges flotantes
                    Positioned(
                      top: 0,
                      right: 0,
                      child: const _FloatingBadge(
                        icon: Icons.star_rounded,
                        color: Color(0xFFF59E0B),
                        delay: 0,
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      left: -10,
                      child: const _FloatingBadge(
                        icon: Icons.local_fire_department_rounded,
                        color: Color(0xFFEF4444),
                        delay: 600,
                      ),
                    ),
                  ],
                ).animate().scale(delay: 200.ms, duration: 800.ms, curve: Curves.elasticOut),
                SizedBox(height: isSmall ? 40 : 0, width: isSmall ? 0 : 60),
                // Detalles de Nivel
                Expanded(
                  flex: isSmall ? 0 : 1,
                  child: Column(
                    crossAxisAlignment: isSmall ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: _emerald.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Nivel: Guardián Esmeralda',
                          style: GoogleFonts.poppins(
                            color: _emerald,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '¡Estás muy cerca de subir al rango Maestro Reciclador! Sigue depositando botellas PET y aluminio.',
                        textAlign: isSmall ? TextAlign.center : TextAlign.left,
                        style: GoogleFonts.poppins(
                          color: _textGray,
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: isSmall ? MainAxisAlignment.center : MainAxisAlignment.start,
                        children: [
                          _StatMini(val: '1.2K', lbl: 'Puntos', icon: Icons.eco_rounded, color: _emerald),
                          const SizedBox(width: 24),
                          _StatMini(val: '45', lbl: 'Rachas', icon: Icons.local_fire_department_rounded, color: const Color(0xFFF59E0B)),
                        ],
                      ),
                    ],
                  ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideX(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
                ),
              ];
              
              if (isSmall) {
                return Column(children: content);
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: content,
              );
            },
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FEATURES SECTION
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildFeaturesSection(
      BuildContext context, bool isDesktop, bool isTablet) {
    final features = [
      {
        'icon': Icons.sensors_rounded,
        'title': 'Sensores de Nivel',
        'desc':
            'Monitoreo en tiempo real del porcentaje de llenado de cada basurero ecológico inteligente.',
        'color': const Color(0xFF10B981),
      },
      {
        'icon': Icons.psychology_rounded,
        'title': 'Clasificación con IA',
        'desc':
            'Visión por computadora que detecta automáticamente el tipo de material al depositarlo.',
        'color': const Color(0xFF3B82F6),
      },
      {
        'icon': Icons.workspace_premium_rounded,
        'title': 'Gamificación Verde',
        'desc':
            'Acumula EcoPuntos y canjéalos por recompensas reales por tus buenos hábitos de reciclaje.',
        'color': const Color(0xFFF59E0B),
      },
      {
        'icon': Icons.insights_rounded,
        'title': 'Dashboard Analítico',
        'desc':
            'Gráficos y métricas de tu impacto ambiental personal, histórico y comparativa social.',
        'color': const Color(0xFF8B5CF6),
      },
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 80.0 : 24.0,
        vertical: 80.0,
      ),
      child: Column(
        children: [
          // ── Section Header ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: _emerald.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _emerald.withOpacity(0.2)),
            ),
            child: Text(
              'CARACTERÍSTICAS',
              style: GoogleFonts.poppins(
                color: _emerald,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ).animate().fadeIn(duration: 500.ms),
          const SizedBox(height: 16),
          Text(
            'Todo lo que necesitas para\nreciclar de forma inteligente',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: _textDark,
              fontSize: isDesktop ? 38 : 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              height: 1.2,
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 600.ms),
          const SizedBox(height: 12),
          Text(
            'Herramientas avanzadas integradas para transformar tu experiencia ecológica.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: _textGray,
              fontSize: 15,
              height: 1.6,
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
          const SizedBox(height: 56),

          // ── Feature Cards Grid ──
          LayoutBuilder(
            builder: (context, constraints) {
              final cards = features.asMap().entries.map((entry) {
                final i = entry.key;
                final f = entry.value;
                return _HoverFeatureCard(
                  icon: f['icon'] as IconData,
                  title: f['title'] as String,
                  desc: f['desc'] as String,
                  accentColor: f['color'] as Color,
                  delay: (i * 80).ms,
                );
              }).toList();

              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      cards.map((c) => Expanded(child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: c,
                      ))).toList(),
                );
              } else if (isTablet) {
                return Column(children: [
                  Row(children: [
                    Expanded(child: cards[0]),
                    const SizedBox(width: 16),
                    Expanded(child: cards[1]),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: cards[2]),
                    const SizedBox(width: 16),
                    Expanded(child: cards[3]),
                  ]),
                ]);
              }
              return Column(
                children: cards
                    .map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: c,
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HOW IT WORKS SECTION
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHowItWorksSection(BuildContext context, bool isDesktop) {
    final steps = [
      {
        'num': '01',
        'icon': Icons.qr_code_scanner_rounded,
        'title': 'Escanea el Basurero',
        'desc':
            'Abre la app y escanea el código QR del basurero EcoSmartBin más cercano para activarlo.',
        'color': _emerald,
      },
      {
        'num': '02',
        'icon': Icons.smart_toy_rounded,
        'title': 'La IA Clasifica',
        'desc':
            'La cámara integrada detecta automáticamente el tipo de material y calcula tus puntos.',
        'color': const Color(0xFF3B82F6),
      },
      {
        'num': '03',
        'icon': Icons.emoji_events_rounded,
        'title': 'Gana Recompensas',
        'desc':
            'EcoPuntos acreditados al instante en tu cuenta. Canjéalos por premios ecológicos reales.',
        'color': const Color(0xFFD97706),
      },
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 80.0 : 24.0,
        vertical: 80.0,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: _borderLight, width: 1),
          bottom: BorderSide(color: _borderLight, width: 1),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
            ),
            child: Text(
              'CÓMO FUNCIONA',
              style: GoogleFonts.poppins(
                color: const Color(0xFF3B82F6),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ).animate().fadeIn(duration: 500.ms),
          const SizedBox(height: 16),
          Text(
            'Tres pasos para formar\nparte del cambio',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: _textDark,
              fontSize: isDesktop ? 38 : 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              height: 1.2,
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 600.ms),
          const SizedBox(height: 56),
          LayoutBuilder(
            builder: (context, constraints) {
              final stepWidgets = steps.asMap().entries.map((entry) {
                final i = entry.key;
                final s = entry.value;
                return _StepCard(
                  number: s['num'] as String,
                  icon: s['icon'] as IconData,
                  title: s['title'] as String,
                  desc: s['desc'] as String,
                  accentColor: s['color'] as Color,
                  delay: (i * 120).ms,
                  isLast: i == steps.length - 1,
                  isDesktop: isDesktop,
                );
              }).toList();

              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: stepWidgets
                      .map((w) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: w,
                            ),
                          ))
                      .toList(),
                );
              }
              return Column(
                children: stepWidgets
                    .map((w) => Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: w,
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CTA SECTION
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildCTASection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 820),
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 56),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF059669), Color(0xFF10B981)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(36),
            boxShadow: [
              BoxShadow(
                color: _emerald.withOpacity(0.2),
                blurRadius: 40,
                spreadRadius: 4,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.eco_rounded,
                    color: Colors.white, size: 36),
              ),
              const SizedBox(height: 24),
              Text(
                '¿Listo para marcar\nla diferencia?',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Únete a EcoSmartBin y comienza a rastrear tu impacto positivo hoy. '
                'Es gratis, instantáneo y apoya la conservación local.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 36),
              _HoverScale(
                onTap: () => Navigator.pushNamed(context, '/register'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(
                    'Crear una Cuenta Gratis →',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF059669),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 700.ms)
            .scale(begin: const Offset(0.95, 0.95)),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FOOTER
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: _borderLight, width: 1),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.recycling_rounded, color: _emerald, size: 18),
              const SizedBox(width: 8),
              Text(
                'EcoSmartBin © 2026',
                style: GoogleFonts.poppins(
                  color: _textGray,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Hacia un campus y comunidad sin residuos.',
            style: GoogleFonts.poppins(
              color: const Color(0xFF94A3B8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// COMPONENTES REUTILIZABLES
// =============================================================================

/// Botón primario con efecto hover de escala y resplandor
class _PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDesktop;
  final bool compact;
  final IconData? icon;

  const _PrimaryButton({
    required this.label,
    required this.onTap,
    required this.isDesktop,
    this.compact = false,
    this.icon,
  });

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
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
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 20 : 32,
            vertical: widget.compact ? 12 : 18,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _hovered
                  ? [const Color(0xFF34D399), const Color(0xFF10B981)]
                  : [const Color(0xFF10B981), const Color(0xFF059669)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981)
                    .withOpacity(_hovered ? 0.45 : 0.25),
                blurRadius: _hovered ? 20 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          transform: Matrix4.identity()
            ..translate(0.0, _hovered ? -2.0 : 0.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: widget.compact ? 13 : 15,
                ),
              ),
              if (widget.icon != null) ...[
                const SizedBox(width: 8),
                Icon(widget.icon, color: Colors.white, size: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón outline con efecto hover
class _OutlineButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDesktop;

  const _OutlineButton({
    required this.label,
    required this.onTap,
    required this.isDesktop,
  });

  @override
  State<_OutlineButton> createState() => _OutlineButtonState();
}

class _OutlineButtonState extends State<_OutlineButton> {
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
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          decoration: BoxDecoration(
            color: _hovered
                ? _borderLight.withOpacity(0.5)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovered
                  ? _borderLight
                  : _borderLight.withOpacity(0.5),
              width: 1.5,
            ),
          ),
          transform: Matrix4.identity()
            ..translate(0.0, _hovered ? -2.0 : 0.0),
          child: Text(
            widget.label,
            style: GoogleFonts.poppins(
              color: _textDark,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón de navegación estilo link con hover
class _NavButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDesktop;

  const _NavButton({
    required this.label,
    required this.onTap,
    required this.isDesktop,
  });

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered
                ? _borderLight.withOpacity(0.5)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.poppins(
              color: _hovered
                  ? _emerald
                  : _textGray,
              fontWeight: FontWeight.w600,
              fontSize: widget.isDesktop ? 14 : 13,
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta hover con elevación y borde luminoso para características
class _HoverFeatureCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String desc;
  final Color accentColor;
  final Duration delay;

  const _HoverFeatureCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.desc,
    required this.accentColor,
    required this.delay,
  }) : super(key: key);

  @override
  State<_HoverFeatureCard> createState() => _HoverFeatureCardState();
}

class _HoverFeatureCardState extends State<_HoverFeatureCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..translate(0.0, _hovered ? -5.0 : 0.0),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _hovered
                ? widget.accentColor.withOpacity(0.5)
                : _borderLight,
            width: _hovered ? 2.0 : 1.5,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: widget.accentColor.withOpacity(0.2),
                    blurRadius: 10,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon container
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _hovered
                    ? widget.accentColor.withOpacity(0.15)
                    : widget.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(widget.icon, color: widget.accentColor, size: 26),
            ),
            const SizedBox(height: 22),
            Text(
              widget.title,
              style: GoogleFonts.poppins(
                color: _textDark,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.desc,
              style: GoogleFonts.poppins(
                color: _textGray,
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: widget.delay, duration: 600.ms)
        .slideY(begin: 0.2, end: 0, delay: widget.delay, curve: Curves.easeOutCubic);
  }
}

/// Tarjeta numerada para el "Cómo funciona"
class _StepCard extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;
  final String desc;
  final Color accentColor;
  final Duration delay;
  final bool isLast;
  final bool isDesktop;

  const _StepCard({
    Key? key,
    required this.number,
    required this.icon,
    required this.title,
    required this.desc,
    required this.accentColor,
    required this.delay,
    required this.isLast,
    required this.isDesktop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: accentColor.withOpacity(0.3)),
              ),
              child: Icon(icon, color: accentColor, size: 26),
            ),
            const SizedBox(width: 16),
            Text(
              number,
              style: GoogleFonts.poppins(
                color: accentColor,
                fontSize: 48,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: GoogleFonts.poppins(
            color: _textDark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          desc,
          style: GoogleFonts.poppins(
            color: _textGray,
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(delay: delay, duration: 600.ms)
        .slideX(begin: 0.15, end: 0, delay: delay);
  }
}

/// Stat item individual
class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Duration delay;
  final bool isDesktop;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.delay,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF10B981), size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: const Color(0xFF10B981),
              fontSize: 36,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.45),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: delay, duration: 600.ms)
        .slideY(begin: 0.2, end: 0, delay: delay);
  }
}

/// Wrapper de hover con escala suave
class _HoverScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scale;

  const _HoverScale({
    required this.child,
    required this.onTap,
    this.scale = 1.04,
  });

  @override
  State<_HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<_HoverScale> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 180),
          scale: _hovered ? widget.scale : 1.0,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Badge flotante gamificado
class _FloatingBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int delay;

  const _FloatingBadge({
    required this.icon,
    required this.color,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 20),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: 0, end: -8, duration: 1500.ms, curve: Curves.easeInOut, delay: delay.ms);
  }
}

/// Estadística en miniatura para el Dashboard
class _StatMini extends StatelessWidget {
  final String val;
  final String lbl;
  final IconData icon;
  final Color color;

  const _StatMini({
    required this.val,
    required this.lbl,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              val,
              style: GoogleFonts.poppins(
                color: const Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            Text(
              lbl,
              style: GoogleFonts.poppins(
                color: const Color(0xFF475569),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
