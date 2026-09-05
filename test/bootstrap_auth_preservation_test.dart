import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:enjoy_lavash_mobile/core/api/api_client.dart';
import 'package:enjoy_lavash_mobile/core/api/api_endpoints.dart';
import 'package:enjoy_lavash_mobile/core/error/failures.dart';
import 'package:enjoy_lavash_mobile/core/error/result.dart';
import 'package:enjoy_lavash_mobile/core/services/mobile_push_notification_service.dart';
import 'package:enjoy_lavash_mobile/core/storage/token_storage.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/address_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/assigned_promotion_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/cart_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/catalog_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/client_notification_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/client_profile_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/loyalty_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/order_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/repositories/mobile_backend_repository_impl.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/domain/entities/mobile_bootstrap.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/domain/repositories/mobile_backend_repository.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/presentation/mobile_backend_controller.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  test('profile failure is propagated instead of returning a guest', () async {
    await TokenStorage.saveAccessToken('valid-access');
    final adapter = _BootstrapAdapter((options) async {
      return switch (options.uri.path) {
        ApiEndpoints.branches => _jsonResponse({'branches': const []}),
        ApiEndpoints.catalog => _jsonResponse({'categories': const []}),
        ApiEndpoints.activePromotions => _jsonResponse({
          'promotions': const [],
        }),
        ApiEndpoints.paymentMethods => _jsonResponse({
          'paymentMethods': const [],
        }),
        ApiEndpoints.clientMe => _jsonResponse({
          'message': 'Profile temporarily unavailable',
        }, statusCode: 503),
        _ => _jsonResponse({'message': 'Unexpected request'}, statusCode: 500),
      };
    });
    final repository = MobileBackendRepositoryImpl(
      ApiClient(baseUrl: 'https://example.test', httpClientAdapter: adapter),
    );

    final result = await repository.bootstrap(language: 'en');

    expect(result, isA<Error<MobileBootstrap>>());
    expect(result.failureOrNull, isA<ServiceUnavailableFailure>());
    expect(adapter.paths, contains(ApiEndpoints.clientMe));
    expect(adapter.paths, isNot(contains(ApiEndpoints.clientAddresses)));
    expect(adapter.paths, isNot(contains(ApiEndpoints.clientOrders)));
  });

  test(
    'address and order failures stay optional after profile success',
    () async {
      await TokenStorage.saveAccessToken('valid-access');
      final adapter = _BootstrapAdapter((options) async {
        return switch (options.uri.path) {
          ApiEndpoints.branches => _jsonResponse({'branches': const []}),
          ApiEndpoints.catalog => _jsonResponse({'categories': const []}),
          ApiEndpoints.activePromotions => _jsonResponse({
            'promotions': const [],
          }),
          ApiEndpoints.paymentMethods => _jsonResponse({
            'paymentMethods': const [],
          }),
          ApiEndpoints.clientMe => _jsonResponse(_clientJson),
          ApiEndpoints.clientAddresses ||
          ApiEndpoints.clientOrders => _jsonResponse({
            'message': 'Optional data temporarily unavailable',
          }, statusCode: 503),
          _ => _jsonResponse({
            'message': 'Unexpected request',
          }, statusCode: 500),
        };
      });
      final repository = MobileBackendRepositoryImpl(
        ApiClient(baseUrl: 'https://example.test', httpClientAdapter: adapter),
      );

      final result = await repository.bootstrap(language: 'en');

      expect(result, isA<Success<MobileBootstrap>>());
      expect(result.dataOrNull?.client?.id, 'client-1');
      expect(result.dataOrNull?.addresses, isEmpty);
      expect(result.dataOrNull?.orders, isEmpty);
      expect(
        adapter.paths,
        containsAll(<String>[
          ApiEndpoints.clientMe,
          ApiEndpoints.clientAddresses,
          ApiEndpoints.clientOrders,
        ]),
      );
    },
  );

  test(
    'first bootstrap without a stored session still loads as guest',
    () async {
      final adapter = _BootstrapAdapter((options) async {
        return switch (options.uri.path) {
          ApiEndpoints.branches => _jsonResponse({'branches': const []}),
          ApiEndpoints.catalog => _jsonResponse({'categories': const []}),
          ApiEndpoints.activePromotions => _jsonResponse({
            'promotions': const [],
          }),
          ApiEndpoints.paymentMethods => _jsonResponse({
            'paymentMethods': const [],
          }),
          _ => _jsonResponse({
            'message': 'Unexpected request',
          }, statusCode: 500),
        };
      });
      final repository = MobileBackendRepositoryImpl(
        ApiClient(baseUrl: 'https://example.test', httpClientAdapter: adapter),
      );

      final result = await repository.bootstrap(language: 'en');

      expect(result, isA<Success<MobileBootstrap>>());
      expect(result.dataOrNull?.client, isNull);
      expect(adapter.paths, isNot(contains(ApiEndpoints.clientMe)));
    },
  );

  test(
    'controller preserves an established client on bootstrap error',
    () async {
      final repository = _SequencedBootstrapRepository();
      final apiClient = ApiClient(baseUrl: 'https://example.test');
      final controller = MobileBackendController(
        repository,
        MobilePushNotificationService(apiClient),
      );
      addTearDown(controller.dispose);

      await controller.bootstrap(language: 'en');
      await Future<void>.delayed(Duration.zero);
      expect(controller.client, same(_client));
      expect(controller.addresses, hasLength(1));
      expect(controller.orders, hasLength(1));

      await controller.bootstrap(language: 'en');

      expect(controller.isAuthenticated, isTrue);
      expect(controller.client, same(_client));
      expect(controller.addresses, hasLength(1));
      expect(controller.orders, hasLength(1));
      expect(controller.failure, isA<ServiceUnavailableFailure>());
      expect(controller.status, MobileBackendStatus.error);
    },
  );
}

