import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/banner_model.dart';
import 'dart:async';
import 'dart:convert';

import 'package:enjoy_lavash_mobile/core/api/base_url.dart';
import 'package:enjoy_lavash_mobile/core/error/failures.dart';
import 'package:enjoy_lavash_mobile/core/error/result.dart';
import 'package:enjoy_lavash_mobile/core/services/mobile_push_notification_service.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/address_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/app_version_policy_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/assigned_promotion_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/auth_models.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/branch_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/cart_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/catalog_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/client_notification_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/client_profile_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/loyalty_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/order_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/ordering_status_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/promotion_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/domain/entities/mobile_bootstrap.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/domain/entities/mobile_public_content.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/domain/repositories/mobile_backend_repository.dart';
import 'package:enjoy_lavash_mobile/features/models/menu_product.dart';
import 'package:enjoy_lavash_mobile/features/models/menu_category.dart';
import 'package:enjoy_lavash_mobile/features/push_permission/push_reminder_schedule.dart';
import 'package:flutter/material.dart';

part 'mobile_backend_controller/mobile_backend_auth_controller.dart';
part 'mobile_backend_controller/mobile_backend_address_controller.dart';
part 'mobile_backend_controller/mobile_backend_bootstrap_controller.dart';
part 'mobile_backend_controller/mobile_backend_catalog_adapter.dart';
part 'mobile_backend_controller/mobile_backend_notifications_controller.dart';
part 'mobile_backend_controller/mobile_backend_order_controller.dart';
part 'mobile_backend_controller/mobile_backend_loyalty_controller.dart';
part 'mobile_backend_controller/mobile_backend_state_controller.dart';

enum MobileBackendStatus { initial, loading, loaded, error }

/// Why the signed-in session ended. The app shell clears on-device customer
/// data (cart, promo code, typed address) for [signedOut] and
/// [accountDeleted]; an [expired] session keeps it for the same customer.
enum SessionEndReason { signedOut, accountDeleted, expired }

/// Minimum time between two background refreshes triggered by app resume.
const Duration resumeRefreshInterval = Duration(seconds: 30);

/// How long a loaded list of assigned promotions counts as current.
const Duration assignedPromotionsFreshFor = Duration(minutes: 1);

