import 'package:enjoy_lavash_mobile/app/location_controller.dart';
import 'package:enjoy_lavash_mobile/core/services/yandex_geocoder_service.dart';
import 'package:enjoy_lavash_mobile/features/models/cart_line.dart';
import 'package:enjoy_lavash_mobile/features/models/menu_product.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/cart_model.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/screens/menu_screen.dart';
import 'package:enjoy_lavash_mobile/widgets/cart_animation/cart_animation_controller.dart';
import 'package:enjoy_lavash_mobile/widgets/cart_animation/cart_animation_source.dart';
import 'package:enjoy_lavash_mobile/widgets/cart_animation/packaging_visual.dart';
import 'package:enjoy_lavash_mobile/widgets/cart_animation/preset_packaging_visual.dart';
import 'package:enjoy_lavash_mobile/widgets/product_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('lavash closes before launch and stays packaged during flight', (
    tester,
  ) async {
    final scene = await _mountScene(tester);
    final controller = CartAnimationController();
    addTearDown(controller.dispose);
    final originalBounds = tester.getRect(find.byKey(scene.anchorKey));
    var operations = 0;
    var confirmations = 0;

    final addition = controller.add(
      context: scene.context,
      source: scene.anchorKey.currentState!.capture(),
      packagingKind: CartPackagingKind.lavash,
      operation: () => operations++,
      destination: () => cartAnimationBounds(scene.cartKey),
      onConfirmed: () => confirmations++,
      onFailed: (_, _) => fail('A successful add must not fail.'),
    );
    expect(
      operations,
      1,
      reason: 'Packaging must not delay the cart mutation.',
    );
    expect(await addition, isTrue);
    await _insertEffect(tester);

    expect(_preset, findsOneWidget);
    expect(_sourceOpacity(tester, scene), 0);
    expect(_visual(tester).kind, CartPackagingKind.lavash);
    await tester.pump(controller.duration * 0.25);
    final earlyProgress = _visual(tester).progress;
    expect(earlyProgress, inExclusiveRange(0.0, 1.0));
    expect(tester.getSize(_preset).shortestSide, greaterThan(0));

    await tester.pump(controller.duration * 0.15);
    expect(_visual(tester).progress, greaterThan(earlyProgress));
    expect(_visual(tester).progress, lessThan(1));

    // The fully closed parcel gets a distinct pause before it leaves.
    await tester.pump(controller.duration * 0.20);
    expect(_visual(tester).progress, 1);
    final packedCenter = tester.getCenter(_preset);
    expect(packedCenter, const Offset(400, 300));
    expect(tester.getSize(_preset), const Size.square(360));
    expect(confirmations, 0);
    await tester.pump(controller.duration * 0.05);
    expect(_visual(tester).progress, 1);
    expect(tester.getCenter(_preset), packedCenter);

    // The payload remains the sealed parcel as it travels toward the cart.
    await tester.pump(controller.duration * 0.15);
    expect(_preset, findsOneWidget);
    expect(_visual(tester).progress, 1);
    expect(tester.getCenter(_preset), isNot(packedCenter));
    expect(confirmations, 0);
    expect(operations, 1);
    expect(tester.getRect(find.byKey(scene.anchorKey)), originalBounds);

    await tester.pumpAndSettle();
    expect(_preset, findsNothing);
    expect(_sourceOpacity(tester, scene), 1);
    expect(tester.getRect(find.byKey(scene.anchorKey)), originalBounds);
    expect(confirmations, 1);
    expect(operations, 1);
    expect(controller.isAnimating, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion skips packaging and confirms once', (
    tester,
  ) async {
    final scene = await _mountScene(tester, reducedMotion: true);
    final controller = CartAnimationController();
    addTearDown(controller.dispose);
    var confirmations = 0;

    await controller.add(
      context: scene.context,
      source: scene.anchorKey.currentState!.capture(),
      packagingKind: CartPackagingKind.lavash,
      operation: () {},
      destination: () => cartAnimationBounds(scene.cartKey),
      onConfirmed: () => confirmations++,
      onFailed: (_, _) => fail('A successful add must not fail.'),
    );
    await _insertEffect(tester);

    expect(_preset, findsNothing);
    expect(_sourceOpacity(tester, scene), 1);
    await tester.pump(const Duration(milliseconds: 80));
    expect(_preset, findsNothing);
    expect(confirmations, 1);
    await tester.pumpAndSettle();
    expect(confirmations, 1);
    expect(controller.isAnimating, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'menu uses a lavash preset without configured packaging artwork',
    (tester) async {
      final menu = await _mountMenu(tester);
      expect(
        tester.widget<MenuScreen>(find.byType(MenuScreen)).packagingAssets,
        isEmpty,
      );

      await tester.tap(find.widgetWithIcon(FilledButton, Icons.add_rounded));
      expect(menu.quantity, 1);
      await _insertEffect(tester);
      expect(_preset, findsOneWidget);
      expect(_visual(tester).kind, CartPackagingKind.lavash);

      await tester.pump(const Duration(milliseconds: 1350));
      expect(_visual(tester).progress, 1);
      expect(menu.arrivals, 0);
      await tester.pump(const Duration(milliseconds: 400));
      expect(_preset, findsOneWidget);
      expect(_visual(tester).progress, 1);
      await tester.pumpAndSettle();
      expect(menu.quantity, 1);
      expect(menu.arrivals, 1);
      expect(_preset, findsNothing);
      expect(find.byType(ProductImage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('product detail uses the preset and remains open after adding', (
    tester,
  ) async {
    final menu = await _mountMenu(tester);
    await tester.tap(find.byType(ProductImage).first);
    await tester.pumpAndSettle();
    final detail = find.byKey(const ValueKey<String>('product-detail-page'));
    expect(detail, findsOneWidget);
    final detailAnchor = tester.state<CartAnimationAnchorState>(
      find.descendant(of: detail, matching: find.byType(CartAnimationAnchor)),
    );
    expect(detailAnchor.capture(), isNotNull);
    expect(detailAnchor.capture()!.bounds.right, 390);

    await tester.tap(find.textContaining('Add ·'));
    expect(menu.quantity, 1);
    await _insertEffect(tester);
    expect(_preset, findsOneWidget);
    expect(_visual(tester).kind, CartPackagingKind.lavash);
    await tester.pump(const Duration(milliseconds: 1350));
    expect(_visual(tester).progress, 1);
    final detailScaffold = tester.widget<Scaffold>(
      find.descendant(of: detail, matching: find.byType(Scaffold)),
    );
    final bodyCenter = tester.getCenter(find.byWidget(detailScaffold.body!));
    expect((tester.getCenter(_preset) - bodyCenter).distance, lessThan(.01));
    expect(tester.getSize(_preset), const Size.square(360));
    await tester.pumpAndSettle();

    expect(detail, findsOneWidget);
    expect(menu.quantity, 1);
    expect(_preset, findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final scrollOffset in [80.0, 360.0]) {
    testWidgets(
      'detail packs with its photo ${scrollOffset < 300 ? 'partly clipped' : 'offscreen'} '
      'and preserves configured repeat additions',
      (tester) async {
        final menu = await _mountMenu(tester, product: _configuredProduct);
        final scroll = await _openConfiguredDetail(tester, scrollOffset);
        final cart = find.descendant(
          of: _detail,
          matching: find.byIcon(Icons.shopping_bag_outlined),
        );
        final cartCenter = tester.getCenter(cart);
        final originalOffset = scroll.position.pixels;

        for (var addition = 1; addition <= 2; addition++) {
          await tester.tap(find.textContaining('Add ·'));
          expect(menu.quantity, addition * 2);
          expect(menu.selections, hasLength(addition));
          expect(menu.selections.last.quantity, 2);
          expect(
            menu.selections.last.modifiers.map(
              (modifier) => modifier.modifierId,
            ),
            ['cheese'],
          );
          await _insertEffect(tester);
          expect(_preset, findsOneWidget);
          expect(_visual(tester).kind, CartPackagingKind.lavash);
          await tester.pump(const Duration(milliseconds: 1350));
          expect(_visual(tester).progress, 1);
          final packageBounds = tester.getRect(_preset);
          expect(packageBounds.left, greaterThanOrEqualTo(0));
          expect(packageBounds.right, lessThanOrEqualTo(390));
          expect(packageBounds.top, greaterThan(cartCenter.dy));
          expect(packageBounds.bottom, lessThan(750));
          expect(scroll.position.pixels, originalOffset);

          // The detail's header icon is the destination even after the photo
          // has left the viewport and the bottom add bar remains fixed.
          await tester.pump(const Duration(milliseconds: 740));
          expect(
            (tester.getCenter(_preset) - cartCenter).distance,
            lessThan(0.5),
          );
          await tester.pumpAndSettle();
          expect(_detail, findsOneWidget);
          expect(_preset, findsNothing);
          expect(scroll.position.pixels, originalOffset);
          expect(menu.quantity, addition * 2);
          expect(tester.takeException(), isNull);
        }
        expect(menu.selections.last.key, menu.selections.first.key);
      },
    );
  }

  testWidgets(
    'closing scrolled detail cancels packaging and allows a fresh add',
    (tester) async {
      final menu = await _mountMenu(tester, product: _configuredProduct);
      await _openConfiguredDetail(tester, 360);
      await tester.tap(find.textContaining('Add ·'));
      await _insertEffect(tester);
      await tester.pump(const Duration(milliseconds: 700));
      expect(_preset, findsOneWidget);
      expect(menu.quantity, 2);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(_detail, findsNothing);
      expect(_preset, findsNothing);
      expect(menu.quantity, 2);
      expect(menu.arrivals, 0);
      expect(find.text('Custom lavash added to cart'), findsNothing);

      await tester.tap(find.byIcon(Icons.add_rounded));
      await _insertEffect(tester);
      expect(_preset, findsOneWidget);
      expect(menu.quantity, 3);
      await tester.pumpAndSettle();
      expect(_preset, findsNothing);
      expect(menu.arrivals, 1);
      expect(tester.takeException(), isNull);
    },
  );
}

final _preset = find.byType(PresetPackagingVisual);
final _detail = find.byKey(const ValueKey<String>('product-detail-page'));

Future<ScrollableState> _openConfiguredDetail(
  WidgetTester tester,
  double scrollOffset,
) async {
  await tester.tap(find.byType(ProductImage).first);
  await tester.pumpAndSettle();
  expect(_detail, findsOneWidget);
  await tester.ensureVisible(find.text('Cheese'));
  await tester.tap(find.text('Cheese'));
  await tester.tap(
    find.descendant(of: _detail, matching: find.byIcon(Icons.add_rounded)),
  );
  final scroll = tester.state<ScrollableState>(
    find.descendant(of: _detail, matching: find.byType(Scrollable)).first,
  );
  expect(scroll.position.maxScrollExtent, greaterThan(scrollOffset));
  scroll.position.jumpTo(scrollOffset);
  await tester.pumpAndSettle();
  final anchors = tester
      .stateList<CartAnimationAnchorState>(
        find.descendant(
          of: _detail,
          matching: find.byType(CartAnimationAnchor),
        ),
      )
      .toList();
  expect(
    anchors.isEmpty || anchors.single.capture() == null,
    isTrue,
    reason: 'The packaging must also work when the photo cannot be captured.',
  );
  return scroll;
}

PresetPackagingVisual _visual(WidgetTester tester) =>
    tester.widget<PresetPackagingVisual>(_preset);

Future<void> _insertEffect(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

double _sourceOpacity(WidgetTester tester, _PackagingSceneState scene) => tester
    .widget<Opacity>(
      find.descendant(
        of: find.byKey(scene.anchorKey),
        matching: find.byType(Opacity),
      ),
    )
    .opacity;

Future<_PackagingSceneState> _mountScene(
  WidgetTester tester, {
  bool reducedMotion = false,
}) async {
  final key = GlobalKey<_PackagingSceneState>();
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(800, 600),
          disableAnimations: reducedMotion,
        ),
        child: _PackagingScene(key: key),
      ),
    ),
  );
  return key.currentState!;
}

class _PackagingScene extends StatefulWidget {
  const _PackagingScene({super.key});

  @override
  State<_PackagingScene> createState() => _PackagingSceneState();
}

class _PackagingSceneState extends State<_PackagingScene> {
  final anchorKey = GlobalKey<CartAnimationAnchorState>();
  final cartKey = GlobalKey();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      children: [
        Positioned(
          left: 140,
          top: 180,
          width: 120,
          height: 96,
          child: CartAnimationAnchor(
            key: anchorKey,
            child: const ColoredBox(
              color: Colors.orange,
              child: Center(child: Text('Selected lavash')),
            ),
          ),
        ),
        Positioned(
          left: 650,
          top: 480,
          width: 32,
          height: 32,
          child: SizedBox(
            key: cartKey,
            child: const Icon(Icons.shopping_bag_outlined),
          ),
        ),
      ],
    ),
  );
}

Future<_PackagingMenuState> _mountMenu(
  WidgetTester tester, {
  MenuProduct product = _product,
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final key = GlobalKey<_PackagingMenuState>();
  await tester.pumpWidget(_PackagingMenu(key: key, product: product));
  await tester.pumpAndSettle();
  return key.currentState!;
}

class _PackagingMenu extends StatefulWidget {
  const _PackagingMenu({super.key, required this.product});

  final MenuProduct product;

  @override
  State<_PackagingMenu> createState() => _PackagingMenuState();
}

class _PackagingMenuState extends State<_PackagingMenu> {
  final location = LocationController(YandexGeocoderService())
    ..setFromMap(latitude: 41.31, longitude: 69.28, address: 'Test address');
  int quantity = 0;
  int arrivals = 0;
  final selections = <CartSelection>[];

  @override
  void dispose() {
    location.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ChangeNotifierProvider<LocationController>.value(
        value: location,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          home: Scaffold(
            body: MenuScreen(
              isDark: false,
              isMenuLoading: false,
              selectedCategoryIndex: 0,
              categories: const ['Lavash'],
              products: [widget.product],
              promotions: const [],
              orderType: MobileOrderType.delivery,
              selectedBranch: null,
              onCategorySelected: (_) {},
              onAddToCart: (_) => setState(() => quantity++),
              onAddConfiguredToCart: (selection) {
                selections.add(selection);
                setState(() => quantity += selection.quantity);
              },
              onDecreaseFromCart: (_) {},
              onCartTap: () {},
              onCartArrival: () => arrivals++,
              onOrderTypeChanged: (_) {},
              onBranchSelected: (_) async {},
              onRetryMenu: () {},
              onRefresh: () async {},
              cartCount: quantity,
              cartTotal: widget.product.price * quantity,
              cartQuantities: {widget.product.id: quantity},
            ),
          ),
        ),
      );
}

const _product = MenuProduct(
  id: 'packaging-test-lavash',
  title: 'Classic lavash',
  description: 'Chicken, fresh vegetables and white sauce.',
  price: 32000,
  category: 'Lavash',
  emoji: 'L',
  tint: Color(0xFFF1E4D2),
  highlight: Color(0xFFF8F2E9),
);

const _configuredProduct = MenuProduct(
  id: 'configured-packaging-lavash',
  title: 'Custom lavash',
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
        MenuModifierOption(
          id: 'tomato',
          name: 'Tomato',
          price: 2000,
          defaultQuantity: 1,
          isDefault: false,
          isAvailable: true,
        ),
        MenuModifierOption(
          id: 'cucumber',
          name: 'Cucumber',
          price: 2000,
          defaultQuantity: 1,
          isDefault: false,
          isAvailable: true,
        ),
        MenuModifierOption(
          id: 'lettuce',
          name: 'Lettuce',
          price: 2000,
          defaultQuantity: 1,
          isDefault: false,
          isAvailable: true,
        ),
        MenuModifierOption(
          id: 'chicken',
          name: 'Chicken',
          price: 6000,
          defaultQuantity: 1,
          isDefault: false,
          isAvailable: true,
        ),
        MenuModifierOption(
          id: 'beef',
          name: 'Beef',
          price: 8000,
          defaultQuantity: 1,
          isDefault: false,
          isAvailable: true,
        ),
        MenuModifierOption(
          id: 'sauce',
          name: 'White sauce',
          price: 1000,
          defaultQuantity: 1,
          isDefault: false,
          isAvailable: true,
        ),
        MenuModifierOption(
          id: 'spicy',
          name: 'Spicy sauce',
          price: 1000,
          defaultQuantity: 1,
          isDefault: false,
          isAvailable: true,
        ),
        MenuModifierOption(
          id: 'mushrooms',
          name: 'Mushrooms',
          price: 3000,
          defaultQuantity: 1,
          isDefault: false,
          isAvailable: true,
        ),
        MenuModifierOption(
          id: 'onions',
          name: 'Onions',
          price: 1000,
          defaultQuantity: 1,
          isDefault: false,
          isAvailable: true,
        ),
        MenuModifierOption(
          id: 'pickles',
          name: 'Pickles',
          price: 2000,
          defaultQuantity: 1,
          isDefault: false,
          isAvailable: true,
        ),
      ],
    ),
  ],
);
