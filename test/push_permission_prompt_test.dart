import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:enjoy_lavash_mobile/core/api/api_client.dart';
import 'package:enjoy_lavash_mobile/core/api/api_endpoints.dart';
import 'package:enjoy_lavash_mobile/core/error/result.dart';
import 'package:enjoy_lavash_mobile/core/services/mobile_push_notification_service.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/auth_models.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/catalog_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/client_notification_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/client_profile_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/domain/entities/mobile_bootstrap.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/domain/repositories/mobile_backend_repository.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/presentation/mobile_backend_controller.dart';
import 'package:enjoy_lavash_mobile/features/push_permission/push_reminder_schedule.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _permissionChannel = MethodChannel(
  'flutter.baseflow.com/permissions/methods',
);
const _apnsChannel = MethodChannel('enjoy_lavash_mobile/apns');

/// The OS notification prompt is shown once, on app entry or at sign-in;
/// background refreshes never show it. After that a signed-in customer with
/// notifications off gets the in-app reminder on a schedule.
void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  late PermissionStatus permissionStatus;
  late PermissionStatus requestResult;
  late bool rationale;
  late int permissionRequestCount;
  late int openSettingsCount;
  late DateTime now;
  late _RecordingAdapter adapter;
  late _Repository repository;
  late MobileBackendController controller;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    permissionStatus = PermissionStatus.denied;
    requestResult = PermissionStatus.granted;
    rationale = false;
    permissionRequestCount = 0;
    openSettingsCount = 0;
    now = DateTime.utc(2026, 11, 11, 10);
    SharedPreferences.setMockInitialValues(<String, Object>{});
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'mobile_client_access_token': 'client-access-token',
    });
    PackageInfo.setMockInitialValues(
      appName: 'Enjoy Lavash',
      packageName: 'com.aurumdev.enjoy_lavash_mobile',
      version: '1.2.3',
      buildNumber: '45',
      buildSignature: '',
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      _permissionChannel,
      (call) async {
        switch (call.method) {
          case 'checkPermissionStatus':
            return permissionStatus.index;
          case 'requestPermissions':
            permissionRequestCount++;
            permissionStatus = requestResult;
            return <int, int>{
              Permission.notification.value: permissionStatus.index,
            };
          case 'shouldShowRequestPermissionRationale':
            return rationale;
          case 'openAppSettings':
            openSettingsCount++;
            return true;
          default:
            return null;
        }
      },
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      _apnsChannel,
      (call) async => 'native-apns-token',
    );

    adapter = _RecordingAdapter();
    repository = _Repository();
    controller = MobileBackendController(
      repository,
      MobilePushNotificationService(
        ApiClient(baseUrl: 'https://example.test', httpClientAdapter: adapter),
      ),
      clock: () => now,
    );
  });

  Future<void> signIn() async {
    repository.bootstrapResult.complete(Success(_signedInBootstrap));
    await controller.bootstrap(language: 'uz');
    await _settle();
  }

  /// A later launch: the OS prompt was shown before and refused.
  Future<void> refusedBefore({DateTime? at}) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'push_permission_prompt_shown': true,
      if (at != null) 'push_permission_asked_at': at.millisecondsSinceEpoch,
      if (at != null) 'push_permission_ask_count': 1,
    });
    permissionStatus = PermissionStatus.permanentlyDenied;
  }

  Future<int> reminderSignals(Future<void> Function() action) async {
    var count = 0;
    final subscription = controller.pushPermissionReminderDue.listen(
      (_) => count++,
    );
    await action();
    await _settle();
    await subscription.cancel();
    return count;
  }

  tearDown(() {
    controller.dispose();
    debugDefaultTargetPlatformOverride = null;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      _permissionChannel,
      null,
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(_apnsChannel, null);
  });

  test(
    'a guest entering the app is asked, but no token is registered',
    () async {
      await controller.requestPushNotificationPermission(locale: 'uz');

      expect(permissionRequestCount, 1);
      expect(controller.pushNotificationSettings?.permissionGranted, isTrue);
      expect(adapter.pushRegistrations, isEmpty);
    },
  );

  test(
    'a signed-in customer entering the app is asked and registered',
    () async {
      repository.bootstrapResult.complete(Success(_signedInBootstrap));
      await controller.bootstrap(language: 'uz');
      // The bootstrap refresh runs in the background and never prompts.
      await _settle();
      expect(permissionRequestCount, 0);
      expect(adapter.pushRegistrations, isEmpty);

      await controller.requestPushNotificationPermission(locale: 'uz');

      expect(permissionRequestCount, 1);
      expect(adapter.pushRegistrations, hasLength(1));
      expect(controller.pushNotificationSettings?.enabled, isTrue);
    },
  );

  test('signing in asks for permission and registers the token', () async {
    await controller.verifyOtp(
      const VerifyOtpRequest(phoneNumber: '+998901234567', code: '1111'),
    );
    await _settle();
    // The sign-in screen asks once the code is accepted, not the request.
    expect(permissionRequestCount, 0);

    expect(
      await controller.requestFirstPushNotificationPrompt(locale: 'en'),
      isTrue,
    );
    await _settle();

    expect(permissionRequestCount, 1);
    expect(adapter.pushRegistrations, hasLength(1));
    final payload =
        adapter.pushRegistrations.single.data as Map<String, Object?>;
    expect(payload['token'], 'native-apns-token');
    expect(payload['locale'], 'en');
    // Asked once: the OS prompt is never shown directly again.
    expect(
      await controller.requestFirstPushNotificationPrompt(locale: 'en'),
      isFalse,
    );
    expect(permissionRequestCount, 1);
  });

  test('a refusal at the first prompt is not reminded about at once', () async {
    requestResult = PermissionStatus.permanentlyDenied;
    await signIn();

    final signals = await reminderSignals(
      () => controller.requestPushNotificationPermission(locale: 'uz'),
    );

    expect(permissionRequestCount, 1);
    expect(signals, 0);
    expect(await controller.takePushPermissionReminder(), isNull);
  });

  test('a later launch reminds instead of prompting again', () async {
    await refusedBefore();
    await signIn();

    final signals = await reminderSignals(
      () => controller.requestPushNotificationPermission(locale: 'uz'),
    );

    expect(permissionRequestCount, 0);
    expect(signals, 1);
    // iOS shows its prompt once: the reminder leads to the phone settings.
    expect(
      await controller.takePushPermissionReminder(),
      PushReminderAction.openSettings,
    );
  });

  test('reminders follow the schedule: one day, then every three', () async {
    final firstAsk = now;
    await refusedBefore(at: firstAsk);
    await signIn();

    now = firstAsk.add(const Duration(hours: 23));
    expect(await controller.takePushPermissionReminder(), isNull);

    now = firstAsk.add(const Duration(days: 1));
    expect(await controller.takePushPermissionReminder(), isNotNull);
    expect(await controller.takePushPermissionReminder(), isNull);

    now = now.add(const Duration(days: 2));
    expect(await controller.takePushPermissionReminder(), isNull);
    now = now.add(const Duration(days: 1));
    expect(await controller.takePushPermissionReminder(), isNotNull);

    now = now.add(const Duration(days: 3));
    expect(await controller.takePushPermissionReminder(), isNotNull);
    // Sign-in reminds regardless of the schedule.
    expect(
      await controller.takePushPermissionReminder(ignoreSchedule: true),
      isNotNull,
    );
  });

  test('no reminder for guests or after switching notifications off', () async {
    await refusedBefore();
    final guestSignals = await reminderSignals(
      () => controller.requestPushNotificationPermission(locale: 'uz'),
    );
    expect(guestSignals, 0);
    expect(await controller.takePushPermissionReminder(), isNull);

    await signIn();
    await controller.setPushNotificationsEnabled(false);
    expect(
      await controller.takePushPermissionReminder(ignoreSchedule: true),
      isNull,
    );
  });

  test(
    'on Android the reminder offers the OS prompt while it still shows',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await refusedBefore();
      // Android reports a refusal as plain "denied"; the rationale flag tells
      // whether the OS will show its prompt again.
      permissionStatus = PermissionStatus.denied;
      rationale = true;
      await signIn();

      expect(
        await controller.takePushPermissionReminder(ignoreSchedule: true),
        PushReminderAction.systemPrompt,
      );

      rationale = false;
      expect(
        await controller.takePushPermissionReminder(ignoreSchedule: true),
        PushReminderAction.openSettings,
      );
    },
  );

  test('accepting the OS prompt from a reminder registers the token', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    SharedPreferences.setMockInitialValues(<String, Object>{
      'push_permission_prompt_shown': true,
    });
    await signIn();

    await controller.acceptPushPermissionReminder(
      PushReminderAction.systemPrompt,
    );
    await _settle();

    expect(permissionRequestCount, 1);
    expect(adapter.pushRegistrations, hasLength(1));
    // Notifications are on: the schedule starts over.
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.containsKey('push_permission_ask_count'), isFalse);
  });

  test('allowing in the phone settings registers on return', () async {
    await refusedBefore();
    await signIn();
    unawaited(controller.handleAppResumed(locale: 'uz'));
    await _settle();
    expect(adapter.pushRegistrations, isEmpty);

    await controller.acceptPushPermissionReminder(
      PushReminderAction.openSettings,
    );
    expect(openSettingsCount, 1);

    // Allowed in the settings; back in the app inside the resume throttle.
    permissionStatus = PermissionStatus.granted;
    unawaited(controller.handleAppResumed(locale: 'uz'));
    await _settle();

    expect(adapter.pushRegistrations, hasLength(1));
    expect(controller.pushNotificationSettings?.enabled, isTrue);
  });

  test('isPushReminderDue', () {
    final asked = DateTime.utc(2026, 1, 1);
    expect(
      isPushReminderDue(now: asked, lastAskedAt: null, timesAsked: 0),
      isTrue,
    );
    expect(
      isPushReminderDue(
        now: asked.add(const Duration(hours: 23)),
        lastAskedAt: asked,
        timesAsked: 1,
      ),
      isFalse,
    );
    expect(
      isPushReminderDue(
        now: asked.add(const Duration(days: 2)),
        lastAskedAt: asked,
        timesAsked: 5,
      ),
      isFalse,
    );
    expect(
      isPushReminderDue(
        now: asked.add(const Duration(days: 3)),
        lastAskedAt: asked,
        timesAsked: 5,
      ),
      isTrue,
    );
    // A clock set backwards does not silence reminders.
    expect(
      isPushReminderDue(
        now: asked.subtract(const Duration(days: 1)),
        lastAskedAt: asked,
        timesAsked: 1,
      ),
      isTrue,
    );
  });

  test('a permanently denied permission is left alone', () async {
    permissionStatus = PermissionStatus.permanentlyDenied;

    await controller.requestPushNotificationPermission(locale: 'uz');

    expect(permissionRequestCount, 0);
    expect(
      controller.pushNotificationSettings?.permissionPermanentlyDenied,
      isTrue,
    );
  });
}

