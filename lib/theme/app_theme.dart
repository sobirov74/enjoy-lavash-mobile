import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_design_tokens.dart';
import 'app_theme_colors.dart';

class AppTheme {
  AppTheme._();

  static final ThemeData light = _build(Brightness.light);
  static final ThemeData dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final background = isDark
        ? AppThemeColors.dark.background
        : AppThemeColors.light.background;
    final surface = isDark ? const Color(0xFF1D1A18) : BaseColors.white;
    final onSurface = isDark ? const Color(0xFFF7F4F1) : BaseColors.black800;
    final muted = isDark ? const Color(0xFFAAA39A) : BaseColors.textGray;
    final border = isDark ? const Color(0xFF35302C) : BaseColors.borderLight;

    final scheme = ColorScheme.fromSeed(
      seedColor: BaseColors.primary,
      brightness: brightness,
      primary: BaseColors.primary,
      surface: surface,
      error: isDark ? BaseColors.dangerDark : BaseColors.danger,
    );

    final baseTextTheme = ThemeData(
      brightness: brightness,
      fontFamily: 'GolosText',
    ).textTheme;
    final textTheme = baseTextTheme.copyWith(
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontFamily: 'Manrope',
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.45,
        color: onSurface,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontFamily: 'Manrope',
        fontSize: 21,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: onSurface,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        fontSize: 16,
        height: 1.25,
        color: onSurface,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        fontSize: 14,
        height: 1.43,
        color: onSurface,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(color: muted),
    );

    final roundedRectangle = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(999),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      primaryColor: BaseColors.primary,
      scaffoldBackgroundColor: background,
      cardColor: surface,
      canvasColor: surface,
      textTheme: textTheme,
      fontFamily: 'GolosText',
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        backgroundColor: background,
        foregroundColor: onSurface,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: roundedRectangle,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppDesignTokens.actionPressed,
          foregroundColor: Colors.white,
          disabledBackgroundColor: BaseColors.primary.withValues(alpha: 0.45),
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
          ),
          shape: roundedRectangle,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: BaseColors.primary,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          side: BorderSide(color: border),
          shape: roundedRectangle,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: TextStyle(color: muted),
        labelStyle: TextStyle(color: muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: BaseColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.error),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: muted.withValues(alpha: 0.55),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFFF3EEE9) : BaseColors.black800,
        contentTextStyle: TextStyle(
          color: isDark ? const Color(0xFF211D1A) : Colors.white,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: DividerThemeData(color: border, space: 1),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: BaseColors.primary,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFFF3EEE9) : BaseColors.black800,
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: TextStyle(
          color: isDark ? const Color(0xFF211D1A) : Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
