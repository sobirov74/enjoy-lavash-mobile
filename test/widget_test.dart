// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:enjoy_lavash_mobile/app/app.dart';
import 'package:enjoy_lavash_mobile/app/locale_controller.dart';
import 'package:enjoy_lavash_mobile/app/location_controller.dart';
import 'package:enjoy_lavash_mobile/app/theme_controller.dart';
import 'package:enjoy_lavash_mobile/core/api/api_client.dart';
import 'package:enjoy_lavash_mobile/core/services/mobile_push_notification_service.dart';
import 'package:enjoy_lavash_mobile/core/services/yandex_geocoder_service.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/repositories/mobile_backend_repository_impl.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/presentation/mobile_backend_controller.dart';
import 'package:enjoy_lavash_mobile/features/models/menu_product.dart';
import 'package:enjoy_lavash_mobile/widgets/product_list_item.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'app_locale': 'ru'});
    final localeController = LocaleController();
    final apiClient = ApiClient();
    await localeController.loadLocale();

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
            create: (_) => MobileBackendController(
              MobileBackendRepositoryImpl(apiClient),
              MobilePushNotificationService(apiClient),
            ),
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Здравствуйте, Гость.'), findsOneWidget);
    expect(find.text('Главная'), findsOneWidget);
    expect(find.text('Меню'), findsWidgets);
    for (var index = 0; index < 5; index++) {
      expect(find.byKey(ValueKey<String>('main-tab-$index')), findsOneWidget);
    }
    expect(_cartBadge(tester).isLabelVisible, isFalse);

    final pageView = find.byKey(const ValueKey<String>('main-tabs-page-view'));
    expect(_tabSemantics(tester, 0).properties.selected, isTrue);

    await tester.drag(pageView, const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(_tabSemantics(tester, 0).properties.selected, isFalse);
    expect(_tabSemantics(tester, 1).properties.selected, isTrue);
    expect(tester.widget<PageView>(pageView).controller!.page, 1);
    expect(find.text('Список пуст'), findsOneWidget);

    await tester.drag(pageView, const Offset(500, 0));
    await tester.pumpAndSettle();

    expect(_tabSemantics(tester, 0).properties.selected, isTrue);
    expect(_tabSemantics(tester, 1).properties.selected, isFalse);
    expect(tester.widget<PageView>(pageView).controller!.page, 0);

    await tester.tap(find.byKey(const ValueKey<String>('main-tab-1')));
    await tester.pumpAndSettle();
    expect(_tabSemantics(tester, 0).properties.selected, isFalse);
    expect(_tabSemantics(tester, 1).properties.selected, isTrue);
    expect(tester.widget<PageView>(pageView).controller!.page, 1);
    expect(find.text('Список пуст'), findsOneWidget);
  });

  testWidgets('cart badge follows committed quantity before motion settles', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'app_locale': 'ru'});
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
            create: (_) => _CatalogController(apiClient),
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('main-tab-1')));
    await tester.pumpAndSettle();
    expect(_cartBadge(tester).isLabelVisible, isFalse);

    final product = find.byType(ProductListItem);
    await tester.tap(
      find.descendant(of: product, matching: find.byIcon(Icons.add_rounded)),
    );
    await tester.pump();

    // The cart owns its count: the badge updates on the first frame, while
    // decorative motion is still running.
    expect(_cartBadge(tester).isLabelVisible, isTrue);
    expect((_cartBadge(tester).label! as Text).data, '1');
    await tester.pumpAndSettle();
    expect((_cartBadge(tester).label! as Text).data, '1');

    await tester.tap(
      find.descendant(of: product, matching: find.byIcon(Icons.add_rounded)),
    );
    await tester.pump();
    expect((_cartBadge(tester).label! as Text).data, '2');
    await tester.pumpAndSettle();
    expect((_cartBadge(tester).label! as Text).data, '2');

    for (var quantity = 1; quantity >= 0; quantity--) {
      await tester.tap(
        find.descendant(
          of: product,
          matching: find.byIcon(Icons.remove_rounded),
        ),
      );
      await tester.pumpAndSettle();
      expect(_cartBadge(tester).isLabelVisible, quantity > 0);
      expect((_cartBadge(tester).label! as Text).data, '$quantity');
    }
    expect(tester.takeException(), isNull);
  });
}

Semantics _tabSemantics(WidgetTester tester, int index) =>
    tester.widget<Semantics>(
      find
          .descendant(
            of: find.byKey(ValueKey<String>('main-tab-$index')),
            matching: find.byType(Semantics),
          )
          .first,
    );

Badge _cartBadge(WidgetTester tester) => tester.widget<Badge>(
  find.descendant(
    of: find.byKey(const ValueKey<String>('main-tab-3')),
    matching: find.byType(Badge),
  ),
);

class _CatalogController extends MobileBackendController {
  _CatalogController(ApiClient apiClient)
    : super(
        MobileBackendRepositoryImpl(apiClient),
        MobilePushNotificationService(apiClient),
      );

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
