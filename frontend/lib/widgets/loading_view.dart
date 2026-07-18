import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import 'background_gradient.dart';

class PremiumLoadingView extends StatelessWidget {
  final String title;
  final String subtext;

  const PremiumLoadingView({
    Key? key,
    this.title = 'Sincronizando con EcoSmartBin...',
    this.subtext = 'Protocolo neural activo • Enlace de datos 98%',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BackgroundGradient(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(32),
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: AppColors.glassSurface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.emeraldGlow.withOpacity(0.3),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.emeraldGlow.withOpacity(0.06),
                    blurRadius: 32,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Futuristic Circular Gauge loading spinner
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.04),
                            width: 6,
                          ),
                        ),
                      ),
                      // Animated glowing track progress indicator
                      SizedBox(
                        width: 110,
                        height: 110,
                        child: CircularProgressIndicator(
                          strokeWidth: 5,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.emeraldGlow),
                        )
                            .animate(onPlay: (c) => c.repeat())
                            .rotate(duration: 2000.ms),
                      ),
                      // Core AI Icon
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: AppColors.emeraldGlow.withOpacity(0.08),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.emeraldGlow.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.insights_rounded,
                          color: AppColors.emeraldGlow,
                          size: 32,
                        ),
                      )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scaleXY(begin: 0.95, end: 1.05, duration: 1200.ms),
                    ],
                  ),
                  const SizedBox(height: 36),
                  // Title text
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(duration: 500.ms),
                  const SizedBox(height: 12),
                  // Technical telemetry subtext
                  Text(
                    subtext,
                    style: GoogleFonts.poppins(
                      color: AppColors.textSecondary.withOpacity(0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
