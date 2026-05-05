import 'package:flutter/material.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';

class WhiteContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadiusGeometry? borderRadius;
  final Color? backgroundColor;

  const WhiteContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: margin ?? const EdgeInsets.only(top: 12, bottom: 12),
      padding: padding ?? const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            (isDark ? BaseColors.black800 : BaseColors.white),
        borderRadius: borderRadius ?? BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}
