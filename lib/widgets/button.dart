import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum ButtonVariant { primary, secondary, tertiary }

enum ButtonSize { small, medium, large }

enum IconPosition { left, right }

class MainButton extends StatelessWidget {
  final Widget title;
  final ButtonVariant variant;
  final ButtonSize size;
  final Widget? icon;
  final IconPosition iconPosition;
  final bool loading;
  final bool disabled;
  final VoidCallback onPressed;
  final EdgeInsets? padding;
  final TextStyle? textStyle;
  final double? elevation;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final BorderSide? borderSide;
  final BorderRadius? borderRadius;

  const MainButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.iconPosition = IconPosition.left,
    this.loading = false,
    this.disabled = false,
    this.padding,
    this.textStyle,
    this.elevation,
    this.backgroundColor,
    this.foregroundColor,
    this.borderSide,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final resolvedBackgroundColor = backgroundColor ?? _backgroundColor(isDark);
    final resolvedForegroundColor = foregroundColor ?? _textColor(isDark);
    final buttonPadding = padding ?? _sizePadding();
    final resolvedBorderRadius = borderRadius ?? BorderRadius.circular(16);
    final resolvedShape = RoundedRectangleBorder(
      borderRadius: resolvedBorderRadius,
      side: borderSide ?? BorderSide.none,
    );

    return AnimatedOpacity(
      opacity: disabled ? 0.5 : 1,
      duration: const Duration(microseconds: 100),
      child: Material(
        color: resolvedBackgroundColor,
        shape: resolvedShape,
        elevation: elevation ?? 0.3,
        shadowColor: Colors.black,
        child: InkWell(
          customBorder: resolvedShape,
          onTap: disabled || loading
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  onPressed();
                },
          child: Padding(
            padding: buttonPadding,
            child: Center(
              child: loading
                  ? SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: resolvedForegroundColor,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: _buildContent(resolvedForegroundColor),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // --- helpers ---

  List<Widget> _buildContent(Color color) {
    final children = <Widget>[];

    if (icon != null && iconPosition == IconPosition.left) {
      children.add(
        Padding(padding: const EdgeInsets.only(right: 6), child: icon!),
      );
    }

    children.add(
      DefaultTextStyle.merge(
        style: TextStyle(color: color).merge(textStyle),
        child: title,
      ),
    );

    if (icon != null && iconPosition == IconPosition.right) {
      children.add(
        Padding(padding: const EdgeInsets.only(left: 6), child: icon!),
      );
    }

    return children;
  }

  EdgeInsets _sizePadding() {
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(vertical: 2, horizontal: 12);
      case ButtonSize.large:
        return const EdgeInsets.symmetric(vertical: 14, horizontal: 20);
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(vertical: 10, horizontal: 16);
    }
  }

  Color _backgroundColor(bool isDark) {
    switch (variant) {
      case ButtonVariant.secondary:
        return isDark ? BaseColors.black600 : BaseColors.baseBg;
      case ButtonVariant.tertiary:
        return isDark ? BaseColors.black800 : BaseColors.white;
      case ButtonVariant.primary:
        return BaseColors.primary; // baseColors.primary
    }
  }

  Color _textColor(bool isDark) {
    switch (variant) {
      case ButtonVariant.primary:
        return BaseColors.white;
      case ButtonVariant.secondary:
      case ButtonVariant.tertiary:
        return !isDark ? BaseColors.black800 : BaseColors.white;
    }
  }
}
