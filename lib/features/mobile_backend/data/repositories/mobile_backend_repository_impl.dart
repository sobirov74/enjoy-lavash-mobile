import 'dart:async';
import 'dart:io' show HttpDate, HttpException;

import 'package:dio/dio.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/banner_model.dart';
import 'package:enjoy_lavash_mobile/core/api/api_client.dart';
import 'package:enjoy_lavash_mobile/core/api/api_endpoints.dart';
import 'package:enjoy_lavash_mobile/core/error/dio_error_mapper.dart';
import 'package:enjoy_lavash_mobile/core/error/failures.dart';
import 'package:enjoy_lavash_mobile/core/error/result.dart';
import 'package:enjoy_lavash_mobile/core/storage/public_content_cache.dart';
import 'package:enjoy_lavash_mobile/core/storage/token_storage.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/address_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/assigned_promotion_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/app_version_policy_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/auth_models.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/branch_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/cart_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/catalog_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/client_notification_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/client_profile_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/json_helpers.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/loyalty_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/order_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/ordering_status_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/domain/entities/mobile_bootstrap.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/domain/entities/mobile_public_content.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/domain/repositories/mobile_backend_repository.dart';

class MobileBackendRepositoryImpl implements MobileBackendRepository {
  const MobileBackendRepositoryImpl(
    this._apiClient, {
    this.organisationId = const String.fromEnvironment('ORGANISATION_ID'),
    this.publicContentCache,
  });

  final ApiClient _apiClient;
  final String organisationId;

  /// Where the last public content is kept for the next cold start; none in
  /// tests that build the repository directly.
  final PublicContentCache? publicContentCache;

  Dio get _dio => _apiClient.dio;

  @override
  Future<Result<OtpRequestResponse>> requestOtp({required String phoneNumber}) {
    return _guard(() async {
      final response = await _dio.post(
        ApiEndpoints.requestOtp,
        data: {'phoneNumber': phoneNumber},
      );
      return OtpRequestResponse.fromJson(
        asJsonMap(response.data),
        serverTime: _serverTime(response),
      );
    });
  }

  /// Parses the HTTP `Date` header, the server's clock at response time.
  DateTime? _serverTime(Response<Object?> response) {
    final value = response.headers.value('date')?.trim();
    if (value == null || value.isEmpty) return null;
    try {
      return HttpDate.parse(value).toUtc();
    } on FormatException {
      return null;
    } on HttpException {
      return null;
    }
  }

  @override
  Future<Result<VerifyOtpResponse>> verifyOtp(VerifyOtpRequest request) {
    return _guard(() async {
      final response = await _dio.post(
        ApiEndpoints.verifyOtp,
        data: request.toJson(),
      );
      final data = VerifyOtpResponse.fromJson(asJsonMap(response.data));
      if (data.accessToken.isNotEmpty && data.refreshToken.isNotEmpty) {
        await _apiClient.replaceClientSession(
          accessToken: data.accessToken,
          refreshToken: data.refreshToken,
          refreshTokenExpiresAt: data.refreshTokenExpiresAt,
        );
      }
      return data;
    });
  }

  @override
  Future<Result<void>> logout() {
    return _guard(_apiClient.clearClientSession);
  }

  @override
  Future<Result<void>> deleteAccount() {
    return _guard(() async {
      await _dio.delete(ApiEndpoints.clientMe);
      await _apiClient.clearClientSession();
    });
  }

