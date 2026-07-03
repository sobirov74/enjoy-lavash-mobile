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
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/client_profile_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/order_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/promotion_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/domain/repositories/mobile_backend_repository.dart';
import 'package:enjoy_lavash_mobile/features/models/menu_product.dart';
import 'package:flutter/material.dart';

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
  List<ClientAddress> _addresses = const <ClientAddress>[];
  List<CustomerOrderModel> _orders = const <CustomerOrderModel>[];
  ClientProfile? _client;
  PushNotificationSettings? _pushNotificationSettings;
  bool _pushNotificationsUpdating = false;
  bool _accountDeleting = false;

  MobileBackendStatus get status => _status;
  Failure? get failure => _failure;
  List<String> get menuCategories => _menuCategories;
  List<MenuProduct> get menuProducts => _menuProducts;
  List<BranchModel> get branches => _branches;
  List<PromotionModel> get promotions => _promotions;
  List<ClientAddress> get addresses => _addresses;
  List<CustomerOrderModel> get orders => _orders;
  ClientProfile? get client => _client;
  PushNotificationSettings? get pushNotificationSettings =>
      _pushNotificationSettings;
  bool get pushNotificationsUpdating => _pushNotificationsUpdating;
  bool get accountDeleting => _accountDeleting;
  bool get isAuthenticated => _client != null;
  bool get isLoading => _status == MobileBackendStatus.loading;

  Future<Result<OtpRequestResponse>> requestOtp({required String phoneNumber}) {
    return _repository.requestOtp(phoneNumber: phoneNumber);
  }

  Future<Result<VerifyOtpResponse>> verifyOtp(VerifyOtpRequest request) async {
    final result = await _repository.verifyOtp(request);
    switch (result) {
      case Success(:final data):
        _client = data.client;
        _failure = null;
        _startPushNotificationSync(locale: data.client.language);
        if (_status == MobileBackendStatus.initial) {
          _status = MobileBackendStatus.loaded;
        }
        notifyListeners();
      case Error():
    }
    return result;
  }

  Future<Result<ClientProfile>> updateProfile(
    ClientProfileUpdate request,
  ) async {
    final result = await _repository.updateProfile(request);
    switch (result) {
      case Success(:final data):
        _client = data;
        _failure = null;
        notifyListeners();
      case Error(:final failure):
        _failure = failure;
        notifyListeners();
    }
    return result;
  }

  Future<void> refreshPushNotificationSettings() async {
    _pushNotificationSettings = await _pushNotifications.getSettings();
    notifyListeners();
  }

  Future<Result<PushNotificationSettings>> setPushNotificationsEnabled(
    bool enabled,
  ) async {
    _pushNotificationsUpdating = true;
    notifyListeners();

    try {
      final settings = await _pushNotifications.setNotificationsEnabled(
        enabled,
        locale: _client?.language,
      );
      _pushNotificationSettings = settings;
      _failure = null;
      return Success(settings);
    } catch (error) {
      final failure = UnknownFailure(error.toString());
      _failure = failure;
      return Error(failure);
    } finally {
      _pushNotificationsUpdating = false;
      notifyListeners();
    }
  }

  Future<Result<void>> logout() async {
    try {
      await _pushNotifications.deleteRegisteredToken();
    } catch (error) {
      debugPrint('Push token cleanup failed during logout: $error');
    }
    final result = await _repository.logout();
    if (result.isSuccess) {
      handleSessionExpired();
    }
    return result;
  }

  Future<Result<void>> deleteAccount() async {
    _accountDeleting = true;
    notifyListeners();

    try {
      try {
        await _pushNotifications.deleteRegisteredToken();
      } catch (error) {
        debugPrint('Push token cleanup failed during account deletion: $error');
      }
      final result = await _repository.deleteAccount();
      if (result.isSuccess) {
        await handleSessionExpired();
      }
      return result;
    } finally {
      _accountDeleting = false;
      notifyListeners();
    }
  }

  Future<void> handleSessionExpired() async {
    _client = null;
    _addresses = const <ClientAddress>[];
    _orders = const <CustomerOrderModel>[];
    _failure = null;
    if (_status == MobileBackendStatus.initial) {
      _status = MobileBackendStatus.loaded;
    }
    notifyListeners();
  }

  Future<void> refreshCustomerData() async {
    if (_client == null) return;

    final profileResult = await _repository.getProfile();
    switch (profileResult) {
      case Success(:final data):
        _client = data;
        _failure = null;
      case Error(:final failure):
        _failure = failure;
        notifyListeners();
        return;
    }

    final addressesResult = await _repository.getAddresses();
    switch (addressesResult) {
      case Success(:final data):
        _addresses = data;
      case Error(:final failure):
        _failure = failure;
        if (_client == null) {
          notifyListeners();
          return;
        }
    }

    final ordersResult = await _repository.getOrders();
    switch (ordersResult) {
      case Success(:final data):
        _orders = data;
      case Error(:final failure):
        _failure = failure;
    }

    notifyListeners();
  }

  Future<Result<CartPreviewModel>> previewCart(
    CartPreviewRequest request,
  ) async {
    return _repository.previewCart(request);
  }

  Future<Result<CustomerOrderModel>> createOrder(
    CreateOrderRequest request,
  ) async {
    final result = await _repository.createOrder(request);
    switch (result) {
      case Success(:final data):
        _orders = <CustomerOrderModel>[
          data,
          for (final order in _orders)
            if (order.id != data.id) order,
        ];
        _failure = null;
        if (_status == MobileBackendStatus.initial) {
          _status = MobileBackendStatus.loaded;
        }
        notifyListeners();
      case Error(:final failure):
        _failure = failure;
    }
    return result;
  }

  Future<void> bootstrap({required String language, String? branchId}) async {
    if (_status == MobileBackendStatus.loading) return;

    _status = MobileBackendStatus.loading;
    _failure = null;
    notifyListeners();

    final result = await _repository.bootstrap(
      language: language,
      branchId: branchId,
    );

    switch (result) {
      case Success(:final data):
        _branches = data.branches;
        _promotions = data.promotions;
        _client = data.client;
        _addresses = data.addresses;
        _orders = data.orders;
        _applyCatalog(data.catalog);
        final client = data.client;
        if (client != null) {
          _startPushNotificationSync(locale: client.language);
        }
        _status = MobileBackendStatus.loaded;
      case Error(:final failure):
        _failure = failure;
        _status = MobileBackendStatus.error;
    }

    notifyListeners();
  }

  Future<Result<CatalogModel>> refreshCatalog({
    required String language,
    String? branchId,
  }) async {
    final result = await _repository.getCatalog(
      language: language,
      branchId: branchId,
    );

    switch (result) {
      case Success(:final data):
        _applyCatalog(data);
        _failure = null;
        notifyListeners();
      case Error(:final failure):
        _failure = failure;
        notifyListeners();
    }

    return result;
  }

  void _startPushNotificationSync({String? locale}) {
    unawaited(_syncPushNotificationToken(locale: locale));
  }

  Future<void> _syncPushNotificationToken({String? locale}) async {
    try {
      await _pushNotifications.syncToken(locale: locale);
      _pushNotificationSettings = await _pushNotifications.getSettings();
      notifyListeners();
    } catch (error) {
      debugPrint('Push notification sync failed: $error');
    }
  }

  void _applyCatalog(CatalogModel catalog) {
    final adaptedProducts = _adaptProducts(catalog);

    final seenCategories = <String>{};
    final adaptedCategories = <String>[];
    for (final product in adaptedProducts) {
      if (seenCategories.add(product.category)) {
        adaptedCategories.add(product.category);
      }
    }

    _menuProducts = adaptedProducts;
    _menuCategories = adaptedCategories;
  }

  List<MenuProduct> _adaptProducts(CatalogModel catalog) {
    final categoryNameById = <String, String>{
      for (final category in catalog.categories) category.id: category.name,
    };

    return catalog.products
        .where((product) => product.isAvailable)
        .map((product) {
          final category = product.categoryName?.isNotEmpty == true
              ? product.categoryName!
              : categoryNameById[product.categoryId] ?? 'Menu';
          final visual = _visualFor(product.id, product.name, category);

          return MenuProduct(
            id: product.id,
            iikoId: product.iikoId,
            title: product.name,
            price: product.price,
            category: category,
            emoji: visual.emoji,
            tint: visual.tint,
            highlight: visual.highlight,
            imageUrl: _resolveImageUrl(product.image),
          );
        })
        .toList(growable: false);
  }
}

