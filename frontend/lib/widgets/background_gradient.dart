import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class BackgroundGradient extends StatelessWidget {
  final Widget child;

  const BackgroundGradient({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.deepObsidian,
        gradient: RadialGradient(
          center: Alignment(-0.5, -0.5),
          radius: 1.5,
          colors: [
            Color(0xFF050506), // Negro casi completo
            Color(0xFF000000), // Negro absoluto
          ],
        ),
      ),
      child: child,
    );
  }
}
