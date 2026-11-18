import 'package:enjoy_lavash_mobile/app/location_controller.dart';
import 'package:enjoy_lavash_mobile/core/services/yandex_geocoder_service.dart';
import 'package:enjoy_lavash_mobile/features/cart/presentation/cart_controller.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/cart_model.dart';
import 'package:enjoy_lavash_mobile/features/models/menu_product.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/screens/menu_screen.dart';
import 'package:enjoy_lavash_mobile/widgets/product_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/menu_catalog.dart';

const _field = ValueKey<String>('menu-search-field');
const _summary = ValueKey<String>('menu-search-summary');
const _shortcut = ValueKey<String>('menu-search-shortcut');
const _firstCategoryChip = ValueKey<String>('menu-category-label-0');

Finder _card(String id) => find.byKey(ValueKey<String>('menu-$id'));

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(
    find.descendant(of: find.byKey(_field), matching: find.byType(TextField)),
    text,
  );
  await tester.pumpAndSettle();
}

void main() {
  late ValueNotifier<int> category;

  setUp(() => category = ValueNotifier<int>(0));
  tearDown(() => category.dispose());

  Future<void> pumpMenu(
    WidgetTester tester, {
    List<MenuProduct> products = menuProducts,
    List<String> categories = menuCategories,
  }) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _MenuHarness(
        category: category,
        products: products,
        categories: categories,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a query finds products in every category, clearing it '
      'brings the selected category back', (tester) async {
    await pumpMenu(tester);
    expect(_card('lavash-cheese'), findsOne);
    expect(_card('burger-classic'), findsNothing);

    await _type(tester, 'burger');

    expect(_card('burger-classic'), findsOne);
    expect(_card('lavash-cheese'), findsNothing);
    expect(find.byKey(_firstCategoryChip), findsNothing);
    expect(find.text('1 item found'), findsOne);

    await tester.tap(
      find.byKey(const ValueKey<String>('menu-search-summary-clear')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(_summary), findsNothing);
    expect(find.byKey(_firstCategoryChip), findsOne);
    expect(_card('lavash-cheese'), findsOne);
    expect(_card('burger-classic'), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
  });

  testWidgets('a query matching nothing says so and offers to clear it', (
    tester,
  ) async {
    await pumpMenu(tester);

    await _type(tester, 'sushi');

    expect(find.text('Nothing found for “sushi”'), findsOne);
    expect(find.byKey(_summary), findsNothing);
    expect(find.byType(ProductListItem), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey<String>('menu-search-empty-clear')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nothing found for “sushi”'), findsNothing);
    expect(_card('lavash-cheese'), findsOne);
  });

  testWidgets('the field clear button empties the query', (tester) async {
    await pumpMenu(tester);
    await _type(tester, 'pepperoni');
    expect(find.byKey(_summary), findsOne);

    await tester.tap(
      find.byKey(const ValueKey<String>('app-search-field-clear')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(_summary), findsNothing);
    expect(find.byKey(_firstCategoryChip), findsOne);
  });

  testWidgets('a category picked from outside ends the search', (tester) async {
    await pumpMenu(tester);
    await _type(tester, 'burger');

    category.value = 1;
    await tester.pumpAndSettle();

    expect(find.byKey(_summary), findsNothing);
    expect(_card('pepperoni'), findsOne);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
  });

  testWidgets('once the field scrolls away a pinned shortcut brings it '
      'back with the keyboard open', (tester) async {
    final products = <MenuProduct>[
      for (var index = 0; index < 30; index++)
        MenuProduct(
          id: 'product-$index',
          title: 'Product $index',
          price: 30000,
          category: 'Lavash',
          emoji: '🌯',
          tint: Colors.orange,
          highlight: Colors.amber,
        ),
    ];
    await pumpMenu(tester, products: products, categories: const ['Lavash']);
    expect(find.byKey(_shortcut), findsNothing);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));
    await tester.pumpAndSettle();
    expect(find.byKey(_shortcut), findsOne);

    await tester.tap(find.byKey(_shortcut));
    await tester.pumpAndSettle();

    final scrollable = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(scrollable.position.pixels, 0);
    expect(find.byKey(_shortcut), findsNothing);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.focusNode!.hasFocus, isTrue);
  });
}

/// Hosts a [MenuScreen] whose selected category the test can change from
/// outside, as the shell does for a banner link.
class _MenuHarness extends StatefulWidget {
  const _MenuHarness({
    required this.category,
    required this.products,
    required this.categories,
  });

  final ValueNotifier<int> category;
  final List<MenuProduct> products;
  final List<String> categories;

  @override
  State<_MenuHarness> createState() => _MenuHarnessState();
}

class _MenuHarnessState extends State<_MenuHarness> {
  late final LocationController _location = LocationController(
    YandexGeocoderService(),
  )..setFromMap(latitude: 41.31, longitude: 69.28, address: 'Test address');
  final CartController _cart = CartController(persist: (_) async {});

  @override
  void dispose() {
    _location.dispose();
    _cart.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LocationController>.value(
      value: _location,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: Scaffold(
          body: ValueListenableBuilder<int>(
            valueListenable: widget.category,
            builder: (context, selected, _) => MenuScreen(
              isDark: false,
              isMenuLoading: false,
              selectedCategoryIndex: selected,
              categories: widget.categories,
              products: widget.products,
              orderType: MobileOrderType.delivery,
              selectedBranch: null,
              onCategorySelected: (index) => widget.category.value = index,
              onAddToCart: (_) {},
              onDecreaseFromCart: (_) {},
              onCartTap: () {},
              onOrderTypeChanged: (_) {},
              onBranchSelected: (_) async {},
              onRetryMenu: () {},
              onRefresh: () async {},
              cart: _cart,
            ),
          ),
        ),
      ),
    );
  }
}
