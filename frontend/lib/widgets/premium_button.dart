import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PremiumButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isSecondary;
  final bool isLoading;

  const PremiumButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isSecondary = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: isSecondary ? AppColors.glassSurface : AppColors.emeraldGlow,
          borderRadius: BorderRadius.circular(12),
          border: isSecondary 
              ? Border.all(color: AppColors.cyberSilver, width: 1)
              : null,
          boxShadow: isSecondary ? [] : [
            BoxShadow(
              color: AppColors.emeraldGlow.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            )
          ]
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.deepObsidian),
                  ),
                )
              : Text(
                  text,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isSecondary ? AppColors.cyberSilver : AppColors.deepObsidian,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
