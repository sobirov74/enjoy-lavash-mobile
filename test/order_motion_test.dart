import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/cart_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/order_model.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/navigation/main_tabs.dart';
import 'package:enjoy_lavash_mobile/screens/profile.dart';
import 'package:enjoy_lavash_mobile/theme/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrderTypeSlidingToggle', () {
    testWidgets('slides one shared surface without moving its hit targets', (
      tester,
    ) async {
      final orderType = ValueNotifier<MobileOrderType>(
        MobileOrderType.delivery,
      );
      addTearDown(orderType.dispose);
      var pickupTaps = 0;

      await tester.pumpWidget(
        _motionHost(
          child: ValueListenableBuilder<MobileOrderType>(
            valueListenable: orderType,
            builder: (context, value, _) {
              return OrderTypeSlidingToggle(
                orderType: value,
                deliverySubtitle: 'Chilonzor 12',
                pickupSubtitle: 'Enjoy Chilonzor',
                onDeliveryTap: () => orderType.value = MobileOrderType.delivery,
                onPickupTap: () {
                  pickupTaps += 1;
                  orderType.value = MobileOrderType.pickup;
                },
              );
            },
          ),
        ),
      );

      const deliveryKey = ValueKey<String>('order-type-delivery-target');
      const pickupKey = ValueKey<String>('order-type-pickup-target');
      const surfaceKey = ValueKey<String>('order-type-selection-surface');
      final deliveryRectBefore = tester.getRect(find.byKey(deliveryKey));
      final pickupRectBefore = tester.getRect(find.byKey(pickupKey));
      final initialSurface = tester.widget<AnimatedAlign>(
        find.byKey(surfaceKey),
      );

      expect(initialSurface.alignment, Alignment.centerLeft);
      expect(initialSurface.duration, AppMotion.state);
      expect(deliveryRectBefore.height, greaterThanOrEqualTo(48));
      expect(pickupRectBefore.height, greaterThanOrEqualTo(48));

      await tester.tap(find.byKey(pickupKey));
      await tester.pump();

      final selectedSurface = tester.widget<AnimatedAlign>(
        find.byKey(surfaceKey),
      );
      expect(pickupTaps, 1);
      expect(selectedSurface.alignment, Alignment.centerRight);
      expect(tester.getRect(find.byKey(deliveryKey)), deliveryRectBefore);
      expect(tester.getRect(find.byKey(pickupKey)), pickupRectBefore);

      await tester.pump(AppMotion.state);
      expect(tester.takeException(), isNull);
    });

    testWidgets('uses instant surface and content changes for reduced motion', (
      tester,
    ) async {
      final orderType = ValueNotifier<MobileOrderType>(
        MobileOrderType.delivery,
      );
      addTearDown(orderType.dispose);

      await tester.pumpWidget(
        _motionHost(
          disableAnimations: true,
          child: ValueListenableBuilder<MobileOrderType>(
            valueListenable: orderType,
            builder: (context, value, _) {
              return OrderTypeSlidingToggle(
                orderType: value,
                onDeliveryTap: () => orderType.value = MobileOrderType.delivery,
                onPickupTap: () => orderType.value = MobileOrderType.pickup,
              );
            },
          ),
        ),
      );

      orderType.value = MobileOrderType.pickup;
      await tester.pump();

      final surface = tester.widget<AnimatedAlign>(
        find.byKey(const ValueKey<String>('order-type-selection-surface')),
      );
      expect(surface.alignment, Alignment.centerRight);
      expect(surface.duration, Duration.zero);
      for (final switcher in tester.widgetList<AnimatedSwitcher>(
        find.byType(AnimatedSwitcher),
      )) {
        expect(switcher.duration, Duration.zero);
      }
    });

    testWidgets('keeps both targets usable at 320px with large text', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _motionHost(
          width: 288,
          textScaler: const TextScaler.linear(1.45),
          child: OrderTypeSlidingToggle(
            orderType: MobileOrderType.delivery,
            deliverySubtitle: 'Very long delivery address',
            pickupSubtitle: 'Very long pickup branch name',
            onDeliveryTap: () {},
            onPickupTap: () {},
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester
            .getRect(
              find.byKey(const ValueKey<String>('order-type-delivery-target')),
            )
            .height,
        greaterThanOrEqualTo(48),
      );
      expect(
        tester
            .getRect(
              find.byKey(const ValueKey<String>('order-type-pickup-target')),
            )
            .height,
        greaterThanOrEqualTo(48),
      );
    });
  });

  group('OrderProgressJourney', () {
    testWidgets('animates to the reported status and no further', (
      tester,
    ) async {
      final status = ValueNotifier<MobileOrderStatus>(
        MobileOrderStatus.newOrder,
      );
      addTearDown(status.dispose);

      await tester.pumpWidget(
        _motionHost(
          child: ValueListenableBuilder<MobileOrderStatus>(
            valueListenable: status,
            builder: (context, value, _) {
              return OrderProgressJourney(
                orderType: MobileOrderType.delivery,
                status: value,
              );
            },
          ),
        ),
      );

      expect(_segmentFill(tester, 0), 0);
      status.value = MobileOrderStatus.cooking;
      await tester.pump();
      expect(_segmentFill(tester, 2), 0);

      await tester.pump(AppMotion.spatial ~/ 2);
      expect(_segmentFill(tester, 2), 0);

      await tester.pump(AppMotion.spatial);
      expect(_segmentFill(tester, 0), 1);
      expect(_segmentFill(tester, 1), 1);
      expect(_segmentFill(tester, 2), 0);

      await tester.pump(const Duration(seconds: 2));
      expect(_segmentFill(tester, 0), 1);
      expect(_segmentFill(tester, 1), 1);
      expect(_segmentFill(tester, 2), 0);
    });

    testWidgets('jumps directly to real status for reduced motion', (
      tester,
    ) async {
      final status = ValueNotifier<MobileOrderStatus>(
        MobileOrderStatus.newOrder,
      );
      addTearDown(status.dispose);

      await tester.pumpWidget(
        _motionHost(
          accessibleNavigation: true,
          child: ValueListenableBuilder<MobileOrderStatus>(
            valueListenable: status,
            builder: (context, value, _) {
              return OrderProgressJourney(
                orderType: MobileOrderType.delivery,
                status: value,
              );
            },
          ),
        ),
      );

      status.value = MobileOrderStatus.onTheWay;
      await tester.pump();

      for (var index = 0; index < 5; index++) {
        expect(_segmentFill(tester, index), 1);
      }
      expect(_segmentFill(tester, 5), 0);
    });

    testWidgets('does not invent a journey for a cancelled order', (
      tester,
    ) async {
      await tester.pumpWidget(
        _motionHost(
          child: const OrderProgressJourney(
            orderType: MobileOrderType.delivery,
            status: MobileOrderStatus.cancelled,
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey<String>('order-progress-journey')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('order-progress-segment-0-fill')),
        findsNothing,
      );
    });
  });
}

double _segmentFill(WidgetTester tester, int index) {
  return tester
      .widget<FractionallySizedBox>(
        find.byKey(ValueKey<String>('order-progress-segment-$index-fill')),
      )
      .widthFactor!;
}

Widget _motionHost({
  required Widget child,
  bool disableAnimations = false,
  bool accessibleNavigation = false,
  double width = 358,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: L.localizationsDelegates,
    supportedLocales: L.supportedLocales,
    home: MediaQuery(
      data: MediaQueryData(
        size: const Size(390, 844),
        textScaler: textScaler,
        disableAnimations: disableAnimations,
        accessibleNavigation: accessibleNavigation,
      ),
      child: Scaffold(
        body: Center(
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  );
}
