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
  late int permissionRequestCount;
  late int apnsTokenRequestCount;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    permissionStatus = PermissionStatus.denied;
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
            permissionStatus = PermissionStatus.granted;
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
}

MobilePushNotificationService _service(HttpClientAdapter adapter) {
  return MobilePushNotificationService(
    ApiClient(baseUrl: 'https://example.test', httpClientAdapter: adapter),
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
