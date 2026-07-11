import 'dart:async';

import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/cart_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/order_model.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/navigation/main_tabs.dart';
import 'package:enjoy_lavash_mobile/theme/dark_theme.dart';
import 'package:enjoy_lavash_mobile/theme/light_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows order content and CTA immediately with reduced motion', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var trackOrderCalls = 0;

    await tester.pumpWidget(
      _testApp(
        OrderSuccessScreen(
          order: _order(paymentMethod: MobilePaymentMethod.cash),
          onTrackOrder: () => trackOrderCalls += 1,
        ),
      ),
    );

    expect(find.text("We've got your order!"), findsOneWidget);
    expect(find.text('Order #90ABCDEF'), findsOneWidget);
    expect(find.text('Pay when you receive your order.'), findsOneWidget);
    expect(find.text('Track order'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('order-success-track-button')),
      findsOneWidget,
    );
    expect(tester.hasRunningAnimations, isFalse);

    await tester.tap(find.text('Track order'));
    await tester.pump();
    expect(trackOrderCalls, 1);
  });

  testWidgets('opens online payment after first frame and reports the result', (
    tester,
  ) async {
    final paymentResult = Completer<bool>();
    var paymentOpenCalls = 0;

    await tester.pumpWidget(
      _testApp(
        OrderSuccessScreen(
          order: _order(
            paymentMethod: MobilePaymentMethod.payme,
            paymentStatus: MobilePaymentStatus.pending,
          ),
          onTrackOrder: () {},
          openPaymentPage: () {
            paymentOpenCalls += 1;
            return paymentResult.future;
          },
        ),
      ),
    );

    expect(find.text("We've got your order!"), findsOneWidget);
    expect(find.text('Track order'), findsOneWidget);
    expect(find.text('Opening the secure payment page…'), findsOneWidget);
    expect(paymentOpenCalls, 1);

    paymentResult.complete(true);
    await tester.pump();

    expect(
      find.text('Complete payment in the page we opened.'),
      findsOneWidget,
    );
    expect(paymentOpenCalls, 1);
  });

  testWidgets('Track order dismisses a pushed success route and calls back', (
    tester,
  ) async {
    var trackOrderCalls = 0;

    await tester.pumpWidget(
      _testApp(
        Builder(
          builder: (context) {
            return Center(
              child: FilledButton(
                onPressed: () {
                  unawaited(
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => OrderSuccessScreen(
                          order: _order(
                            paymentMethod: MobilePaymentMethod.cash,
                          ),
                          onTrackOrder: () => trackOrderCalls += 1,
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('Open success'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open success'));
    await tester.pumpAndSettle();
    expect(find.text('Track order'), findsOneWidget);

    await tester.tap(find.text('Track order'));
    await tester.pumpAndSettle();

    expect(trackOrderCalls, 1);
    expect(find.text('Open success'), findsOneWidget);
    expect(find.text('Track order'), findsNothing);
  });

  testWidgets('keeps Track order reachable at 320px with large dark text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _testApp(
        OrderSuccessScreen(
          order: _order(paymentMethod: MobilePaymentMethod.cash),
          onTrackOrder: () {},
        ),
        dark: true,
        size: const Size(320, 568),
        textScaler: const TextScaler.linear(1.45),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    final trackButton = find.byKey(
      const ValueKey<String>('order-success-track-button'),
    );
    expect(trackButton, findsOneWidget);
    expect(tester.getRect(trackButton).bottom, lessThanOrEqualTo(568));
  });
}

Widget _testApp(
  Widget child, {
  bool dark = false,
  Size size = const Size(390, 844),
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return MaterialApp(
    theme: lightTheme,
    darkTheme: darkTheme,
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    locale: const Locale('en'),
    localizationsDelegates: L.localizationsDelegates,
    supportedLocales: L.supportedLocales,
    home: MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: textScaler,
        disableAnimations: true,
      ),
      child: child,
    ),
  );
}

CustomerOrderModel _order({
  required MobilePaymentMethod paymentMethod,
  MobilePaymentStatus? paymentStatus,
}) {
  return CustomerOrderModel(
    id: '12345678-90abcdef',
    type: MobileOrderType.delivery,
    status: MobileOrderStatus.newOrder,
    totalAmount: 56000,
    paymentMethod: paymentMethod,
    paymentStatus: paymentStatus,
    items: const <CustomerOrderItemModel>[],
    statusLog: const <OrderStatusLogModel>[],
  );
}
