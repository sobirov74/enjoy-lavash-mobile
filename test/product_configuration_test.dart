import 'package:enjoy_lavash_mobile/app/location_controller.dart';
import 'package:enjoy_lavash_mobile/core/services/yandex_geocoder_service.dart';
import 'package:enjoy_lavash_mobile/features/models/cart_line.dart';
import 'package:enjoy_lavash_mobile/features/models/menu_product.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/cart_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/promotion_model.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/screens/menu_screen.dart';
import 'package:enjoy_lavash_mobile/theme/light_theme.dart';
import 'package:enjoy_lavash_mobile/widgets/product_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('product options are selected and returned as a cart line', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final location = LocationController(YandexGeocoderService())
      ..setFromMap(latitude: 41.31, longitude: 69.28, address: 'Test address');
    addTearDown(location.dispose);
    CartSelection? configured;

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
              categories: const <String>['Lavash'],
              products: const <MenuProduct>[_configuredProduct],
              promotions: const <PromotionModel>[],
              orderType: MobileOrderType.delivery,
              selectedBranch: null,
              onCategorySelected: (_) {},
              onAddToCart: (_) {},
              onAddConfiguredToCart: (selection) => configured = selection,
              onDecreaseFromCart: (_) {},
              onCartTap: () {},
              onOrderTypeChanged: (_) {},
              onBranchSelected: (_) async {},
              onRetryMenu: () {},
              onRefresh: () async {},
              cartCount: 0,
              cartTotal: 0,
              cartQuantities: const <String, int>{},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ProductImage).first);
    await tester.pumpAndSettle();
    expect(find.text('Choose sauce'), findsOneWidget);
    expect(find.text('Cheese'), findsOneWidget);

    await tester.tap(find.text('Cheese'));
    await tester.tap(find.textContaining('Add ·'));
    await tester.pumpAndSettle();

    expect(configured, isNotNull);
    expect(configured!.productId, 'configured-lavash');
    expect(
      configured!.modifiers.map((modifier) => modifier.modifierId),
      containsAll(<String>['white', 'cheese']),
    );
  });
}

const MenuProduct _configuredProduct = MenuProduct(
  id: 'configured-lavash',
  title: 'Classic lavash',
  description: 'Chicken, fresh vegetables and white sauce.',
  price: 32000,
  category: 'Lavash',
  emoji: 'L',
  tint: Color(0xFFF1E4D2),
  highlight: Color(0xFFF8F2E9),
  modifierGroups: <MenuModifierGroup>[
    MenuModifierGroup(
      id: 'sauce',
      name: 'Choose sauce',
      minSelected: 1,
      maxSelected: 1,
      options: <MenuModifierOption>[
        MenuModifierOption(
          id: 'white',
          name: 'White sauce',
          price: 0,
          defaultQuantity: 1,
          isDefault: true,
          isAvailable: true,
        ),
      ],
    ),
    MenuModifierGroup(
      id: 'extras',
      name: 'Extras',
      minSelected: 0,
      maxSelected: 3,
      options: <MenuModifierOption>[
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
