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
        this._applyFailure(failure);
        return;
    }

    final addressesResult = await _repository.getAddresses();
    switch (addressesResult) {
      case Success(:final data):
        _addresses = data;
      case Error(:final failure):
        if (failure is AuthFailure) {
          this._applyFailure(failure);
          return;
        }
        this._applyFailure(failure, notify: false);
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
        if (failure is AuthFailure) {
          this._applyFailure(failure);
          return;
        }
        this._applyFailure(failure, notify: false);
    }

    final notificationsResult = await _repository.getNotifications();
    switch (notificationsResult) {
      case Success(:final data):
        this._applyNotifications(data);
      case Error(:final failure):
        if (failure is AuthFailure) {
          this._applyFailure(failure);
          return;
        }
        this._applyFailure(failure, notify: false);
    }

    notifyListeners();
  }

  Future<void> _bootstrap({required String language, String? branchId}) async {
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
        _paymentMethods = data.paymentMethods;
        _client = data.client;
        _addresses = data.addresses;
        _orders = data.orders;
        this._applyCatalog(data.catalog);
        final client = data.client;
        if (client != null) {
          this._startPushNotificationSync(locale: language);
          unawaited(syncClientLanguage(language: language));
          unawaited(refreshNotifications());
        } else {
          _notifications = const <ClientNotificationItemModel>[];
          _notificationUnreadCount = 0;
          _notificationTotal = 0;
        }
        _status = MobileBackendStatus.loaded;
      case Error(:final failure):
        if (!this._applyFailure(failure, notify: false)) {
          _status = MobileBackendStatus.error;
        }
    }

    notifyListeners();
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
        this._applyCatalog(data);
        _failure = null;
        notifyListeners();
      case Error(:final failure):
        this._applyFailure(failure);
    }

    return result;
  }
}
