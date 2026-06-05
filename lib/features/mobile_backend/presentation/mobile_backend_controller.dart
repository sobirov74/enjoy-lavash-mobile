import 'package:enjoy_lavash_mobile/core/error/failures.dart';
import 'package:enjoy_lavash_mobile/core/error/result.dart';
import 'package:enjoy_lavash_mobile/features/data/menu_catalog.dart'
    as static_catalog;
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
  MobileBackendController(this._repository);

  final MobileBackendRepository _repository;

  MobileBackendStatus _status = MobileBackendStatus.initial;
  Failure? _failure;
  List<String> _menuCategories = static_catalog.menuCategories;
  List<MenuProduct> _menuProducts = static_catalog.menuProducts;
  List<BranchModel> _branches = const <BranchModel>[];
  List<PromotionModel> _promotions = const <PromotionModel>[];
  List<ClientAddress> _addresses = const <ClientAddress>[];
  List<CustomerOrderModel> _orders = const <CustomerOrderModel>[];
  ClientProfile? _client;

  MobileBackendStatus get status => _status;
  Failure? get failure => _failure;
  List<String> get menuCategories => _menuCategories;
  List<MenuProduct> get menuProducts => _menuProducts;
  List<BranchModel> get branches => _branches;
  List<PromotionModel> get promotions => _promotions;
  List<ClientAddress> get addresses => _addresses;
  List<CustomerOrderModel> get orders => _orders;
  ClientProfile? get client => _client;
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
        if (_status == MobileBackendStatus.initial) {
          _status = MobileBackendStatus.loaded;
        }
        notifyListeners();
      case Error():
    }
    return result;
  }

  Future<Result<void>> logout() async {
    final result = await _repository.logout();
    if (result.isSuccess) {
      _client = null;
      _addresses = const <ClientAddress>[];
      _orders = const <CustomerOrderModel>[];
      _failure = null;
      if (_status == MobileBackendStatus.initial) {
        _status = MobileBackendStatus.loaded;
      }
      notifyListeners();
    }
    return result;
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
        _status = MobileBackendStatus.loaded;
      case Error(:final failure):
        _failure = failure;
        _status = MobileBackendStatus.error;
    }

    notifyListeners();
  }

  void _applyCatalog(CatalogModel catalog) {
    final adaptedProducts = _adaptProducts(catalog);
    if (adaptedProducts.isEmpty) return;

    final seenCategories = <String>{};
    final adaptedCategories = <String>[];
    for (final product in adaptedProducts) {
      if (seenCategories.add(product.category)) {
        adaptedCategories.add(product.category);
      }
    }

    if (adaptedCategories.isEmpty) return;

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
              : categoryNameById[product.categoryId] ??
                    static_catalog.menuCategories.first;
          final visual = _visualFor(product.id, product.name, category);

          return MenuProduct(
            id: product.id,
            title: product.name,
            price: product.price,
            category: category,
            emoji: visual.emoji,
            tint: visual.tint,
            highlight: visual.highlight,
          );
        })
        .toList(growable: false);
  }
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
