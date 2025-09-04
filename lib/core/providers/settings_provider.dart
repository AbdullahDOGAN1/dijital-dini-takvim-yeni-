import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  // Private state properties with default values
  ThemeMode _themeMode = ThemeMode.system;
  String _fontFamily = 'Merriweather';
  bool _azanSoundEnabled = false;
  String _azanSoundName = 'athan';

  // Public getters
  ThemeMode get themeMode => _themeMode;
  String get fontFamily => _fontFamily;
  bool get azanSoundEnabled => _azanSoundEnabled;
  String get azanSoundName => _azanSoundName;

  // Keys for SharedPreferences
  static const String _themeModeKey = 'theme_mode';
  static const String _fontFamilyKey = 'font_family';
  static const String _azanSoundEnabledKey = 'azan_sound_enabled';
  static const String _azanSoundNameKey = 'azan_sound_name';

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
      
      // Load azan sound settings
      _azanSoundEnabled = prefs.getBool(_azanSoundEnabledKey) ?? false;
      _azanSoundName = prefs.getString(_azanSoundNameKey) ?? 'athan';
      
      print('DEBUG SettingsProvider: Loaded settings - Theme: $_themeMode, Font: $_fontFamily, Azan: $_azanSoundEnabled');
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

  // Set azan sound enabled/disabled
  Future<void> setAzanSoundEnabled(bool enabled) async {
    try {
      _azanSoundEnabled = enabled;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_azanSoundEnabledKey, enabled);
      
      print('DEBUG SettingsProvider: Azan sound enabled set to $_azanSoundEnabled');
      notifyListeners();
    } catch (e) {
      print('Error setting azan sound enabled: $e');
    }
  }

  // Set azan sound name
  Future<void> setAzanSoundName(String soundName) async {
    try {
      _azanSoundName = soundName;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_azanSoundNameKey, soundName);
      
      print('DEBUG SettingsProvider: Azan sound name set to $_azanSoundName');
      notifyListeners();
    } catch (e) {
      print('Error setting azan sound name: $e');
    }
  }
}