class MobileBackendController extends ChangeNotifier {
  MobileBackendController(
    this._repository,
    this._pushNotifications, {
    @visibleForTesting DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    _pushMessageSubscription = _pushNotifications.messages.listen(
      _handlePushMessage,
    );
  }

  final MobileBackendRepository _repository;
  final MobilePushNotificationService _pushNotifications;
  late final StreamSubscription<PushNotificationMessage>
  _pushMessageSubscription;
  final StreamController<SessionEndReason> _sessionEndedController =
      StreamController<SessionEndReason>.broadcast();
  final StreamController<void> _pushReminderDueController =
      StreamController<void>.broadcast();

  /// Bumped whenever the signed-in customer changes (login, logout, expiry).
  /// Async work captures it first and drops its result if it changed, so a
  /// late response can never restore or overwrite another session's data.
  final DateTime Function() _clock;
  DateTime? _lastResumeRefreshAt;
  DateTime? _assignedPromotionsFetchedAt;
  int _sessionGeneration = 0;
  bool _disposed = false;
  int _catalogRequestVersion = 0;

  /// The catalog on screen came from the device, not yet from the network.
  bool _showingCachedContent = false;

  /// A network catalog has been applied; saved content may no longer
  /// replace what is shown.
  bool _networkContentApplied = false;

  /// Completes when the running bootstrap ends; null when none runs.
  Completer<void>? _bootstrapInFlight;

  MobileBackendStatus _status = MobileBackendStatus.initial;
  Failure? _failure;
  List<String> _menuCategories = const <String>[];
  List<MenuCategory> _menuCategoryItems = const <MenuCategory>[];
  List<MenuProduct> _menuProducts = const <MenuProduct>[];
  List<BranchModel> _branches = const <BranchModel>[];
  List<BannerModel> _banners = const <BannerModel>[];
  List<PromotionModel> _promotions = const <PromotionModel>[];
  List<PaymentMethodModel> _paymentMethods = const <PaymentMethodModel>[];
  String? _paymentMethodsBranchId;
  Failure? _paymentMethodsFailure;
  bool _paymentMethodsLoading = false;
  int _paymentMethodsRequestVersion = 0;
  List<ClientAddress> _addresses = const <ClientAddress>[];
  bool _addressesUpdating = false;
  Failure? _addressesFailure;
  List<CustomerOrderModel> _orders = const <CustomerOrderModel>[];
  List<ClientNotificationItemModel> _notifications =
      const <ClientNotificationItemModel>[];
  List<AssignedPromotionModel> _assignedPromotions =
      const <AssignedPromotionModel>[];
  ClientProfile? _client;
  int _notificationUnreadCount = 0;
  int _notificationTotal = 0;
  bool _notificationsLoading = false;
  Failure? _notificationsFailure;
  int _notificationsRequestVersion = 0;
  int _notificationCountRequestVersion = 0;
  bool _assignedPromotionsLoading = false;
  bool _assignedPromotionsIncludeAll = false;
  Failure? _assignedPromotionsFailure;
  int _assignedPromotionsRequestVersion = 0;
  PushNotificationMessage? _pendingPushMessage;
  PushNotificationSettings? _pushNotificationSettings;
  bool _pushNotificationsUpdating = false;

  /// Set when the phone settings were opened to allow notifications; the
  /// next resume re-checks the permission even inside the resume throttle.
  bool _pushSettingsRecheckPending = false;
  bool _accountDeleting = false;
  LoyaltyWalletModel? _loyaltyWallet;
  bool _loyaltyWalletLoading = false;
  Failure? _loyaltyWalletFailure;
  int _loyaltyWalletRequestVersion = 0;
  List<LoyaltyTransactionModel> _loyaltyTransactions =
      const <LoyaltyTransactionModel>[];
  String? _loyaltyTransactionsNextCursor;
  bool _loyaltyTransactionsLoading = false;
  bool _loyaltyTransactionsLoadingMore = false;
  Failure? _loyaltyTransactionsFailure;
  int _loyaltyTransactionsRequestVersion = 0;

  MobileBackendStatus get status => _status;
  Failure? get failure => _failure;
  List<String> get menuCategories => _menuCategories;
  List<MenuCategory> get menuCategoryItems => _menuCategoryItems;
  List<MenuProduct> get menuProducts => _menuProducts;
  List<BranchModel> get branches => _branches;
  List<BannerModel> get banners => _banners;
  List<PromotionModel> get promotions => _promotions;
  List<PaymentMethodModel> get paymentMethods => _paymentMethods;
  String? get paymentMethodsBranchId => _paymentMethodsBranchId;
  Failure? get paymentMethodsFailure => _paymentMethodsFailure;
  bool get paymentMethodsLoading => _paymentMethodsLoading;
  List<ClientAddress> get addresses => _addresses;
  bool get addressesUpdating => _addressesUpdating;
  Failure? get addressesFailure => _addressesFailure;
  List<CustomerOrderModel> get orders => _orders;
  List<ClientNotificationItemModel> get notifications => _notifications;
  List<AssignedPromotionModel> get assignedPromotions => _assignedPromotions;
  ClientProfile? get client => _client;
  int get notificationUnreadCount => _notificationUnreadCount;
  int get notificationTotal => _notificationTotal;
  bool get notificationsLoading => _notificationsLoading;
  Failure? get notificationsFailure => _notificationsFailure;
  bool get assignedPromotionsLoading => _assignedPromotionsLoading;
  bool get assignedPromotionsIncludeAll => _assignedPromotionsIncludeAll;

  /// Whether the [includeAll] list was loaded within
  /// [assignedPromotionsFreshFor]; screens skip an initial fetch then.
  bool hasFreshAssignedPromotions({required bool includeAll}) {
    final fetchedAt = _assignedPromotionsFetchedAt;
    if (fetchedAt == null || _assignedPromotionsIncludeAll != includeAll) {
      return false;
    }
    final age = _clock().difference(fetchedAt);
    return !age.isNegative && age < assignedPromotionsFreshFor;
  }

  Failure? get assignedPromotionsFailure => _assignedPromotionsFailure;
  PushNotificationMessage? get pendingPushMessage => _pendingPushMessage;
  PushNotificationSettings? get pushNotificationSettings =>
      _pushNotificationSettings;
  bool get pushNotificationsUpdating => _pushNotificationsUpdating;
  bool get accountDeleting => _accountDeleting;
  LoyaltyWalletModel? get loyaltyWallet => _loyaltyWallet;
  bool get loyaltyWalletLoading => _loyaltyWalletLoading;
  Failure? get loyaltyWalletFailure => _loyaltyWalletFailure;
  List<LoyaltyTransactionModel> get loyaltyTransactions => _loyaltyTransactions;
  String? get loyaltyTransactionsNextCursor => _loyaltyTransactionsNextCursor;
  bool get loyaltyTransactionsLoading => _loyaltyTransactionsLoading;
  bool get loyaltyTransactionsLoadingMore => _loyaltyTransactionsLoadingMore;
  Failure? get loyaltyTransactionsFailure => _loyaltyTransactionsFailure;
  bool get hasMoreLoyaltyTransactions => _loyaltyTransactionsNextCursor != null;
  bool get isAuthenticated => _client != null;

  /// Whether the menu, branches, promotions and banners shown were saved by
  /// an earlier launch and the network has not confirmed them yet. The cart
  /// is not reconciled against them, and screens may hold back customer
  /// details until the session is known.
  bool get isShowingCachedContent => _showingCachedContent;

  /// Completes once the running bootstrap (and so the signed-in state) is
  /// settled; at once when none runs. Actions that need to know whether the
  /// customer is signed in wait for it instead of treating "still loading"
  /// as "signed out".
  Future<void> whenSessionSettled() =>
      _bootstrapInFlight?.future ?? Future<void>.value();

  /// Shows the public content saved by the last launch while the bootstrap
  /// is still loading. Ignored once network content has arrived.
  Future<void> restoreCachedContent({required String language}) {
    return _restoreCachedContent(language: language);
  }

  Stream<SessionEndReason> get sessionEnded => _sessionEndedController.stream;
  bool get isLoading => _status == MobileBackendStatus.loading;

  PushNotificationMessage? takePendingPushMessage() {
    final message = _pendingPushMessage;
    _pendingPushMessage = null;
    return message;
  }

  void _handlePushMessage(PushNotificationMessage message) {
    if (message.openedByUser) {
      _pendingPushMessage = message;
    }
    if (_client != null) {
      // The inbox response carries the unread count too.
      unawaited(refreshNotifications());
      if (message.opensPromotions) {
        unawaited(
          refreshAssignedPromotions(
            language: _client?.language ?? 'uz',
            includeAll: true,
          ),
        );
      }
      if (message.opensLoyalty) {
        unawaited(refreshLoyaltyWallet());
      }
    }
    _notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_pushMessageSubscription.cancel());
    unawaited(_sessionEndedController.close());
    unawaited(_pushReminderDueController.close());
    super.dispose();
  }