  @override
  Future<Result<MobileBootstrap>> bootstrap({
    required String language,
    String? branchId,
  }) {
    return _guard(() async {
      final accessToken = await TokenStorage.getAccessToken();
      final refreshToken = await TokenStorage.getRefreshToken();
      final hasToken = accessToken != null || refreshToken != null;

      Future<List<PaymentMethodModel>> optionalPaymentMethods() async {
        try {
          return await _fetchPaymentMethods(
            language: language,
            branchId: branchId,
          );
        } catch (_) {
          return const <PaymentMethodModel>[];
        }
      }

      final publicFuture = Future.wait<Object?>([
        _branchesPayload(),
        _catalogPayload(language: language, branchId: branchId),
        optionalPaymentMethods(),
        // A banner outage must not prevent browsing or ordering.
        _optionalPayload(_bannersPayload),
      ]);

      final authFuture = hasToken
          ? _fetchAuthenticatedData()
          : Future<List<Object?>>.value(_guestAuthData);

      final publicData = await publicFuture;
      final branches = _parseBranches(publicData[0], language: language);
      final catalog = CatalogModel.fromJson(publicData[1], language: language);
      // Optional content: a failed or unreadable response shows as empty.
      final banners = _parseOptional(
        publicData[3],
        (payload) => _parseBanners(payload, language: language),
        const <BannerModel>[],
      );
      _savePublicContent(
        language: language,
        branchId: branchId,
        catalog: catalog,
        payloads: (
          catalog: publicData[1],
          branches: publicData[0],
          banners: publicData[3],
        ),
      );
      final authData = await authFuture;

      return MobileBootstrap(
        branches: branches,
        catalog: catalog,
        banners: banners,
        paymentMethods: publicData[2] as List<PaymentMethodModel>,
        client: authData[0] as ClientProfile?,
        addresses: authData[1] as List<ClientAddress>,
        orders: authData[2] as List<CustomerOrderModel>,
      );
    });
  }

  @override
  Future<Result<AppVersionPolicyModel>> getAppVersionPolicy({
    required String platform,
    String? currentVersion,
    String? language,
  }) {
    return _guard(() async {
      final normalizedCurrentVersion = currentVersion?.trim();
      final queryCurrentVersion = normalizedCurrentVersion?.isEmpty == true
          ? null
          : normalizedCurrentVersion;
      final response = await _dio.get(
        ApiEndpoints.appVersion,
        queryParameters: withoutNulls({
          'platform': platform,
          'currentVersion': queryCurrentVersion,
          'lang': language?.trim().isEmpty == true ? null : language?.trim(),
        }),
      );
      return AppVersionPolicyModel.fromJson(
        _appVersionPayload(response.data),
      ).resolveForCurrentVersion(queryCurrentVersion);
    });
  }

  @override
  Future<Result<OrderingStatusModel>> getBranchOrderingStatus({
    required String branchId,
  }) {
    return _guard(() async {
      final response = await _dio.get(
        ApiEndpoints.branchOrderingStatus(branchId),
      );
      return OrderingStatusModel.fromJson(asJsonMap(response.data));
    });
  }

  @override
  Future<Result<CatalogModel>> getCatalog({
    String language = 'ru',
    String? branchId,
  }) {
    return _guard(() => _fetchCatalog(language: language, branchId: branchId));
  }

  @override
  Future<Result<List<PaymentMethodModel>>> getPaymentMethods({
    String language = 'ru',
    String? branchId,
  }) {
    return _guard(
      () => _fetchPaymentMethods(language: language, branchId: branchId),
    );
  }

  @override
  Future<Result<CartPreviewModel>> previewCart(CartPreviewRequest request) {
    return _guard(() async {
      final response = await _dio.post(
        ApiEndpoints.cartPreview,
        data: request.toJson(),
      );
      return CartPreviewModel.fromJson(asJsonMap(response.data));
    });
  }

  @override
  Future<Result<ClientProfile>> getProfile() {
    return _guard(_fetchProfile);
  }

  @override
  Future<Result<ClientProfile>> updateProfile(ClientProfileUpdate request) {
    return _guard(() async {
      final response = await _dio.patch(
        ApiEndpoints.clientMe,
        data: request.toJson(),
      );
      return ClientProfile.fromJson(asJsonMap(response.data));
    });
  }

  @override
  Future<Result<List<ClientAddress>>> getAddresses() {
    return _guard(_fetchAddresses);
  }

  @override
  Future<Result<ClientAddress>> createAddress(ClientAddressInput request) {
    return _guard(() async {
      final response = await _dio.post(
        ApiEndpoints.clientAddresses,
        data: request.toJson(),
      );
      return ClientAddress.fromJson(asJsonMap(response.data));
    });
  }

  @override
  Future<Result<ClientAddress>> updateAddress({
    required String id,
    required ClientAddressInput request,
  }) {
    return _guard(() async {
      final response = await _dio.patch(
        ApiEndpoints.clientAddress(id),
        data: request.toJson(),
      );
      return ClientAddress.fromJson(asJsonMap(response.data));
    });
  }

  @override
  Future<Result<void>> deleteAddress({required String id}) {
    return _guard(() async {
      await _dio.delete(ApiEndpoints.clientAddress(id));
    });
  }

