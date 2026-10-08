import 'dart:math' as math;

import 'package:enjoy_lavash_mobile/core/error/failures.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'package:enjoy_lavash_mobile/widgets/typography.dart';
import 'package:flutter/material.dart';
import 'package:enjoy_lavash_mobile/widgets/utils/failure_message.dart';

class AnimatedErrorMessage extends StatefulWidget {
  const AnimatedErrorMessage({
    super.key,
    this.failure,
    this.message,
    this.onRetry,
    this.compact = false,
  });

  final Failure? failure;
  final String? message;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  State<AnimatedErrorMessage> createState() => _AnimatedErrorMessageState();
}

const int _pulseCycles = 6;

class _AnimatedErrorMessageState extends State<AnimatedErrorMessage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // A few attention pulses, then still: an error card on a kept-alive tab
    // must not keep forcing frames for as long as it is shown.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true, count: _pulseCycles);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData get _icon {
    return switch (widget.failure) {
      TimeoutFailure() => Icons.wifi_tethering_error_rounded,
      NetworkFailure() => Icons.wifi_off_rounded,
      ServerFailure() => Icons.cloud_off_rounded,
      AuthFailure() => Icons.lock_outline_rounded,
      _ => Icons.error_outline_rounded,
    };
  }

  String _title(L t) {
    return switch (widget.failure) {
      TimeoutFailure() => t.errorSlowNetwork,
      NetworkFailure() => t.errorConnectionProblem,
      ServerFailure() => t.errorBackend,
      AuthFailure() => t.errorAuthorizationExpired,
      _ => t.errorGenericTitle,
    };
  }

  String _body(L t) {
    final provided = widget.message?.trim();
    if (provided?.isNotEmpty == true) return provided!;

    final failure = widget.failure;
    if (failure != null) return failureDetail(t, failure);

    return t.errorGenericBody;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = L.of(context);
    final cardColor = isDark ? const Color(0xFF1D1A18) : Colors.white;
    final pulseColor = switch (widget.failure) {
      TimeoutFailure() => const Color(0xFFF59E0B),
      NetworkFailure() => const Color(0xFF3B82F6),
      ServerFailure() => BaseColors.danger,
      _ => BaseColors.primary,
    };

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(widget.compact ? 14 : 18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(widget.compact ? 18 : 24),
        border: Border.all(
          color: pulseColor.withValues(alpha: isDark ? 0.28 : 0.18),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.06),
            blurRadius: widget.compact ? 18 : 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      // Text and buttons are built once; only the icon listens to the pulse.
      child: widget.compact
          ? _buildCompact(t, pulseColor)
          : _buildFull(t, pulseColor),
    );
  }

  Widget _buildFull(L t, Color pulseColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _AnimatedErrorIcon(
          icon: _icon,
          color: pulseColor,
          pulse: _controller,
          size: 76,
        ),
        const SizedBox(height: 16),
        TypographyText(
          _title(t),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        TypographyText(
          _body(t),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: BaseColors.textGray,
            fontSize: 14,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (widget.onRetry != null) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: widget.onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: TypographyText(t.retry),
            style: FilledButton.styleFrom(
              backgroundColor: BaseColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompact(L t, Color pulseColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _AnimatedErrorIcon(
          icon: _icon,
          color: pulseColor,
          pulse: _controller,
          size: 48,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TypographyText(
                _title(t),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              TypographyText(
                _body(t),
                style: const TextStyle(
                  color: BaseColors.textGray,
                  fontSize: 13,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (widget.onRetry != null) ...[
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: widget.onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: TypographyText(t.retry),
                  style: TextButton.styleFrom(
                    foregroundColor: BaseColors.primary,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AnimatedErrorIcon extends StatelessWidget {
  const _AnimatedErrorIcon({
    required this.icon,
    required this.color,
    required this.pulse,
    required this.size,
  });

  final IconData icon;
  final Color color;
  final Animation<double> pulse;
  final double size;

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      width: size * 0.72,
      height: size * 0.72,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: size * 0.38),
    );
    return SizedBox(
      width: size,
      height: size,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: pulse,
          child: badge,
          builder: (context, badge) {
            final value = Curves.easeInOut.transform(pulse.value);
            final pulseScale = 1 + value * 0.18;
            final pulseOpacity = 0.08 + (1 - value) * 0.12;
            return Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Transform.scale(
                  scale: pulseScale,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: pulseOpacity),
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
                Transform.rotate(
                  angle: math.sin(pulseScale * math.pi) * 0.04,
                  child: badge,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
