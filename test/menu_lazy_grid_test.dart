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
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _productCount = 60;

void main() {
  testWidgets('the menu builds only the rows near the viewport', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'app_locale': 'en'});
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
            create: (_) => _LargeCatalogController(apiClient),
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('main-tab-1')));
    await tester.pumpAndSettle();

    final built = tester.widgetList(find.byType(ProductListItem)).length;
    expect(built, greaterThan(0));
    expect(built, lessThan(_productCount));

    // Scrolling far down builds later products on demand.
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('menu-product-59')),
      600,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('menu-product-59')), findsOne);
    expect(find.byKey(const ValueKey<String>('menu-product-0')), findsNothing);
  });
}

class _LargeCatalogController extends MobileBackendController {
  _LargeCatalogController(ApiClient apiClient)
    : super(
        MobileBackendRepositoryImpl(apiClient),
        MobilePushNotificationService(apiClient),
      );

  @override
  List<String> get menuCategories => const ['Lavash'];

  @override
  List<MenuProduct> get menuProducts => _products;
}

final List<MenuProduct> _products = List<MenuProduct>.unmodifiable([
  for (var index = 0; index < _productCount; index++)
    MenuProduct(
      id: 'product-$index',
      title: 'Product $index',
      price: 30000,
      category: 'Lavash',
      emoji: '🌯',
      tint: Colors.orange,
      highlight: Colors.amber,
    ),
]);
