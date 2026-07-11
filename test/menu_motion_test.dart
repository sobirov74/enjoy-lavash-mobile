import 'package:enjoy_lavash_mobile/app/location_controller.dart';
import 'package:enjoy_lavash_mobile/core/services/yandex_geocoder_service.dart';
import 'package:enjoy_lavash_mobile/features/data/menu_catalog.dart';
import 'package:enjoy_lavash_mobile/features/models/menu_product.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/cart_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/promotion_model.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/screens/menu_screen.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'package:enjoy_lavash_mobile/theme/app_motion.dart';
import 'package:enjoy_lavash_mobile/widgets/product_list_item.dart';
import 'package:enjoy_lavash_mobile/widgets/product_image.dart';
import 'package:enjoy_lavash_mobile/widgets/quantity_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('first add reports its origin without delaying cart state', (
    tester,
  ) async {
    var quantity = 0;
    var originCalls = 0;
    Rect? reportedOrigin;

    await tester.pumpWidget(
      _motionHost(
        child: StatefulBuilder(
          builder: (context, setState) => ProductListItem(
            product: menuProducts.first,
            isDark: false,
            quantity: quantity,
            imageHeroTag: 'menu-product-test',
            onAdd: () => setState(() => quantity += 1),
            onAddOrigin: (origin) {
              originCalls += 1;
              reportedOrigin = origin;
            },
            onDecrease: () => setState(() => quantity -= 1),
            onIncrease: () => setState(() => quantity += 1),
          ),
        ),
      ),
    );

    final addButton = find.widgetWithIcon(FilledButton, Icons.add_rounded);
    final expectedOrigin = tester.getRect(addButton);
    final hero = tester.widget<Hero>(find.byType(Hero));
    expect(hero.tag, 'menu-product-test');

    await tester.tap(addButton);

    // Both callbacks run synchronously from the tap. Motion is optional
    // feedback and does not gate the state change.
    expect(quantity, 1);
    expect(originCalls, 1);
    expect(reportedOrigin, isNotNull);
    expect(reportedOrigin!.center.dx, closeTo(expectedOrigin.center.dx, 0.1));
    expect(reportedOrigin!.center.dy, closeTo(expectedOrigin.center.dy, 0.1));

    await tester.pumpAndSettle();
    expect(find.byType(QuantityButton), findsNWidgets(2));

    await tester.tap(find.byIcon(Icons.add_rounded));
    expect(quantity, 2);
    expect(originCalls, 1);
  });

  testWidgets('product state change is immediate for reduced motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      _motionHost(
        disableAnimations: true,
        child: ProductListItem(
          product: menuProducts.first,
          isDark: false,
          quantity: 0,
          onAdd: () {},
          onDecrease: () {},
          onIncrease: () {},
        ),
      ),
    );

    final switcher = tester.widget<AnimatedSwitcher>(
      find.descendant(
        of: find.byType(ProductListItem),
        matching: find.byType(AnimatedSwitcher),
      ),
    );
    expect(switcher.duration, Duration.zero);
  });

  testWidgets('menu runs the cart flight and reversible product detail route', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const _MenuMotionHarness());
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(MenuScreen),
        matching: find.byType(AnimatedPositioned),
      ),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithIcon(FilledButton, Icons.add_rounded));
    await tester.pump();
    await tester.pump();

    expect(find.text('View cart'), findsOneWidget);
    final cartBar = tester.widget<Material>(
      find.byKey(const ValueKey<String>('menu-cart-summary-bar')),
    );
    final cartBarShape = cartBar.shape! as RoundedRectangleBorder;
    expect(cartBar.color, Colors.white);
    expect(cartBarShape.side.color, BaseColors.primary.withValues(alpha: 0.22));
    expect(
      find.byKey(const ValueKey<String>('wrap-to-cart-flight')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.pump(AppMotion.spatial);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('wrap-to-cart-flight')),
      findsNothing,
    );

    await tester.tap(find.byType(ProductImage).first);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('product-detail-page')),
      findsOneWidget,
    );
    expect(find.text(menuProducts.first.title), findsNWidgets(2));
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('product-detail-page')),
      findsNothing,
    );
  });

  testWidgets('menu skips cart travel when motion is disabled', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const _MenuMotionHarness(disableAnimations: true));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithIcon(FilledButton, Icons.add_rounded));
    await tester.pump();

    expect(find.text('View cart'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('wrap-to-cart-flight')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}

Widget _motionHost({required Widget child, bool disableAnimations = false}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: L.localizationsDelegates,
    supportedLocales: L.supportedLocales,
    home: MediaQuery(
      data: MediaQueryData(
        size: const Size(390, 844),
        disableAnimations: disableAnimations,
      ),
      child: Scaffold(
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[child],
        ),
      ),
    ),
  );
}

class _MenuMotionHarness extends StatefulWidget {
  const _MenuMotionHarness({this.disableAnimations = false});

  final bool disableAnimations;

  @override
  State<_MenuMotionHarness> createState() => _MenuMotionHarnessState();
}

class _MenuMotionHarnessState extends State<_MenuMotionHarness> {
  late final LocationController _location = LocationController(
    YandexGeocoderService(),
  )..setFromMap(latitude: 41.31, longitude: 69.28, address: 'Test address');
  final Map<String, int> _cart = <String, int>{};
  MobileOrderType _orderType = MobileOrderType.delivery;

  @override
  void dispose() {
    _location.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = menuProducts.first;
    final quantity = _cart[product.id] ?? 0;

    return ChangeNotifierProvider<LocationController>.value(
      value: _location,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(390, 844),
            disableAnimations: widget.disableAnimations,
          ),
          child: Scaffold(
            body: MenuScreen(
              isDark: false,
              isMenuLoading: false,
              selectedCategoryIndex: 0,
              categories: <String>[product.category],
              products: <MenuProduct>[product],
              promotions: const <PromotionModel>[],
              orderType: _orderType,
              selectedBranch: null,
              onCategorySelected: (_) {},
              onAddToCart: (_) {
                setState(() => _cart[product.id] = quantity + 1);
              },
              onDecreaseFromCart: (_) {
                setState(() {
                  if (quantity <= 1) {
                    _cart.remove(product.id);
                  } else {
                    _cart[product.id] = quantity - 1;
                  }
                });
              },
              onCartTap: () {},
              onOrderTypeChanged: (type) => setState(() => _orderType = type),
              onBranchSelected: (_) async {},
              onRetryMenu: () {},
              onRefresh: () async {},
              cartCount: quantity,
              cartTotal: product.price * quantity,
              cartQuantities: _cart,
            ),
          ),
        ),
      ),
    );
  }
}
