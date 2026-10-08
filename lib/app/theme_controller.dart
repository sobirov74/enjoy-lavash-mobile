import 'package:flutter/material.dart';
import 'package:enjoy_lavash_mobile/core/storage/theme_storage.dart';

class ThemeController extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  /// Restores the saved mode. Unreadable preferences keep the system mode so
  /// startup can never stall here.
  Future<void> loadTheme() async {
    try {
      _themeMode = await ThemeStorage.loadThemeMode();
    } catch (error) {
      debugPrint('Saved theme unreadable, using system: ${error.runtimeType}');
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> setTheme(ThemeMode mode) async {
    _themeMode = mode;
    await ThemeStorage.saveThemeMode(mode);
    notifyListeners();
  }

  bool get isDark => _themeMode == ThemeMode.dark;
}
