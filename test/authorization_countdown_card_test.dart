import 'package:enjoy_lavash_mobile/screens/authorization_screen.dart';
import 'package:enjoy_lavash_mobile/theme/light_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('OTP countdown is a vertical, large-text-safe action card', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var resendCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 568),
            textScaler: TextScaler.linear(1.4),
            disableAnimations: true,
          ),
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: OtpCountdownCard(
                title: 'SMS code',
                countdown: '01:42',
                semanticLabel: 'Code expires in 01:42',
                expiredMessage: 'Code expired',
                resendLabel: 'Resend code',
                progress: 0.75,
                isExpired: false,
                isDark: false,
                onResend: () => resendCalls += 1,
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('01:42'), findsOneWidget);
    expect(find.byType(Column), findsWidgets);

    final cardRect = tester.getRect(
      find.byKey(const ValueKey<String>('otp-countdown-card')),
    );
    final resendButton = find.byKey(
      const ValueKey<String>('otp-resend-button'),
    );
    final buttonRect = tester.getRect(resendButton);
    expect(buttonRect.height, greaterThanOrEqualTo(48));
    expect(buttonRect.width, greaterThan(cardRect.width * 0.8));

    await tester.tap(resendButton);
    expect(resendCalls, 1);
  });
}
