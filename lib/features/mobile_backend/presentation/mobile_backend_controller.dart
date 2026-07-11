import 'dart:async';

import 'package:enjoy_lavash_mobile/core/api/base_url.dart';
import 'package:enjoy_lavash_mobile/core/error/failures.dart';
import 'package:enjoy_lavash_mobile/core/error/result.dart';
import 'package:enjoy_lavash_mobile/core/services/mobile_push_notification_service.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/address_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/auth_models.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/branch_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/cart_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/catalog_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/client_notification_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/client_profile_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/order_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/promotion_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/domain/repositories/mobile_backend_repository.dart';
import 'package:enjoy_lavash_mobile/features/models/menu_product.dart';
import 'package:flutter/material.dart';

part 'mobile_backend_controller/mobile_backend_auth_controller.dart';
part 'mobile_backend_controller/mobile_backend_bootstrap_controller.dart';
part 'mobile_backend_controller/mobile_backend_catalog_adapter.dart';
part 'mobile_backend_controller/mobile_backend_notifications_controller.dart';
part 'mobile_backend_controller/mobile_backend_order_controller.dart';
part 'mobile_backend_controller/mobile_backend_state_controller.dart';

enum MobileBackendStatus { initial, loading, loaded, error }

class MobileBackendController extends ChangeNotifier {
  MobileBackendController(this._repository, this._pushNotifications);

  final MobileBackendRepository _repository;
  final MobilePushNotificationService _pushNotifications;

  MobileBackendStatus _status = MobileBackendStatus.initial;
  Failure? _failure;
  List<String> _menuCategories = const <String>[];
  List<MenuProduct> _menuProducts = const <MenuProduct>[];
  List<BranchModel> _branches = const <BranchModel>[];
  List<PromotionModel> _promotions = const <PromotionModel>[];
  List<PaymentMethodModel> _paymentMethods = const <PaymentMethodModel>[];
  String? _paymentMethodsBranchId;
  Failure? _paymentMethodsFailure;
  bool _paymentMethodsLoading = false;
  int _paymentMethodsRequestVersion = 0;
  List<ClientAddress> _addresses = const <ClientAddress>[];
  List<CustomerOrderModel> _orders = const <CustomerOrderModel>[];
  List<ClientNotificationItemModel> _notifications =
      const <ClientNotificationItemModel>[];
  ClientProfile? _client;
  int _notificationUnreadCount = 0;
  int _notificationTotal = 0;
  bool _notificationsLoading = false;
  PushNotificationSettings? _pushNotificationSettings;
  bool _pushNotificationsUpdating = false;
  bool _accountDeleting = false;

  MobileBackendStatus get status => _status;
  Failure? get failure => _failure;
  List<String> get menuCategories => _menuCategories;
  List<MenuProduct> get menuProducts => _menuProducts;
  List<BranchModel> get branches => _branches;
  List<PromotionModel> get promotions => _promotions;
  List<PaymentMethodModel> get paymentMethods => _paymentMethods;
  String? get paymentMethodsBranchId => _paymentMethodsBranchId;
  Failure? get paymentMethodsFailure => _paymentMethodsFailure;
  bool get paymentMethodsLoading => _paymentMethodsLoading;
  List<ClientAddress> get addresses => _addresses;
  List<CustomerOrderModel> get orders => _orders;
  List<ClientNotificationItemModel> get notifications => _notifications;
  ClientProfile? get client => _client;
  int get notificationUnreadCount => _notificationUnreadCount;
  int get notificationTotal => _notificationTotal;
  bool get notificationsLoading => _notificationsLoading;
  PushNotificationSettings? get pushNotificationSettings =>
      _pushNotificationSettings;
  bool get pushNotificationsUpdating => _pushNotificationsUpdating;
  bool get accountDeleting => _accountDeleting;
  bool get isAuthenticated => _client != null;
  bool get isLoading => _status == MobileBackendStatus.loading;

  // Controller behavior is split into private extensions. Keeping the
  // ChangeNotifier call inside the class preserves its protected contract.
  void _notifyListeners() => notifyListeners();

  Future<Result<OtpRequestResponse>> requestOtp({required String phoneNumber}) {
    return _requestOtp(phoneNumber: phoneNumber);
  }

  Future<Result<VerifyOtpResponse>> verifyOtp(VerifyOtpRequest request) {
    return _verifyOtp(request);
  }

  Future<Result<ClientProfile>> updateProfile(ClientProfileUpdate request) {
    return _updateProfile(request);
  }

  Future<void> syncClientLanguage({required String language}) {
    return _syncClientLanguage(language: language);
  }

  Future<void> refreshPushNotificationSettings() {
    return _refreshPushNotificationSettings();
  }

  Future<Result<PushNotificationSettings>> setPushNotificationsEnabled(
    bool enabled,
  ) {
    return _setPushNotificationsEnabled(enabled);
  }

  Future<Result<void>> logout() {
    return _logout();
  }

  Future<Result<void>> deleteAccount() {
    return _deleteAccount();
  }

  Future<void> handleSessionExpired() {
    return _handleSessionExpired();
  }

  Future<void> refreshCustomerData() {
    return _refreshCustomerData();
  }

  Future<Result<ClientNotificationInboxModel>> refreshNotifications({
    int limit = 50,
    int offset = 0,
    bool unreadOnly = false,
  }) {
    return _refreshNotifications(
      limit: limit,
      offset: offset,
      unreadOnly: unreadOnly,
    );
  }

  Future<Result<int>> refreshNotificationUnreadCount() {
    return _refreshNotificationUnreadCount();
  }

  Future<Result<ClientNotificationReadResultModel>> markNotificationRead({
    required String notificationId,
  }) {
    return _markNotificationRead(notificationId: notificationId);
  }

  Future<Result<ClientNotificationReadResultModel>> markAllNotificationsRead() {
    return _markAllNotificationsRead();
  }

  Future<Result<CartPreviewModel>> previewCart(CartPreviewRequest request) {
    return _previewCart(request);
  }

  Future<Result<List<PaymentMethodModel>>> refreshPaymentMethods({
    required String language,
    String? branchId,
  }) {
    return _refreshPaymentMethods(language: language, branchId: branchId);
  }

  Future<Result<CustomerOrderModel>> createOrder(CreateOrderRequest request) {
    return _createOrder(request);
  }

  Future<Result<CustomerOrderModel>> refreshOrder({required String id}) {
    return _refreshOrder(id: id);
  }

  Future<Result<CustomerOrderModel>> retryOrderPayment({required String id}) {
    return _retryOrderPayment(id: id);
  }

  Future<void> bootstrap({required String language, String? branchId}) {
    return _bootstrap(language: language, branchId: branchId);
  }

  Future<Result<CatalogModel>> refreshCatalog({
    required String language,
    String? branchId,
  }) {
    return _refreshCatalog(language: language, branchId: branchId);
  }
}
