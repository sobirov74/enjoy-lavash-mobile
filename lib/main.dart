import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:enjoy_lavash_mobile/app/app.dart';
import 'package:enjoy_lavash_mobile/app/di.dart';
import 'package:enjoy_lavash_mobile/app/locale_controller.dart';
import 'package:enjoy_lavash_mobile/app/location_controller.dart';
import 'package:enjoy_lavash_mobile/app/theme_controller.dart';
import 'package:enjoy_lavash_mobile/core/api/api_client.dart';
import 'package:enjoy_lavash_mobile/core/services/yandex_geocoder_service.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/domain/repositories/mobile_backend_repository.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/presentation/mobile_backend_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  setupDi();

  final themeController = ThemeController();
  final localeController = LocaleController();
  final locationController = LocationController(YandexGeocoderService());
  final mobileBackendController = MobileBackendController(
    sl<MobileBackendRepository>(),
  );
  sl<ApiClient>().setOnLogout(mobileBackendController.handleSessionExpired);

  await Future.wait([
    themeController.loadTheme(),
    localeController.loadLocale(),
  ]);

  // Request location permission on startup
  unawaited(locationController.requestPermissionAndLocate());
  unawaited(
    mobileBackendController.bootstrap(
      language: localeController.locale.languageCode,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeController>.value(value: themeController),
        ChangeNotifierProvider<LocaleController>.value(value: localeController),
        ChangeNotifierProvider<LocationController>.value(
          value: locationController,
        ),
        ChangeNotifierProvider<MobileBackendController>.value(
          value: mobileBackendController,
        ),
      ],
      child: const MyApp(),
    ),
  );
}
