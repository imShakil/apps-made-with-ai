import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'duo_colors.dart';

class DuoTheme {
  DuoTheme._();

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: DuoColors.bgLight,
      colorScheme: const ColorScheme.light(
        primary: DuoColors.primary,
        secondary: DuoColors.secondary,
        tertiary: DuoColors.accent,
        surface: DuoColors.cardLight,
        error: Color(0xFFE54D60),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: DuoColors.textPrimaryLight,
      ),
      cardTheme: CardThemeData(
        color: DuoColors.cardLight,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: DuoColors.borderLight, width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DuoColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: DuoColors.primary.withValues(alpha: 0.35),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DuoColors.primary,
          side: const BorderSide(color: DuoColors.primary, width: 1.5),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: DuoColors.borderLight, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: DuoColors.borderLight, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: DuoColors.primary, width: 2),
        ),
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: DuoColors.textPrimaryLight),
        displayMedium: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w600, color: DuoColors.textPrimaryLight),
        headlineSmall: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: DuoColors.textPrimaryLight),
        titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: DuoColors.textPrimaryLight),
        bodyLarge: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.normal, color: DuoColors.textSecondaryLight),
        bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.normal, color: DuoColors.textSecondaryLight),
        labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: DuoColors.textMutedLight),
      ),
    );
  }

  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: DuoColors.bgDark,
      colorScheme: const ColorScheme.dark(
        primary: DuoColors.primary,
        secondary: DuoColors.secondary,
        tertiary: DuoColors.accent,
        surface: DuoColors.cardDark,
        error: Color(0xFFE54D60),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: DuoColors.textPrimaryDark,
      ),
      cardTheme: CardThemeData(
        color: DuoColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: DuoColors.borderDark, width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DuoColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: DuoColors.primary.withValues(alpha: 0.4),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DuoColors.primary,
          side: const BorderSide(color: DuoColors.primary, width: 1.5),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DuoColors.cardDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: DuoColors.borderDark, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: DuoColors.borderDark, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: DuoColors.primary, width: 2),
        ),
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: DuoColors.textPrimaryDark),
        displayMedium: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w600, color: DuoColors.textPrimaryDark),
        headlineSmall: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: DuoColors.textPrimaryDark),
        titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: DuoColors.textPrimaryDark),
        bodyLarge: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.normal, color: DuoColors.textSecondaryDark),
        bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.normal, color: DuoColors.textSecondaryDark),
        labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: DuoColors.textMutedDark),
      ),
    );
  }
}
