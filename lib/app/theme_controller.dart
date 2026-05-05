import 'package:flutter/material.dart';
import 'package:enjoy_lavash_mobile/core/storage/theme_storage.dart';

class ThemeController extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  Future<void> loadTheme() async {
    _themeMode = await ThemeStorage.loadThemeMode();
    notifyListeners();
  }

  Future<void> setTheme(ThemeMode mode) async {
    _themeMode = mode;
    await ThemeStorage.saveThemeMode(mode);
    notifyListeners();
  }

  bool get isDark => _themeMode == ThemeMode.dark;
}
