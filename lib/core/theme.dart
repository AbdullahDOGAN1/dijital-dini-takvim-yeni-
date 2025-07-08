import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Get light theme with custom font
  static ThemeData getLightThemeData([String fontFamily = 'Merriweather']) {
    final textTheme = _getTextTheme(fontFamily);
    
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
      fontFamily: _getFontFamily(fontFamily),
      textTheme: textTheme,

      // AppBar Teması
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      // Card Teması
      cardTheme: CardThemeData(
        color: Colors.white.withOpacity(0.9),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.brown.shade600,
          foregroundColor: Colors.white,
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.brown.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.brown.shade700, width: 2),
        ),
      ),
    );
  }

  // Get dark theme with custom font
  static ThemeData getDarkThemeData([String fontFamily = 'Merriweather']) {
    final textTheme = _getTextTheme(fontFamily, isDark: true);
    
    return ThemeData(
      // Ana renkler
      primaryColor: Colors.brown.shade400,
      scaffoldBackgroundColor: const Color(0xFF1A1A1A), // Dark background
      
      // Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.brown.shade400,
        brightness: Brightness.dark,
        surface: const Color(0xFF2A2A2A),
        onSurface: Colors.white,
      ),

      // Font Family
      fontFamily: _getFontFamily(fontFamily),
      textTheme: textTheme,

      // AppBar Teması
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.brown.shade800,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      // Card Teması
      cardTheme: CardThemeData(
        color: const Color(0xFF2A2A2A),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.brown.shade600,
          foregroundColor: Colors.white,
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.brown.shade600),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.brown.shade400, width: 2),
        ),
      ),
    );
  }

  // Backward compatibility method
  static ThemeData getThemeData([String fontFamily = 'Merriweather']) {
    return getLightThemeData(fontFamily);
  }

  // Private helper method to get font family
  static String? _getFontFamily(String fontFamily) {
    switch (fontFamily) {
      case 'Merriweather':
        return GoogleFonts.merriweather().fontFamily;
      case 'Inter':
        return GoogleFonts.inter().fontFamily;
      case 'Lato':
        return GoogleFonts.lato().fontFamily;
      case 'Roboto':
        return GoogleFonts.roboto().fontFamily;
      case 'Open Sans':
        return GoogleFonts.openSans().fontFamily;
      default:
        return GoogleFonts.merriweather().fontFamily;
    }
  }

  // Private helper method to get text theme
  static TextTheme _getTextTheme(String fontFamily, {bool isDark = false}) {
    final color = isDark ? Colors.white : Colors.black87;
    
    switch (fontFamily) {
      case 'Merriweather':
        return GoogleFonts.merriweatherTextTheme().copyWith(
          bodyLarge: GoogleFonts.merriweather(color: color),
          bodyMedium: GoogleFonts.merriweather(color: color),
          titleLarge: GoogleFonts.merriweather(color: color, fontWeight: FontWeight.w600),
        );
      case 'Inter':
        return GoogleFonts.interTextTheme().copyWith(
          bodyLarge: GoogleFonts.inter(color: color),
          bodyMedium: GoogleFonts.inter(color: color),
          titleLarge: GoogleFonts.inter(color: color, fontWeight: FontWeight.w600),
        );
      case 'Lato':
        return GoogleFonts.latoTextTheme().copyWith(
          bodyLarge: GoogleFonts.lato(color: color),
          bodyMedium: GoogleFonts.lato(color: color),
          titleLarge: GoogleFonts.lato(color: color, fontWeight: FontWeight.w600),
        );
      case 'Roboto':
        return GoogleFonts.robotoTextTheme().copyWith(
          bodyLarge: GoogleFonts.roboto(color: color),
          bodyMedium: GoogleFonts.roboto(color: color),
          titleLarge: GoogleFonts.roboto(color: color, fontWeight: FontWeight.w600),
        );
      case 'Open Sans':
        return GoogleFonts.openSansTextTheme().copyWith(
          bodyLarge: GoogleFonts.openSans(color: color),
          bodyMedium: GoogleFonts.openSans(color: color),
          titleLarge: GoogleFonts.openSans(color: color, fontWeight: FontWeight.w600),
        );
      default:
        return GoogleFonts.merriweatherTextTheme().copyWith(
          bodyLarge: GoogleFonts.merriweather(color: color),
          bodyMedium: GoogleFonts.merriweather(color: color),
          titleLarge: GoogleFonts.merriweather(color: color, fontWeight: FontWeight.w600),
        );
    }
  }

  // Available font families
  static const List<String> availableFonts = [
    'Merriweather',
    'Inter', 
    'Lato',
    'Roboto',
    'Open Sans',
  ];

  // Display names for fonts
  static String getFontDisplayName(String fontFamily) {
    switch (fontFamily) {
      case 'Merriweather':
        return 'Merriweather (Klasik)';
      case 'Inter':
        return 'Inter (Modern)';
      case 'Lato':
        return 'Lato (Temiz)';
      case 'Roboto':
        return 'Roboto (Standart)';
      case 'Open Sans':
        return 'Open Sans (Okunabilir)';
      default:
        return fontFamily;
    }
  }
}
