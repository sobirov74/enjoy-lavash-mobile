import 'dart:math' as math;

import 'package:enjoy_lavash_mobile/theme/app_design_tokens.dart';
import 'package:enjoy_lavash_mobile/theme/app_motion.dart';
import 'package:flutter/material.dart';

/// The child/badge always comes from real cart state, never from the effect.
///
/// A landing parcel has weight: the icon takes it with a short dip, springs
/// back past rest and settles, while a soft ring spreads out from the impact.
/// Reduced motion keeps only the brief tint pulse.
class CartArrivalFeedback extends StatelessWidget {
  const CartArrivalFeedback({
    required this.revision,
    required this.child,
    super.key,
  });

  final int revision;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    return TweenAnimationBuilder<double>(
      key: ValueKey<int>(revision),
      tween: Tween(begin: revision == 0 ? 1 : 0, end: 1),
      duration: Duration(milliseconds: reduced ? 140 : 460),
      child: child,
      builder: (context, value, child) {
        final glow = math.sin(value * math.pi);
        // Damped spring: one overshoot, one undershoot, then rest.
        final spring = reduced
            ? 0.0
            : math.exp(-3 * value) *
                  (1 - value) *
                  math.sin(2 * math.pi * 1.25 * value);
        final ring = reduced ? 0.0 : Curves.easeOutCubic.transform(value);
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (ring > 0 && ring < 1)
              Positioned.fill(
                child: IgnorePointer(
                  child: Transform.scale(
                    scale: 1 + 1.1 * ring,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppDesignTokens.action.withValues(
                            alpha: .42 * math.pow(1 - ring, 1.4),
                          ),
                          width: 1.6,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppDesignTokens.action.withValues(alpha: glow * 0.16),
              ),
              child: Transform.translate(
                offset: Offset(0, 4 * spring),
                child: Transform.scale(scale: 1 + .4 * spring, child: child),
              ),
            ),
          ],
        );
      },
    );
  }
}
