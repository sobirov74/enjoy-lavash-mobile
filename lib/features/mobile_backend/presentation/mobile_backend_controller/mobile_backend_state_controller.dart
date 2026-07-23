part of '../mobile_backend_controller.dart';

extension _MobileBackendStateController on MobileBackendController {
  void _clearAuthenticatedState({bool notify = true}) {
    _notificationsRequestVersion++;
    _notificationCountRequestVersion++;
    _assignedPromotionsRequestVersion++;
    _client = null;
    _addresses = const <ClientAddress>[];
    _orders = const <CustomerOrderModel>[];
    _notifications = const <ClientNotificationItemModel>[];
    _assignedPromotions = const <AssignedPromotionModel>[];
    _notificationUnreadCount = 0;
    _notificationTotal = 0;
    _notificationsLoading = false;
    _notificationsFailure = null;
    _assignedPromotionsLoading = false;
    _assignedPromotionsIncludeAll = false;
    _assignedPromotionsFailure = null;
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
