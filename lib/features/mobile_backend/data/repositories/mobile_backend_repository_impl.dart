import 'package:dio/dio.dart';
import 'package:enjoy_lavash_mobile/core/api/api_client.dart';
import 'package:enjoy_lavash_mobile/core/api/api_endpoints.dart';
import 'package:enjoy_lavash_mobile/core/error/dio_error_mapper.dart';
import 'package:enjoy_lavash_mobile/core/error/failures.dart';
import 'package:enjoy_lavash_mobile/core/error/result.dart';
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
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/file_upload_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/json_helpers.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/loyalty_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/order_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/ordering_status_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/promotion_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/domain/entities/mobile_bootstrap.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/domain/repositories/mobile_backend_repository.dart';

class MobileBackendRepositoryImpl implements MobileBackendRepository {
  const MobileBackendRepositoryImpl(this._apiClient);

  final ApiClient _apiClient;

  Dio get _dio => _apiClient.dio;

  @override
  Future<Result<OtpRequestResponse>> requestOtp({required String phoneNumber}) {
    return _guard(() async {
      final response = await _dio.post(
        ApiEndpoints.requestOtp,
        data: {'phoneNumber': phoneNumber},
      );
      return OtpRequestResponse.fromJson(asJsonMap(response.data));
    });
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

      Future<List<PromotionModel>> optionalPromotions() async {
        try {
          return await _fetchActivePromotions(language: language);
        } catch (_) {
          return const <PromotionModel>[];
        }
      }

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
        _fetchBranches(language: language),
        _fetchCatalog(language: language, branchId: branchId),
        optionalPromotions(),
        optionalPaymentMethods(),
      ]);

      final authFuture = hasToken
          ? _fetchAuthenticatedData()
          : Future<List<Object?>>.value(<Object?>[
              null,
              const <ClientAddress>[],
              const <CustomerOrderModel>[],
            ]);

      final publicData = await publicFuture;
      final authData = await authFuture;

      return MobileBootstrap(
        branches: publicData[0] as List<BranchModel>,
        catalog: publicData[1] as CatalogModel,
        promotions: publicData[2] as List<PromotionModel>,
        paymentMethods: publicData[3] as List<PaymentMethodModel>,
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
  Future<Result<List<BranchModel>>> getBranches({String language = 'ru'}) {
    return _guard(() => _fetchBranches(language: language));
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
  Future<Result<CatalogProductModel>> getCatalogProduct({
    required String idOrSlug,
    String language = 'ru',
  }) {
    return _guard(() async {
      final response = await _dio.get(
        ApiEndpoints.catalogProduct(idOrSlug),
        queryParameters: {'lang': language},
      );
      return CatalogProductModel.fromJson(
        asJsonMap(response.data),
        language: language,
      );
    });
  }

  @override
  Future<Result<List<PromotionModel>>> getActivePromotions({
    String language = 'ru',
  }) {
    return _guard(() => _fetchActivePromotions(language: language));
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
  Future<Result<CustomerOrderModel?>> cancelOrder({
    required String id,
    required String reason,
  }) {
    return _guard(() async {
      final response = await _dio.post(
        ApiEndpoints.clientOrderCancel(id),
        data: {'reason': reason},
      );
      final data = asJsonMap(response.data);
      if (data.isEmpty) return null;
      return CustomerOrderModel.fromJson(data);
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

  @override
  Future<Result<FileUploadResultModel>> uploadFile(FileUploadRequest request) {
    if (request.isTooLarge) {
      return Future<Result<FileUploadResultModel>>.value(
        const Error<FileUploadResultModel>(
          PayloadTooLargeFailure('File must be 10 MB or smaller'),
        ),
      );
    }
    return _guard(() async {
      final response = await _dio.post(
        ApiEndpoints.filesUpload,
        data: FormData.fromMap({
          request.fieldName: MultipartFile.fromBytes(
            request.bytes,
            filename: request.filename,
          ),
        }),
      );
      return FileUploadResultModel.fromJson(asJsonMap(response.data));
    });
  }

  @override
  Future<Result<void>> deleteFile({required String filename}) {
    return _guard(() async {
      await _dio.delete(
        ApiEndpoints.filesDelete,
        queryParameters: {'filename': filename},
      );
    });
  }

  Future<List<BranchModel>> _fetchBranches({required String language}) async {
    final response = await _dio.get(ApiEndpoints.branches);
    return asJsonMapList(_listPayload(response.data, key: 'branches'))
        .map((json) => BranchModel.fromJson(json, language: language))
        .toList(growable: false);
  }

  Future<CatalogModel> _fetchCatalog({
    required String language,
    String? branchId,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.catalog,
      queryParameters: withoutNulls({'lang': language, 'branchId': branchId}),
    );
    return CatalogModel.fromJson(response.data, language: language);
  }

  Future<List<PromotionModel>> _fetchActivePromotions({
    required String language,
  }) async {
    final response = await _dio.get(ApiEndpoints.activePromotions);
    return asJsonMapList(_listPayload(response.data, key: 'promotions'))
        .map((json) => PromotionModel.fromJson(json, language: language))
        .toList(growable: false);
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
    final profile = await _fetchProfile();
    List<ClientAddress> addresses;
    List<CustomerOrderModel> orders;
    try {
      addresses = await _fetchAddresses();
    } catch (_) {
      addresses = const <ClientAddress>[];
    }
    try {
      orders = await _fetchOrders();
    } catch (_) {
      orders = const <CustomerOrderModel>[];
    }

    return <Object?>[profile, addresses, orders];
  }

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
