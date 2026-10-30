import 'package:flutter/material.dart';
import '../theme/duo_colors.dart';

/// A sleek, rounded progress bar featuring Duo's brand gradients.
class DuoProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double height;
  final Gradient? gradient;
  final Color? trackColor;
  final BorderRadius? borderRadius;

  const DuoProgressBar({
    super.key,
    required this.progress,
    this.height = 8.0,
    this.gradient,
    this.trackColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final clamped = progress.clamp(0.0, 1.0);
    final radius = borderRadius ?? BorderRadius.circular(height / 2);

    final effectiveTrack = trackColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.08)
            : DuoColors.primary.withValues(alpha: 0.12));

    final effectiveGradient = gradient ?? DuoColors.primaryGradient;

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: effectiveTrack,
        borderRadius: radius,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final targetWidth = constraints.maxWidth * clamped;
          return Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              width: targetWidth,
              height: height,
              decoration: BoxDecoration(
                gradient: effectiveGradient,
                borderRadius: radius,
                boxShadow: [
                  BoxShadow(
                    color: DuoColors.primary.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
