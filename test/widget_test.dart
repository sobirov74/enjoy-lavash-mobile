// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:enjoy_lavash_mobile/app/app.dart';
import 'package:enjoy_lavash_mobile/app/locale_controller.dart';
import 'package:enjoy_lavash_mobile/app/location_controller.dart';
import 'package:enjoy_lavash_mobile/app/theme_controller.dart';
import 'package:enjoy_lavash_mobile/core/api/api_client.dart';
import 'package:enjoy_lavash_mobile/core/services/yandex_geocoder_service.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/repositories/mobile_backend_repository_impl.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/presentation/mobile_backend_controller.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'app_locale': 'ru'});
    final localeController = LocaleController();
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
              MobileBackendRepositoryImpl(ApiClient()),
            ),
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Enjoy Lavash'), findsOneWidget);
    expect(find.text('Меню'), findsOneWidget);
    expect(find.text('Список пуст'), findsOneWidget);
  });
}
