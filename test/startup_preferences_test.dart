import 'package:enjoy_lavash_mobile/app/locale_controller.dart';
import 'package:enjoy_lavash_mobile/app/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('restores a saved supported language', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'app_locale': 'ru',
    });
    final controller = LocaleController();

    await controller.loadLocale();

    expect(controller.locale, const Locale('ru'));
  });

  test('ignores an unsupported saved language', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'app_locale': 'de',
    });
    final controller = LocaleController();

    await controller.loadLocale();

    expect(controller.locale, LocaleController.defaultLocale);
  });

  test('unknown saved theme falls back to the system mode', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'theme_mode': 'sepia',
    });
    final controller = ThemeController();

    await controller.loadTheme();

    expect(controller.themeMode, ThemeMode.system);
  });
}
