import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/background_gradient.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/premium_button.dart';

part 'landing_view.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({Key? key}) : super(key: key);

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> with TickerProviderStateMixin {
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

    // En Android no mostrar la landing page. Redirigir a login o perfil.
    if (!kIsWeb && Platform.isAndroid) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final loggedIn = await ApiService.hasSession();
        if (mounted) {
          Navigator.pushReplacementNamed(context, loggedIn ? '/profile' : '/login');
        }
      });
    }
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
            ? AppColors.background.withOpacity(0.95)
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: _navScrolled ? AppColors.glassBorder : Colors.transparent,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.emeraldGlow.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.emeraldGlow.withOpacity(0.25), width: 1.2),
                ),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.recycling_rounded,
                    color: AppColors.emeraldGlow,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'EcoSmartBin',
                style: GoogleFonts.poppins(
                  color: AppColors.textPrimary,
                  fontSize: isDesktop ? 20 : 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),

          // Actions
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: Text(
                  'Iniciar Sesión',
                  style: GoogleFonts.poppins(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emeraldGlow,
                  foregroundColor: AppColors.deepObsidian,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  elevation: 0,
                ),
                child: Text(
                  'Registrarse',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
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
    final double padding = isDesktop ? 80.0 : 24.0;

    final infoColumn = Column(
      crossAxisAlignment: isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.emeraldGlow.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.emeraldGlow.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome_rounded, color: AppColors.emeraldGlow, size: 13),
              const SizedBox(width: 6),
              Text(
                'SOSTENIBILIDAD INTELIGENTE',
                style: GoogleFonts.poppins(
                  color: AppColors.emeraldGlow,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        RichText(
          textAlign: isDesktop ? TextAlign.left : TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.poppins(
              color: AppColors.textPrimary,
              fontSize: isDesktop ? 54 : (isTablet ? 42 : 32),
              fontWeight: FontWeight.w900,
              height: 1.15,
              letterSpacing: -1.0,
            ),
            children: const [
              TextSpan(text: 'EL FUTURO\nDEL RECICLAJE\n'),
              TextSpan(
                text: 'ES AHORA',
                style: TextStyle(color: AppColors.emeraldGlow),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Integramos Inteligencia Artificial y diseño de vanguardia para transformar la gestión de residuos en una experiencia premium y sostenible.',
          textAlign: isDesktop ? TextAlign.left : TextAlign.center,
          style: GoogleFonts.poppins(
            color: AppColors.textSecondary,
            fontSize: isDesktop ? 16 : 14,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 36),
        Row(
          mainAxisAlignment: isDesktop ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emeraldGlow,
                foregroundColor: AppColors.deepObsidian,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                elevation: 0,
              ),
              child: Row(
                children: [
                  Text(
                    'Comenzar Ahora',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
          ],
        ),
      ],
    );

    final illustrationColumn = Center(
      child: SizedBox(
        width: 320,
        height: 360,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Center decorative radial glow
            Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.emeraldGlow.withOpacity(0.04),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.emeraldGlow.withOpacity(0.08),
                    blurRadius: 80,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),

            // Smart Bin Hero Image Container
            Positioned(
              top: 20,
              child: GlassCard(
                padding: EdgeInsets.zero,
                child: Container(
                  width: 280,
                  height: 320,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.emeraldGlow.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/images/hero_smart_bin.png',
                      width: 280,
                      height: 320,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Placeholder visual en caso de que no cargue la imagen
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.emeraldGlow.withOpacity(0.06),
                                Colors.transparent,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.sensors_rounded,
                                  color: AppColors.emeraldGlow,
                                  size: 64,
                                  shadows: [
                                    Shadow(
                                      color: AppColors.emeraldGlow.withOpacity(0.4),
                                      blurRadius: 16,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'EcoSmartBin',
                                  style: GoogleFonts.poppins(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'AI-POWERED',
                                  style: GoogleFonts.poppins(
                                    color: AppColors.emeraldGlow,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            // Floating Badge 1
            Positioned(
              left: 0,
              top: 80,
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PRECISIÓN',
                      style: GoogleFonts.poppins(
                        color: AppColors.emeraldGlow,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '94%',
                      style: GoogleFonts.poppins(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Eficiencia IA',
                      style: GoogleFonts.poppins(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Floating Badge 2
            Positioned(
              right: 0,
              bottom: 60,
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TECNOLOGÍA',
                      style: GoogleFonts.poppins(
                        color: AppColors.emeraldGlow,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Visión',
                      style: GoogleFonts.poppins(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Por Computadora',
                      style: GoogleFonts.poppins(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 60),
      child: isDesktop
          ? Row(
              children: [
                Expanded(child: infoColumn),
                const SizedBox(width: 48),
                Expanded(child: illustrationColumn),
              ],
            )
          : Column(
              children: [
                infoColumn,
                const SizedBox(height: 48),
                illustrationColumn,
              ],
            ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ECO DASHBOARD (Narrativa / Visión)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildEcoDashboard(BuildContext context, bool isDesktop) {
    final double padding = isDesktop ? 80.0 : 24.0;

    final infoCol = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'REDEFINIENDO EL FLUJO URBANO',
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontSize: isDesktop ? 28 : 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'No solo creamos contenedores; diseñamos infraestructuras de luz y datos. En la oscuridad de los retos climáticos actuales, EcoSmartBin surge como una pieza de arte funcional, una intersección entre el minimalismo y el impacto ambiental medible.',
          style: GoogleFonts.poppins(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ],
    );

    final techCol = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassCard(
          padding: EdgeInsets.zero,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/vision_eco_dashboard.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Icon(
                      Icons.eco_rounded,
                      color: AppColors.emeraldGlow,
                      size: 56,
                      shadows: [
                        Shadow(
                          color: AppColors.emeraldGlow.withOpacity(0.4),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.only(left: 16),
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: AppColors.emeraldGlow, width: 2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sostenibilidad Estética',
                style: GoogleFonts.poppins(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Cada curva y componente ha sido seleccionado para minimizar la huella de carbono sin comprometer la elegancia del espacio público o privado.',
                style: GoogleFonts.poppins(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 60),
      child: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: infoCol),
                const SizedBox(width: 48),
                Expanded(child: techCol),
              ],
            )
          : Column(
              children: [
                infoCol,
                const SizedBox(height: 40),
                techCol,
              ],
            ),
    );
  }



  // ─────────────────────────────────────────────────────────────────────────
  // HOW IT WORKS (Recompensas)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHowItWorksSection(BuildContext context, bool isDesktop) {
    final double padding = isDesktop ? 80.0 : 24.0;

    final rewardsIllustration = Center(
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Container(
          width: 320,
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.emeraldGlow.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              'assets/images/eco_rewards_ticket.png',
              width: 320,
              height: 220,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.confirmation_number_rounded,
                        color: AppColors.emeraldGlow,
                        size: 48,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'RECOMPENSAS',
                        style: GoogleFonts.poppins(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        'EcoSmartBin Ticket',
                        style: GoogleFonts.poppins(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    final infoCol = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ECOSISTEMA ECOSMART',
          style: GoogleFonts.poppins(
            color: AppColors.emeraldGlow,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'TU IMPACTO TIENE VALOR',
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontSize: isDesktop ? 32 : 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Cada acción de reciclaje genera Eco-Tokens, una moneda digital respaldada por el impacto ambiental positivo que produces. Úsalos en nuestra red de partners sostenibles o canjéalos por mejoras en tu infraestructura local.',
          style: GoogleFonts.poppins(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
        isDesktop
            ? Row(
                children: [
                  Expanded(
                    child: _buildSmallHighlightCard(
                      icon: Icons.token_rounded,
                      text: 'Tokens Disponibles',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSmallHighlightCard(
                      icon: Icons.redeem_rounded,
                      text: 'Marketplace Exclusivo',
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  _buildSmallHighlightCard(
                    icon: Icons.token_rounded,
                    text: 'Tokens Disponibles',
                  ),
                  const SizedBox(height: 10),
                  _buildSmallHighlightCard(
                    icon: Icons.redeem_rounded,
                    text: 'Marketplace Exclusivo',
                  ),
                ],
              ),
      ],
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 60),
      child: isDesktop
          ? Row(
              children: [
                Expanded(child: rewardsIllustration),
                const SizedBox(width: 48),
                Expanded(child: infoCol),
              ],
            )
          : Column(
              children: [
                rewardsIllustration,
                const SizedBox(height: 40),
                infoCol,
              ],
            ),
    );
  }

  Widget _buildSmallHighlightCard({
    required IconData icon,
    required String text,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.emeraldGlow, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
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
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Column(
        children: [
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.emeraldGlow.withOpacity(0.2),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(65),
              child: Image.asset(
                'assets/images/eco_planet_minimal.png',
                width: 130,
                height: 130,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.public_rounded,
                  color: AppColors.emeraldGlow,
                  size: 64,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            '¿LISTO PARA LIDERAR EL CAMBIO?',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emeraldGlow,
                  foregroundColor: AppColors.deepObsidian,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  elevation: 0,
                ),
                child: Text(
                  'Comenzar Ahora',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.glassBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: Text(
                  'Iniciar Sesión',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FOOTER (Solo mantiene el contenido original con el nuevo diseño)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
      decoration: const BoxDecoration(
        color: Colors.transparent,
        border: Border(
          top: BorderSide(color: AppColors.glassBorder, width: 0.5),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.recycling_rounded, color: AppColors.emeraldGlow, size: 16),
              const SizedBox(width: 8),
              Text(
                'EcoSmartBin © 2026',
                style: GoogleFonts.poppins(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Hacia un campus y comunidad sin residuos.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
