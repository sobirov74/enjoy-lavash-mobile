import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends ChangeNotifier {
  static const _key = 'app_locale';
  static const defaultLocale = Locale('uz');

  static const supportedLocales = [Locale('uz'), Locale('ru'), Locale('en')];

  Locale _locale = defaultLocale;
  Locale get locale => _locale;

  /// Restores the saved language. Unknown codes and unreadable preferences
  /// keep [defaultLocale] so startup can never stall here.
  Future<void> loadLocale() async {
    final String? code;
    try {
      final prefs = await SharedPreferences.getInstance();
      code = prefs.getString(_key);
    } catch (error) {
      debugPrint(
        'Saved locale unreadable, using default: ${error.runtimeType}',
      );
      return;
    }
    final saved = supportedLocales.where(
      (locale) => locale.languageCode == code,
    );
    if (saved.isEmpty) return;
    _locale = saved.first;
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
  }
}
