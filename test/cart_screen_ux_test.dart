import 'package:enjoy_lavash_mobile/features/data/menu_catalog.dart';
import 'package:enjoy_lavash_mobile/features/models/cart_line.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/screens/cart_screen.dart';
import 'package:enjoy_lavash_mobile/theme/light_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('checkout remains reachable with a long cart', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final items = menuProducts
        .take(6)
        .map((product) => CartLine(product: product, quantity: 2))
        .toList(growable: false);

    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        locale: const Locale('en'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: Scaffold(
          body: CartScreen(
            isDark: false,
            items: items,
            totalAmount: 398000,
            onDecrease: (_) {},
            onIncrease: (_) {},
            onBrowseMenu: () {},
            onCheckout: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final checkout = find.text('Checkout');
    expect(checkout, findsOneWidget);
    expect(checkout.hitTestable(), findsOneWidget);
  });
}
