import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF4CAF50); // Unified green
  static const Color primaryDarkColor = Color(0xFF388E3C);
  static const Color backgroundColor = Color(0xFFF8FAF9);
  static const Color foregroundColor = Color(0xFF0F172A);
  static const Color cardColor = Colors.white;
  static const Color mutedColor = Color(0xFFF1F5F9);
  static const Color mutedForegroundColor = Color(0xFF64748B);
  static const Color accentColor = Color(0xFFE2E8F0);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF66BB6A), Color(0xFF43A047)], // Unified green gradient
  );

  static const LinearGradient softGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF0FDF4), Color(0xFFFAFAFA)],
  );

  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x1A000000), // Approx
      blurRadius: 30,
      offset: Offset(0, 10),
      spreadRadius: -12,
    )
  ];

  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x14000000), // Approx
      blurRadius: 20,
      offset: Offset(0, 4),
      spreadRadius: -8,
    )
  ];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primaryDarkColor,
        background: backgroundColor,
        surface: cardColor,
        onBackground: foregroundColor,
        onSurface: foregroundColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: GoogleFonts.nunitoTextTheme().apply(
        bodyColor: foregroundColor,
        displayColor: foregroundColor,
      ),
      cardTheme: const CardThemeData(
        color: cardColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }
}
