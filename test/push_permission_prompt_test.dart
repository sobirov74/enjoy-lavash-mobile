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

/// The OS notification prompt is shown on app entry and on login while the
/// permission is still undecided; background refreshes never show it.
void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  late PermissionStatus permissionStatus;
  late int permissionRequestCount;
  late _RecordingAdapter adapter;
  late _Repository repository;
  late MobileBackendController controller;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    permissionStatus = PermissionStatus.denied;
    permissionRequestCount = 0;
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
            permissionStatus = PermissionStatus.granted;
            return <int, int>{
              Permission.notification.value: permissionStatus.index,
            };
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
    );
  });

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

  test('logging in asks for permission and registers the token', () async {
    await controller.verifyOtp(
      const VerifyOtpRequest(phoneNumber: '+998901234567', code: '1111'),
    );
    await _settle();

    expect(permissionRequestCount, 1);
    expect(adapter.pushRegistrations, hasLength(1));
    final payload =
        adapter.pushRegistrations.single.data as Map<String, Object?>;
    expect(payload['token'], 'native-apns-token');
    expect(payload['locale'], 'en');
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
