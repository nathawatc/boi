import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme mode setting: auto (follow system), light, or dark
enum ThemeModeSetting { auto, light, dark }

class SettingsProvider extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _isThaiKey = 'is_thai';

  ThemeModeSetting _themeMode = ThemeModeSetting.auto;
  bool _isThai = true;
  bool _isInitialized = false;

  ThemeModeSetting get themeMode => _themeMode;
  bool get isThai => _isThai;
  bool get isInitialized => _isInitialized;

  /// Get the actual ThemeMode for MaterialApp
  ThemeMode get materialThemeMode {
    switch (_themeMode) {
      case ThemeModeSetting.auto:
        return ThemeMode.system;
      case ThemeModeSetting.light:
        return ThemeMode.light;
      case ThemeModeSetting.dark:
        return ThemeMode.dark;
    }
  }

  /// Initialize settings from SharedPreferences
  Future<void> initialize() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString(_themeModeKey) ?? 'auto';
    _themeMode = _themeModeFromString(themeModeString);
    _isThai = prefs.getBool(_isThaiKey) ?? true;
    _isInitialized = true;
    notifyListeners();
  }

  /// Set theme mode
  Future<void> setThemeMode(ThemeModeSetting mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, _themeModeToString(mode));
    notifyListeners();
  }

  /// Set language
  Future<void> setIsThai(bool isThai) async {
    if (_isThai == isThai) return;

    _isThai = isThai;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isThaiKey, isThai);
    notifyListeners();
  }

  ThemeModeSetting _themeModeFromString(String value) {
    switch (value) {
      case 'light':
        return ThemeModeSetting.light;
      case 'dark':
        return ThemeModeSetting.dark;
      case 'auto':
      default:
        return ThemeModeSetting.auto;
    }
  }

  String _themeModeToString(ThemeModeSetting mode) {
    switch (mode) {
      case ThemeModeSetting.auto:
        return 'auto';
      case ThemeModeSetting.light:
        return 'light';
      case ThemeModeSetting.dark:
        return 'dark';
    }
  }
}
