part of '../mobile_backend_controller.dart';

extension _MobileBackendNotificationsController on MobileBackendController {
  Future<void> _refreshPushNotificationSettings() async {
    _pushNotificationSettings = await _pushNotifications.getSettings();
    _notifyListeners();
  }

  Future<Result<PushNotificationSettings>> _setPushNotificationsEnabled(
    bool enabled,
  ) async {
    _pushNotificationsUpdating = true;
    _notifyListeners();

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
      _applyFailure(failure, notify: false);
      return Error(failure);
    } finally {
      _pushNotificationsUpdating = false;
      _notifyListeners();
    }
  }

  Future<Result<ClientNotificationInboxModel>> _refreshNotifications({
    int limit = 50,
    int offset = 0,
    bool unreadOnly = false,
  }) async {
    if (_client == null) {
      return Success(
        ClientNotificationInboxModel(
          items: _notifications,
          unreadCount: _notificationUnreadCount,
          total: _notificationTotal,
          limit: limit,
          offset: offset,
        ),
      );
    }

    final requestVersion = ++_notificationsRequestVersion;
    _notificationsLoading = true;
    _notificationsFailure = null;
    _notifyListeners();

    final result = await _repository.getNotifications(
      limit: limit,
      offset: offset,
      unreadOnly: unreadOnly,
    );
    if (requestVersion == _notificationsRequestVersion) {
      switch (result) {
        case Success(:final data):
          _applyNotifications(data);
          _notificationsFailure = null;
          _failure = null;
        case Error(:final failure):
          _notificationsFailure = failure;
          _applyFailure(failure, notify: false);
      }

      _notificationsLoading = false;
      _notifyListeners();
    }
    return result;
  }

  Future<Result<int>> _refreshNotificationUnreadCount() async {
    if (_client == null) {
      _notificationUnreadCount = 0;
      _notifyListeners();
      return const Success(0);
    }

    final requestVersion = ++_notificationCountRequestVersion;
    final result = await _repository.getUnreadNotificationCount();
    if (requestVersion != _notificationCountRequestVersion) return result;
    switch (result) {
      case Success(:final data):
        _notificationUnreadCount = data;
        _notificationsFailure = null;
        _failure = null;
        _notifyListeners();
      case Error(:final failure):
        _notificationsFailure = failure;
        _applyFailure(failure);
    }
    return result;
  }

  Future<Result<ClientNotificationReadResultModel>> _markNotificationRead({
    required String notificationId,
  }) async {
    final result = await _repository.markNotificationRead(
      notificationId: notificationId,
    );
    switch (result) {
      case Success(:final data):
        _notificationsRequestVersion++;
        _notificationCountRequestVersion++;
        _notificationsLoading = false;
        _notificationUnreadCount = data.unreadCount;
        _notifications = _notifications
            .map(
              (notification) => notification.notificationId == notificationId
                  ? notification.copyWith(readAt: DateTime.now(), isRead: true)
                  : notification,
            )
            .toList(growable: false);
        _failure = null;
        _notificationsFailure = null;
        _notifyListeners();
      case Error(:final failure):
        _notificationsFailure = failure;
        _applyFailure(failure);
    }
    return result;
  }

  Future<Result<ClientNotificationReadResultModel>> _markNotificationUnread({
    required String notificationId,
  }) async {
    final result = await _repository.markNotificationUnread(
      notificationId: notificationId,
    );
    switch (result) {
      case Success(:final data):
        _notificationsRequestVersion++;
        _notificationCountRequestVersion++;
        _notificationsLoading = false;
        _notificationUnreadCount = data.unreadCount;
        _notifications = _notifications
            .map(
              (notification) => notification.notificationId == notificationId
                  ? notification.copyWith(clearReadAt: true, isRead: false)
                  : notification,
            )
            .toList(growable: false);
        _failure = null;
        _notificationsFailure = null;
        _notifyListeners();
      case Error(:final failure):
        _notificationsFailure = failure;
        _applyFailure(failure);
    }
    return result;
  }

  Future<Result<ClientNotificationReadResultModel>>
  _markAllNotificationsRead() async {
    final result = await _repository.markAllNotificationsRead();
    switch (result) {
      case Success(:final data):
        _notificationsRequestVersion++;
        _notificationCountRequestVersion++;
        _notificationsLoading = false;
        _notificationUnreadCount = data.unreadCount;
        final now = DateTime.now();
        _notifications = _notifications
            .map(
              (notification) => notification.isRead
                  ? notification
                  : notification.copyWith(readAt: now, isRead: true),
            )
            .toList(growable: false);
        _failure = null;
        _notificationsFailure = null;
        _notifyListeners();
      case Error(:final failure):
        _notificationsFailure = failure;
        _applyFailure(failure);
    }
    return result;
  }

  Future<Result<List<AssignedPromotionModel>>> _refreshAssignedPromotions({
    required bool includeAll,
    required String language,
  }) async {
    if (_client == null) {
      _assignedPromotions = const <AssignedPromotionModel>[];
      _assignedPromotionsIncludeAll = includeAll;
      _assignedPromotionsFailure = null;
      _notifyListeners();
      return const Success(<AssignedPromotionModel>[]);
    }

    final requestVersion = ++_assignedPromotionsRequestVersion;
    _assignedPromotionsLoading = true;
    _assignedPromotionsFailure = null;
    _notifyListeners();

    final result = await _repository.getAssignedPromotions(
      includeAll: includeAll,
      language: language,
    );
    if (requestVersion == _assignedPromotionsRequestVersion) {
      switch (result) {
        case Success(:final data):
          _assignedPromotions = data;
          _assignedPromotionsIncludeAll = includeAll;
          _assignedPromotionsFailure = null;
          _failure = null;
        case Error(:final failure):
          _assignedPromotionsFailure = failure;
          _applyFailure(failure, notify: false);
      }
      _assignedPromotionsLoading = false;
      _notifyListeners();
    }
    return result;
  }

  Future<void> _handleAppResumed({String? locale}) async {
    final client = _client;
    if (client == null) return;

    _startPushNotificationSync(locale: locale ?? client.language);
    await Future.wait<Object?>([
      refreshNotificationUnreadCount(),
      refreshAssignedPromotions(
        language: locale ?? client.language,
        includeAll: _assignedPromotionsIncludeAll,
      ),
    ]);
  }

  void _startPushNotificationSync({String? locale}) {
    unawaited(_syncPushNotificationToken(locale: locale));
  }

  Future<void> _syncPushNotificationToken({String? locale}) async {
    try {
      await _pushNotifications.syncTokenIfPermissionGranted(locale: locale);
      _pushNotificationSettings = await _pushNotifications.getSettings();
      _notifyListeners();
    } catch (error) {
      debugPrint('Push notification sync failed: $error');
    }
  }

  void _applyNotifications(ClientNotificationInboxModel inbox) {
    _notificationCountRequestVersion++;
    _notifications = inbox.items;
    _notificationUnreadCount = inbox.unreadCount;
    _notificationTotal = inbox.total;
    _notificationsFailure = null;
  }
}
