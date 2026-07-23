part of '../mobile_backend_controller.dart';

extension _MobileBackendBootstrapController on MobileBackendController {
  Future<void> _refreshCustomerData() async {
    if (_client == null) return;

    final profileResult = await _repository.getProfile();
    switch (profileResult) {
      case Success(:final data):
        _client = data;
        _failure = null;
      case Error(:final failure):
        _applyFailure(failure);
        return;
    }

    final addressesResult = await _repository.getAddresses();
    switch (addressesResult) {
      case Success(:final data):
        _addresses = data;
      case Error(:final failure):
        if (failure is AuthFailure) {
          _applyFailure(failure);
          return;
        }
        _applyFailure(failure, notify: false);
        if (_client == null) {
          _notifyListeners();
          return;
        }
    }

    final ordersResult = await _repository.getOrders();
    switch (ordersResult) {
      case Success(:final data):
        _orders = data;
      case Error(:final failure):
        if (failure is AuthFailure) {
          _applyFailure(failure);
          return;
        }
        _applyFailure(failure, notify: false);
    }

    final notificationsResult = await _repository.getNotifications();
    switch (notificationsResult) {
      case Success(:final data):
        _applyNotifications(data);
      case Error(:final failure):
        if (failure is AuthFailure) {
          _applyFailure(failure);
          return;
        }
        _applyFailure(failure, notify: false);
    }

    final assignedPromotionsResult = await _repository.getAssignedPromotions(
      language: _client?.language ?? 'uz',
    );
    switch (assignedPromotionsResult) {
      case Success(:final data):
        _assignedPromotions = data;
        _assignedPromotionsIncludeAll = false;
        _assignedPromotionsFailure = null;
      case Error(:final failure):
        if (failure is AuthFailure) {
          _applyFailure(failure);
          return;
        }
        _assignedPromotionsFailure = failure;
        _applyFailure(failure, notify: false);
    }

    _notifyListeners();
  }

  Future<void> _bootstrap({required String language, String? branchId}) async {
    if (_status == MobileBackendStatus.loading) return;

    _status = MobileBackendStatus.loading;
    _failure = null;
    _notifyListeners();

    final result = await _repository.bootstrap(
      language: language,
      branchId: branchId,
    );

    switch (result) {
      case Success(:final data):
        _branches = data.branches;
        _promotions = data.promotions;
        _paymentMethods = data.paymentMethods;
        _paymentMethodsBranchId = branchId?.trim().isEmpty == true
            ? null
            : branchId?.trim();
        _paymentMethodsFailure = null;
        _paymentMethodsLoading = false;
        _client = data.client;
        _addresses = data.addresses;
        _orders = data.orders;
        _applyCatalog(data.catalog);
        final client = data.client;
        if (client != null) {
          _startPushNotificationSync(locale: language);
          unawaited(syncClientLanguage(language: language));
          unawaited(refreshNotifications());
          unawaited(refreshAssignedPromotions(language: language));
        } else {
          _notifications = const <ClientNotificationItemModel>[];
          _notificationUnreadCount = 0;
          _notificationTotal = 0;
          _assignedPromotions = const <AssignedPromotionModel>[];
        }
        _status = MobileBackendStatus.loaded;
      case Error(:final failure):
        if (!_applyFailure(failure, notify: false)) {
          _status = MobileBackendStatus.error;
        }
    }

    _notifyListeners();
  }

  Future<Result<CatalogModel>> _refreshCatalog({
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
        _notifyListeners();
      case Error(:final failure):
        _applyFailure(failure);
    }

    return result;
  }
}
