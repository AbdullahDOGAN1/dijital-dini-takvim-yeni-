import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData getThemeData() {
    return ThemeData(
      // Ana renkler
      primaryColor: Colors.brown.shade700,
      scaffoldBackgroundColor: const Color(0xFFF1EAD9), // Warm parchment color
      
      // Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.brown.shade700,
        brightness: Brightness.light,
        surface: const Color(0xFFF1EAD9),
        onSurface: Colors.black87,
      ),
      
      // Font Family
      fontFamily: GoogleFonts.ebGaramond().fontFamily,
      
      // AppBar Teması
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: GoogleFonts.ebGaramond(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      
      // Text Teması
      textTheme: GoogleFonts.ebGaramondTextTheme().copyWith(
        headlineLarge: GoogleFonts.ebGaramond(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        headlineMedium: GoogleFonts.ebGaramond(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        headlineSmall: GoogleFonts.ebGaramond(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        titleLarge: GoogleFonts.ebGaramond(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        titleMedium: GoogleFonts.ebGaramond(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        bodyLarge: GoogleFonts.ebGaramond(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: Colors.black87,
        ),
        bodyMedium: GoogleFonts.ebGaramond(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: Colors.black87,
        ),
        bodySmall: GoogleFonts.ebGaramond(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: const Color(0xFF6D4C41), // Dark brown for secondary text
        ),
      ),
      
      // Card Teması
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      
      // Elevated Button Teması
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.brown.shade600,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.ebGaramond(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Input Decoration Teması
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.brown.shade700, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
