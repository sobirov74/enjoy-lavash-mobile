import 'package:flutter/material.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'app_theme_colors.dart';

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: AppThemeColors.light.background,
  primaryColor: AppThemeColors.light.primary,
  colorScheme: const ColorScheme.light(
    primary: BaseColors.primary,
    secondary: BaseColors.accent,
    surface: BaseColors.white,
  ),
  appBarTheme: const AppBarTheme(
    elevation: 0,
    centerTitle: false,
    surfaceTintColor: Colors.transparent,
    backgroundColor: BaseColors.baseBg,
  ),
  cardColor: BaseColors.card,
  useMaterial3: true,
  textTheme: const TextTheme(
    headlineMedium: TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.w700,
      color: Color(0xFF14110F),
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: Color(0xFF14110F),
    ),
    bodyMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: Color(0xFF14110F),
    ),
  ),
);