  @override
  Future<Result<List<CustomerOrderModel>>> getOrders() {
    return _guard(_fetchOrders);
  }

  @override
  Future<Result<CustomerOrderModel>> getOrder({required String id}) {
    return _guard(() async {
      final response = await _dio.get(ApiEndpoints.clientOrder(id));
      return CustomerOrderModel.fromJson(asJsonMap(response.data));
    });
  }

  @override
  Future<Result<CustomerOrderModel>> createOrder(
    CreateOrderRequest request, {
    String? idempotencyKey,
  }) {
    return _guard(() async {
      final normalizedKey = idempotencyKey?.trim();
      final response = await _dio.post(
        ApiEndpoints.clientOrders,
        data: request.toJson(),
        options: normalizedKey?.isNotEmpty == true
            ? Options(headers: {'Idempotency-Key': normalizedKey})
            : null,
      );
      return CustomerOrderModel.fromJson(asJsonMap(response.data));
    });
  }

  @override
  Future<Result<LoyaltyWalletModel>> getLoyaltyWallet() {
    return _guard(() async {
      final response = await _dio.get(ApiEndpoints.clientLoyaltyWallet);
      return LoyaltyWalletModel.fromJson(asJsonMap(response.data));
    });
  }

  @override
  Future<Result<LoyaltyTransactionPageModel>> getLoyaltyTransactions({
    int limit = 50,
    String? cursor,
  }) {
    return _guard(() async {
      final response = await _dio.get(
        ApiEndpoints.clientLoyaltyTransactions,
        queryParameters: withoutNulls({
          'limit': limit.clamp(1, 100),
          'cursor': cursor,
        }),
      );
      return LoyaltyTransactionPageModel.fromJson(asJsonMap(response.data));
    });
  }

  @override
  Future<Result<CustomerOrderModel>> retryOrderPayment({required String id}) {
    return _guard(() async {
      final response = await _dio.post(
        ApiEndpoints.clientOrderRetryPayment(id),
      );
      return CustomerOrderModel.fromJson(asJsonMap(response.data));
    });
  }

  @override
  Future<Result<ClientNotificationInboxModel>> getNotifications({
    int limit = 50,
    int offset = 0,
    bool unreadOnly = false,
  }) {
    return _guard(() async {
      final response = await _dio.get(
        ApiEndpoints.clientNotifications,
        queryParameters: {
          'limit': limit,
          'offset': offset,
          'unreadOnly': unreadOnly,
        },
      );
      return ClientNotificationInboxModel.fromJson(asJsonMap(response.data));
    });
  }

  @override
  Future<Result<int>> getUnreadNotificationCount() {
    return _guard(() async {
      final response = await _dio.get(
        ApiEndpoints.clientNotificationsUnreadCount,
      );
      return readInt(asJsonMap(response.data), const [
        'unreadCount',
        'unread_count',
      ]);
    });
  }

  @override
  Future<Result<ClientNotificationReadResultModel>> markNotificationRead({
    required String notificationId,
  }) {
    return _guard(() async {
      final response = await _dio.post(
        ApiEndpoints.clientNotificationRead(notificationId),
      );
      return ClientNotificationReadResultModel.fromJson(
        asJsonMap(response.data),
      );
    });
  }

  @override
  Future<Result<ClientNotificationReadResultModel>> markNotificationUnread({
    required String notificationId,
  }) {
    return _guard(() async {
      final response = await _dio.post(
        ApiEndpoints.clientNotificationUnread(notificationId),
      );
      return ClientNotificationReadResultModel.fromJson(
        asJsonMap(response.data),
      );
    });
  }

  @override
  Future<Result<ClientNotificationReadResultModel>> markAllNotificationsRead() {
    return _guard(() async {
      final response = await _dio.post(ApiEndpoints.clientNotificationsReadAll);
      return ClientNotificationReadResultModel.fromJson(
        asJsonMap(response.data),
      );
    });
  }

