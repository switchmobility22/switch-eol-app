import 'package:flutter/material.dart';

class EolTheme {
  // Official Powerpedal Blue extracted from powerpedal_logo.png
  static const Color powerpedalBlue = Color(0xFF0074D7);
  static const Color powerpedalBlueDark = Color(0xFF005FB3);
  static const Color powerpedalBlueLight = Color(0xFFE6F1FB);

  // High-contrast industrial porcelain canvas & surfaces
  static const Color canvasBackground = Color(0xFFF4F5F7);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFF8F9FA);

  // Borders & Dividers
  static const Color borderSubtle = Color(0xFFE2E8F0);
  static const Color borderFocused = Color(0xFF0074D7);

  // High-contrast factory typography
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textOnBlue = Color(0xFFFFFFFF);

  // Status Colors
  static const Color statusSuccess = Color(0xFF10B981);
  static const Color statusSuccessBg = Color(0xFFE8F7F0);
  static const Color statusFault = Color(0xFFEF4444);
  static const Color statusFaultBg = Color(0xFFFEE2E2);
  static const Color statusWarning = Color(0xFFF59E0B);
  static const Color statusWarningBg = Color(0xFFFEF3C7);

  // Gloved-hand ergonomic dimensions
  static const double minTouchTarget = 56.0;
  static const double buttonHeight = 56.0;
  static const double borderRadius = 14.0;
  static const double borderRadiusPill = 999.0;

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: canvasBackground,
      colorScheme: const ColorScheme.light(
        primary: powerpedalBlue,
        onPrimary: textOnBlue,
        surface: surfaceCard,
        onSurface: textPrimary,
        error: statusFault,
        onError: Colors.white,
      ),
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceCard,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(buttonHeight),
          backgroundColor: powerpedalBlue,
          foregroundColor: textOnBlue,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: const BorderSide(color: borderSubtle, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
    );
  }
}
