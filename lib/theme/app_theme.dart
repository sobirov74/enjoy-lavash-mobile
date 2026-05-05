import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_theme_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.grey.shade100,
    primaryColor: BaseColors.primary,
    colorScheme: const ColorScheme.light(
      primary: BaseColors.primary,
      error: Color(0xFFCF0000),
    ),
  );

  static ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppThemeColors.dark.background,
    primaryColor: BaseColors.primary,
    colorScheme: const ColorScheme.dark(
      primary: BaseColors.primary,
      error: Color(0xFFFF5757),
    ),
  );
}
