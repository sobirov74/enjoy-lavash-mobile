import 'dart:async';

import 'package:enjoy_lavash_mobile/app/location_controller.dart';
import 'package:enjoy_lavash_mobile/core/services/yandex_geocoder_service.dart';
import 'package:enjoy_lavash_mobile/features/models/cart_line.dart';
import 'package:enjoy_lavash_mobile/features/models/menu_product.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/cart_model.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/screens/menu_screen.dart';
import 'package:enjoy_lavash_mobile/theme/light_theme.dart';
import 'package:enjoy_lavash_mobile/widgets/product_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('rejected configured add stays open and retries once', (
    tester,
  ) async {
    final pending = Completer<void>();
    final attempts = <CartSelection>[];
    await _openDetail(
      tester,
      onConfiguredAdd: (selection) async {
        attempts.add(selection);
        if (attempts.length == 1) await pending.future;
      },
    );
    await tester.ensureVisible(find.text('Cheese'));
    await tester.tap(find.text('Cheese'));
    final detailScroll = tester.state<ScrollableState>(
      find.descendant(of: _detail, matching: find.byType(Scrollable)).first,
    );
    final scrollOffset = detailScroll.position.pixels;

    await tester.tap(find.textContaining('Add ·'));
    await tester.pump();
    expect(attempts, hasLength(1));
    _expectNoSuccess();

    pending.completeError(StateError('Rejected by cart service'));
    await tester.pumpAndSettle();
    expect(_detail, findsOneWidget);
    expect(detailScroll.position.pixels, scrollOffset);
    _expectNoSuccess();
    expect(find.text('Please try again in a moment.'), findsWidgets);

    // Use a real hit-tested tap: Retry must remain above the detail add bar.
    final retry = find.widgetWithText(SnackBarAction, 'Retry').hitTestable();
    expect(retry, findsOneWidget);
    await tester.tap(retry);
    await tester.pumpAndSettle();

    expect(attempts, hasLength(2));
    expect(attempts.last.key, attempts.first.key);
    expect(attempts.last.quantity, attempts.first.quantity);
    expect(
      attempts.last.modifiers.map((modifier) => modifier.modifierId),
      contains('cheese'),
    );
    expect(_detail, findsOneWidget);
    expect(detailScroll.position.pixels, scrollOffset);
    expect(find.text('Classic lavash added to cart'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('legacy partial add retries only uncommitted units', (
    tester,
  ) async {
    var attempts = 0;
    var committed = 0;
    await _openDetail(
      tester,
      onAdd: (_) async {
        attempts++;
        if (attempts == 2) throw StateError('Second unit rejected');
        committed++;
      },
    );
    final increase = find.descendant(
      of: _detail,
      matching: find.byIcon(Icons.add_rounded),
    );
    await tester.tap(increase);
    await tester.pump();
    await tester.tap(increase);
    await tester.pump();
    await tester.tap(find.textContaining('Add ·'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(committed, 1);
    expect(_detail, findsOneWidget);
    _expectNoSuccess();

    final retry = find.widgetWithText(SnackBarAction, 'Retry').hitTestable();
    expect(retry, findsOneWidget);
    await tester.tap(retry);
    await tester.pumpAndSettle();

    expect(attempts, 4);
    expect(committed, 3);
    expect(_detail, findsOneWidget);
    expect(find.text('Classic lavash added to cart'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

final _detail = find.byKey(const ValueKey<String>('product-detail-page'));

void _expectNoSuccess() {
  expect(find.text('Classic lavash added to cart'), findsNothing);
  expect(
    find.byKey(const ValueKey<String>('wrap-to-cart-flight')),
    findsNothing,
  );
  expect(find.byKey(const ValueKey<String>('cart-add-fade')), findsNothing);
}

Future<void> _openDetail(
  WidgetTester tester, {
  FutureOr<void> Function(CartSelection)? onConfiguredAdd,
  FutureOr<void> Function(MenuProduct)? onAdd,
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final location = LocationController(YandexGeocoderService())
    ..setFromMap(latitude: 41.31, longitude: 69.28, address: 'Test address');
  addTearDown(location.dispose);

  await tester.pumpWidget(
    ChangeNotifierProvider<LocationController>.value(
      value: location,
      child: MaterialApp(
        theme: lightTheme,
        locale: const Locale('en'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: Scaffold(
          body: MenuScreen(
            isDark: false,
            isMenuLoading: false,
            selectedCategoryIndex: 0,
            categories: const ['Lavash'],
            products: const [_product],
            promotions: const [],
            orderType: MobileOrderType.delivery,
            selectedBranch: null,
            onCategorySelected: (_) {},
            onAddToCart: onAdd ?? (_) {},
            onAddConfiguredToCart: onConfiguredAdd,
            onDecreaseFromCart: (_) {},
            onCartTap: () {},
            onOrderTypeChanged: (_) {},
            onBranchSelected: (_) async {},
            onRetryMenu: () {},
            onRefresh: () async {},
            cartCount: 0,
            cartTotal: 0,
            cartQuantities: const {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byType(ProductImage).first);
  await tester.pumpAndSettle();
  expect(_detail, findsOneWidget);
}

const _product = MenuProduct(
  id: 'failure-test-lavash',
  title: 'Classic lavash',
  description: 'Chicken, fresh vegetables and white sauce.',
  price: 32000,
  category: 'Lavash',
  emoji: 'L',
  tint: Color(0xFFF1E4D2),
  highlight: Color(0xFFF8F2E9),
  modifierGroups: [
    MenuModifierGroup(
      id: 'extras',
      name: 'Extras',
      minSelected: 0,
      maxSelected: 1,
      options: [
        MenuModifierOption(
          id: 'cheese',
          name: 'Cheese',
          price: 6000,
          defaultQuantity: 1,
          isDefault: false,
          isAvailable: true,
        ),
      ],
    ),
  ],
);
