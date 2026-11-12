part of 'package:enjoy_lavash_mobile/navigation/main_tabs.dart';

/// How long a due notification reminder waits before it opens, so the
/// customer sees the app (or what closed just before) first.
const Duration _pushReminderDelay = Duration(seconds: 2);

/// Tab switching, pushed screens, deep links and push taps, sign-in gating
/// and the startup prompts.
extension _ShellNavigation on _MainTabsState {
  /// After an explicit sign-out or account deletion the next person to use
  /// the device must not inherit the cart, promo code or typed address. An
  /// expired session keeps them: it is almost always the same customer.
  void _handleSessionEnded(SessionEndReason reason) {
    if (!mounted || reason == SessionEndReason.expired) return;
    _cart.clear();
    _promoCode = '';
    context.read<LocationController>().clearPersonalData();
  }

  Future<void> _shareApp(L t) async {
    await AppShareService.share(t);
  }

  /// Whether nothing (screen, sheet or dialog) is open on top of the tabs.
  /// Reads the navigator without subscribing the shell to route changes.
  bool get _tabsAreOnTop => !Navigator.of(context).canPop();

  /// Waits until the app knows whether the customer is signed in.
  ///
  /// While the start-up request runs with the saved menu already on screen,
  /// "not signed in" may only mean "not known yet". When that request has
  /// failed (an offline launch), it is tried once more: the customer may be
  /// signed in and must not be sent to the sign-in screen. False means the
  /// session is still unknown; the Retry notice says why.
  Future<bool> _sessionKnown() async {
    final backend = _backend;
    await backend.whenSessionSettled();
    if (!mounted) return false;
    if (!backend.isSessionUnknown) return true;
    await _refreshMenuData();
    return mounted && !backend.isSessionUnknown;
  }

