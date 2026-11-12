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
/// notifications off gets the in-app reminder: on a schedule at app entry
/// and on return to the app, and at sign-in.
void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  late PermissionStatus permissionStatus;
  late PermissionStatus requestResult;
  late int permissionRequestCount;
  late int openSettingsCount;
  late DateTime now;
  late _RecordingAdapter adapter;
  late _Repository repository;
  late MobileBackendController controller;

  /// [osShowsPrompt]: the OS shows its dialog and the customer answers it.
  /// False: the OS answers by itself at once (it has no prompt to show).
  MobileBackendController buildController({bool osShowsPrompt = true}) {
    final apiClient = ApiClient(
      baseUrl: 'https://example.test',
      httpClientAdapter: adapter,
    );
    return MobileBackendController(
      repository,
      osShowsPrompt
          ? MobilePushNotificationService(
              apiClient,
              promptAnswerThreshold: Duration.zero,
            )
          : MobilePushNotificationService(apiClient),
      clock: () => now,
    );
  }

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    permissionStatus = PermissionStatus.denied;
    requestResult = PermissionStatus.granted;
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
    controller = buildController();
  });

  void useOsThatShowsNoPrompt() {
    controller.dispose();
    controller = buildController(osShowsPrompt: false);
  }

  Future<void> signIn() async {
    repository.bootstrapResult.complete(Success(_signedInBootstrap));
    await controller.bootstrap(language: 'uz');
    await _settle();
  }

  /// A later launch: the OS prompt was shown before and refused (iOS then
  /// reports the permission as permanently denied).
  void refusedBefore({DateTime? at}) {
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

  group('the first ask', () {
    test(
      'a guest entering the app is asked, but no token is registered',
      () async {
        await controller.requestPushNotificationPermission(locale: 'uz');
        await _settle();

        expect(permissionRequestCount, 1);
        expect(controller.pushNotificationSettings?.permissionGranted, isTrue);
        expect(adapter.pushRegistrations, isEmpty);
      },
    );

    test(
      'a signed-in customer entering the app is asked and registered',
      () async {
        await signIn();
        // The bootstrap refresh runs in the background and never prompts.
        expect(permissionRequestCount, 0);
        expect(adapter.pushRegistrations, isEmpty);

        await controller.requestPushNotificationPermission(locale: 'uz');
        await _settle();

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

    test('sign-in does not wait for the registration request', () async {
      permissionStatus = PermissionStatus.granted;
      adapter.hang = true;
      await controller.verifyOtp(
        const VerifyOtpRequest(phoneNumber: '+998901234567', code: '1111'),
      );

      // Notifications are already allowed: nothing to ask, and the pending
      // registration must not hold the sign-in screen.
      final shown = await controller
          .requestFirstPushNotificationPrompt(locale: 'en')
          .timeout(const Duration(seconds: 2));

      expect(shown, isFalse);
      expect(permissionRequestCount, 0);
      expect(
        await controller.takePushPermissionReminder(atSignIn: true),
        isNull,
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

    test('a refusal is not followed by a reminder, at entry or at a sign-in '
        'minutes later', () async {
      requestResult = PermissionStatus.permanentlyDenied;
      await signIn();

      final signals = await reminderSignals(
        () => controller.requestPushNotificationPermission(locale: 'uz'),
      );

      expect(permissionRequestCount, 1);
      expect(signals, 0);
      expect(await controller.takePushPermissionReminder(), isNull);
      now = now.add(const Duration(minutes: 5));
      expect(
        await controller.takePushPermissionReminder(atSignIn: true),
        isNull,
      );
      // Later the same day a sign-in does remind.
      now = now.add(const Duration(minutes: 30));
      expect(
        await controller.takePushPermissionReminder(atSignIn: true),
        PushReminderAction.openSettings,
      );
    });

    test(
      'when the OS has no prompt to show, the reminder takes over at once',
      () async {
        // Android 12 and lower with notifications blocked, or an install the
        // OS already stopped asking: the request is answered without a dialog.
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        useOsThatShowsNoPrompt();
        requestResult = PermissionStatus.denied;
        await signIn();

        final signals = await reminderSignals(
          () => controller.requestPushNotificationPermission(locale: 'uz'),
        );

        expect(permissionRequestCount, 1);
        // Nothing was shown, so it is not counted as an ask.
        expect(signals, 1);
        expect(
          await controller.takePushPermissionReminder(),
          PushReminderAction.openSettings,
        );
      },
    );
  });

  group('reminders', () {
    test('a later launch reminds instead of prompting again', () async {
      refusedBefore();
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

    test('coming back to the app reminds too', () async {
      refusedBefore();
      await signIn();

      final signals = await reminderSignals(() async {
        unawaited(controller.handleAppResumed(locale: 'uz'));
      });

      expect(signals, 1);
    });

    test('nothing is offered before the first OS prompt was used', () async {
      // Signed in, never asked: app entry or sign-in shows the OS prompt.
      await signIn();

      final signals = await reminderSignals(() async {
        unawaited(controller.handleAppResumed(locale: 'uz'));
      });

      expect(signals, 0);
      expect(await controller.takePushPermissionReminder(), isNull);
      expect(permissionRequestCount, 0);
    });

    test('they follow the schedule: one day, then every three', () async {
      final firstAsk = now;
      refusedBefore(at: firstAsk);
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
    });

    test('no reminder for guests', () async {
      refusedBefore();
      final signals = await reminderSignals(
        () => controller.requestPushNotificationPermission(locale: 'uz'),
      );

      expect(signals, 0);
      expect(
        await controller.takePushPermissionReminder(atSignIn: true),
        isNull,
      );
    });

    test('no reminder after switching notifications off in the app', () async {
      refusedBefore();
      await signIn();
      await controller.setPushNotificationsEnabled(false);

      expect(
        await controller.takePushPermissionReminder(atSignIn: true),
        isNull,
      );
    });

    test(
      '"don\'t remind me" stops them, at entry, on return and at sign-in',
      () async {
        refusedBefore();
        await signIn();
        await controller.stopPushPermissionReminders();

        final signals = await reminderSignals(() async {
          await controller.requestPushNotificationPermission(locale: 'uz');
          unawaited(controller.handleAppResumed(locale: 'uz'));
        });

        expect(signals, 0);
        expect(await controller.takePushPermissionReminder(), isNull);
        expect(
          await controller.takePushPermissionReminder(atSignIn: true),
          isNull,
        );
      },
    );
  });

  group('accepting a reminder', () {
    test(
      'the OS prompt registers the token and restarts the schedule',
      () async {
        // Asked before, but the OS still shows its prompt.
        SharedPreferences.setMockInitialValues(<String, Object>{
          'push_permission_prompt_shown': true,
        });
        await signIn();
        expect(
          await controller.takePushPermissionReminder(),
          PushReminderAction.systemPrompt,
        );

        await controller.acceptPushPermissionReminder(
          PushReminderAction.systemPrompt,
        );
        await _settle();

        expect(permissionRequestCount, 1);
        expect(openSettingsCount, 0);
        expect(adapter.pushRegistrations, hasLength(1));
        final preferences = await SharedPreferences.getInstance();
        expect(preferences.containsKey('push_permission_ask_count'), isFalse);
      },
    );

    test('on Android a refusal in the prompt is respected; the next reminder '
        'leads to the settings', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      SharedPreferences.setMockInitialValues(<String, Object>{
        'push_permission_prompt_shown': true,
      });
      await signIn();
      expect(
        await controller.takePushPermissionReminder(),
        PushReminderAction.systemPrompt,
      );

      // The second refusal: Android will not show its prompt again.
      requestResult = PermissionStatus.permanentlyDenied;
      await controller.acceptPushPermissionReminder(
        PushReminderAction.systemPrompt,
      );
      // The customer just said no in the dialog: no trip to the settings.
      expect(openSettingsCount, 0);

      // A status check on Android only ever says "denied".
      permissionStatus = PermissionStatus.denied;
      now = now.add(const Duration(days: 3));
      expect(
        await controller.takePushPermissionReminder(),
        PushReminderAction.openSettings,
      );
    });

    test(
      'when the OS shows no prompt after all, "Allow" opens the settings',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        useOsThatShowsNoPrompt();
        SharedPreferences.setMockInitialValues(<String, Object>{
          'push_permission_prompt_shown': true,
        });
        requestResult = PermissionStatus.denied;
        await signIn();
        expect(
          await controller.takePushPermissionReminder(),
          PushReminderAction.systemPrompt,
        );

        await controller.acceptPushPermissionReminder(
          PushReminderAction.systemPrompt,
        );

        expect(permissionRequestCount, 1);
        expect(openSettingsCount, 1);
      },
    );

    test('allowing in the phone settings registers on return', () async {
      refusedBefore();
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
    // Sign-in ignores the schedule but not an ask of a moment ago.
    expect(
      isPushReminderDue(
        now: asked.add(const Duration(minutes: 29)),
        lastAskedAt: asked,
        timesAsked: 1,
        atSignIn: true,
      ),
      isFalse,
    );
    expect(
      isPushReminderDue(
        now: asked.add(const Duration(minutes: 30)),
        lastAskedAt: asked,
        timesAsked: 9,
        atSignIn: true,
      ),
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

  /// The server never answers (a dead connection).
  bool hang = false;

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
    if (hang) return Completer<ResponseBody>().future;
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
