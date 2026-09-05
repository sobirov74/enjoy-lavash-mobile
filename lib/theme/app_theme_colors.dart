import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
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
    text: Color(0xFF1D1B2C),
    background: Color(0xFFF6F3EC),
    tint: BaseColors.primary,
    icon: Color(0xFF6C6A67),
    tabIconDefault: Color(0xFF8D8781),
    tabIconSelected: BaseColors.primary,
    primary: BaseColors.primary,
    textGray: Color(0xFF6C6A73),
    black800: Color(0xFF1D1B2C),
    danger: Color(0xFFC2452D),
    border: Color(0xFFE8E4DC),
    link: BaseColors.primary,
    white: Color(0xFFFFFFFF),
    success: Color(0xFFE6F4EA),
  );

  // Dark theme
  static const dark = AppThemeColors(
    text: Color(0xFFFFFFFF),
    background: Color(0xFF151312),
    tint: Color(0xFFFFFFFF),
    icon: Color(0xFF9BA1A6),
    tabIconDefault: Color(0xFF9BA1A6),
    tabIconSelected: BaseColors.primary,
    primary: BaseColors.primary,
    textGray: Color(0xFF9F9B97),
    black800: Color(0xFF212121),
    danger: Color(0xFFFF8A80),
    border: Color(0xFF35302C),
    link: BaseColors.primaryOnDark,
    white: Color(0xFFFFFFFF),
    success: Color(0xFF1F5E45),
  );
}