  Future<bool> _ensureAuthenticated() async {
    final backend = _backend;
    if (backend.isAuthenticated) return true;
    // Nothing covers the button while the session is awaited, so a second
    // tap would queue a second screen.
    if (_sessionGateBusy) return false;
    _sessionGateBusy = true;
    try {
      final wasOnTabs = _tabsAreOnTop;
      final tab = _currentIndex;
      if (!await _sessionKnown() || !mounted) return false;
      // The customer moved on while the app was finding out: opening a
      // screen over what they are doing now would come out of nowhere.
      if (wasOnTabs && (!_tabsAreOnTop || _currentIndex != tab)) return false;
      if (backend.isAuthenticated) return true;
      await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(builder: (_) => const AuthorizationScreen()),
      );
      return mounted && backend.isAuthenticated;
    } finally {
      _sessionGateBusy = false;
    }
  }

  Future<void> _openBannerLink(Uri uri) async {
    if (ExternalUrlLauncher.allowedUri(uri.toString()) != null) {
      await ExternalUrlLauncher.open(uri.toString());
      return;
    }
    switch (AppDeepLink.fromUri(uri)) {
      case AppDeepLink.home:
        _selectTab(_homeTabIndex);
      case AppDeepLink.menu:
        _selectTab(_menuTabIndex);
      case AppDeepLink.cart:
        _selectTab(_cartPageIndex);
      case AppDeepLink.profile:
        _selectTab(_profileTabIndex);
      case AppDeepLink.promotions:
        await _selectPromotionsTab();
      case AppDeepLink.orders:
        await _openOrders();
      case AppDeepLink.notifications:
        await _openNotifications();
      case AppDeepLink.loyalty:
        await _openLoyaltyWallet();
      case null:
        break;
    }
  }

  Future<void> _openNotifications() async {
    if (!await _ensureAuthenticated() || !mounted) return;
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const NotificationsScreen()),
    );
    if (code != null && mounted) {
      _applyAssignedPromoCode(code);
    }
  }

  Future<void> _selectPromotionsTab() async {
    if (!await _ensureAuthenticated() || !mounted) return;
    _selectTab(_promotionsTabIndex);
  }

  Future<void> _openLoyaltyWallet() async {
    if (!await _ensureAuthenticated() || !mounted) return;
    // The wallet screen refreshes itself on open; waiting here only delayed
    // the navigation by a round trip.
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const LoyaltyWalletScreen()),
    );
  }

  Future<void> _openAssignedPromotions({String? highlightedCode}) async {
    if (!await _ensureAuthenticated() || !mounted) return;
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => AssignedPromotionsScreen(
          initialShowAll: highlightedCode?.trim().isNotEmpty == true,
          highlightedCode: highlightedCode,
        ),
      ),
    );
    if (code != null && mounted) {
      _applyAssignedPromoCode(code);
    }
  }

  Future<void> _openOrders() async {
    if (!await _ensureAuthenticated() || !mounted) return;
    await showAllOrdersScreen(context);
  }

  void _maybeShowStartupBirthDatePrompt(
    MobileBackendStatus status, {
    required bool needsBirthDate,
  }) {
    if (_startupBirthDatePromptChecked ||
        status != MobileBackendStatus.loaded ||
        _pushNavigationScheduled) {
      return;
    }

    _startupBirthDatePromptChecked = true;
    if (!needsBirthDate) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // A notification reminder that was due while this prompt was open
      // follows it instead of being lost for the whole launch.
      unawaited(
        showBirthDatePromptSheet(context).whenComplete(_retryPushReminder),
      );
    });
  }

  /// A notification reminder is due
  /// ([MobileBackendController.pushPermissionReminderDue]: at app entry and
  /// whenever the app comes back to the foreground).
  void _queuePushReminder() {
    _pushReminderPending = true;
    _retryPushReminder();
  }

  void _retryPushReminder() {
    if (!_pushReminderPending) return;
    unawaited(
      Future<void>.delayed(_pushReminderDelay, _showPendingPushReminder),
    );
  }

  /// Opens the pending reminder when the customer is on the tabs with
  /// nothing on top. Otherwise it stays pending: it is tried again when the
  /// start-up birth-date prompt closes and each time the app comes back,
  /// and the controller keeps it due until it has been shown.
  Future<void> _showPendingPushReminder() async {
    if (!mounted || !_pushReminderPending || _pushReminderOpen) return;
    if (!_tabsAreOnTop ||
        _isCheckingOut.value ||
        AppVersionGate.isPromptVisible(context)) {
      return;
    }
    _pushReminderPending = false;
    _pushReminderOpen = true;
    try {
      await showPushPermissionReminder(
        context,
        locale: context.read<LocaleController>().locale.languageCode,
      );
    } finally {
      _pushReminderOpen = false;
    }
  }

  void _applyAssignedPromoCode(String code) {
    final normalized = code.trim();
    if (normalized.isEmpty || !mounted) return;
    final products = context.read<MobileBackendController>().menuProducts;
    final hasCartItems = !_cart.snapshot(products).isEmpty;
    // Read when checkout opens; nothing on screen shows it.
    _promoCode = normalized;
    _selectTab(hasCartItems ? _cartPageIndex : _menuTabIndex);
    ScaffoldMessenger.of(context).showSnackBar(
      appSnackBar(L.of(context).promoReadyForCheckout(normalized)),
    );
  }

  Future<void> _handlePushNavigation(PushNotificationMessage message) async {
    if (!message.openedByUser || !mounted) return;
    if (!await _ensureAuthenticated() || !mounted) return;
    final notificationId = message.notificationId?.trim();
    if (notificationId?.isNotEmpty == true) {
      await context.read<MobileBackendController>().markNotificationRead(
        notificationId: notificationId!,
      );
      if (!mounted) return;
    }

    if (message.opensPromotions) {
      await _openAssignedPromotions(highlightedCode: message.promotionCode);
      return;
    }
    if (message.opensLoyalty) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => const LoyaltyWalletScreen()),
      );
      return;
    }
    await _openNotifications();
  }

  void _setSelectedCategory(int index) {
    _selectedCategory.value = index;
  }

  void _selectTab(int index) {
    assert(index >= 0 && index < _tabCount);
    if (_currentIndex == index) return;
    final previousIndex = _currentIndex;
    _currentTab.value = index;
    _animateToSelectedTab(
      index,
      jump:
          (previousIndex - index).abs() > 1 ||
          previousIndex == _cartPageIndex ||
          index == _cartPageIndex,
    );
  }

  void _handleTabPageChanged(int index) {
    if (_currentIndex == index) return;
    if (index == _promotionsTabIndex &&
        !context.read<MobileBackendController>().isAuthenticated) {
      final previousIndex = _currentIndex;
      // A swipe must use the same sign-in flow as tapping Promotions. Restore
      // the previous page so dismissing sign-in cannot leave an empty tab.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _currentIndex != previousIndex) return;
        _animateToSelectedTab(previousIndex, jump: true);
        unawaited(_selectPromotionsTab());
      });
      return;
    }
    _currentTab.value = index;
  }

  void _animateToSelectedTab(int index, {bool jump = false}) {
    if (!_tabPageController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _currentIndex == index) {
          _animateToSelectedTab(index, jump: jump);
        }
      });
      return;
    }

    if (jump) {
      _tabPageController.jumpToPage(index);
      return;
    }

    final duration = AppMotion.duration(context, AppMotion.spatial);
    if (duration == Duration.zero) {
      _tabPageController.jumpToPage(index);
      return;
    }
    unawaited(
      _tabPageController.animateToPage(
        index,
        duration: duration,
        curve: AppMotion.enter,
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(appSnackBar(message));
  }
}
