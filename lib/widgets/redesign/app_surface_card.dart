import 'package:enjoy_lavash_mobile/theme/app_design_tokens.dart';
import 'package:flutter/material.dart';

class AppSurfaceCard extends StatelessWidget {
  const AppSurfaceCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(16),
    this.radius = AppDesignTokens.radiusCard,
    this.color,
    this.onTap,
    this.clipBehavior = Clip.none,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final VoidCallback? onTap;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: color ?? AppDesignTokens.surface(context),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: AppDesignTokens.cardShadow(context),
    );

    if (onTap == null) {
      return Container(
        padding: padding,
        clipBehavior: clipBehavior,
        decoration: decoration,
        child: child,
      );
    }

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: decoration,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