  // Controller behavior is split into private extensions. Keeping the
  // ChangeNotifier call inside the class preserves its protected contract.
  // Background requests may finish after disposal; notifying then would throw.
  void _notifyListeners() {
    if (!_disposed) notifyListeners();
  }

  Future<Result<OtpRequestResponse>> requestOtp({required String phoneNumber}) {
    return _requestOtp(phoneNumber: phoneNumber);
  }

  Future<Result<VerifyOtpResponse>> verifyOtp(VerifyOtpRequest request) {
    return _verifyOtp(request);
  }

  Future<Result<ClientProfile>> updateProfile(ClientProfileUpdate request) {
    return _updateProfile(request);
  }

  Future<void> syncClientLanguage({required String language}) {
    return _syncClientLanguage(language: language);
  }

  Future<void> refreshPushNotificationSettings() {
    return _refreshPushNotificationSettings();
  }

  /// App entry: shows the OS notification prompt the first time only and
  /// registers the token when allowed. When a signed-in customer has
  /// notifications off and a reminder is due, [pushPermissionReminderDue]
  /// fires afterwards so the shell can show the reminder.
  Future<void> requestPushNotificationPermission({String? locale}) {
    return _requestPushNotificationPermissionOnEntry(locale: locale);
  }

  /// Sign-in: shows the OS notification prompt if this install never saw it.
  /// Returns whether it was shown; when not, the sign-in flow shows the
  /// in-app reminder instead.
  Future<bool> requestFirstPushNotificationPrompt({String? locale}) {
    return _askFirstPushPermission(locale: locale);
  }

  /// Fires after app entry when a notification reminder is due.
  Stream<void> get pushPermissionReminderDue =>
      _pushReminderDueController.stream;

  /// The reminder to show now, or null. Only for signed-in customers with
  /// notifications off and not switched off in the app; on the
  /// [pushReminderIntervals] schedule unless [ignoreSchedule]. A returned
  /// reminder counts as shown.
  Future<PushReminderAction?> takePushPermissionReminder({
    bool ignoreSchedule = false,
  }) {
    return _takePushPermissionReminder(ignoreSchedule: ignoreSchedule);
  }

  /// The customer accepted a reminder: shows the OS prompt, or opens the
  /// phone settings and re-checks when the app comes back.
  Future<void> acceptPushPermissionReminder(
    PushReminderAction action, {
    String? locale,
  }) {
    return _acceptPushPermissionReminder(action, locale: locale);
  }

  /// Opens this app's page in the phone settings to allow notifications.
  Future<bool> openNotificationSettings() {
    return _openNotificationSettings();
  }

  Future<Result<PushNotificationSettings>> setPushNotificationsEnabled(
    bool enabled,
  ) {
    return _setPushNotificationsEnabled(enabled);
  }

