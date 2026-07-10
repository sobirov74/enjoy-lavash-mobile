import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:enjoy_lavash_mobile/app/app.dart';
import 'package:enjoy_lavash_mobile/app/di.dart';
import 'package:enjoy_lavash_mobile/app/locale_controller.dart';
import 'package:enjoy_lavash_mobile/app/location_controller.dart';
import 'package:enjoy_lavash_mobile/app/theme_controller.dart';
import 'package:enjoy_lavash_mobile/core/api/api_client.dart';
import 'package:enjoy_lavash_mobile/core/services/yandex_geocoder_service.dart';
import 'package:enjoy_lavash_mobile/core/services/mobile_push_notification_service.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/domain/repositories/mobile_backend_repository.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/presentation/mobile_backend_controller.dart';

Future<void> main() async {
  await runZonedGuarded<Future<void>>(_startApp, _reportUnhandledError);
}

Future<void> _startApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    _reportUnhandledError(
      details.exception,
      details.stack ?? StackTrace.current,
    );
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    _reportUnhandledError(error, stack);
    return true;
  };

  setupDi();

  final themeController = ThemeController();
  final localeController = LocaleController();
  final locationController = LocationController(YandexGeocoderService());
  final apiClient = sl<ApiClient>();
  final mobileBackendController = MobileBackendController(
    sl<MobileBackendRepository>(),
    sl<MobilePushNotificationService>(),
  );
  apiClient.setOnLogout(mobileBackendController.handleSessionExpired);
  unawaited(
    _runStartupTask(
      'push message handlers',
      sl<MobilePushNotificationService>().configureMessageHandlers,
    ),
  );

  await Future.wait([
    themeController.loadTheme(),
    localeController.loadLocale(),
  ]);
  apiClient.setLanguage(localeController.locale.languageCode);
  localeController.addListener(() {
    final language = localeController.locale.languageCode;
    apiClient.setLanguage(language);
    unawaited(
      _runStartupTask(
        'client language sync',
        () => mobileBackendController.syncClientLanguage(language: language),
      ),
    );
  });

  unawaited(
    _runStartupTask(
      'mobile backend bootstrap',
      () => mobileBackendController.bootstrap(
        language: localeController.locale.languageCode,
      ),
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

Future<void> _runStartupTask(String name, Future<void> Function() task) async {
  try {
    await task();
  } catch (error, stackTrace) {
    debugPrint('Startup task failed: $name');
    _reportUnhandledError(error, stackTrace);
  }
}

void _reportUnhandledError(Object error, StackTrace stackTrace) {
  debugPrint('Unhandled app error: $error');
  debugPrintStack(stackTrace: stackTrace);
}
