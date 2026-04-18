import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Shadcn-inspired color palette
  static const _lightBackground = Color(0xFFFFFFFF);
  static const _lightForeground = Color(0xFF020817);
  static const _lightCard = Color(0xFFFFFFFF);
  static const _lightCardForeground = Color(0xFF020817);
  static const _lightPrimary = Color(0xFF0F172A);
  static const _lightPrimaryForeground = Color(0xFFF8FAFC);
  static const _lightSecondary = Color(0xFFF1F5F9);
  static const _lightSecondaryForeground = Color(0xFF0F172A);
  static const _lightMuted = Color(0xFFF1F5F9);
  static const _lightMutedForeground = Color(0xFF64748B);
  static const _lightAccent = Color(0xFFF1F5F9);
  static const _lightAccentForeground = Color(0xFF0F172A);
  static const _lightBorder = Color(0xFFE2E8F0);
  static const _lightInput = Color(0xFFE2E8F0);
  static const _lightRing = Color(0xFF020817);

  static const _darkBackground = Color(0xFF020817);
  static const _darkForeground = Color(0xFFF8FAFC);
  static const _darkCard = Color(0xFF020817);
  static const _darkCardForeground = Color(0xFFF8FAFC);
  static const _darkPrimary = Color(0xFFF8FAFC);
  static const _darkPrimaryForeground = Color(0xFF0F172A);
  static const _darkSecondary = Color(0xFF1E293B);
  static const _darkSecondaryForeground = Color(0xFFF8FAFC);
  static const _darkMuted = Color(0xFF1E293B);
  static const _darkMutedForeground = Color(0xFF94A3B8);
  static const _darkAccent = Color(0xFF1E293B);
  static const _darkAccentForeground = Color(0xFFF8FAFC);
  static const _darkBorder = Color(0xFF1E293B);
  static const _darkInput = Color(0xFF1E293B);
  static const _darkRing = Color(0xFFD4D4D8);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: _lightBackground,
    colorScheme: const ColorScheme.light(
      primary: _lightPrimary,
      onPrimary: _lightPrimaryForeground,
      secondary: _lightSecondary,
      onSecondary: _lightSecondaryForeground,
      surface: _lightCard,
      onSurface: _lightCardForeground,
      error: Color(0xFFEF4444),
      onError: Colors.white,
    ),
    textTheme: GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: _lightForeground,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: _lightForeground,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: _lightForeground,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: _lightForeground,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: _lightForeground,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        color: _lightForeground,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        color: _lightForeground,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        color: _lightMutedForeground,
      ),
    ),
    cardTheme: CardThemeData(
      color: _lightCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _lightBorder, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _lightPrimary,
        foregroundColor: _lightPrimaryForeground,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _lightForeground,
        side: const BorderSide(color: _lightBorder),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _lightBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _lightInput),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _lightInput),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _lightRing, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    dividerColor: _lightBorder,
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _darkBackground,
    colorScheme: const ColorScheme.dark(
      primary: _darkPrimary,
      onPrimary: _darkPrimaryForeground,
      secondary: _darkSecondary,
      onSecondary: _darkSecondaryForeground,
      surface: _darkCard,
      onSurface: _darkCardForeground,
      error: Color(0xFFEF4444),
      onError: Colors.white,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: _darkForeground,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: _darkForeground,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: _darkForeground,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: _darkForeground,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: _darkForeground,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        color: _darkForeground,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        color: _darkForeground,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        color: _darkMutedForeground,
      ),
    ),
    cardTheme: CardThemeData(
      color: _darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _darkBorder, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _darkPrimary,
        foregroundColor: _darkPrimaryForeground,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _darkForeground,
        side: const BorderSide(color: _darkBorder),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _darkBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _darkInput),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _darkInput),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _darkRing, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    dividerColor: _darkBorder,
  );
}
