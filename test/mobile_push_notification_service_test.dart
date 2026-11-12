import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:enjoy_lavash_mobile/core/api/api_client.dart';
import 'package:enjoy_lavash_mobile/core/api/api_endpoints.dart';
import 'package:enjoy_lavash_mobile/core/services/mobile_push_notification_service.dart';
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

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  late PermissionStatus permissionStatus;
  late PermissionStatus requestResult;
  late int permissionRequestCount;
  late int apnsTokenRequestCount;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    permissionStatus = PermissionStatus.denied;
    requestResult = PermissionStatus.granted;
    permissionRequestCount = 0;
    apnsTokenRequestCount = 0;

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
            expect(call.arguments, Permission.notification.value);
            return permissionStatus.index;
          case 'requestPermissions':
            permissionRequestCount++;
            permissionStatus = requestResult;
            return <int, int>{
              Permission.notification.value: permissionStatus.index,
            };
          default:
            return null;
        }
      },
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(_apnsChannel, (
      call,
    ) async {
      expect(call.method, 'requestToken');
      apnsTokenRequestCount++;
      return 'native-apns-token';
    });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      _permissionChannel,
      null,
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(_apnsChannel, null);
  });

  test('background sync does not request notification permission', () async {
    final adapter = _RecordingAdapter();
    final service = _service(adapter);

    await service.syncTokenIfPermissionGranted(locale: 'uz');

    expect(permissionRequestCount, 0);
    expect(apnsTokenRequestCount, 0);
    expect(adapter.requests, isEmpty);
  });

  test('background sync respects the in-app notification opt-out', () async {
    permissionStatus = PermissionStatus.granted;
    SharedPreferences.setMockInitialValues(<String, Object>{
      'push_notifications_enabled': false,
    });
    final adapter = _RecordingAdapter();
    final service = _service(adapter);

    await service.syncTokenIfPermissionGranted(locale: 'uz');

    expect(permissionRequestCount, 0);
    expect(apnsTokenRequestCount, 0);
    expect(adapter.requests, isEmpty);
  });

  test('granted iOS background sync posts the native APNs token', () async {
    permissionStatus = PermissionStatus.granted;
    final adapter = _RecordingAdapter();
    final service = _service(adapter);

    await service.syncTokenIfPermissionGranted(locale: 'uz');

    expect(permissionRequestCount, 0);
    expect(apnsTokenRequestCount, 1);
    expect(adapter.requests, hasLength(1));
    final request = adapter.requests.single;
    expect(request.uri.path, ApiEndpoints.clientPushTokens);
    expect(request.headers['Authorization'], 'Bearer client-access-token');

    final payload = request.data as Map<String, Object?>;
    expect(payload['platform'], 'ios');
    expect(payload['token'], 'native-apns-token');
    expect(payload['appVersion'], '1.2.3+45');
    expect(payload['locale'], 'uz');
    expect(payload['deviceId'], isNotEmpty);
  });

  test(
    'an unchanged registration is not posted again on the next sync',
    () async {
      permissionStatus = PermissionStatus.granted;
      final adapter = _RecordingAdapter();
      final service = _service(adapter);

      await service.syncTokenIfPermissionGranted(locale: 'uz');
      await service.syncTokenIfPermissionGranted(locale: 'uz');
      expect(adapter.requests, hasLength(1));

      // A different locale is a different registration.
      await service.syncTokenIfPermissionGranted(locale: 'ru');
      expect(adapter.requests, hasLength(2));
    },
  );

  test(
    'requestPermission shows the OS prompt while it is still denied',
    () async {
      final adapter = _RecordingAdapter();
      final service = _service(adapter);

      final request = await service.requestPermission();

      expect(permissionRequestCount, 1);
      expect(request.settings.permissionGranted, isTrue);
      expect(request.promptShown, isTrue);
      // Asking for permission never registers a token on its own.
      expect(apnsTokenRequestCount, 0);
      expect(adapter.requests, isEmpty);
    },
  );

  test('requestPermission does not prompt once already granted', () async {
    permissionStatus = PermissionStatus.granted;
    final service = _service(_RecordingAdapter());

    final request = await service.requestPermission();

    expect(permissionRequestCount, 0);
    expect(request.settings.enabled, isTrue);
    expect(request.promptShown, isFalse);
  });

  test('requestPermission does not prompt when the OS locked it', () async {
    permissionStatus = PermissionStatus.permanentlyDenied;
    final service = _service(_RecordingAdapter());

    final settings = (await service.requestPermission()).settings;

    expect(permissionRequestCount, 0);
    expect(settings.permissionPermanentlyDenied, isTrue);
    expect(settings.canRequestPermission, isFalse);
  });

  test('requestPermission respects the in-app notification opt-out', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'push_notifications_enabled': false,
    });
    final service = _service(_RecordingAdapter());

    final settings = (await service.requestPermission()).settings;

    expect(permissionRequestCount, 0);
    expect(settings.userEnabled, isFalse);
  });

  test(
    'explicit notification enable may request permission and sync',
    () async {
      final adapter = _RecordingAdapter();
      final service = _service(adapter);

      final settings = await service.setNotificationsEnabled(
        true,
        locale: 'ru',
      );

      expect(settings.enabled, isTrue);
      expect(permissionRequestCount, 1);
      expect(apnsTokenRequestCount, 1);
      expect(adapter.requests, hasLength(1));
      final payload = adapter.requests.single.data as Map<String, Object?>;
      expect(payload['platform'], 'ios');
      expect(payload['token'], 'native-apns-token');
      expect(payload['locale'], 'ru');
    },
  );

  group('whether the OS still shows its prompt (Android)', () {
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);

    test('a refusal the customer tapped keeps the prompt available', () async {
      requestResult = PermissionStatus.denied;
      // Any answer counts as the customer's: a prompt was shown.
      final service = _service(
        _RecordingAdapter(),
        promptAnswerThreshold: Duration.zero,
      );

      final request = await service.requestPermission();

      expect(request.promptShown, isTrue);
      expect(request.settings.canRequestPermission, isTrue);
      expect((await service.getSettings()).canRequestPermission, isTrue);
    });

    test('a second refusal is the last prompt', () async {
      requestResult = PermissionStatus.permanentlyDenied;
      final service = _service(
        _RecordingAdapter(),
        promptAnswerThreshold: Duration.zero,
      );

      final request = await service.requestPermission();
      // Android reports plain "denied" from a status check afterwards.
      permissionStatus = PermissionStatus.denied;

      expect(request.promptShown, isTrue);
      expect(request.settings.permissionPermanentlyDenied, isTrue);
      expect((await service.getSettings()).canRequestPermission, isFalse);
      // Known to be useless: not requested again.
      await service.requestPermission();
      expect(permissionRequestCount, 1);
    });

    test(
      'an answer faster than a person means the OS showed nothing',
      () async {
        // Android 12 and lower, or an install the OS already stopped asking.
        requestResult = PermissionStatus.denied;
        final service = _service(_RecordingAdapter());

        final request = await service.requestPermission();

        expect(request.promptShown, isFalse);
        expect(request.settings.permissionPermanentlyDenied, isTrue);
        expect((await service.getSettings()).canRequestPermission, isFalse);
      },
    );

    test('allowing in the phone settings forgets what was learned', () async {
      requestResult = PermissionStatus.denied;
      final service = _service(_RecordingAdapter());
      await service.requestPermission();
      expect((await service.getSettings()).canRequestPermission, isFalse);

      permissionStatus = PermissionStatus.granted;
      expect((await service.getSettings()).enabled, isTrue);
      // Switched off again later: the prompt gets another try.
      permissionStatus = PermissionStatus.denied;
      expect((await service.getSettings()).canRequestPermission, isTrue);
    });
  });

  test('"don\'t remind me" holds until notifications are switched on in the '
      'app', () async {
    final service = _service(_RecordingAdapter());
    expect(await service.permissionRemindersStopped(), isFalse);

    await service.stopPermissionReminders();
    expect(await service.permissionRemindersStopped(), isTrue);
    // It is not the in-app opt-out: allowing in the phone settings works.
    expect((await service.getSettings()).userEnabled, isTrue);

    await service.setNotificationsEnabled(true, locale: 'uz');
    expect(await service.permissionRemindersStopped(), isFalse);
  });
}

MobilePushNotificationService _service(
  HttpClientAdapter adapter, {
  Duration? promptAnswerThreshold,
}) {
  final apiClient = ApiClient(
    baseUrl: 'https://example.test',
    httpClientAdapter: adapter,
  );
  return promptAnswerThreshold == null
      ? MobilePushNotificationService(apiClient)
      : MobilePushNotificationService(
          apiClient,
          promptAnswerThreshold: promptAnswerThreshold,
        );
}

class _RecordingAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(<String, Object?>{'id': 'push-registration-id'}),
      201,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