  @override
  Future<Result<List<AssignedPromotionModel>>> getAssignedPromotions({
    bool includeAll = false,
    String language = 'uz',
  }) {
    return _guard(() async {
      final response = await _dio.get(
        ApiEndpoints.clientPromotions,
        queryParameters: includeAll ? const {'status': 'ALL'} : null,
      );
      final responseMap = asJsonMap(response.data);
      final nestedData = asJsonMap(responseMap['data']);
      final payloadMap = nestedData.isEmpty ? responseMap : nestedData;
      final payload =
          payloadMap['items'] ??
          payloadMap['assignments'] ??
          payloadMap['promotions'] ??
          response.data;
      return asJsonMapList(payload)
          .map(
            (json) => AssignedPromotionModel.fromJson(json, language: language),
          )
          .toList(growable: false);
    });
  }

  Future<Object?> _branchesPayload() async {
    return (await _dio.get(ApiEndpoints.branches)).data;
  }

  List<BranchModel> _parseBranches(
    Object? payload, {
    required String language,
  }) {
    return asJsonMapList(_listPayload(payload, key: 'branches'))
        .map((json) => BranchModel.fromJson(json, language: language))
        .toList(growable: false);
  }

  Future<Object?> _catalogPayload({
    required String language,
    String? branchId,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.catalog,
      queryParameters: withoutNulls({'lang': language, 'branchId': branchId}),
    );
    return response.data;
  }

  Future<CatalogModel> _fetchCatalog({
    required String language,
    String? branchId,
  }) async {
    return CatalogModel.fromJson(
      await _catalogPayload(language: language, branchId: branchId),
      language: language,
    );
  }

  @override
  Future<Result<List<BannerModel>>> getActiveBanners({String language = 'uz'}) {
    return _guard(() => _fetchActiveBanners(language: language));
  }

  Future<Object?> _bannersPayload() async {
    // Global public content: no organisation or client token is required.
    return (await _dio.get(ApiEndpoints.activeBanners)).data;
  }

  List<BannerModel> _parseBanners(Object? payload, {required String language}) {
    return asJsonMapList(payload)
        .map(
          (json) => BannerModel.fromJson(
            json,
            language: language,
            backendBaseUrl: _dio.options.baseUrl,
          ),
        )
        .toList(growable: false);
  }

  Future<List<BannerModel>> _fetchActiveBanners({
    required String language,
  }) async {
    return _parseBanners(await _bannersPayload(), language: language);
  }

  static Future<Object?> _optionalPayload(
    Future<Object?> Function() request,
  ) async {
    try {
      return await request();
    } catch (_) {
      return null;
    }
  }

  static T _parseOptional<T>(
    Object? payload,
    T Function(Object? payload) parse,
    T fallback,
  ) {
    if (payload == null) return fallback;
    try {
      return parse(payload);
    } catch (_) {
      return fallback;
    }
  }

  /// Server and organisation the saved public content belongs to.
  String get _publicContentScope =>
      '${_dio.options.baseUrl}|${organisationId.trim()}';

  /// Keeps the public payloads of a default bootstrap for the next cold
  /// start, as soon as its public part has loaded (whatever the customer's
  /// own requests then do). Branch-specific catalogs are not saved: a cold
  /// start always loads the default one. A menu with nothing to order (an
  /// empty or unreadable answer) never replaces a good saved one.
  void _savePublicContent({
    required String language,
    required String? branchId,
    required CatalogModel catalog,
    required PublicContentPayloads payloads,
  }) {
    final cache = publicContentCache;
    if (cache == null || branchId?.trim().isNotEmpty == true) return;
    if (!catalog.products.any((product) => product.isAvailable)) return;
    unawaited(
      cache.write(
        scope: _publicContentScope,
        language: language,
        payloads: payloads,
      ),
    );
  }

  @override
  Future<MobilePublicContent?> readCachedPublicContent({
    required String language,
  }) async {
    final cache = publicContentCache;
    if (cache == null) return null;
    final payloads = await cache.read(
      scope: _publicContentScope,
      language: language,
    );
    if (payloads == null) return null;
    try {
      final catalog = CatalogModel.fromJson(
        payloads.catalog,
        language: language,
      );
      // An empty saved menu would only replace one empty state with another.
      if (!catalog.products.any((product) => product.isAvailable)) return null;
      return MobilePublicContent(
        catalog: catalog,
        branches: _parseOptional(
          payloads.branches,
          (payload) => _parseBranches(payload, language: language),
          const <BranchModel>[],
        ),
        // A saved banner may advertise a promotion that has ended since;
        // the server would no longer send it.
        banners: _parseOptional(
          payloads.banners,
          (payload) => _parseBanners(payload, language: language),
          const <BannerModel>[],
        ).where(_isStillRunning).toList(growable: false),
      );
    } catch (_) {
      return null;
    }
  }

