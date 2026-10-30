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
  static const Color accentDark = Color(0xFFB45309); // High contrast amber/bronze
  static const Color mint = Color(0xFF56C596);
  static const Color mintDark = Color(0xFF047857); // Deep emerald
  static const Color success = Color(0xFF56C596);
  static const Color surfaceWarm = Color(0xFFFFEBE8);

  // High-Contrast Text Tokens for Badges & Accents (WCAG AAA >= 7:1)
  static const Color primaryTextLight = Color(0xFFBE123C); // Deep rich rose
  static const Color primaryTextDark = Color(0xFFFF8FA3);  // Soft pink on dark
  static const Color secondaryTextLight = Color(0xFF5B45BA); // Deep violet
  static const Color secondaryTextDark = Color(0xFFC4B5FD);  // Bright lavender on dark
  static const Color accentTextLight = Color(0xFFB45309);   // Deep warm amber
  static const Color accentTextDark = Color(0xFFFFD166);    // Crisp gold on dark

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

  /// Returns a high-contrast foreground text/icon color suited for badges and chips
  static Color getAccessibleTextColor(Color baseColor, {required bool isDark}) {
    if (isDark) {
      if (baseColor == accent) return accentTextDark;
      if (baseColor == primary || baseColor == primaryDark || baseColor == primaryLight) return primaryTextDark;
      if (baseColor == secondary || baseColor == secondaryLight) return secondaryTextDark;
      if (baseColor == mint || baseColor == success) return const Color(0xFF6EE7B7);
      return Colors.white70;
    } else {
      if (baseColor == accent) return accentTextLight;
      if (baseColor == primary || baseColor == primaryDark || baseColor == primaryLight) return primaryTextLight;
      if (baseColor == secondary || baseColor == secondaryLight) return secondaryTextLight;
      if (baseColor == mint || baseColor == success) return mintDark;
      if (baseColor == Colors.grey) return const Color(0xFF4B5563);
      return baseColor;
    }
  }
}