const Map<String, Object?> _clientJson = {
  'id': 'client-1',
  'fullName': 'Ali',
  'phoneNumber': '+998901234567',
  'language': 'en',
  'bonusBalance': 12000,
  'marketingConsent': true,
  'isBlocked': false,
};

final ClientProfile _client = ClientProfile.fromJson(_clientJson);

final ClientAddress _address = ClientAddress.fromJson({
  'id': 'address-1',
  'label': 'Home',
  'street': 'Test street',
  'latitude': 41.3,
  'longitude': 69.2,
  'isDefault': true,
});

final CustomerOrderModel _order = CustomerOrderModel.fromJson({
  'id': 'order-1',
  'type': 'PICKUP',
  'status': 'NEW',
  'paymentMethod': 'CASH',
  'totalAmount': 32000,
  'items': const [],
  'statusLog': const [],
});

class _SequencedBootstrapRepository implements MobileBackendRepository {
  int _bootstrapCalls = 0;

  @override
  Future<Result<MobileBootstrap>> bootstrap({
    required String language,
    String? branchId,
  }) async {
    _bootstrapCalls++;
    if (_bootstrapCalls > 1) {
      return const Error<MobileBootstrap>(ServiceUnavailableFailure());
    }
    return Success(
      MobileBootstrap(
        branches: const [],
        catalog: CatalogModel.fromJson(const <String, dynamic>{}),
        promotions: const [],
        paymentMethods: const <PaymentMethodModel>[],
        client: _client,
        addresses: <ClientAddress>[_address],
        orders: <CustomerOrderModel>[_order],
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
  Future<Result<List<AssignedPromotionModel>>> getAssignedPromotions({
    bool includeAll = false,
    String language = 'uz',
  }) async {
    return const Success(<AssignedPromotionModel>[]);
  }

  @override
  Future<Result<LoyaltyWalletModel>> getLoyaltyWallet() async {
    return Success(LoyaltyWalletModel.fromJson(const <String, dynamic>{}));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _BootstrapAdapter implements HttpClientAdapter {
  _BootstrapAdapter(this.onFetch);

  final Future<ResponseBody> Function(RequestOptions options) onFetch;
  final List<String> paths = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    paths.add(options.uri.path);
    return onFetch(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(Map<String, Object?> data, {int statusCode = 200}) {
  return ResponseBody.fromString(
    jsonEncode(data),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}
