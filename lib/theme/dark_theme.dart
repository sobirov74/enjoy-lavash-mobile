import 'package:flutter/material.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'app_theme_colors.dart';

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppThemeColors.dark.background,
  primaryColor: AppThemeColors.dark.primary,
  colorScheme: const ColorScheme.dark(
    primary: BaseColors.primary,
    secondary: BaseColors.accent,
    surface: Color(0xFF1D1A18),
  ),
  appBarTheme: const AppBarTheme(
    elevation: 0,
    centerTitle: false,
    surfaceTintColor: Colors.transparent,
    backgroundColor: Color(0xFF151312),
  ),
  cardColor: const Color(0xFF1D1A18),
  useMaterial3: true,
  textTheme: const TextTheme(
    headlineMedium: TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    ),
    bodyMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: Colors.white,
    ),
  ),
);
