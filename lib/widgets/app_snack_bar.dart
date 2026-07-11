import 'dart:async';

import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'package:enjoy_lavash_mobile/theme/app_motion.dart';
import 'package:enjoy_lavash_mobile/widgets/typography.dart';
import 'package:flutter/material.dart';

SnackBar appSnackBar(
  String message, {
  Duration duration = const Duration(seconds: 3),
  String? actionLabel,
  VoidCallback? onAction,
  bool showCountdown = false,
  bool? isDark,
}) {
  final palette = _AppSnackBarPalette.resolve(isDark);

  return SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: palette.background,
    duration: duration,
    dismissDirection: DismissDirection.horizontal,
    elevation: 12,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: palette.border),
    ),
    action: actionLabel == null || onAction == null
        ? null
        : SnackBarAction(
            label: actionLabel,
            textColor: palette.action,
            onPressed: onAction,
          ),
    content: _AppSnackBarContent(
      message: message,
      duration: duration,
      showCountdown: showCountdown,
      foreground: palette.foreground,
      progressTrack: palette.progressTrack,
      progress: palette.progress,
    ),
  );
}

/// Shows an action snack bar that closes after [duration] even when platform
/// accessibility settings would normally keep action snack bars on screen.
/// The visible countdown makes the time limit predictable.
ScaffoldFeatureController<SnackBar, SnackBarClosedReason>
showAutoClosingAppSnackBar(
  ScaffoldMessengerState messenger,
  String message, {
  Duration duration = const Duration(seconds: 5),
  required String actionLabel,
  required VoidCallback onAction,
}) {
  final isDark = Theme.of(messenger.context).brightness == Brightness.dark;
  messenger.hideCurrentSnackBar();
  final controller = messenger.showSnackBar(
    appSnackBar(
      message,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
      showCountdown: true,
      isDark: isDark,
    ),
  );
  final timer = Timer(duration, controller.close);
  unawaited(controller.closed.whenComplete(timer.cancel));
  return controller;
}

class _AppSnackBarPalette {
  const _AppSnackBarPalette({
    required this.background,
    required this.foreground,
    required this.action,
    required this.border,
    required this.progressTrack,
    required this.progress,
  });

  final Color background;
  final Color foreground;
  final Color action;
  final Color border;
  final Color progressTrack;
  final Color progress;

  static _AppSnackBarPalette resolve(bool? isDark) {
    if (isDark == false) {
      return _AppSnackBarPalette(
        background: Colors.white,
        foreground: const Color(0xFF211D1A),
        action: BaseColors.primaryDark,
        border: BaseColors.primary.withValues(alpha: 0.18),
        progressTrack: BaseColors.primary.withValues(alpha: 0.12),
        progress: BaseColors.primary,
      );
    }

    return _AppSnackBarPalette(
      background: BaseColors.black800,
      foreground: Colors.white,
      action: BaseColors.primary,
      border: Colors.white.withValues(alpha: 0.08),
      progressTrack: Colors.white.withValues(alpha: 0.16),
      progress: BaseColors.primary,
    );
  }
}

class _AppSnackBarContent extends StatelessWidget {
  const _AppSnackBarContent({
    required this.message,
    required this.duration,
    required this.showCountdown,
    required this.foreground,
    required this.progressTrack,
    required this.progress,
  });

  final String message;
  final Duration duration;
  final bool showCountdown;
  final Color foreground;
  final Color progressTrack;
  final Color progress;

  @override
  Widget build(BuildContext context) {
    final showProgress = showCountdown && !AppMotion.reduced(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TypographyText(
          message,
          style: TextStyle(color: foreground, fontWeight: FontWeight.w700),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        if (showProgress) ...<Widget>[
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 3,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  ColoredBox(color: progressTrack),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 1, end: 0),
                    duration: duration,
                    curve: Curves.linear,
                    builder: (context, value, child) => Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: value,
                        heightFactor: 1,
                        child: child,
                      ),
                    ),
                    child: ColoredBox(color: progress),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
