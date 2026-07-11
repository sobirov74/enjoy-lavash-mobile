part of '../mobile_backend_controller.dart';

extension _MobileBackendStateController on MobileBackendController {
  void _clearAuthenticatedState({bool notify = true}) {
    _client = null;
    _addresses = const <ClientAddress>[];
    _orders = const <CustomerOrderModel>[];
    _notifications = const <ClientNotificationItemModel>[];
    _notificationUnreadCount = 0;
    _notificationTotal = 0;
    _notificationsLoading = false;
    _failure = null;
    if (_status == MobileBackendStatus.initial ||
        _status == MobileBackendStatus.loading) {
      _status = MobileBackendStatus.loaded;
    }
    if (notify) {
      _notifyListeners();
    }
  }

  bool _applyFailure(Failure failure, {bool notify = true}) {
    if (failure is AuthFailure) {
      _clearAuthenticatedState(notify: notify);
      return true;
    }

    _failure = failure;
    if (notify) {
      _notifyListeners();
    }
    return false;
  }
}
