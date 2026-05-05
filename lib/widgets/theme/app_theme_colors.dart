import 'package:flutter/material.dart';

class AppThemeColors {
  final Color text;
  final Color background;
  final Color tint;
  final Color icon;
  final Color tabIconDefault;
  final Color tabIconSelected;
  final Color primary;
  final Color textGray;
  final Color black800;
  final Color danger;
  final Color border;
  final Color link;
  final Color white;
  final Color success;

  const AppThemeColors({
    required this.text,
    required this.background,
    required this.tint,
    required this.icon,
    required this.tabIconDefault,
    required this.tabIconSelected,
    required this.primary,
    required this.textGray,
    required this.black800,
    required this.danger,
    required this.border,
    required this.link,
    required this.white,
    required this.success,
  });

  // Light theme
  static const light = AppThemeColors(
    text: Color(0xFF000000),
    background: Color(0xFFF9F8F6),
    tint: Color(0xFF0A7EA4),
    icon: Color(0xFF687076),
    tabIconDefault: Color(0xFF687076),
    tabIconSelected: Color(0xFF0A7EA4),
    primary: Color(0xFFDCC38B),
    textGray: Color(0xFFA9A9A9),
    black800: Color(0xFF212121),
    danger: Color(0xFFCF0000),
    border: Color(0xFFEFEEEA),
    link: Color(0xFF0000FF),
    white: Color(0xFFFFFFFF),
    success: Color(0xFFDDF5E7),
  );

  // Dark theme
  static const dark = AppThemeColors(
    text: Color(0xFFFFFFFF),
    background: Color(0xFF000000),
    tint: Color(0xFFFFFFFF),
    icon: Color(0xFF9BA1A6),
    tabIconDefault: Color(0xFF9BA1A6),
    tabIconSelected: Color(0xFFFFFFFF),
    primary: Color(0xFFDCC38B),
    textGray: Color(0xFF727272),
    black800: Color(0xFF212121),
    danger: Color(0xFFFF5757),
    border: Color(0xFF414141),
    link: Color(0xFF76A3F2),
    white: Color(0xFFFFFFFF),
    success: Color(0xFF1F5E45),
  );
}
