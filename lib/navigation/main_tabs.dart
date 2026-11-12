import 'dart:async';
import 'dart:convert';

import 'package:enjoy_lavash_mobile/app/locale_controller.dart';
import 'package:enjoy_lavash_mobile/app/location_controller.dart';
import 'package:enjoy_lavash_mobile/core/error/failures.dart';
import 'package:enjoy_lavash_mobile/core/error/result.dart';
import 'package:enjoy_lavash_mobile/core/navigation/app_deep_link.dart';
import 'package:enjoy_lavash_mobile/core/services/app_share_service.dart';
import 'package:enjoy_lavash_mobile/core/services/external_url_launcher.dart';
import 'package:enjoy_lavash_mobile/core/services/mobile_push_notification_service.dart';
import 'package:enjoy_lavash_mobile/core/storage/cart_storage.dart';
import 'package:enjoy_lavash_mobile/features/address/delivery_address_text.dart';
import 'package:enjoy_lavash_mobile/features/cart/domain/cart_rules.dart';
import 'package:enjoy_lavash_mobile/features/app_version/presentation/app_version_gate.dart';
import 'package:enjoy_lavash_mobile/features/checkout/checkout_requests.dart';
import 'package:enjoy_lavash_mobile/features/checkout/payment_method_label.dart';
import 'package:enjoy_lavash_mobile/features/push_permission/presentation/push_permission_sheet.dart';
import 'package:enjoy_lavash_mobile/features/checkout/order_submission_keys.dart';
import 'package:enjoy_lavash_mobile/features/models/cart_line.dart';
import 'package:enjoy_lavash_mobile/features/models/menu_product.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/address_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/branch_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/cart_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/loyalty_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/order_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/ordering_status_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/presentation/mobile_backend_controller.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/screens/address_bottom_sheet.dart';
import 'package:enjoy_lavash_mobile/screens/assigned_promotions_screen.dart';
import 'package:enjoy_lavash_mobile/screens/authorization_screen.dart';
import 'package:enjoy_lavash_mobile/screens/branch_bottom_sheet.dart';
import 'package:enjoy_lavash_mobile/screens/cart_screen.dart';
import 'package:enjoy_lavash_mobile/screens/home_screen.dart';
import 'package:enjoy_lavash_mobile/screens/menu_screen.dart';
import 'package:enjoy_lavash_mobile/screens/notifications_screen.dart';
import 'package:enjoy_lavash_mobile/screens/order_context_sheet.dart';
import 'package:enjoy_lavash_mobile/screens/loyalty_wallet_screen.dart';
import 'package:enjoy_lavash_mobile/screens/profile.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'package:enjoy_lavash_mobile/theme/app_design_tokens.dart';
import 'package:enjoy_lavash_mobile/theme/app_motion.dart';
import 'package:enjoy_lavash_mobile/utils/log_redaction.dart';
import 'package:enjoy_lavash_mobile/utils/price_formatter.dart';
import 'package:enjoy_lavash_mobile/widgets/app_bottom_sheet_drag_handle.dart';
import 'package:enjoy_lavash_mobile/widgets/app_modal_bottom_sheet.dart';
import 'package:enjoy_lavash_mobile/widgets/app_snack_bar.dart';
import 'package:enjoy_lavash_mobile/widgets/redesign/cart_pill.dart';
import 'package:enjoy_lavash_mobile/widgets/typography.dart';
import 'package:enjoy_lavash_mobile/widgets/cart_animation/cart_arrival_feedback.dart';
import 'package:flutter/foundation.dart' show ValueListenable, kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:enjoy_lavash_mobile/widgets/utils/failure_message.dart';
import 'package:enjoy_lavash_mobile/widgets/utils/text_change_listener.dart';
import 'package:enjoy_lavash_mobile/widgets/curved_fade_transition.dart';
import 'package:enjoy_lavash_mobile/utils/format_cache.dart';
import 'package:enjoy_lavash_mobile/features/cart/presentation/cart_controller.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/banner_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/client_profile_model.dart';
import 'package:enjoy_lavash_mobile/features/models/menu_category.dart';

