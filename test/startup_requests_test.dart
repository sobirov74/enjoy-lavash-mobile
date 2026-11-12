import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:enjoy_lavash_mobile/core/api/api_client.dart';
import 'package:enjoy_lavash_mobile/core/api/api_endpoints.dart';
import 'package:enjoy_lavash_mobile/core/services/mobile_push_notification_service.dart';
import 'package:enjoy_lavash_mobile/core/storage/token_storage.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/repositories/mobile_backend_repository_impl.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/presentation/mobile_backend_controller.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Everything a signed-in cold start may request, each exactly once. A new
/// startup request (or a duplicate) must be added here deliberately.
const Set<String> _expectedStartupRequests = <String>{
  ApiEndpoints.branches,
  ApiEndpoints.catalog,
  ApiEndpoints.activeBanners,
  ApiEndpoints.paymentMethods,
  ApiEndpoints.clientMe,
  ApiEndpoints.clientAddresses,
  ApiEndpoints.clientOrders,
  ApiEndpoints.clientNotifications,
  ApiEndpoints.clientPromotions,
  ApiEndpoints.clientLoyaltyWallet,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  test('a signed-in cold start requests each endpoint once', () async {
    await TokenStorage.saveAccessToken('valid-access');
    final paths = <String>[];
    final apiClient = ApiClient(
      baseUrl: 'https://example.test',
      httpClientAdapter: _Adapter((options) {
        paths.add(options.uri.path);
        return _responseFor(options.uri.path);
      }),
    );
    final controller = MobileBackendController(
      MobileBackendRepositoryImpl(apiClient),
      MobilePushNotificationService(apiClient),
    );
    addTearDown(controller.dispose);

    await controller.bootstrap(language: 'en');
    // Let the post-login refreshes (inbox, promotions, wallet) finish.
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }

    expect(controller.isAuthenticated, isTrue);
    expect(paths.toSet(), _expectedStartupRequests);
    expect(paths, hasLength(_expectedStartupRequests.length));
  });
}

ResponseBody _responseFor(String path) {
  final Object body = switch (path) {
    ApiEndpoints.clientMe => {
      'id': 'client-1',
      'fullName': 'Ali',
      'phoneNumber': '+998901234567',
      'language': 'en',
    },
    ApiEndpoints.catalog => {'categories': const []},
    ApiEndpoints.clientNotifications => {
      'items': const [],
      'unreadCount': 0,
      'total': 0,
    },
    ApiEndpoints.clientLoyaltyWallet => {'spendableBalance': 0},
    _ => const <Object>[],
  };
  return ResponseBody.fromString(
    jsonEncode(body),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.onFetch);

  final ResponseBody Function(RequestOptions options) onFetch;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => onFetch(options);

  @override
  void close({bool force = false}) {}
}
