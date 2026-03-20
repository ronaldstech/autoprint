import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF0D47A1); // Deep Blue
  static const Color accentColor = Color(0xFF1976D2); // Vibrant Blue
  static const Color backgroundColor = Color(0xFFF8FAFC); // Slate 50
  static const Color surfaceColor = Colors.white;
  static const Color textColor = Color(0xFF1E293B); // Slate 800

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceColor,
        background: backgroundColor,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.outfit(
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        titleLarge: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFF64748B)),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        color: surfaceColor,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surfaceColor,
        selectedIconTheme: const IconThemeData(color: primaryColor),
        unselectedIconTheme: const IconThemeData(color: Color(0xFF64748B)),
        selectedLabelTextStyle: GoogleFonts.outfit(
          color: primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        unselectedLabelTextStyle: GoogleFonts.outfit(
          color: const Color(0xFF64748B),
          fontWeight: FontWeight.normal,
          fontSize: 14,
        ),
        indicatorColor: primaryColor.withOpacity(0.08),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