part 'main_tabs/checkout_models.dart';
part 'main_tabs/main_tabs_bottom_navigation.dart';
part 'main_tabs/main_tabs_drawer.dart';
part 'main_tabs/order_success_screen.dart';
part 'main_tabs/order_confirmation_sheet.dart';
part 'main_tabs/order_type_toggle.dart';
part 'main_tabs/payment_method_selector.dart';
part 'main_tabs/promo_code_field.dart';
part 'main_tabs/order_confirmation_items.dart';
part 'main_tabs/checkout_preview_summary.dart';
part 'main_tabs/home_tab.dart';
part 'main_tabs/keep_alive_tab_page.dart';
part 'main_tabs/menu_tab.dart';
part 'main_tabs/checkout_flow.dart';
part 'main_tabs/order_context.dart';
part 'main_tabs/shell_cart.dart';
part 'main_tabs/shell_navigation.dart';
part 'main_tabs/checkout_loyalty_control.dart';
part 'main_tabs/checkout_ordering_status.dart';
part 'main_tabs/checkout_preview_details_sheet.dart';
part 'main_tabs/checkout_sheet_actions.dart';
part 'main_tabs/checkout_sheet_parts.dart';
part 'main_tabs/checkout_sheet_preview.dart';

String _formatLoyaltyPoints(BuildContext context, int value) {
  return decimalFormat(
    Localizations.localeOf(context).toLanguageTag(),
  ).format(value);
}

bool _needsBirthDate(ClientProfile? client) =>
    client != null && client.birthDate == null;

/// The backend fields the shell itself needs: the catalog for the cart tab,
/// the bottom bar and cart reconciliation, sign-in state for the Promotions
/// tab, and what the startup birth-date prompt checks. Each tab selects its
/// own fields, so most backend updates do not rebuild the shell.
typedef _ShellData = ({
  MobileBackendStatus status,
  List<MenuProduct> menuProducts,
  bool showingCachedContent,
  bool isAuthenticated,
  bool needsBirthDate,
});

// Bottom tabs, in order.
const int _homeTabIndex = 0;
const int _menuTabIndex = 1;
const int _promotionsTabIndex = 2;
const int _cartPageIndex = 3;
const int _profileTabIndex = 4;
const int _tabCount = 5;

/// How long the "could not refresh" notice over the saved menu stays unless
/// the customer dismisses it: in effect until then, because nothing else on
/// screen says the menu may be out of date.
const Duration _refreshFailureNoticeDuration = Duration(hours: 12);

class MainTabs extends StatefulWidget {
  const MainTabs({super.key});

  @override
  State<MainTabs> createState() => _MainTabsState();
}

class _MainTabsState extends State<MainTabs> {
  /// The visible tab. Only the bottom bar, the back-button scope and each
  /// tab's active flag listen, so switching tabs rebuilds no tab content.
  final ValueNotifier<int> _currentTab = ValueNotifier<int>(0);
  int get _currentIndex => _currentTab.value;
  late final List<ValueListenable<bool>> _tabActive = <ValueListenable<bool>>[
    for (var index = 0; index < _tabCount; index++)
      _TabActive(_currentTab, index),
  ];

  /// Bumped when an add-to-cart flight lands; only the cart icon listens.
  final ValueNotifier<int> _cartArrival = ValueNotifier<int>(0);
  final _cartIconKey = GlobalKey(debugLabel: 'main-cart-icon');

  /// Menu category filter; -1 is the reference design's "All". Only the
  /// menu tab listens.
  final ValueNotifier<int> _selectedCategory = ValueNotifier<int>(-1);

  /// Owned here, listened to only by the menu tab, the cart tab and the
  /// bottom bar, so a quantity change does not rebuild the whole shell.
  final CartController _cart = CartController();
  MobileOrderType _orderType = MobileOrderType.delivery;
  BranchModel? _selectedBranch;
  String? _deliveryBranchId;
  String _promoCode = '';

