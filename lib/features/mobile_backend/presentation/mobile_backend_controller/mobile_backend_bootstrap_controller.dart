part of '../mobile_backend_controller.dart';

extension _MobileBackendBootstrapController on MobileBackendController {
  Future<void> _refreshCustomerData() async {
    if (_client == null) return;
    final generation = _sessionGeneration;
    // Independent reads: request them together, then apply in order. Each
    // repository call returns a Result, so none of these futures can throw.
    final profileRequest = _repository.getProfile();
    final addressesRequest = _repository.getAddresses();
    final ordersRequest = _repository.getOrders();
    final notificationsRequest = _repository.getNotifications();
    final assignedPromotionsRequest = _repository.getAssignedPromotions(
      language: _client?.language ?? 'uz',
    );

    final profileResult = await profileRequest;
    if (!_isCurrentSession(generation)) return;
    switch (profileResult) {
      case Success(:final data):
        _client = data;
        _failure = null;
      case Error(:final failure):
        _applyFailure(failure);
        return;
    }

    final addressesResult = await addressesRequest;
    if (!_isCurrentSession(generation)) return;
    switch (addressesResult) {
      case Success(:final data):
        _addresses = _sortedAddresses(data);
        _addressesFailure = null;
      case Error(:final failure):
        _addressesFailure = failure;
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

    final ordersResult = await ordersRequest;
    if (!_isCurrentSession(generation)) return;
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

    final notificationsResult = await notificationsRequest;
    if (!_isCurrentSession(generation)) return;
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

    final assignedPromotionsResult = await assignedPromotionsRequest;
    if (!_isCurrentSession(generation)) return;
    switch (assignedPromotionsResult) {
      case Success(:final data):
        _assignedPromotions = data;
        _assignedPromotionsFetchedAt = _clock();
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

    unawaited(refreshLoyaltyWallet());

    _notifyListeners();
  }

  Future<void> _bootstrap({required String language, String? branchId}) async {
    if (_status == MobileBackendStatus.loading) return;

    final settled = Completer<void>();
    _bootstrapInFlight = settled;
    try {
      await _runBootstrap(language: language, branchId: branchId);
    } finally {
      if (identical(_bootstrapInFlight, settled)) _bootstrapInFlight = null;
      settled.complete();
    }
  }

  Future<void> _runBootstrap({
    required String language,
    String? branchId,
  }) async {
    final generation = _sessionGeneration;
    final catalogVersion = ++_catalogRequestVersion;
    final paymentMethodsVersion = ++_paymentMethodsRequestVersion;
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
        _banners = data.banners;
        if (paymentMethodsVersion == _paymentMethodsRequestVersion) {
          _paymentMethods = data.paymentMethods;
          _paymentMethodsBranchId = branchId?.trim().isEmpty == true
              ? null
              : branchId?.trim();
          _paymentMethodsFailure = null;
          _paymentMethodsLoading = false;
        }
        if (catalogVersion == _catalogRequestVersion) {
          _applyCatalog(data.catalog);
          _markNetworkContent();
        }
        // A login, logout or expiry while this request was in flight owns the
        // customer state now; only the public data above is applied.
        if (_isCurrentSession(generation)) {
          _applyBootstrapSession(data, language: language);
        }
        _status = MobileBackendStatus.loaded;
      case Error(:final failure):
        _applyFailure(failure, notify: false);
        // Keep the failure visible even when it was an auth failure (which
        // already cleared the session) so the retry UI can reload as a guest.
        _failure = failure;
        _status = MobileBackendStatus.error;
    }

    _notifyListeners();
  }

  void _applyBootstrapSession(
    MobileBootstrap data, {
    required String language,
  }) {
    _client = data.client;
    _addresses = _sortedAddresses(data.addresses);
    _addressesFailure = null;
    _orders = data.orders;
    if (data.client != null) {
      _startPushNotificationSync(locale: language);
      unawaited(syncClientLanguage(language: language));
      unawaited(refreshNotifications());
      unawaited(refreshAssignedPromotions(language: language));
      unawaited(refreshLoyaltyWallet());
    } else {
      _notifications = const <ClientNotificationItemModel>[];
      _notificationUnreadCount = 0;
      _notificationTotal = 0;
      _assignedPromotions = const <AssignedPromotionModel>[];
    }
  }

  Future<Result<CatalogModel>> _refreshCatalog({
    required String language,
    String? branchId,
  }) async {
    final catalogVersion = ++_catalogRequestVersion;
    final result = await _repository.getCatalog(
      language: language,
      branchId: branchId,
    );
    // A newer catalog request (another branch, or a bootstrap) wins.
    if (catalogVersion != _catalogRequestVersion) return result;

    switch (result) {
      case Success(:final data):
        _applyCatalog(data);
        _markNetworkContent();
        _failure = null;
        _notifyListeners();
      case Error(:final failure):
        _applyFailure(failure);
    }

    return result;
  }

  void _markNetworkContent() {
    _networkContentApplied = true;
    _showingCachedContent = false;
  }

  Future<void> _restoreCachedContent({required String language}) async {
    if (_networkContentApplied) return;
    MobilePublicContent? content;
    try {
      content = await _repository.readCachedPublicContent(language: language);
    } catch (_) {
      return;
    }
    // The network may have answered while the file was read; it wins. The
    // catalog request version is left alone so the running bootstrap still
    // applies its own catalog.
    if (content == null || _networkContentApplied || _disposed) return;
    _branches = content.branches;
    _promotions = content.promotions;
    _banners = content.banners;
    _applyCatalog(content.catalog);
    _showingCachedContent = true;
    _notifyListeners();
  }
}
