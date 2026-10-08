part of '../mobile_backend_controller.dart';

extension _MobileBackendStateController on MobileBackendController {
  bool _isCurrentSession(int generation) => generation == _sessionGeneration;

  /// Ends the session for [reason] and tells listeners (the app shell clears
  /// on-device customer data for an explicit sign-out or deletion).
  void _endSession(SessionEndReason reason) {
    _pendingPushMessage = null;
    _clearAuthenticatedState();
    if (!_sessionEndedController.isClosed) _sessionEndedController.add(reason);
  }

  void _clearAuthenticatedState({bool notify = true}) {
    _sessionGeneration++;
    _notificationsRequestVersion++;
    _notificationCountRequestVersion++;
    _assignedPromotionsRequestVersion++;
    _loyaltyWalletRequestVersion++;
    _loyaltyTransactionsRequestVersion++;
    _client = null;
    _addresses = const <ClientAddress>[];
    _addressesUpdating = false;
    _addressesFailure = null;
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
    _assignedPromotionsFetchedAt = null;
    _loyaltyWallet = null;
    _loyaltyWalletLoading = false;
    _loyaltyWalletFailure = null;
    _loyaltyTransactions = const <LoyaltyTransactionModel>[];
    _loyaltyTransactionsNextCursor = null;
    _loyaltyTransactionsLoading = false;
    _loyaltyTransactionsLoadingMore = false;
    _loyaltyTransactionsFailure = null;
    _failure = null;
    // A running bootstrap owns the loading state and settles it itself;
    // flipping it here let a second bootstrap start concurrently.
    if (_status == MobileBackendStatus.initial) {
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
