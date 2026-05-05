import 'package:flutter/material.dart';
import 'app_theme_colors.dart';

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: AppThemeColors.light.background,
  primaryColor: AppThemeColors.light.primary,

  appBarTheme: const AppBarTheme(elevation: 0, centerTitle: true),

  // cardColor: AppThemeColors.light.card,
  textTheme: const TextTheme(
    bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
  ),
);
