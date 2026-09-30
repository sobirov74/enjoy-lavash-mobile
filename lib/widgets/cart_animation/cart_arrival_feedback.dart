import 'dart:math' as math;

import 'package:enjoy_lavash_mobile/theme/app_design_tokens.dart';
import 'package:enjoy_lavash_mobile/theme/app_motion.dart';
import 'package:flutter/material.dart';

/// The child/badge always comes from real cart state, never from the effect.
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
      duration: const Duration(milliseconds: 140),
      child: child,
      builder: (context, value, child) {
        final strength = math.sin(value * math.pi);
        return DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppDesignTokens.action.withValues(alpha: strength * 0.16),
          ),
          child: Transform.scale(
            scale: reduced ? 1 : 1 + strength * 0.08,
            child: child,
          ),
        );
      },
    );
  }
}
