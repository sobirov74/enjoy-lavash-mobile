import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'package:enjoy_lavash_mobile/theme/app_motion.dart';
import 'package:enjoy_lavash_mobile/widgets/typography.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Quantity label that pops with a scale + fade whenever the value changes.
class AnimatedQuantityText extends StatelessWidget {
  const AnimatedQuantityText({super.key, required this.quantity});

  final int quantity;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.duration(context, AppMotion.micro),
      switchInCurve: AppMotion.enter,
      switchOutCurve: AppMotion.exit,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.7, end: 1).animate(animation),
          child: child,
        ),
      ),
      child: TypographyText(
        '$quantity',
        key: ValueKey<int>(quantity),
        textAlign: TextAlign.center,
        maxLines: 1,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
      ),
    );
  }
}

class QuantityButton extends StatelessWidget {
  const QuantityButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.emphasized = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final tooltip = emphasized || icon == Icons.add_rounded
        ? L.of(context).increaseQuantity
        : L.of(context).decreaseQuantity;

    return Material(
      color: emphasized
          ? BaseColors.primary
          : Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF332D28)
          : const Color(0xFFF3F0EB),
      borderRadius: BorderRadius.circular(14),
      child: Tooltip(
        message: tooltip,
        child: Semantics(
          button: true,
          label: tooltip,
          excludeSemantics: true,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(
                icon,
                size: 19,
                color: emphasized
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
