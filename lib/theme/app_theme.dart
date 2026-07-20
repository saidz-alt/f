import 'package:flutter/material.dart';

/// Shared color palette. Kept high-contrast and saturated so it reads
/// well for young children. Full visual identity work (illustrations,
/// Tifinagh/Latin script treatment, cultural motifs) happens in Stage 2 —
/// these are the functional hooks that Stage 2's design system builds on.
class AppColors {
  AppColors._();

  static const Color primaryGreen = Color(0xFF58CC02);
  static const Color primaryGreenDark = Color(0xFF4CAD00);
  static const Color heartRed = Color(0xFFFF4B4B);
  static const Color xpGold = Color(0xFFFFC800);
  static const Color gemBlue = Color(0xFF1CB0F6);
  static const Color streakOrange = Color(0xFFFF9600);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF7F7F7);
  static const Color textDark = Color(0xFF3C3C3C);
  static const Color disabledGrey = Color(0xFFE0E0E0);

  // Accent colors referencing Kabyle/Amazigh visual identity (flag & Yaz
  // symbol colors); used sparingly until Stage 2's full theming pass.
  static const Color kabyleBlue = Color(0xFF1E5AA8);
  static const Color kabyleYellow = Color(0xFFFFD100);
  static const Color kabyleGreen = Color(0xFF3AA655);
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      // Ensures Tifinagh glyphs (e.g. the yaz ⵣ) always have a font to render.
      fontFamilyFallback: const ['NotoTifinagh'],
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryGreen,
        primary: AppColors.primaryGreen,
        secondary: AppColors.gemBlue,
        surface: AppColors.surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w800,
          color: AppColors.textDark,
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
      ),
    );
  }
}
