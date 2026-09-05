import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Visual constants transcribed from the Enjoy Lavash redesign board.
///
/// Feature widgets should use these roles instead of introducing new colors,
/// radii, or spacing values. This keeps light/dark screens aligned while the
/// existing domain and API layers remain unchanged.
abstract final class AppDesignTokens {
  static const double gutter = 20;

  static const double radiusSheet = 28;
  static const double radiusHero = 24;
  static const double radiusCard = 22;
  static const double radiusTile = 20;
  static const double radiusPanel = 18;
  static const double radiusInput = 14;
  static const double radiusThumb = 11;
  static const double radiusPill = 999;

  static const double primaryButtonHeight = 54;
  static const double buttonHeight = 52;
  static const double chipHeight = 38;
  static const double tabBarHeight = 72;

  static const Color lightGround = Color(0xFFF6F3EC);
  static const Color darkGround = Color(0xFF151312);
  static const Color darkSurface = Color(0xFF1D1A18);
  static const Color ink = Color(0xFF1D1B2C);
  static const Color action = BaseColors.primary;
  static const Color actionPressed = BaseColors.primaryDark;
  static const Color actionSoft = BaseColors.surfaceTint;
  static const Color gold = Color(0xFFF5C84C);
  static const Color goldWash = Color(0xFFF8ECCF);
  static const Color goldInk = Color(0xFF5C4300);
  static const Color success = Color(0xFF3E7C4F);
  static const Color successWash = Color(0xFFE9F2EB);
  static const Color danger = Color(0xFFC2452D);
  static const Color dangerWash = Color(0xFFFBEDE8);

  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? darkSurface
      : Colors.white;

  static Color ground(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? darkGround
      : lightGround;

  static Color primaryText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFF7F4F1)
      : ink;

  static Color secondaryText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFAAA39A)
      : ink.withValues(alpha: 0.60);

  static Color tertiaryText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFB9B1AA)
      : const Color(0xFF6F6862);

  static Color inkSurface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFF4EEE8)
      : ink;

  static Color onInk(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? ink : Colors.white;

  static Color goldText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFF0C763)
      : goldInk;

  static Color successText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF91D5A2)
      : success;

  static Color dangerText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFFFB4AB)
      : danger;

  static Color hairline(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? Colors.white.withValues(alpha: 0.09)
      : ink.withValues(alpha: 0.08);

  static Color controlBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? Colors.white.withValues(alpha: 0.24)
      : ink.withValues(alpha: 0.24);

  static List<BoxShadow> cardShadow(BuildContext context) => <BoxShadow>[
    BoxShadow(
      color: Colors.black.withValues(
        alpha: Theme.of(context).brightness == Brightness.dark ? 0.45 : 0.06,
      ),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> actionGlow = <BoxShadow>[
    BoxShadow(color: Color(0x66C4511A), blurRadius: 24, offset: Offset(0, 10)),
  ];

  static const List<BoxShadow> darkPillShadow = <BoxShadow>[
    BoxShadow(color: Color(0x801D1B2C), blurRadius: 26, offset: Offset(0, 10)),
  ];
}

abstract final class AppTextStyles {
  static TextStyle display({
    required double size,
    double? height,
    FontWeight weight = FontWeight.w700,
    Color? color,
  }) => TextStyle(
    fontFamily: 'Manrope',
    fontSize: size,
    height: height,
    fontWeight: weight,
    letterSpacing: size >= 24 ? -0.45 : -0.2,
    color: color,
  );

  static TextStyle ui({
    required double size,
    double? height,
    FontWeight weight = FontWeight.w400,
    Color? color,
  }) => TextStyle(
    fontFamily: 'GolosText',
    fontSize: size,
    height: height,
    fontWeight: weight,
    color: color,
  );
}