String? _resolveImageUrl(String? value) {
  final imageUrl = value?.trim();
  if (imageUrl == null || imageUrl.isEmpty) return null;

  final parsedUrl = Uri.tryParse(imageUrl);
  if (parsedUrl != null && parsedUrl.hasScheme) return imageUrl;

  final baseUrl = Uri.tryParse(BaseUrl.baseUrl);
  if (baseUrl == null) return imageUrl;

  return baseUrl.resolve(imageUrl).toString();
}

typedef _ProductVisual = ({String emoji, Color tint, Color highlight});

const List<_ProductVisual> _fallbackVisuals = <_ProductVisual>[
  (emoji: '🌯', tint: Color(0xFFFFE0D6), highlight: Color(0xFFFFF6F0)),
  (emoji: '🥙', tint: Color(0xFFFFEAD1), highlight: Color(0xFFFFF7EE)),
  (emoji: '🍕', tint: Color(0xFFFFE2D4), highlight: Color(0xFFFFF5F0)),
  (emoji: '🍔', tint: Color(0xFFFFE8C8), highlight: Color(0xFFFFF7EA)),
  (emoji: '🌭', tint: Color(0xFFFFDFC9), highlight: Color(0xFFFFF5EE)),
  (emoji: '🥗', tint: Color(0xFFE4F3D8), highlight: Color(0xFFF6FBF0)),
  (emoji: '🥤', tint: Color(0xFFDDF1FF), highlight: Color(0xFFF3FAFF)),
];

_ProductVisual _visualFor(String id, String name, String category) {
  final text = '$name $category'.toLowerCase();
  if (text.contains('pizza') || text.contains('пиц')) {
    return _fallbackVisuals[2];
  }
  if (text.contains('burger') || text.contains('бургер')) {
    return _fallbackVisuals[3];
  }
  if (text.contains('hot') || text.contains('хот')) {
    return _fallbackVisuals[4];
  }
  if (text.contains('salad') || text.contains('салат')) {
    return _fallbackVisuals[5];
  }
  if (text.contains('cola') ||
      text.contains('pepsi') ||
      text.contains('напит')) {
    return _fallbackVisuals[6];
  }
  return _fallbackVisuals[_stableHash(id) % _fallbackVisuals.length];
}

int _stableHash(String value) {
  var hash = 0;
  for (final codeUnit in value.codeUnits) {
    hash = 0x1fffffff & (hash + codeUnit);
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    hash ^= hash >> 6;
  }
  hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
  hash ^= hash >> 11;
  hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  return hash;
}
