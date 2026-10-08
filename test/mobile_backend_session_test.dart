import 'dart:async';

import 'package:enjoy_lavash_mobile/core/api/api_client.dart';
import 'package:enjoy_lavash_mobile/core/error/result.dart';
import 'package:enjoy_lavash_mobile/core/services/mobile_push_notification_service.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/assigned_promotion_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/auth_models.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/catalog_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/client_notification_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/client_profile_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/order_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/domain/entities/mobile_bootstrap.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/domain/repositories/mobile_backend_repository.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/presentation/mobile_backend_controller.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _ControlledRepository repository;
  late MobileBackendController controller;
  late DateTime now;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    repository = _ControlledRepository();
    now = DateTime.utc(2026, 10, 7, 12);
    controller = MobileBackendController(
      repository,
      MobilePushNotificationService(ApiClient(baseUrl: 'https://example.test')),
      clock: () => now,
    );
  });

  tearDown(() => controller.dispose());

  test('a guest bootstrap finishing after login keeps the customer', () async {
    final bootstrap = controller.bootstrap(language: 'en');
    await controller.verifyOtp(
      const VerifyOtpRequest(phoneNumber: '+998901234567', code: '1111'),
    );
    expect(controller.client?.id, 'client-1');

    // The bootstrap started as a guest; its (client-less) result lands late.
    repository.bootstrapResult.complete(Success(_guestBootstrap));
    await bootstrap;

    expect(controller.client?.id, 'client-1');
    expect(controller.menuProducts.single.id, 'prod-1');
    expect(controller.status, MobileBackendStatus.loaded);
  });

  test('a customer refresh finishing after logout does not restore the '
      'session', () async {
    repository.bootstrapResult.complete(Success(_signedInBootstrap));
    await controller.bootstrap(language: 'en');
    expect(controller.isAuthenticated, isTrue);

    repository.profileResult = Completer<Result<ClientProfile>>();
    final refresh = controller.refreshCustomerData();
    await controller.logout();
    repository.profileResult!.complete(Success(_client));
    await refresh;

    expect(controller.isAuthenticated, isFalse);
    expect(controller.client, isNull);
  });

  test('session end reasons reach listeners', () async {
    final reasons = <SessionEndReason>[];
    final subscription = controller.sessionEnded.listen(reasons.add);
    addTearDown(subscription.cancel);
    repository.bootstrapResult.complete(Success(_signedInBootstrap));
    await controller.bootstrap(language: 'en');

    await controller.logout();
    await controller.handleSessionExpired();
    await Future<void>.delayed(Duration.zero);

    expect(reasons, [SessionEndReason.signedOut, SessionEndReason.expired]);
    expect(controller.pendingPushMessage, isNull);
  });

  test('app resume refreshes at most once per interval', () async {
    repository.bootstrapResult.complete(Success(_signedInBootstrap));
    await controller.bootstrap(language: 'en');
    int unreadCountCalls() => repository.calls
        .where((call) => call == #getUnreadNotificationCount)
        .length;

    unawaited(controller.handleAppResumed());
    unawaited(controller.handleAppResumed());
    expect(unreadCountCalls(), 1);

    now = now.add(resumeRefreshInterval + const Duration(seconds: 1));
    unawaited(controller.handleAppResumed());
    expect(unreadCountCalls(), 2);
  });

  test('polling an unchanged order does not notify listeners', () async {
    repository.bootstrapResult.complete(
      Success(
        MobileBootstrap(
          branches: const [],
          catalog: _catalog,
          promotions: const [],
          paymentMethods: const [],
          client: _client,
          orders: [_order('COOKING')],
        ),
      ),
    );
    await controller.bootstrap(language: 'en');
    // Let the post-login background refreshes settle first.
    await Future<void>.delayed(Duration.zero);
    var notifications = 0;
    controller.addListener(() => notifications++);

    repository.orderResult = _order('COOKING');
    await controller.refreshOrder(id: 'order-1');
    expect(notifications, 0);

    repository.orderResult = _order('ON_THE_WAY');
    await controller.refreshOrder(id: 'order-1');
    expect(notifications, 1);
    expect(controller.orders.single.status, MobileOrderStatus.onTheWay);
  });

  test('assigned promotions stay fresh for a minute after loading', () async {
    repository.bootstrapResult.complete(Success(_signedInBootstrap));
    await controller.bootstrap(language: 'en');
    expect(controller.hasFreshAssignedPromotions(includeAll: false), isFalse);

    repository.promotionsResult = const <AssignedPromotionModel>[];
    await controller.refreshAssignedPromotions(language: 'en');
    expect(controller.hasFreshAssignedPromotions(includeAll: false), isTrue);
    expect(controller.hasFreshAssignedPromotions(includeAll: true), isFalse);

    now = now.add(assignedPromotionsFreshFor);
    expect(controller.hasFreshAssignedPromotions(includeAll: false), isFalse);
  });

  test('an expired session during bootstrap no longer flips loading', () async {
    final bootstrap = controller.bootstrap(language: 'en');
    expect(controller.status, MobileBackendStatus.loading);

    await controller.handleSessionExpired();
    // Still loading: a second bootstrap must not start concurrently.
    expect(controller.status, MobileBackendStatus.loading);
    await controller.bootstrap(language: 'en');
    expect(repository.bootstrapCalls, 1);

    repository.bootstrapResult.complete(Success(_guestBootstrap));
    await bootstrap;
    expect(controller.status, MobileBackendStatus.loaded);
  });
}

