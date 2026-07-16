import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ProgressGauge extends StatelessWidget {
  final double percentage; // 0.0 to 1.0
  final double size;
  final String label;

  const ProgressGauge({
    super.key,
    required this.percentage,
    this.size = 120.0,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final color = percentage >= 0.8 ? AppColors.error : AppColors.emeraldGlow;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 8,
              color: AppColors.glassBorder,
            ),
          ),
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: percentage,
              strokeWidth: 8,
              color: color,
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(percentage * 100).toInt()}%',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
