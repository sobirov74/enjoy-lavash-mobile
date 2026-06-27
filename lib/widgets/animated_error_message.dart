import 'dart:math' as math;

import 'package:enjoy_lavash_mobile/core/error/failures.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'package:enjoy_lavash_mobile/widgets/typography.dart';
import 'package:flutter/material.dart';

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

class _AnimatedErrorMessageState extends State<AnimatedErrorMessage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
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
      TimeoutFailure() => _errorText(
        t,
        en: 'Slow network',
        ru: 'Медленная сеть',
        uz: 'Internet sekin',
      ),
      NetworkFailure() => _errorText(
        t,
        en: 'Connection problem',
        ru: 'Проблема с подключением',
        uz: 'Ulanishda muammo',
      ),
      ServerFailure() => _errorText(
        t,
        en: 'Backend error',
        ru: 'Ошибка сервера',
        uz: 'Server xatosi',
      ),
      AuthFailure() => _errorText(
        t,
        en: 'Authorization expired',
        ru: 'Авторизация истекла',
        uz: 'Avtorizatsiya muddati tugadi',
      ),
      _ => _errorText(
        t,
        en: 'Something went wrong',
        ru: 'Что-то пошло не так',
        uz: "Nimadir noto'g'ri ketdi",
      ),
    };
  }

  String _body(L t) {
    final provided = widget.message?.trim();
    if (provided?.isNotEmpty == true) return provided!;

    final failureMessage = widget.failure?.message.trim();
    if (failureMessage?.isNotEmpty == true) return failureMessage!;

    return _errorText(
      t,
      en: 'Please try again in a moment.',
      ru: 'Попробуйте еще раз через несколько секунд.',
      uz: "Birozdan keyin qayta urinib ko'ring.",
    );
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

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = Curves.easeInOut.transform(_controller.value);
        final pulseScale = 1 + value * 0.18;
        final pulseOpacity = 0.08 + (1 - value) * 0.12;

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
          child: widget.compact
              ? _buildCompact(t, pulseColor, pulseScale, pulseOpacity)
              : _buildFull(t, pulseColor, pulseScale, pulseOpacity),
        );
      },
    );
  }

  Widget _buildFull(
    L t,
    Color pulseColor,
    double pulseScale,
    double pulseOpacity,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _AnimatedErrorIcon(
          icon: _icon,
          color: pulseColor,
          pulseScale: pulseScale,
          pulseOpacity: pulseOpacity,
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
            label: TypographyText(
              _errorText(t, en: 'Retry', ru: 'Повторить', uz: 'Qayta urinish'),
            ),
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

  Widget _buildCompact(
    L t,
    Color pulseColor,
    double pulseScale,
    double pulseOpacity,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _AnimatedErrorIcon(
          icon: _icon,
          color: pulseColor,
          pulseScale: pulseScale,
          pulseOpacity: pulseOpacity,
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
                  label: TypographyText(
                    _errorText(
                      t,
                      en: 'Retry',
                      ru: 'Повторить',
                      uz: 'Qayta urinish',
                    ),
                  ),
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
    required this.pulseScale,
    required this.pulseOpacity,
    required this.size,
  });

  final IconData icon;
  final Color color;
  final double pulseScale;
  final double pulseOpacity;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Transform.scale(
            scale: pulseScale,
            child: Container(
              decoration: BoxDecoration(
                color: color.withValues(alpha: pulseOpacity),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Transform.rotate(
            angle: math.sin(pulseScale * math.pi) * 0.04,
            child: Container(
              width: size * 0.72,
              height: size * 0.72,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: size * 0.38),
            ),
          ),
        ],
      ),
    );
  }
}

String _errorText(
  L t, {
  required String en,
  required String ru,
  required String uz,
}) {
  return switch (t.localeName.split('_').first) {
    'ru' => ru,
    'uz' => uz,
    _ => en,
  };
}