final ClientProfile _client = ClientProfile.fromJson(const {
  'id': 'client-1',
  'fullName': 'Ali',
  'phoneNumber': '+998901234567',
  'language': 'en',
});

final CatalogModel _catalog = CatalogModel.fromJson({
  'categories': [
    {
      'id': 'cat-1',
      'name': 'Lavash',
      'products': [
        {'id': 'prod-1', 'name': 'Classic', 'basePrice': 32000},
      ],
    },
  ],
});

CustomerOrderModel _order(String status) => CustomerOrderModel.fromJson({
  'id': 'order-1',
  'type': 'PICKUP',
  'status': status,
  'paymentMethod': 'CASH',
  'totalAmount': 32000,
  'items': const [],
  'statusLog': const [],
});

final MobileBootstrap _guestBootstrap = MobileBootstrap(
  branches: const [],
  catalog: _catalog,
  promotions: const [],
  paymentMethods: const [],
);

final MobileBootstrap _signedInBootstrap = MobileBootstrap(
  branches: const [],
  catalog: _catalog,
  promotions: const [],
  paymentMethods: const [],
  client: _client,
);

/// Answers only what these tests use; anything else fails loudly.
class _ControlledRepository implements MobileBackendRepository {
  final Completer<Result<MobileBootstrap>> bootstrapResult =
      Completer<Result<MobileBootstrap>>();
  Completer<Result<ClientProfile>>? profileResult;
  CustomerOrderModel? orderResult;
  List<AssignedPromotionModel>? promotionsResult;
  int bootstrapCalls = 0;
  final List<Symbol> calls = <Symbol>[];

  @override
  Future<Result<MobileBootstrap>> bootstrap({
    required String language,
    String? branchId,
  }) {
    bootstrapCalls++;
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
  Future<Result<ClientProfile>> getProfile() {
    return profileResult?.future ?? Future.value(Success(_client));
  }

  @override
  Future<Result<void>> logout() async => const Success(null);

  @override
  Future<Result<List<AssignedPromotionModel>>> getAssignedPromotions({
    bool includeAll = false,
    String language = 'uz',
  }) {
    final result = promotionsResult;
    if (result == null) return Completer<Never>().future;
    return Future.value(Success(result));
  }

  @override
  Future<Result<CustomerOrderModel>> getOrder({required String id}) async {
    return Success(orderResult!);
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
    // Background refreshes (loyalty, promotions, language sync) are not under
    // test; answer them with a never-completing future so they stay inert.
    calls.add(invocation.memberName);
    if (invocation.isMethod) return Completer<Never>().future;
    return super.noSuchMethod(invocation);
  }
}
