import 'package:enjoy_lavash_mobile/features/data/menu_catalog.dart';
import 'package:enjoy_lavash_mobile/features/models/menu_category.dart';
import 'package:enjoy_lavash_mobile/features/models/menu_product.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/screens/home_screen.dart';
import 'package:enjoy_lavash_mobile/theme/app_design_tokens.dart';
import 'package:enjoy_lavash_mobile/widgets/product_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('home category image uses the shared thumbnail radius', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final product = menuProducts.first;
    final category = MenuCategory(id: 'lavash', name: product.category);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: Scaffold(
          body: HomeScreen(
            customerName: 'Guest',
            loyaltyBalance: 0,
            orderModeLabel: 'Delivery',
            orderContextLabel: 'Choose address',
            categories: <MenuCategory>[category],
            products: <MenuProduct>[product],
            promotions: const [],
            locale: 'en',
            onOrderContextTap: () {},
            onNotificationsTap: () {},
            onLoyaltyTap: () {},
            onMenuTap: () {},
            onCategoryTap: (_) {},
            onRefresh: () async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final imageClip = find.byKey(
      const ValueKey<String>('home-category-image-lavash'),
    );
    expect(imageClip, findsOneWidget);
    expect(
      tester.widget<ClipRRect>(imageClip).borderRadius,
      BorderRadius.circular(AppDesignTokens.radiusThumb),
    );
    expect(
      find.descendant(of: imageClip, matching: find.byType(ProductImage)),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
