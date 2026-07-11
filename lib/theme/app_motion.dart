import 'package:flutter/material.dart';

/// Shared timing, easing, and accessibility policy for app motion.
abstract final class AppMotion {
  /// Small feedback such as icon, count, and color changes.
  static const Duration micro = Duration(milliseconds: 140);

  /// A local component changing between two UI states.
  static const Duration state = Duration(milliseconds: 220);

  /// Motion that travels across or reveals a meaningful part of the screen.
  static const Duration spatial = Duration(milliseconds: 380);

  /// A short, one-time success or brand moment.
  static const Duration celebration = Duration(milliseconds: 650);

  /// Balanced easing for a value moving between two visible states.
  static const Curve standard = Curves.easeInOutCubic;

  /// Decelerating easing for content entering or becoming visible.
  static const Curve enter = Curves.easeOutCubic;

  /// Accelerating easing for content leaving or becoming hidden.
  static const Curve exit = Curves.easeInCubic;

  /// Whether non-essential motion should be removed for this context.
  ///
  /// Both platform animation suppression and accessible navigation request a
  /// stable UI. A missing [MediaQuery] is treated as the normal-motion case so
  /// this helper remains safe in isolated widgets and tests.
  static bool reduced(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    return mediaQuery?.disableAnimations == true ||
        mediaQuery?.accessibleNavigation == true;
  }

  /// Returns [normal] unless the user has requested reduced motion.
  static Duration duration(BuildContext context, Duration normal) {
    return reduced(context) ? Duration.zero : normal;
  }
}
