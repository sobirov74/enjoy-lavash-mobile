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
import 'package:enjoy_lavash_mobile/screens/home_screen.dart';
import 'package:enjoy_lavash_mobile/screens/menu_screen.dart';
import 'package:enjoy_lavash_mobile/widgets/product_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('a cart tap rebuilds the menu but not the rest of the shell', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'app_locale': 'en'});
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final localeController = LocaleController();
    await localeController.loadLocale();
    addTearDown(localeController.dispose);
    final apiClient = ApiClient();
    final backend = _CatalogController(apiClient);

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
          ChangeNotifierProvider<MobileBackendController>.value(value: backend),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('main-tab-1')));
    await tester.pumpAndSettle();

    HomeScreen home() =>
        tester.widget<HomeScreen>(find.byType(HomeScreen, skipOffstage: false));
    MenuScreen menu() => tester.widget<MenuScreen>(find.byType(MenuScreen));
    final homeBefore = home();
    final menuBefore = menu();

    await tester.tap(
      find.descendant(
        of: find.byType(ProductListItem),
        matching: find.byIcon(Icons.add_rounded),
      ),
    );
    await tester.pumpAndSettle();

    // The shell did not rebuild: Home is the very same widget instance.
    expect(identical(home(), homeBefore), isTrue);
    // The menu did, with the new count.
    expect(identical(menu(), menuBefore), isFalse);
    expect(menu().cartCount, 1);

    // A backend notification about data the shell does not render (here a
    // notifyListeners with nothing changed) does not rebuild it either.
    backend.ping();
    await tester.pump();
    expect(identical(home(), homeBefore), isTrue);
  });
}

class _CatalogController extends MobileBackendController {
  _CatalogController(ApiClient apiClient)
    : super(
        MobileBackendRepositoryImpl(apiClient),
        MobilePushNotificationService(apiClient),
      );

  void ping() => notifyListeners();

  @override
  List<String> get menuCategories => const ['Lavash'];

  @override
  List<MenuProduct> get menuProducts => _products;
}

const List<MenuProduct> _products = <MenuProduct>[
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
