import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // ── Core colours ──────────────────────────────────────────────────────────
  static const Color bgDeep   = Color(0xFF0A1628); // deep navy background
  static const Color bgCard   = Color(0xFF111E38); // card surface
  static const Color bgInput  = Color(0xFF1A2B4A); // input / secondary surface

  static const Color accentBlue   = Color(0xFF4F8EF7);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentCyan   = Color(0xFF06B6D4);
  static const Color accentGreen  = Color(0xFF10B981);
  static const Color accentOrange = Color(0xFFF97316);

  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8);

  // ── Quick-action card gradients ───────────────────────────────────────────
  static const List<Color> gradientTranslate = [Color(0xFF7C3AED), Color(0xFFDB2777)];
  static const List<Color> gradientQuiz      = [Color(0xFF0891B2), Color(0xFF0E7490)];
  static const List<Color> gradientPdf       = [Color(0xFFEA580C), Color(0xFFF59E0B)];
  static const List<Color> gradientNotes     = [Color(0xFF059669), Color(0xFF10B981)];

  // ── Banner gradient ───────────────────────────────────────────────────────
  static const List<Color> gradientBanner = [Color(0xFF1E3A8A), Color(0xFF3730A3), Color(0xFF5B21B6)];

  // ── Theme ──────────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDeep,
      primaryColor: accentBlue,
      colorScheme: const ColorScheme.dark(
        primary: accentBlue,
        secondary: accentPurple,
        surface: bgCard,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 26,
        ),
        headlineSmall: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 14),
        bodySmall: TextStyle(color: textSecondary, fontSize: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgInput,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1E3A5F), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: accentBlue, width: 2),
        ),
        hintStyle: const TextStyle(color: textSecondary),
        labelStyle: const TextStyle(color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      dividerColor: const Color(0xFF1E3A5F),
      dialogTheme: DialogThemeData(
        backgroundColor: bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: bgCard,
        contentTextStyle: TextStyle(color: textPrimary),
        behavior: SnackBarBehavior.floating,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: accentBlue,
        unselectedLabelColor: textSecondary,
        indicatorColor: accentBlue,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentPurple,
        foregroundColor: Colors.white,
      ),
    );
  }

  // kept for backward compat – points to darkTheme
  static ThemeData get lightTheme => darkTheme;
}
