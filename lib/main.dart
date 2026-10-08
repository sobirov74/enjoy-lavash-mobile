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
import 'package:enjoy_lavash_mobile/core/services/error_reporter.dart';
import 'package:enjoy_lavash_mobile/core/services/yandex_geocoder_service.dart';
import 'package:enjoy_lavash_mobile/core/services/mobile_push_notification_service.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/domain/repositories/mobile_backend_repository.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/presentation/mobile_backend_controller.dart';

Future<void> main() async {
  await runZonedGuarded<Future<void>>(_startApp, _reportUnhandledError);
}

Future<void> _startApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Local logging only. When a SENTRY_DSN is configured, ErrorReporter.init
  // chains Sentry onto these handlers, which then reports each error once.
  FlutterError.onError = FlutterError.presentError;
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught platform error: ${error.runtimeType}');
    debugPrintStack(stackTrace: stack, maxFrames: 20);
    return true;
  };
  await ErrorReporter.init();

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

  // Both loaders fall back to defaults internally; this guard only makes sure
  // nothing unexpected can keep the app on the native splash.
  await _runStartupTask(
    'theme and locale',
    () => Future.wait([
      themeController.loadTheme(),
      localeController.loadLocale(),
    ]),
  );
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
      child: const InitialLocationLoader(child: MyApp()),
    ),
  );
}

Future<void> _runStartupTask(String name, Future<void> Function() task) async {
  try {
    await task();
  } catch (error, stackTrace) {
    ErrorReporter.report(error, stackTrace, context: 'startup: $name');
  }
}

void _reportUnhandledError(Object error, StackTrace stackTrace) {
  ErrorReporter.report(error, stackTrace, context: 'zone');
}
