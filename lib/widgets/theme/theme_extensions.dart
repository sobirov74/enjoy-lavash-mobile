import 'package:flutter/material.dart';
import 'app_theme_colors.dart';

extension ThemeColorsX on BuildContext {
  ThemeData get theme => Theme.of(this);

  bool get isDark => theme.brightness == Brightness.dark;

  AppThemeColors get colors =>
      isDark ? AppThemeColors.dark : AppThemeColors.light;
}