  Future<Result<void>> logout() {
    return _logout();
  }

  Future<Result<void>> deleteAccount() {
    return _deleteAccount();
  }

  Future<void> handleSessionExpired() {
    return _handleSessionExpired();
  }

  Future<void> refreshCustomerData() {
    return _refreshCustomerData();
  }

  Future<Result<List<ClientAddress>>> refreshAddresses() {
    return _refreshAddresses();
  }

  Future<Result<ClientAddress>> createAddress(ClientAddressInput request) {
    return _createAddress(request);
  }

  Future<Result<ClientAddress>> updateAddress({
    required String id,
    required ClientAddressInput request,
  }) {
    return _updateAddress(id: id, request: request);
  }

  Future<Result<void>> deleteAddress({required String id}) {
    return _deleteAddress(id: id);
  }

  Future<Result<ClientNotificationInboxModel>> refreshNotifications({
    int limit = 50,
    int offset = 0,
    bool unreadOnly = false,
  }) {
    return _refreshNotifications(
      limit: limit,
      offset: offset,
      unreadOnly: unreadOnly,
    );
  }

  Future<Result<int>> refreshNotificationUnreadCount() {
    return _refreshNotificationUnreadCount();
  }

  Future<Result<ClientNotificationReadResultModel>> markNotificationRead({
    required String notificationId,
  }) {
    return _markNotificationRead(notificationId: notificationId);
  }

  Future<Result<ClientNotificationReadResultModel>> markNotificationUnread({
    required String notificationId,
  }) {
    return _markNotificationUnread(notificationId: notificationId);
  }

  Future<Result<ClientNotificationReadResultModel>> markAllNotificationsRead() {
    return _markAllNotificationsRead();
  }

  Future<Result<List<AssignedPromotionModel>>> refreshAssignedPromotions({
    bool includeAll = false,
    String language = 'uz',
  }) {
    return _refreshAssignedPromotions(
      includeAll: includeAll,
      language: language,
    );
  }

  Future<void> handleAppResumed({String? locale}) {
    return _handleAppResumed(locale: locale);
  }

  Future<Result<CartPreviewModel>> previewCart(CartPreviewRequest request) {
    return _previewCart(request);
  }

  Future<Result<OrderingStatusModel>> getBranchOrderingStatus({
    required String branchId,
  }) {
    return _repository.getBranchOrderingStatus(branchId: branchId);
  }

  Future<Result<AppVersionPolicyModel>> getAppVersionPolicy({
    required String platform,
    String? currentVersion,
    String? language,
  }) {
    return _repository.getAppVersionPolicy(
      platform: platform,
      currentVersion: currentVersion,
      language: language,
    );
  }

  Future<Result<List<PaymentMethodModel>>> refreshPaymentMethods({
    required String language,
    String? branchId,
  }) {
    return _refreshPaymentMethods(language: language, branchId: branchId);
  }

  Future<Result<CustomerOrderModel>> createOrder(
    CreateOrderRequest request, {
    required String idempotencyKey,
  }) {
    return _createOrder(request, idempotencyKey: idempotencyKey);
  }

  Future<Result<LoyaltyWalletModel>> refreshLoyaltyWallet() {
    return _refreshLoyaltyWallet();
  }

  Future<Result<LoyaltyTransactionPageModel>> refreshLoyaltyTransactions({
    int limit = 50,
  }) {
    return _refreshLoyaltyTransactions(limit: limit);
  }

  Future<Result<LoyaltyTransactionPageModel>> loadMoreLoyaltyTransactions({
    int limit = 50,
  }) {
    return _loadMoreLoyaltyTransactions(limit: limit);
  }

  /// Drops the loaded transaction pages once the wallet screen closes; the
  /// list grows by a page per scroll and nothing else reads it.
  void releaseLoyaltyTransactions() {
    _loyaltyTransactionsRequestVersion++;
    _loyaltyTransactions = const <LoyaltyTransactionModel>[];
    _loyaltyTransactionsNextCursor = null;
    _loyaltyTransactionsLoading = false;
    _loyaltyTransactionsLoadingMore = false;
    _loyaltyTransactionsFailure = null;
  }

  Future<Result<CustomerOrderModel>> refreshOrder({required String id}) {
    return _refreshOrder(id: id);
  }

  Future<Result<CustomerOrderModel>> retryOrderPayment({required String id}) {
    return _retryOrderPayment(id: id);
  }

  Future<void> bootstrap({required String language, String? branchId}) {
    return _bootstrap(language: language, branchId: branchId);
  }

  Future<Result<CatalogModel>> refreshCatalog({
    required String language,
    String? branchId,
  }) {
    return _refreshCatalog(language: language, branchId: branchId);
  }
}
