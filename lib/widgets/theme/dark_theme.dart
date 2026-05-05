import 'package:flutter/material.dart';
import 'app_theme_colors.dart';

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppThemeColors.dark.background,
  primaryColor: AppThemeColors.dark.primary,

  appBarTheme: const AppBarTheme(elevation: 0, centerTitle: true),

  // cardColor: AppThemeColors.dark.card,
  textTheme: const TextTheme(
    bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
  ),
);
