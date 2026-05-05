import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:enjoy_lavash_mobile/app/app.dart';
import 'package:enjoy_lavash_mobile/app/di.dart';
import 'package:enjoy_lavash_mobile/app/locale_controller.dart';
import 'package:enjoy_lavash_mobile/app/location_controller.dart';
import 'package:enjoy_lavash_mobile/app/theme_controller.dart';
import 'package:enjoy_lavash_mobile/core/services/yandex_geocoder_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  setupDi();

  final themeController = ThemeController();
  final localeController = LocaleController();
  final locationController = LocationController(YandexGeocoderService());

  await Future.wait([
    themeController.loadTheme(),
    localeController.loadLocale(),
  ]);

  // Request location permission on startup
  locationController.requestPermissionAndLocate();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeController>.value(value: themeController),
        ChangeNotifierProvider<LocaleController>.value(value: localeController),
        ChangeNotifierProvider<LocationController>.value(
            value: locationController),
      ],
      child: const MyApp(),
    ),
  );
}
