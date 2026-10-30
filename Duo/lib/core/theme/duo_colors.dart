import 'package:flutter/material.dart';

/// Design tokens with WCAG-compliant contrast for Duo
class DuoColors {
  DuoColors._();

  // Primary & Accents
  static const Color primary = Color(0xFFFF6B81); // Vibrant Coral Pink
  static const Color primaryDark = Color(0xFFE05368);
  static const Color primaryLight = Color(0xFFFF8FA3);
  static const Color secondary = Color(0xFF9B8AFB); // Lavender
  static const Color secondaryLight = Color(0xFFB5A9FC);
  static const Color accent = Color(0xFFFFC857); // Warm Gold / Yellow
  static const Color mint = Color(0xFF56C596);
  static const Color success = Color(0xFF56C596);
  static const Color surfaceWarm = Color(0xFFFFEBE8);

  // Light Theme Surfaces & Text (High Contrast)
  static const Color bgLight = Color(0xFFFAF7F5);
  static const Color cardLight = Colors.white;
  static const Color textPrimaryLight = Color(0xFF1B1824); // Crisp deep charcoal
  static const Color textSecondaryLight = Color(0xFF4B4759); // Distinct readable body
  static const Color textMutedLight = Color(0xFF736F82); // Muted labels
  static const Color borderLight = Color(0xFFEDE6E5);

  // Dark Theme Surfaces & Text (High Contrast)
  static const Color bgDark = Color(0xFF121118);
  static const Color cardDark = Color(0xFF1D1B26);
  static const Color textPrimaryDark = Color(0xFFFAF9FC); // Bright crisp text
  static const Color textSecondaryDark = Color(0xFFD8D5E5); // High contrast secondary
  static const Color textMutedDark = Color(0xFFA5A1B5); // Crisp readable muted
  static const Color borderDark = Color(0xFF2E2B3C);

  // Missing Design System Tokens
  static const Color onAccent = Colors.white;
  static const Color overlay = Color(0x7A000000);
  static const Color dividerLight = Color(0xFFEDE6E5);
  static const Color dividerDark = Color(0xFF2E2B3C);
  static const Color surfaceWarmDark = Color(0xFF2A1E24);

  // Shimmer Tokens
  static const Color shimmerBaseLight = Color(0xFFEBE6E8);
  static const Color shimmerHighlightLight = Color(0xFFF9F5F6);
  static const Color shimmerBaseDark = Color(0xFF25202D);
  static const Color shimmerHighlightDark = Color(0xFF352F3F);

  // Brand Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFFFF8599)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient romanticGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sunsetGradient = LinearGradient(
    colors: [Color(0xFFFF7A8A), accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
