import 'package:enjoy_lavash_mobile/features/data/menu_catalog.dart';
import 'package:enjoy_lavash_mobile/features/models/menu_product.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/theme/app_design_tokens.dart';
import 'package:enjoy_lavash_mobile/widgets/product_image.dart';
import 'package:enjoy_lavash_mobile/widgets/product_list_item.dart';
import 'package:enjoy_lavash_mobile/widgets/quantity_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('product card image uses the shared thumbnail radius', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 180,
            child: ProductListItem(
              product: menuProducts.first,
              isDark: false,
              quantity: 0,
              onAdd: () {},
              onDecrease: () {},
              onIncrease: () {},
            ),
          ),
        ),
      ),
    );

    final image = tester.widget<ProductImage>(find.byType(ProductImage));
    expect(image.borderRadius, AppDesignTokens.radiusThumb);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact cards stay equal before and after adding an item', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final textScale in [1.0, 2.0]) {
      var quantity = 0;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(20),
              children: <Widget>[
                StatefulBuilder(
                  key: ValueKey(textScale),
                  builder: (context, setState) => Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ProductListItem(
                          key: const ValueKey('short-card'),
                          product: menuProducts.first,
                          isDark: false,
                          quantity: quantity,
                          onAdd: () => setState(() => quantity++),
                          onDecrease: () => setState(() => quantity--),
                          onIncrease: () => setState(() => quantity++),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ProductListItem(
                          key: const ValueKey('long-card'),
                          product: const MenuProduct(
                            id: 'long-product',
                            title:
                                'Large chicken lavash with cheese and vegetables',
                            description:
                                'Chicken, cheese, fresh vegetables and white sauce.',
                            price: 125000,
                            category: 'Lavash',
                            emoji: '🌯',
                            tint: Colors.white,
                            highlight: Colors.white,
                            calories: 750,
                            weightGrams: 450,
                          ),
                          isDark: false,
                          quantity: 99,
                          onAdd: () {},
                          onDecrease: () {},
                          onIncrease: () {},
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final shortCard = find.byKey(const ValueKey('short-card'));
      final longCard = find.byKey(const ValueKey('long-card'));
      final initialBounds = tester.getRect(shortCard);
      expect(initialBounds.size, tester.getSize(longCard));
      expect(initialBounds.width, 134);
      expect(tester.takeException(), isNull);

      await tester.tap(
        find.descendant(
          of: shortCard,
          matching: find.widgetWithIcon(FilledButton, Icons.add_rounded),
        ),
      );
      await tester.pumpAndSettle();

      expect(quantity, 1);
      expect(tester.getRect(shortCard), initialBounds);
      expect(tester.getRect(longCard).bottom, initialBounds.bottom);
      expect(tester.takeException(), isNull);
      expect(find.byType(QuantityButton), findsNWidgets(4));

      await tester.tap(
        find.descendant(
          of: shortCard,
          matching: find.byIcon(Icons.add_rounded),
        ),
      );
      await tester.pumpAndSettle();
      expect(quantity, 2);
      expect(tester.getRect(shortCard), initialBounds);
      expect(tester.takeException(), isNull);
    }
  });
}
