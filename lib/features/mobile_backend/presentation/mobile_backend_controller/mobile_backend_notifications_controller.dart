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

    _notificationsLoading = true;
    _notifyListeners();

    final result = await _repository.getNotifications(
      limit: limit,
      offset: offset,
      unreadOnly: unreadOnly,
    );
    switch (result) {
      case Success(:final data):
        _applyNotifications(data);
        _failure = null;
      case Error(:final failure):
        _applyFailure(failure, notify: false);
    }

    _notificationsLoading = false;
    _notifyListeners();
    return result;
  }

  Future<Result<int>> _refreshNotificationUnreadCount() async {
    if (_client == null) {
      _notificationUnreadCount = 0;
      _notifyListeners();
      return const Success(0);
    }

    final result = await _repository.getUnreadNotificationCount();
    switch (result) {
      case Success(:final data):
        _notificationUnreadCount = data;
        _failure = null;
        _notifyListeners();
      case Error(:final failure):
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
        _notificationUnreadCount = data.unreadCount;
        _notifications = _notifications
            .map(
              (notification) => notification.notificationId == notificationId
                  ? notification.copyWith(readAt: DateTime.now(), isRead: true)
                  : notification,
            )
            .toList(growable: false);
        _failure = null;
        _notifyListeners();
      case Error(:final failure):
        _applyFailure(failure);
    }
    return result;
  }

  Future<Result<ClientNotificationReadResultModel>>
  _markAllNotificationsRead() async {
    final result = await _repository.markAllNotificationsRead();
    switch (result) {
      case Success(:final data):
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
        _notifyListeners();
      case Error(:final failure):
        _applyFailure(failure);
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
      _notifyListeners();
    } catch (error) {
      debugPrint('Push notification sync failed: $error');
    }
  }

  void _applyNotifications(ClientNotificationInboxModel inbox) {
    _notifications = inbox.items;
    _notificationUnreadCount = inbox.unreadCount;
    _notificationTotal = inbox.total;
  }
}