Future<void> _settle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

final ClientProfile _client = ClientProfile.fromJson(const {
  'id': 'client-1',
  'fullName': 'Ali',
  'phoneNumber': '+998901234567',
  'language': 'en',
});

final MobileBootstrap _signedInBootstrap = MobileBootstrap(
  branches: const [],
  catalog: CatalogModel.fromJson(const {'categories': []}),
  promotions: const [],
  paymentMethods: const [],
  client: _client,
);

class _Repository implements MobileBackendRepository {
  final Completer<Result<MobileBootstrap>> bootstrapResult =
      Completer<Result<MobileBootstrap>>();

  @override
  Future<Result<MobileBootstrap>> bootstrap({
    required String language,
    String? branchId,
  }) {
    return bootstrapResult.future;
  }

  @override
  Future<Result<VerifyOtpResponse>> verifyOtp(VerifyOtpRequest request) async {
    return Success(
      VerifyOtpResponse(
        accessToken: 'access',
        refreshToken: 'refresh',
        refreshTokenExpiresAt: DateTime.utc(2027),
        tokenType: 'Bearer',
        client: _client,
      ),
    );
  }

  @override
  Future<Result<ClientNotificationInboxModel>> getNotifications({
    int limit = 50,
    int offset = 0,
    bool unreadOnly = false,
  }) async {
    return Success(
      ClientNotificationInboxModel(
        items: const [],
        unreadCount: 0,
        total: 0,
        limit: limit,
        offset: offset,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Background refreshes are not under test; keep them inert.
    if (invocation.isMethod) return Completer<Never>().future;
    return super.noSuchMethod(invocation);
  }
}

class _RecordingAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = <RequestOptions>[];

  List<RequestOptions> get pushRegistrations => requests
      .where((r) => r.uri.path == ApiEndpoints.clientPushTokens)
      .toList();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode({'id': 'registration-1'}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