  static bool _isStillRunning(BannerModel banner) {
    final endsAt = banner.promotion?.endsAt;
    return endsAt == null || endsAt.isAfter(DateTime.now());
  }

  Future<List<PaymentMethodModel>> _fetchPaymentMethods({
    required String language,
    String? branchId,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.paymentMethods,
      queryParameters: withoutNulls({
        'lang': language,
        'branchId': branchId?.trim().isEmpty == true ? null : branchId?.trim(),
      }),
    );
    final methods =
        asJsonMapList(_listPayload(response.data, key: 'paymentMethods'))
            .map(PaymentMethodModel.fromJson)
            .where((method) => method.code != MobilePaymentMethod.unknown)
            .toList(growable: false);
    return methods..sort((a, b) {
      final sortComparison = a.sortOrder.compareTo(b.sortOrder);
      if (sortComparison != 0) return sortComparison;
      return a.code.index.compareTo(b.code.index);
    });
  }

  Future<ClientProfile> _fetchProfile() async {
    final response = await _dio.get(ApiEndpoints.clientMe);
    return ClientProfile.fromJson(asJsonMap(response.data));
  }

  Future<List<ClientAddress>> _fetchAddresses() async {
    final response = await _dio.get(ApiEndpoints.clientAddresses);
    return asJsonMapList(
      _listPayload(response.data, key: 'addresses'),
    ).map(ClientAddress.fromJson).toList(growable: false);
  }

  Future<List<Object?>> _fetchAuthenticatedData() async {
    // Addresses and orders are optional and requested alongside the profile,
    // so a signed-in launch waits for one round trip instead of three.
    final addresses = _orFallback(_fetchAddresses(), const <ClientAddress>[]);
    final orders = _orFallback(_fetchOrders(), const <CustomerOrderModel>[]);
    final ClientProfile profile;
    try {
      profile = await _fetchProfile();
    } on DioException catch (error) {
      // The stored session is no longer valid (the auth interceptor already
      // tried to refresh it). Browse as a guest instead of failing the whole
      // bootstrap, which would leave the menu empty with no error.
      if (error.response?.statusCode == 401) return _guestAuthData;
      rethrow;
    }
    return <Object?>[profile, await addresses, await orders];
  }

  static Future<T> _orFallback<T>(Future<T> request, T fallback) async {
    try {
      return await request;
    } catch (_) {
      return fallback;
    }
  }

  static const List<Object?> _guestAuthData = <Object?>[
    null,
    <ClientAddress>[],
    <CustomerOrderModel>[],
  ];

  Future<List<CustomerOrderModel>> _fetchOrders() async {
    final response = await _dio.get(ApiEndpoints.clientOrders);
    return asJsonMapList(
      _listPayload(response.data, key: 'orders'),
    ).map(CustomerOrderModel.fromJson).toList(growable: false);
  }

  Object? _listPayload(Object? data, {required String key}) {
    final map = asJsonMap(data);
    if (map.containsKey(key)) return map[key];
    if (map.containsKey('items')) return map['items'];
    return data;
  }

  JsonMap _appVersionPayload(Object? data) {
    final map = asJsonMap(data);
    if (_looksLikeAppVersionPolicy(map)) return map;

    for (final key in const ['data', 'result', 'appVersion', 'app_version']) {
      final nested = asJsonMap(map[key]);
      if (nested.isNotEmpty) return nested;
    }

    return map;
  }

  bool _looksLikeAppVersionPolicy(JsonMap map) {
    return map.containsKey('latestVersion') ||
        map.containsKey('latest_version') ||
        map.containsKey('minSupportedVersion') ||
        map.containsKey('min_supported_version') ||
        map.containsKey('appUrl') ||
        map.containsKey('app_url');
  }

  Future<Result<T>> _guard<T>(Future<T> Function() request) async {
    try {
      return Success<T>(await request());
    } on DioException catch (error) {
      return Error<T>(mapDioError(error));
    } catch (error) {
      return Error<T>(UnknownFailure(error.toString()));
    }
  }
}
