import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData getThemeData() {
    return ThemeData(
      // Ana renkler
      primaryColor: const Color(0xFF0D47A1),
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      
      // Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0D47A1),
        brightness: Brightness.light,
        surface: const Color(0xFFF5F5F5),
        onSurface: const Color(0xFF1A1A1A),
      ),
      
      // Font Family
      fontFamily: 'Inter',
      
      // AppBar Teması
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      
      // Text Teması
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A1A1A),
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A1A),
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Inter',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A1A),
        ),
        titleLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1A1A1A),
        ),
        titleMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1A1A1A),
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: Color(0xFF1A1A1A),
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: Color(0xFF1A1A1A),
        ),
        bodySmall: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: Color(0xFF666666),
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
          backgroundColor: const Color(0xFF0D47A1),
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
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
          borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
