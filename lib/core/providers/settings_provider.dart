import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  // Private state properties with default values
  ThemeMode _themeMode = ThemeMode.system;
  String _fontFamily = 'Merriweather';

  // Public getters
  ThemeMode get themeMode => _themeMode;
  String get fontFamily => _fontFamily;

  // Keys for SharedPreferences
  static const String _themeModeKey = 'theme_mode';
  static const String _fontFamilyKey = 'font_family';

  // Load settings from SharedPreferences
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load theme mode
      final themeIndex = prefs.getInt(_themeModeKey);
      if (themeIndex != null) {
        _themeMode = ThemeMode.values[themeIndex];
      }
      
      // Load font family
      final savedFont = prefs.getString(_fontFamilyKey);
      if (savedFont != null) {
        _fontFamily = savedFont;
      }
      
      print('DEBUG SettingsProvider: Loaded settings - Theme: $_themeMode, Font: $_fontFamily');
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  // Set theme mode and persist it
  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      _themeMode = mode;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeModeKey, mode.index);
      
      print('DEBUG SettingsProvider: Theme mode set to $_themeMode');
      notifyListeners();
    } catch (e) {
      print('Error setting theme mode: $e');
    }
  }

  // Set font family and persist it
  Future<void> setFontFamily(String fontFamily) async {
    try {
      _fontFamily = fontFamily;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fontFamilyKey, fontFamily);
      
      print('DEBUG SettingsProvider: Font family set to $_fontFamily');
      notifyListeners();
    } catch (e) {
      print('Error setting font family: $e');
    }
  }

  // Get theme mode display name for UI
  String getThemeModeDisplayName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Açık Tema';
      case ThemeMode.dark:
        return 'Koyu Tema';
      case ThemeMode.system:
        return 'Sistem Ayarı';
    }
  }

  // Get available font families for dropdown
  List<String> get availableFonts => [
        'Merriweather',
        'Inter',
        'Lato',
        'Roboto',
        'Open Sans',
      ];

  // Get font display name for UI
  String getFontDisplayName(String font) {
    switch (font) {
      case 'Merriweather':
        return 'Merriweather (Varsayılan)';
      case 'Inter':
        return 'Inter (Modern)';
      case 'Lato':
        return 'Lato (Temiz)';
      case 'Roboto':
        return 'Roboto (Standart)';
      case 'Open Sans':
        return 'Open Sans (Açık)';
      default:
        return font;
    }
  }
}
