import 'package:dio/dio.dart';
import 'package:enjoy_lavash_mobile/core/api/api_client.dart';
import 'package:enjoy_lavash_mobile/core/api/api_endpoints.dart';
import 'package:enjoy_lavash_mobile/core/error/dio_error_mapper.dart';
import 'package:enjoy_lavash_mobile/core/error/failures.dart';
import 'package:enjoy_lavash_mobile/core/error/result.dart';
import 'package:enjoy_lavash_mobile/core/storage/token_storage.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/address_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/app_version_policy_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/auth_models.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/branch_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/cart_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/catalog_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/client_profile_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/file_upload_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/json_helpers.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/order_model.dart';
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
      if (data.accessToken.isNotEmpty) {
        await TokenStorage.clear();
        await TokenStorage.saveAccessToken(data.accessToken);
        if (data.refreshToken?.isNotEmpty == true) {
          await TokenStorage.saveRefreshToken(data.refreshToken!);
        }
      }
      return data;
    });
  }

  @override
  Future<Result<void>> logout() {
    return _guard(TokenStorage.clear);
  }

  @override
  Future<Result<void>> deleteAccount() {
    return _guard(() async {
      await _dio.delete(ApiEndpoints.clientMe);
      await TokenStorage.clear();
    });
  }

  @override
  Future<Result<MobileBootstrap>> bootstrap({
    required String language,
    String? branchId,
  }) {
    return _guard(() async {
      final hasToken = await TokenStorage.getAccessToken() != null;

      final publicFuture = Future.wait<Object?>([
        _fetchBranches(language: language),
        _fetchCatalog(language: language, branchId: branchId),
        _fetchActivePromotions(language: language),
      ]);

      final authFuture = hasToken
          ? _fetchAuthenticatedData().catchError((Object _) {
              return <Object?>[
                null,
                const <ClientAddress>[],
                const <CustomerOrderModel>[],
              ];
            })
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
      final response = await _dio.get(
        ApiEndpoints.appVersion,
        queryParameters: withoutNulls({
          'platform': platform,
          'currentVersion': currentVersion?.trim().isEmpty == true
              ? null
              : currentVersion?.trim(),
          'lang': language?.trim().isEmpty == true ? null : language?.trim(),
        }),
      );
      return AppVersionPolicyModel.fromJson(asJsonMap(response.data));
    });
  }

  @override
  Future<Result<List<BranchModel>>> getBranches({String language = 'ru'}) {
    return _guard(() => _fetchBranches(language: language));
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
  Future<Result<CustomerOrderModel>> createOrder(CreateOrderRequest request) {
    return _guard(() async {
      final response = await _dio.post(
        ApiEndpoints.clientOrders,
        data: request.toJson(),
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
  Future<Result<FileUploadResultModel>> uploadFile(FileUploadRequest request) {
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
    final authData = await Future.wait<Object?>([
      _fetchAddresses(),
      _fetchOrders(phoneNumber: profile.phoneNumber),
    ]);

    return <Object?>[profile, authData[0], authData[1]];
  }

  Future<List<CustomerOrderModel>> _fetchOrders({String? phoneNumber}) async {
    final response = await _dio.get(
      ApiEndpoints.clientOrders,
      queryParameters: withoutNulls({
        'phoneNumber': phoneNumber?.trim().isEmpty == true
            ? null
            : phoneNumber?.trim(),
      }),
    );
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
