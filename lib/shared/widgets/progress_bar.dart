import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class CustomProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double height;
  final Color? color;
  final Color? backgroundColor;
  final bool showPercentage;

  const CustomProgressBar({
    super.key,
    required this.progress,
    this.height = 10.0,
    this.color,
    this.backgroundColor,
    this.showPercentage = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final clampedProgress = progress.clamp(0.0, 1.0);
    final percentageText = '${(clampedProgress * 100).toInt()}%';

    final activeColor = color ?? (isDark ? AppColors.accent : AppColors.primary);
    final trackColor = backgroundColor ?? (isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showPercentage) ...[
          Text(
            percentageText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: activeColor,
            ),
          ),
          const SizedBox(height: 4),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: Stack(
            children: [
              Container(
                height: height,
                width: double.infinity,
                color: trackColor,
              ),
              FractionallySizedBox(
                widthFactor: clampedProgress,
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: activeColor,
                    borderRadius: BorderRadius.circular(height / 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
