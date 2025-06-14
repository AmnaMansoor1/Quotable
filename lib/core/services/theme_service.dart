import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'app_theme_mode';
  static const String _customThemesUnlockedKey = 'custom_themes_unlocked';
  static const String _themeChangesCountKey = 'theme_changes_count';
  
  ThemeMode _themeMode = ThemeMode.light;
  bool _customThemesUnlocked = false;
  int _themeChangesCount = 0;

  ThemeMode get themeMode => _themeMode;
  bool get customThemesUnlocked => _customThemesUnlocked;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  int get themeChangesCount => _themeChangesCount;

  // Initialize theme service
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load custom themes unlock status
    _customThemesUnlocked = prefs.getBool(_customThemesUnlockedKey) ?? false;
    _themeChangesCount = prefs.getInt(_themeChangesCountKey) ?? 0;
    
    // Load theme mode only if custom themes are unlocked
    if (_customThemesUnlocked) {
      final themeIndex = prefs.getInt(_themeKey) ?? 0;
      _themeMode = ThemeMode.values[themeIndex];
    } else {
      _themeMode = ThemeMode.light; // Default to light theme
    }
    
    notifyListeners();
  }

  // Check if user can change theme (needs to watch ad each time)
  bool canChangeTheme() {
    return _customThemesUnlocked;
  }

  // Toggle between light and dark theme (requires watching ad each time)
  Future<bool> toggleTheme() async {
    if (!_customThemesUnlocked) {
      print('Custom themes not unlocked');
      return false;
    }

    // User needs to watch ad for each theme change
    return false; // This will be handled by the premium screen
  }

  // Apply theme change after watching rewarded ad
  Future<void> applyThemeChange() async {
    if (!_customThemesUnlocked) {
      print('Custom themes not unlocked');
      return;
    }

    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _themeChangesCount++;
    
    await _saveThemeMode();
    await _saveThemeChangesCount();
    notifyListeners();
    
    print('Theme changed to: ${_themeMode.name}');
  }

  // Set specific theme mode after watching ad
  Future<void> setThemeModeAfterAd(ThemeMode mode) async {
    if (!_customThemesUnlocked) {
      print('Custom themes not unlocked');
      return;
    }

    if (_themeMode != mode) {
      _themeMode = mode;
      _themeChangesCount++;
      
      await _saveThemeMode();
      await _saveThemeChangesCount();
      notifyListeners();
      
      print('Theme set to: ${_themeMode.name}');
    }
  }

  // Unlock custom themes (one-time unlock)
  Future<void> unlockCustomThemes() async {
    _customThemesUnlocked = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_customThemesUnlockedKey, true);
    notifyListeners();
    print('Custom themes unlocked!');
  }

  // Check if custom themes are unlocked
  Future<bool> areCustomThemesUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_customThemesUnlockedKey) ?? false;
  }

  // Save theme mode to preferences
  Future<void> _saveThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, _themeMode.index);
  }

  // Save theme changes count
  Future<void> _saveThemeChangesCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeChangesCountKey, _themeChangesCount);
  }

  // Reset to default theme (for testing)
  Future<void> resetTheme() async {
    _themeMode = ThemeMode.light;
    await _saveThemeMode();
    notifyListeners();
  }

  // Get current theme name for display
  String get currentThemeName {
    return _themeMode == ThemeMode.dark ? 'Dark' : 'Light';
  }
}
