import 'package:flutter/material.dart';

/// Thème global de MauriVote
/// Couleurs inspirées du drapeau mauritanien : vert islamique + or
class AppTheme {
  // ── Palette mauritanienne ─────────────────────────────────────────────────
  static const Color primaryGreen   = Color(0xFF1B5E20); // Vert drapeau
  static const Color primaryGold    = Color(0xFFF9A825); // Or/jaune drapeau
  static const Color accentGreen    = Color(0xFF2E7D32);
  static const Color lightGreen     = Color(0xFFC8E6C9);
  static const Color errorRed       = Color(0xFFB71C1C);
  static const Color backgroundWhite = Color(0xFFFAFAFA);
  static const Color surfaceWhite   = Color(0xFFFFFFFF);
  static const Color textPrimary    = Color(0xFF1A1A1A);
  static const Color textSecondary  = Color(0xFF666666);

  // ── Thème clair ───────────────────────────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    fontFamily: 'Roboto',

    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryGreen,
      brightness: Brightness.light,
      primary: primaryGreen,
      secondary: primaryGold,
      error: errorRed,
      background: backgroundWhite,
      surface: surfaceWhite,
    ),

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),

    // Boutons principaux
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        elevation: 2,
      ),
    ),

    // Boutons outline
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryGreen,
        side: const BorderSide(color: primaryGreen, width: 1.5),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),

    // Champs de texte
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorRed, width: 1.5),
      ),
      labelStyle: const TextStyle(color: textSecondary),
      hintStyle: const TextStyle(color: textSecondary),
    ),

    // Cards
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: surfaceWhite,
      shadowColor: Colors.black12,
    ),

    // Bottom Navigation Bar
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: primaryGreen,
      unselectedItemColor: textSecondary,
      backgroundColor: surfaceWhite,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
    ),

    // Snackbar
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),

    // Texte
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textPrimary),
      headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary),
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary),
      bodyLarge: TextStyle(fontSize: 16, color: textPrimary),
      bodyMedium: TextStyle(fontSize: 14, color: textSecondary),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
    ),
  );

  // ── Thème sombre ──────────────────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    fontFamily: 'Roboto',
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryGreen,
      brightness: Brightness.dark,
      primary: const Color(0xFF4CAF50),
      secondary: primaryGold,
      error: const Color(0xFFEF5350),
      background: const Color(0xFF121212),
      surface: const Color(0xFF1E1E1E),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
  );

  // ── Décoration de carte élection ──────────────────────────────────────────
  static BoxDecoration electionCardDecoration({Color? color}) => BoxDecoration(
    color: color ?? surfaceWhite,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.06),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
    border: Border.all(color: lightGreen, width: 1),
  );
}
