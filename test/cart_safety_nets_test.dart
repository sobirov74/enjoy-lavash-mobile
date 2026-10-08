import 'dart:convert';

import 'package:enjoy_lavash_mobile/app/app.dart';
import 'package:enjoy_lavash_mobile/app/locale_controller.dart';
import 'package:enjoy_lavash_mobile/app/location_controller.dart';
import 'package:enjoy_lavash_mobile/app/theme_controller.dart';
import 'package:enjoy_lavash_mobile/core/api/api_client.dart';
import 'package:enjoy_lavash_mobile/core/services/mobile_push_notification_service.dart';
import 'package:enjoy_lavash_mobile/core/services/yandex_geocoder_service.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/order_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/repositories/mobile_backend_repository_impl.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/presentation/mobile_backend_controller.dart';
import 'package:enjoy_lavash_mobile/features/models/cart_line.dart';
import 'package:enjoy_lavash_mobile/features/models/menu_product.dart';
import 'package:enjoy_lavash_mobile/widgets/product_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> pumpApp(
    WidgetTester tester,
    List<Object?> savedLines, {
    List<CustomerOrderModel> orders = const [],
  }) async {
    SharedPreferences.setMockInitialValues({
      'app_locale': 'en',
      'mobile_cart_lines_v2': jsonEncode(savedLines),
    });
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final localeController = LocaleController();
    await localeController.loadLocale();
    addTearDown(localeController.dispose);
    final apiClient = ApiClient();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeController>(
            create: (_) => ThemeController(),
          ),
          ChangeNotifierProvider<LocaleController>.value(
            value: localeController,
          ),
          ChangeNotifierProvider<LocationController>(
            create: (_) => LocationController(YandexGeocoderService()),
          ),
          ChangeNotifierProvider<MobileBackendController>(
            create: (_) => _CatalogController(apiClient, orders),
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('saved lines that left the menu are announced, not dropped '
      'silently', (tester) async {
    await pumpApp(tester, [
      {'productId': 'test-lavash', 'quantity': 1},
      {'productId': 'retired-product', 'quantity': 2},
    ]);

    expect(
      find.text(
        'Some items are no longer available and were removed from your cart',
      ),
      findsOneWidget,
    );
    final preferences = await SharedPreferences.getInstance();
    final saved = jsonDecode(preferences.getString('mobile_cart_lines_v2')!);
    expect(saved, [
      {'productId': 'test-lavash', 'quantity': 1, 'modifiers': <Object>[]},
    ]);
  });

  testWidgets('repeat order adds what it can and names what it could not', (
    tester,
  ) async {
    await pumpApp(tester, const [], orders: [_pastOrder]);

    await tester.tap(find.textContaining('Repeat ·'));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't add to your cart: Old combo"), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    final saved = jsonDecode(preferences.getString('mobile_cart_lines_v2')!);
    expect(saved, [
      {'productId': 'test-lavash', 'quantity': 2, 'modifiers': <Object>[]},
    ]);
  });

  testWidgets('a cart line stops at the quantity limit with a message', (
    tester,
  ) async {
    await pumpApp(tester, [
      {'productId': 'test-lavash', 'quantity': maxCartLineQuantity},
    ]);
    await tester.tap(find.byKey(const ValueKey<String>('main-tab-1')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(ProductListItem),
        matching: find.byIcon(Icons.add_rounded),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('You can add up to $maxCartLineQuantity of one item'),
      findsOneWidget,
    );
    final preferences = await SharedPreferences.getInstance();
    final saved = jsonDecode(preferences.getString('mobile_cart_lines_v2')!);
    expect((saved as List).single['quantity'], maxCartLineQuantity);
  });
}

final CustomerOrderModel _pastOrder = CustomerOrderModel.fromJson({
  'id': 'order-1',
  'type': 'PICKUP',
  'status': 'DELIVERED',
  'paymentMethod': 'CASH',
  'totalAmount': 90000,
  'items': [
    {'productId': 'test-lavash', 'quantity': 2, 'name': 'Test lavash'},
    {'productId': 'retired-product', 'quantity': 1, 'name': 'Old combo'},
  ],
  'statusLog': const [],
});

class _CatalogController extends MobileBackendController {
  _CatalogController(ApiClient apiClient, this._orders)
    : super(
        MobileBackendRepositoryImpl(apiClient),
        MobilePushNotificationService(apiClient),
      );

  final List<CustomerOrderModel> _orders;

  @override
  List<CustomerOrderModel> get orders => _orders;

  @override
  List<String> get menuCategories => const ['Lavash'];

  @override
  List<MenuProduct> get menuProducts => const [
    MenuProduct(
      id: 'test-lavash',
      title: 'Test lavash',
      price: 30000,
      category: 'Lavash',
      emoji: '🌯',
      tint: Colors.orange,
      highlight: Colors.amber,
    ),
  ];
}
