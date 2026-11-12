// The app-entry notification reminder: the shell shows it a moment after
// the controller says one is due, and leaves it for a later launch while
// another screen is open on top of the tabs.

import 'dart:async';

import 'package:enjoy_lavash_mobile/app/app.dart';
import 'package:enjoy_lavash_mobile/app/locale_controller.dart';
import 'package:enjoy_lavash_mobile/app/location_controller.dart';
import 'package:enjoy_lavash_mobile/app/theme_controller.dart';
import 'package:enjoy_lavash_mobile/core/api/api_client.dart';
import 'package:enjoy_lavash_mobile/core/error/failures.dart';
import 'package:enjoy_lavash_mobile/core/error/result.dart';
import 'package:enjoy_lavash_mobile/core/services/mobile_push_notification_service.dart';
import 'package:enjoy_lavash_mobile/core/services/yandex_geocoder_service.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/app_version_policy_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/client_profile_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/repositories/mobile_backend_repository_impl.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/presentation/mobile_backend_controller.dart';
import 'package:enjoy_lavash_mobile/features/models/menu_product.dart';
import 'package:enjoy_lavash_mobile/features/push_permission/push_reminder_schedule.dart';
import 'package:enjoy_lavash_mobile/navigation/main_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Longer than the shell's start-up delay before the reminder.
const Duration _afterStartupDelay = Duration(seconds: 3);

void main() {
  testWidgets('a due reminder shows over the tabs and opens the settings', (
    tester,
  ) async {
    final backend = _ReminderController();
    await _pumpShell(tester, backend);

    backend.signalReminderDue();
    await tester.pump();
    expect(find.byKey(const ValueKey('push-permission-sheet')), findsNothing);

    await tester.pump(_afterStartupDelay);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('push-permission-sheet')), findsOneWidget);
    expect(find.text('Open settings'), findsOneWidget);
    expect(backend.takeCalls, 1);

    await tester.tap(find.byKey(const ValueKey('push-permission-accept')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('push-permission-sheet')), findsNothing);
    expect(backend.accepted, [PushReminderAction.openSettings]);
  });

  testWidgets('"Not now" closes the reminder and changes nothing', (
    tester,
  ) async {
    final backend = _ReminderController();
    await _pumpShell(tester, backend);

    backend.signalReminderDue();
    await tester.pump(_afterStartupDelay);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('push-permission-later')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('push-permission-sheet')), findsNothing);
    expect(backend.accepted, isEmpty);
  });

  testWidgets('no reminder while another screen is open on top', (
    tester,
  ) async {
    final backend = _ReminderController();
    await _pumpShell(tester, backend);
    unawaited(
      Navigator.of(tester.element(find.byType(MainTabs))).push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Other screen')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    backend.signalReminderDue();
    await tester.pump(_afterStartupDelay);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('push-permission-sheet')), findsNothing);
    // Not taken, so it is not counted as shown and stays due.
    expect(backend.takeCalls, 0);
  });
}

Future<void> _pumpShell(
  WidgetTester tester,
  _ReminderController backend,
) async {
  SharedPreferences.setMockInitialValues({'app_locale': 'en'});
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final localeController = LocaleController();
  await localeController.loadLocale();
  addTearDown(localeController.dispose);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeController>(
          create: (_) => ThemeController(),
        ),
        ChangeNotifierProvider<LocaleController>.value(value: localeController),
        ChangeNotifierProvider<LocationController>(
          create: (_) => LocationController(YandexGeocoderService()),
        ),
        ChangeNotifierProvider<MobileBackendController>.value(value: backend),
      ],
      child: const MyApp(),
    ),
  );
  await tester.pumpAndSettle();
}

class _ReminderController extends MobileBackendController {
  _ReminderController() : this._(ApiClient(baseUrl: 'https://example.test'));

  _ReminderController._(ApiClient apiClient)
    : super(
        MobileBackendRepositoryImpl(apiClient),
        MobilePushNotificationService(apiClient),
      );

  final StreamController<void> _due = StreamController<void>.broadcast();
  int takeCalls = 0;
  final List<PushReminderAction> accepted = <PushReminderAction>[];

  void signalReminderDue() => _due.add(null);

  @override
  Stream<void> get pushPermissionReminderDue => _due.stream;

  @override
  Future<PushReminderAction?> takePushPermissionReminder({
    bool ignoreSchedule = false,
  }) async {
    takeCalls++;
    return PushReminderAction.openSettings;
  }

  @override
  Future<void> acceptPushPermissionReminder(
    PushReminderAction action, {
    String? locale,
  }) async {
    accepted.add(action);
  }

  @override
  MobileBackendStatus get status => MobileBackendStatus.loaded;

  @override
  bool get isAuthenticated => true;

  @override
  ClientProfile? get client => _client;

  @override
  List<String> get menuCategories => const ['Lavash'];

  @override
  List<MenuProduct> get menuProducts => _products;

  @override
  Future<void> refreshPushNotificationSettings() async {}

  @override
  Future<Result<AppVersionPolicyModel>> getAppVersionPolicy({
    required String platform,
    String? currentVersion,
    String? language,
  }) async => const Error(NetworkFailure());

  @override
  void dispose() {
    unawaited(_due.close());
    super.dispose();
  }
}

final ClientProfile _client = ClientProfile.fromJson(const {
  'id': 'client-1',
  'fullName': 'Ali Valiyev',
  'phoneNumber': '+998901234567',
  'language': 'en',
  'birthDate': '1990-05-01',
});

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
