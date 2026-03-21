import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

class AppTheme {
  // --- Premium Color Palette (Slate & Indigo) ---
  static const Color primaryColor = Color(0xFF6366F1); // Indigo 500
  static const Color primaryDark = Color(0xFF4338CA);  // Indigo 700
  static const Color primaryLight = Color(0xFFEEF2FF); // Indigo 50
  
  static const Color secondaryColor = Color(0xFF10B981); // Emerald 500
  
  static const Color backgroundColor = Color(0xFFF8FAFC); // Slate 50
  static const Color surfaceColor = Colors.white;
  static const Color cardColor = Colors.white;
  
  static const Color textPrimary = Color(0xFF0F172A);   // Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textMuted = Color(0xFF94A3B8);     // Slate 400
  static const Color borderColor = Color(0xFFE2E8F0);   // Slate 200

  // --- Design Tokens ---
  static const double borderRadius = 16.0;
  static const double borderRadiusLarge = 24.0;
  
  static final List<BoxShadow> softShadow = [
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static final List<BoxShadow> premiumShadow = [
    BoxShadow(
      color: primaryColor.withOpacity(0.12),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: secondaryColor,
        surface: surfaceColor,
        background: backgroundColor,
        outline: borderColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      
      // --- Typography ---
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.outfit(
          fontWeight: FontWeight.bold,
          color: textPrimary,
          fontSize: 32,
        ),
        displayMedium: GoogleFonts.outfit(
          fontWeight: FontWeight.bold,
          color: textPrimary,
          fontSize: 28,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          color: textPrimary,
          fontSize: 24,
        ),
        titleLarge: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          color: textPrimary,
          fontSize: 20,
        ),
        titleMedium: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          color: textPrimary,
          fontSize: 16,
        ),
        bodyLarge: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 16,
        ),
        bodyMedium: GoogleFonts.inter(
          color: textSecondary,
          fontSize: 14,
        ),
      ),

      // --- Component Themes ---
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          elevation: 0,
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ).copyWith(
          elevation: ButtonStyleButton.allOrNull(0),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          minimumSize: const Size(double.infinity, 56),
          side: const BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textMuted),
        prefixIconColor: textSecondary,
      ),

      cardTheme: CardTheme(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusLarge),
          side: const BorderSide(color: borderColor),
        ),
        color: cardColor,
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surfaceColor,
        selectedIconTheme: const IconThemeData(color: primaryColor, size: 28),
        unselectedIconTheme: const IconThemeData(color: textMuted, size: 24),
        selectedLabelTextStyle: GoogleFonts.outfit(
          color: primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        unselectedLabelTextStyle: GoogleFonts.outfit(
          color: textMuted,
          fontWeight: FontWeight.normal,
          fontSize: 14,
        ),
        indicatorColor: primaryColor.withOpacity(0.08),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: textPrimary,
        contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
    );
  }

  static ThemeData get darkTheme {
    const Color darkBg = Color(0xFF0F172A);
    const Color darkSurface = Color(0xFF1E293B);
    const Color darkBorder = Color(0xFF334155);
    const Color darkText = Color(0xFFF1F5F9);
    const Color darkTextMuted = Color(0xFF94A3B8);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: secondaryColor,
        surface: darkSurface,
        onSurface: darkText,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: darkBg,
      
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: darkText, fontSize: 32),
        displayMedium: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: darkText, fontSize: 28),
        headlineMedium: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: darkText, fontSize: 24),
        titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: darkText, fontSize: 20),
        titleMedium: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: darkText, fontSize: 16),
        bodyLarge: GoogleFonts.inter(color: darkText, fontSize: 16),
        bodyMedium: GoogleFonts.inter(color: darkTextMuted, fontSize: 14),
        bodySmall: GoogleFonts.inter(color: darkTextMuted, fontSize: 12),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: darkText),
        titleTextStyle: TextStyle(color: darkText, fontSize: 20, fontWeight: FontWeight.bold),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
          elevation: 0,
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(borderRadius), borderSide: const BorderSide(color: darkBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(borderRadius), borderSide: const BorderSide(color: darkBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(borderRadius), borderSide: const BorderSide(color: primaryColor, width: 2)),
      ),

      cardTheme: CardTheme(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadiusLarge), side: const BorderSide(color: darkBorder)),
        color: darkSurface,
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: darkBg,
        selectedIconTheme: const IconThemeData(color: primaryColor, size: 28),
        unselectedIconTheme: const IconThemeData(color: darkTextMuted, size: 24),
        selectedLabelTextStyle: GoogleFonts.outfit(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
        unselectedLabelTextStyle: GoogleFonts.outfit(color: darkTextMuted, fontWeight: FontWeight.normal, fontSize: 14),
        indicatorColor: primaryColor.withOpacity(0.08),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: primaryColor,
        contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
    );
  }
}
