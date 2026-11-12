// The notification reminder in the shell: it opens a moment after the
// controller says one is due, waits while something else is open on top of
// the tabs (another screen, the start-up birth-date prompt, the update
// prompt), and its sheet stays usable on a small screen with large text.

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
import 'package:enjoy_lavash_mobile/features/push_permission/presentation/push_permission_sheet.dart';
import 'package:enjoy_lavash_mobile/features/push_permission/push_reminder_schedule.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/navigation/main_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
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

  testWidgets('"Don\'t remind me" stops the reminders', (tester) async {
    final backend = _ReminderController();
    await _pumpShell(tester, backend);

    backend.signalReminderDue();
    await tester.pump(_afterStartupDelay);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('push-permission-never')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('push-permission-sheet')), findsNothing);
    expect(backend.stopCalls, 1);
    expect(backend.accepted, isEmpty);
  });

  testWidgets('it waits while another screen is open, and opens when the '
      'app next says it is due', (tester) async {
    final backend = _ReminderController();
    await _pumpShell(tester, backend);
    final navigator = Navigator.of(tester.element(find.byType(MainTabs)));
    unawaited(
      navigator.push(
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

    navigator.pop();
    await tester.pumpAndSettle();
    // Coming back to the app signals again.
    backend.signalReminderDue();
    await tester.pump(_afterStartupDelay);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('push-permission-sheet')), findsOneWidget);
    expect(backend.takeCalls, 1);
  });

  testWidgets('it follows the start-up birth-date prompt instead of being '
      'lost behind it', (tester) async {
    final backend = _ReminderController(hasBirthDate: false);
    await _pumpShell(tester, backend);
    expect(
      find.byKey(const ValueKey<String>('birth-date-close-button')),
      findsOneWidget,
    );

    backend.signalReminderDue();
    await tester.pump(_afterStartupDelay);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('push-permission-sheet')), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey<String>('birth-date-close-button')),
    );
    await tester.pumpAndSettle();
    await tester.pump(_afterStartupDelay);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('push-permission-sheet')), findsOneWidget);
    expect(backend.takeCalls, 1);
  });

  testWidgets('it does not open over the update prompt', (tester) async {
    PackageInfo.setMockInitialValues(
      appName: 'Enjoy Lavash',
      packageName: 'com.aurumdev.enjoy_lavash_mobile',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    final backend = _ReminderController(updateRequired: true);
    await _pumpShell(tester, backend, settle: false);
    // The prompt is really there.
    expect(find.text('Update required'), findsWidgets);

    backend.signalReminderDue();
    await tester.pump(_afterStartupDelay);
    await tester.pump(const Duration(seconds: 1));

    expect(find.byKey(const ValueKey('push-permission-sheet')), findsNothing);
    expect(backend.takeCalls, 0);
  });

  testWidgets('the sheet scrolls instead of cutting its buttons off on a '
      'small screen with large text', (tester) async {
    _usePhoneScreen(tester, const Size(320, 480));
    PushPermissionChoice? choice;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('uz'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.6)),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () async {
                  choice = await showModalBottomSheet<PushPermissionChoice>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const PushPermissionSheet(
                      action: PushReminderAction.openSettings,
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Nothing overflowed, and the sheet left room above itself.
    expect(tester.takeException(), isNull);
    final sheet = tester.getSize(
      find.byKey(const ValueKey('push-permission-sheet')),
    );
    expect(sheet.height, lessThanOrEqualTo(480 * 0.88 + 0.5));

    // The last action is reached by scrolling and works.
    final never = find.byKey(const ValueKey('push-permission-never'));
    await tester.ensureVisible(never);
    await tester.pumpAndSettle();
    await tester.tap(never);
    await tester.pumpAndSettle();
    expect(choice, PushPermissionChoice.never);
  });
}

/// A phone screen of [size] logical pixels. Unlike `setSurfaceSize`, this
/// is also what `MediaQuery` reports, which the sheet sizes itself by.
void _usePhoneScreen(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}

Future<void> _pumpShell(
  WidgetTester tester,
  _ReminderController backend, {
  bool settle = true,
}) async {
  SharedPreferences.setMockInitialValues({'app_locale': 'en'});
  _usePhoneScreen(tester, const Size(390, 844));
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
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    // The update prompt animates for as long as it shows.
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
}

class _ReminderController extends MobileBackendController {
  _ReminderController({bool hasBirthDate = true, bool updateRequired = false})
    : this._(
        ApiClient(baseUrl: 'https://example.test'),
        hasBirthDate: hasBirthDate,
        updateRequired: updateRequired,
      );

  _ReminderController._(
    ApiClient apiClient, {
    required this.hasBirthDate,
    required this.updateRequired,
  }) : super(
         MobileBackendRepositoryImpl(apiClient),
         MobilePushNotificationService(apiClient),
       );

  final bool hasBirthDate;
  final bool updateRequired;
  final StreamController<void> _due = StreamController<void>.broadcast();
  int takeCalls = 0;
  int stopCalls = 0;
  final List<PushReminderAction> accepted = <PushReminderAction>[];

  void signalReminderDue() => _due.add(null);

  @override
  Stream<void> get pushPermissionReminderDue => _due.stream;

  @override
  Future<PushReminderAction?> takePushPermissionReminder({
    bool atSignIn = false,
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
  Future<void> stopPushPermissionReminders() async {
    stopCalls++;
  }

  @override
  MobileBackendStatus get status => MobileBackendStatus.loaded;

  @override
  bool get isAuthenticated => true;

  @override
  ClientProfile? get client => hasBirthDate ? _client : _clientNoBirthDate;

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
  }) async => updateRequired
      ? const Success(
          AppVersionPolicyModel(
            id: 'policy-1',
            platform: 'android',
            latestVersion: '9.0.0',
            minSupportedVersion: '9.0.0',
            description: 'Update required',
            appUrl: 'https://play.google.com/store/apps/details?id=app',
            updateAvailable: true,
            forceUpdate: true,
          ),
        )
      : const Error(NetworkFailure());

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

final ClientProfile _clientNoBirthDate = ClientProfile.fromJson(const {
  'id': 'client-1',
  'fullName': 'Ali Valiyev',
  'phoneNumber': '+998901234567',
  'language': 'en',
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
