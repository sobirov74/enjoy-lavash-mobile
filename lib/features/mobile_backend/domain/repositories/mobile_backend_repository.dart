import 'package:enjoy_lavash_mobile/core/error/result.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/address_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/auth_models.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/branch_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/cart_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/catalog_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/client_profile_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/file_upload_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/order_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/promotion_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/domain/entities/mobile_bootstrap.dart';

abstract class MobileBackendRepository {
  Future<Result<OtpRequestResponse>> requestOtp({required String phoneNumber});

  Future<Result<VerifyOtpResponse>> verifyOtp(VerifyOtpRequest request);

  Future<Result<void>> logout();

  Future<Result<MobileBootstrap>> bootstrap({
    required String language,
    String? branchId,
  });

  Future<Result<List<BranchModel>>> getBranches({String language = 'ru'});

  Future<Result<CatalogModel>> getCatalog({
    String language = 'ru',
    String? branchId,
  });

  Future<Result<CatalogProductModel>> getCatalogProduct({
    required String idOrSlug,
    String language = 'ru',
  });

  Future<Result<List<PromotionModel>>> getActivePromotions({
    String language = 'ru',
  });

  Future<Result<CartPreviewModel>> previewCart(CartPreviewRequest request);

  Future<Result<ClientProfile>> getProfile();

  Future<Result<ClientProfile>> updateProfile(ClientProfileUpdate request);

  Future<Result<List<ClientAddress>>> getAddresses();

  Future<Result<ClientAddress>> createAddress(ClientAddressInput request);

  Future<Result<ClientAddress>> updateAddress({
    required String id,
    required ClientAddressInput request,
  });

  Future<Result<void>> deleteAddress({required String id});

  Future<Result<List<CustomerOrderModel>>> getOrders();

  Future<Result<CustomerOrderModel>> createOrder(CreateOrderRequest request);

  Future<Result<CustomerOrderModel?>> cancelOrder({
    required String id,
    required String reason,
  });

  Future<Result<FileUploadResultModel>> uploadFile(FileUploadRequest request);

  Future<Result<void>> deleteFile({required String filename});
}