  /// True while an order is being created; only the cart tab shows it.
  final ValueNotifier<bool> _isCheckingOut = ValueNotifier<bool>(false);
  late final Listenable _cartTabChanges = Listenable.merge(<Listenable>[
    _cart,
    _isCheckingOut,
  ]);
  late final Listenable _bottomBarChanges = Listenable.merge(<Listenable>[
    _cart,
    _cartArrival,
    _currentTab,
  ]);
  final OrderSubmissionKeys _orderSubmissionKeys = OrderSubmissionKeys();
  StreamSubscription<SessionEndReason>? _sessionEndedSubscription;
  StreamSubscription<void>? _pushReminderSubscription;
  bool _pushNavigationScheduled = false;
  bool _startupBirthDatePromptChecked = false;
  bool _cartReconciliationScheduled = false;
  List<MenuProduct>? _lastReconciledProducts;

  /// The saved catalog shown before the network answered: never used to
  /// remove cart lines, only to name the ones the network catalog removes.
  List<MenuProduct>? _cachedCatalogProducts;

  /// Whether the "could not refresh, Retry" notice was shown for the current
  /// failure over the saved menu, and the notice while it is on screen.
  bool _refreshFailureAnnounced = false;
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>?
  _refreshFailureNotice;

  /// A sign-in-gated action (bell, loyalty, promotions, orders) is waiting
  /// for the session; further taps are dropped until it is done.
  bool _sessionGateBusy = false;

  /// A notification reminder is due but could not be shown yet (something
  /// was open on top of the tabs); and whether its sheet is open now.
  bool _pushReminderPending = false;
  bool _pushReminderOpen = false;
  final PageController _tabPageController = PageController();

  /// Built once so cart/category updates don't rebuild the profile subtree;
  /// it listens to its providers internally.
  late final Widget _profileTab = Profile(
    onRefresh: _refreshProfileData,
    onPromoSelected: _applyAssignedPromoCode,
    onNotificationsTap: () => unawaited(_openNotifications()),
  );
  late final Widget _promotionsTab = AssignedPromotionsScreen(
    embedded: true,
    onPromoSelected: _applyAssignedPromoCode,
  );

  late final MobileBackendController _backend;

  /// `setState` for the shell's part-file extensions, which may not call the
  /// protected member directly.
  void _updateState(VoidCallback change) => setState(change);

