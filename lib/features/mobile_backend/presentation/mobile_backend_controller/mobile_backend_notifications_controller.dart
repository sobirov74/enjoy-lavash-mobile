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
    final generation = _sessionGeneration;
    final result = await _repository.markNotificationRead(
      notificationId: notificationId,
    );
    if (!_isCurrentSession(generation)) return result;
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
    final generation = _sessionGeneration;
    final result = await _repository.markNotificationUnread(
      notificationId: notificationId,
    );
    if (!_isCurrentSession(generation)) return result;
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
    final generation = _sessionGeneration;
    final result = await _repository.markAllNotificationsRead();
    if (!_isCurrentSession(generation)) return result;
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
          _assignedPromotionsFetchedAt = _clock();
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
    final pushRecheck = _pushSettingsRecheckPending;
    _pushSettingsRecheckPending = false;
    final client = _client;
    if (client == null) {
      if (pushRecheck) unawaited(_refreshPushNotificationSettings());
      return;
    }
    // Returning from the payment page, a permission dialog or a quick app
    // switch should not re-fetch everything each time. Coming back from the
    // phone settings re-checks notifications anyway.
    final now = _clock();
    final last = _lastResumeRefreshAt;
    if (last != null && now.difference(last) < resumeRefreshInterval) {
      if (pushRecheck) {
        _startPushNotificationSync(locale: locale ?? client.language);
      }
      return;
    }
    _lastResumeRefreshAt = now;

    _startPushNotificationSync(locale: locale ?? client.language);
    await Future.wait<Object?>([
      refreshNotificationUnreadCount(),
      refreshAssignedPromotions(
        language: locale ?? client.language,
        includeAll: _assignedPromotionsIncludeAll,
      ),
      refreshLoyaltyWallet(),
    ]);
  }

  void _startPushNotificationSync({
    String? locale,
    bool requestPermission = false,
  }) {
    unawaited(
      _syncPushNotificationToken(
        locale: locale,
        requestPermission: requestPermission,
      ),
    );
  }

  /// Registers the device token when notifications are allowed. With
  /// [requestPermission] the OS prompt is shown first (the first ask, or a
  /// reminder the customer accepted); background refreshes never prompt. A
  /// guest's settings are only read; the token is registered once the
  /// customer signs in.
  Future<void> _syncPushNotificationToken({
    String? locale,
    bool requestPermission = false,
  }) async {
    try {
      if (requestPermission) {
        final settings = await _pushNotifications.requestPermission();
        _pushNotificationSettings = settings;
        _notifyListeners();
        if (!settings.enabled || _client == null) return;
      } else if (_client == null) {
        await _refreshPushNotificationSettings();
        return;
      }
      await _pushNotifications.syncTokenIfPermissionGranted(locale: locale);
      final settings = await _pushNotifications.getSettings();
      _pushNotificationSettings = settings;
      if (settings.enabled) await _pushNotifications.clearPermissionAsks();
      _notifyListeners();
    } catch (error) {
      debugPrint('Push notification sync failed: $error');
    }
  }

  /// Shows the OS prompt if this install never saw it, and returns whether
  /// it did. Otherwise only syncs (registers when already allowed).
  Future<bool> _askFirstPushPermission({String? locale}) async {
    try {
      if (!await _pushNotifications.canShowFirstPermissionPrompt()) {
        await _syncPushNotificationToken(locale: locale);
        return false;
      }
      await _pushNotifications.recordPermissionAsk(_clock());
    } catch (error) {
      debugPrint('Push permission check failed: $error');
      return false;
    }
    await _syncPushNotificationToken(locale: locale, requestPermission: true);
    return true;
  }

  Future<void> _requestPushNotificationPermissionOnEntry({
    String? locale,
  }) async {
    if (await _askFirstPushPermission(locale: locale)) return;
    // The reminder is for signed-in customers; wait until the start-up
    // request says who that is.
    await whenSessionSettled();
    if (_disposed || _client == null) return;
    try {
      if (await _pushReminderAction(ignoreSchedule: false) == null) return;
    } catch (error) {
      debugPrint('Push reminder check failed: $error');
      return;
    }
    if (!_pushReminderDueController.isClosed) {
      _pushReminderDueController.add(null);
    }
  }

  Future<PushReminderAction?> _takePushPermissionReminder({
    required bool ignoreSchedule,
  }) async {
    try {
      final action = await _pushReminderAction(ignoreSchedule: ignoreSchedule);
      if (action != null) {
        await _pushNotifications.recordPermissionAsk(_clock());
      }
      return action;
    } catch (error) {
      debugPrint('Push reminder check failed: $error');
      return null;
    }
  }

  /// The reminder that applies now, without recording it as shown.
  Future<PushReminderAction?> _pushReminderAction({
    required bool ignoreSchedule,
  }) async {
    if (_client == null) return null;
    final settings = await _pushNotifications.getSettings();
    if (!settings.supported || settings.enabled || !settings.userEnabled) {
      return null;
    }
    if (!ignoreSchedule) {
      final asks = await _pushNotifications.permissionAsks();
      final due = isPushReminderDue(
        now: _clock(),
        lastAskedAt: asks.lastAskedAt,
        timesAsked: asks.count,
      );
      if (!due) return null;
    }
    return await _pushNotifications.systemPromptAvailable()
        ? PushReminderAction.systemPrompt
        : PushReminderAction.openSettings;
  }

  Future<void> _acceptPushPermissionReminder(
    PushReminderAction action, {
    String? locale,
  }) async {
    switch (action) {
      case PushReminderAction.systemPrompt:
        await _syncPushNotificationToken(
          locale: locale ?? _client?.language,
          requestPermission: true,
        );
      case PushReminderAction.openSettings:
        await _openNotificationSettings();
    }
  }

  Future<bool> _openNotificationSettings() {
    _pushSettingsRecheckPending = true;
    return _pushNotifications.openNotificationSettings();
  }

  void _applyNotifications(ClientNotificationInboxModel inbox) {
    _notificationCountRequestVersion++;
    _notifications = inbox.items;
    _notificationUnreadCount = inbox.unreadCount;
    _notificationTotal = inbox.total;
    _notificationsFailure = null;
  }
}
