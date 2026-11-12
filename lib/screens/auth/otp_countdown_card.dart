part of 'package:enjoy_lavash_mobile/screens/authorization_screen.dart';

/// Vertical OTP timing surface that keeps the countdown and resend action
/// readable without making either one compete for horizontal space.
class OtpCountdownCard extends StatelessWidget {
  const OtpCountdownCard({
    super.key,
    required this.title,
    required this.countdown,
    required this.semanticLabel,
    required this.expiredMessage,
    required this.resendLabel,
    required this.progress,
    required this.isExpired,
    required this.isDark,
    required this.onResend,
  });

  final String title;
  final String countdown;
  final String semanticLabel;
  final String expiredMessage;
  final String resendLabel;
  final double progress;
  final bool isExpired;
  final bool isDark;
  final VoidCallback? onResend;

  @override
  Widget build(BuildContext context) {
    final accent = isExpired ? BaseColors.danger : BaseColors.primary;
    final surface = AppDesignTokens.surface(context);
    final muted = isDark ? const Color(0xFFAAA39A) : BaseColors.textGray;
    final duration = AppMotion.duration(context, AppMotion.micro);

    return AnimatedContainer(
      key: const ValueKey<String>('otp-countdown-card'),
      duration: AppMotion.duration(context, AppMotion.state),
      curve: AppMotion.standard,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.05),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            container: true,
            label: semanticLabel,
            child: ExcludeSemantics(
              child: Row(
                children: <Widget>[
                  AnimatedContainer(
                    duration: AppMotion.duration(context, AppMotion.state),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: isDark ? 0.18 : 0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      isExpired
                          ? Icons.timer_off_outlined
                          : Icons.timer_outlined,
                      color: accent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        TypographyText(
                          isExpired ? expiredMessage : title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isExpired ? BaseColors.danger : muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        AnimatedSwitcher(
                          duration: duration,
                          switchInCurve: AppMotion.enter,
                          switchOutCurve: AppMotion.exit,
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.18),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              ),
                          child: TypographyText(
                            countdown,
                            key: ValueKey<String>(countdown),
                            style: TextStyle(
                              color: accent,
                              fontSize: 27,
                              height: 1,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              fontFeatures: const <FontFeature>[
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          ExcludeSemantics(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 5,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    ColoredBox(color: accent.withValues(alpha: 0.12)),
                    TweenAnimationBuilder<double>(
                      duration: duration,
                      curve: AppMotion.standard,
                      tween: Tween<double>(
                        begin: 0,
                        end: progress.clamp(0.0, 1.0),
                      ),
                      builder: (context, value, child) => Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: value,
                          heightFactor: 1,
                          child: child,
                        ),
                      ),
                      child: ColoredBox(color: accent),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              key: const ValueKey<String>('otp-resend-button'),
              style: TextButton.styleFrom(
                foregroundColor: BaseColors.primary,
                backgroundColor: BaseColors.primary.withValues(
                  alpha: isDark ? 0.14 : 0.08,
                ),
                disabledForegroundColor: muted,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: onResend,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: TypographyText(
                resendLabel,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