  @override
  void initState() {
    super.initState();
    _backend = context.read<MobileBackendController>();
    unawaited(_restoreSavedCart());
    _sessionEndedSubscription = _backend.sessionEnded.listen(
      _handleSessionEnded,
    );
    _pushReminderSubscription = _backend.pushPermissionReminderDue.listen(
      (_) => _queuePushReminder(),
    );
    // Push taps are consumed from a listener, not from build: the shell no
    // longer rebuilds on every backend notification.
    _backend.addListener(_takePendingPushMessage);
    _backend.addListener(_announceRefreshFailureOverSavedContent);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _takePendingPushMessage();
      // The start-up request may have failed before this screen existed
      // (an offline launch fails within milliseconds).
      _announceRefreshFailureOverSavedContent();
    });
  }

  @override
  void dispose() {
    _backend.removeListener(_takePendingPushMessage);
    _backend.removeListener(_announceRefreshFailureOverSavedContent);
    unawaited(_sessionEndedSubscription?.cancel());
    unawaited(_pushReminderSubscription?.cancel());
    _tabPageController.dispose();
    _cart.dispose();
    _cartArrival.dispose();
    _currentTab.dispose();
    _selectedCategory.dispose();
    _isCheckingOut.dispose();
    super.dispose();
  }

  void _takePendingPushMessage() {
    if (!mounted ||
        _pushNavigationScheduled ||
        _backend.pendingPushMessage == null) {
      return;
    }
    final message = _backend.takePendingPushMessage();
    if (message == null) return;
    _pushNavigationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _handlePushNavigation(message);
      } finally {
        _pushNavigationScheduled = false;
        // A message that arrived while this one was handled is next.
        _takePendingPushMessage();
        // The startup birth-date prompt waits for push navigation; the shell
        // no longer rebuilds on every backend update to retry it later.
        if (mounted) {
          _maybeShowStartupBirthDatePrompt(
            _backend.status,
            needsBirthDate: _needsBirthDate(_backend.client),
          );
        }
      }
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  /// While the start-up request has failed with the saved menu on screen,
  /// the menu stays and a notice with Retry says so. It follows the state,
  /// not a moment: it shows for a failure that happened before this screen
  /// existed, stays until the customer dismisses it or a retry starts, and
  /// shows again when that retry fails. Without saved content the
  /// full-screen error state shows instead, as before.
  void _announceRefreshFailureOverSavedContent() {
    if (!mounted) return;
    final failed =
        _backend.status == MobileBackendStatus.error &&
        _backend.isShowingCachedContent;
    if (failed == _refreshFailureAnnounced) return;
    _refreshFailureAnnounced = failed;
    final failure = _backend.failure;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      if (!failed) {
        // A retry is running or it worked: the notice is out of date.
        if (_refreshFailureNotice != null) messenger.clearSnackBars();
        return;
      }
      final t = L.of(context);
      messenger.hideCurrentSnackBar();
      final notice = messenger.showSnackBar(
        appSnackBar(
          failure == null
              ? t.errorGenericBody
              : failureMessage(t, failure, fallback: t.errorGenericBody),
          duration: _refreshFailureNoticeDuration,
          actionLabel: t.retry,
          onAction: () {
            if (mounted) unawaited(_refreshMenuData());
          },
        ),
      );
      _refreshFailureNotice = notice;
      unawaited(
        notice.closed.then((_) {
          if (identical(_refreshFailureNotice, notice)) {
            _refreshFailureNotice = null;
          }
        }),
      );
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = L.of(context);
    // Each tab selects the fields it renders; the shell rebuilds only for
    // what it needs itself (see [_ShellData]). Tab switches, category taps
    // and cart taps go through notifiers and never rebuild it.
    final shell = context.select<MobileBackendController, _ShellData>(
      (controller) => (
        status: controller.status,
        menuProducts: controller.menuProducts,
        showingCachedContent: controller.isShowingCachedContent,
        isAuthenticated: controller.isAuthenticated,
        needsBirthDate: _needsBirthDate(controller.client),
      ),
    );
    _maybeShowStartupBirthDatePrompt(
      shell.status,
      needsBirthDate: shell.needsBirthDate,
    );
    final products = shell.menuProducts;
    if (shell.showingCachedContent) {
      _cachedCatalogProducts = products;
    } else {
      _scheduleCartReconciliation(products);
    }

    final scaffold = Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: _MainTabsDrawer(
        isDark: isDark,
        t: t,
        onTabSelected: _selectTab,
        onNotificationsTap: () => unawaited(_openNotifications()),
        onPromotionsTap: () => unawaited(_selectPromotionsTab()),
        onOrdersTap: () => unawaited(_openOrders()),
        onShareApp: () => unawaited(_shareApp(t)),
      ),
      body: SafeArea(
        child: PageView(
          key: const ValueKey<String>('main-tabs-page-view'),
          controller: _tabPageController,
          onPageChanged: _handleTabPageChanged,
          physics: const PageScrollPhysics(),
          children: <Widget>[
            _KeepAliveTabPage(
              active: _tabActive[_homeTabIndex],
              child: _HomeTab(
                orderType: _orderType,
                selectedBranch: _selectedBranch,
                onBannerLinkTap: (uri) => unawaited(_openBannerLink(uri)),
                onOrderContextTap: () => unawaited(_openOrderContextPicker()),
                onNotificationsTap: () => unawaited(_openNotifications()),
                onLoyaltyTap: () => unawaited(_openLoyaltyWallet()),
                onMenuTap: () => _selectTab(_menuTabIndex),
                onCategoryTap: (index) {
                  _setSelectedCategory(index);
                  _selectTab(_menuTabIndex);
                },
                onRepeatOrder: _repeatOrder,
                onRefresh: _refreshMenuData,
              ),
            ),
            _KeepAliveTabPage(
              active: _tabActive[_menuTabIndex],
              child: _MenuTab(
                isDark: isDark,
                selectedCategory: _selectedCategory,
                cart: _cart,
                active: _tabActive[_menuTabIndex],
                orderType: _orderType,
                selectedBranch: _selectedBranch,
                cartTargetKey: _cartIconKey,
                onCategorySelected: _setSelectedCategory,
                onAddToCart: _addToCart,
                onAddConfiguredToCart: _addConfiguredToCart,
                onDecreaseFromCart: (product) => _updateCart(product, -1),
                onCartTap: () => _selectTab(_cartPageIndex),
                onOrderContextTap: () => unawaited(_openOrderContextPicker()),
                onCartArrival: () => _cartArrival.value++,
                onOrderTypeChanged: _setOrderType,
                onBranchSelected: _setPickupBranch,
                onRefresh: _refreshMenuData,
                onRetryMenu: () =>
                    context.read<MobileBackendController>().bootstrap(
                      language: context
                          .read<LocaleController>()
                          .locale
                          .languageCode,
                      branchId: _selectedBranch?.id,
                    ),
              ),
            ),
            _KeepAliveTabPage(
              active: _tabActive[_promotionsTabIndex],
              child: shell.isAuthenticated
                  ? _promotionsTab
                  : const SizedBox.shrink(),
            ),
            _KeepAliveTabPage(
              active: _tabActive[_cartPageIndex],
              child: ListenableBuilder(
                listenable: _cartTabChanges,
                builder: (context, _) {
                  final cart = _cart.snapshot(products);
                  return CartScreen(
                    isDark: isDark,
                    items: cart.lines,
                    totalAmount: cart.totalAmount,
                    isCheckingOut: _isCheckingOut.value,
                    onDecrease: (line) => _updateCartLine(line, -1),
                    onIncrease: (line) => _updateCartLine(line, 1),
                    onBrowseMenu: () => _selectTab(_menuTabIndex),
                    onCheckout: () => unawaited(_handleCheckout(cart.lines)),
                  );
                },
              ),
            ),
            _KeepAliveTabPage(
              active: _tabActive[_profileTabIndex],
              child: _profileTab,
            ),
          ],
        ),
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: _bottomBarChanges,
        builder: (context, _) {
          final cart = _cart.snapshot(products);
          final currentIndex = _currentIndex;
          return _MainTabsBottomNavigation(
            cartIconKey: _cartIconKey,
            cartArrival: _cartArrival.value,
            isDark: isDark,
            currentIndex: currentIndex,
            totalItems: cart.totalItems,
            totalAmount: cart.totalAmount,
            showCartPill:
                cart.totalItems > 0 &&
                (currentIndex == _homeTabIndex ||
                    currentIndex == _menuTabIndex),
            t: t,
            onCartTap: () => _selectTab(_cartPageIndex),
            onDestinationSelected: (index) {
              if (index == _promotionsTabIndex) {
                unawaited(_selectPromotionsTab());
              } else {
                _selectTab(index);
              }
            },
          );
        },
      ),
    );

    // Only the back-button scope follows the tab; the Scaffold is reused.
    return ValueListenableBuilder<int>(
      valueListenable: _currentTab,
      builder: (context, currentIndex, child) => PopScope(
        canPop: currentIndex == _homeTabIndex,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && _currentIndex != _homeTabIndex) {
            _selectTab(
              _currentIndex == _cartPageIndex ? _menuTabIndex : _homeTabIndex,
            );
          }
        },
        child: child!,
      ),
      child: scaffold,
    );
  }
}
