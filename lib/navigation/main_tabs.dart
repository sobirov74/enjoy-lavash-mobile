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
import 'package:flutter/foundation.dart' show kDebugMode;
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
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/promotion_model.dart';
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

String _formatLoyaltyPoints(BuildContext context, int value) {
  return decimalFormat(
    Localizations.localeOf(context).toLanguageTag(),
  ).format(value);
}

/// The backend fields the shell renders. It rebuilds only when one of them
/// changes; lists compare by identity because the controller replaces them.
typedef _ShellData = ({
  MobileBackendStatus status,
  Failure? failure,
  ClientProfile? client,
  List<String> menuCategories,
  List<MenuCategory> menuCategoryItems,
  List<MenuProduct> menuProducts,
  List<PromotionModel> promotions,
  List<BannerModel> banners,
  LoyaltyWalletModel? loyaltyWallet,
  int notificationUnreadCount,
  List<CustomerOrderModel> orders,
  bool isAuthenticated,
});

class MainTabs extends StatefulWidget {
  const MainTabs({super.key});

  @override
  State<MainTabs> createState() => _MainTabsState();
}

class _MainTabsState extends State<MainTabs> {
  static const int _homeTabIndex = 0;
  static const int _menuTabIndex = 1;
  static const int _promotionsTabIndex = 2;
  static const int _cartPageIndex = 3;
  static const int _profileTabIndex = 4;
  static const int _tabCount = 5;

  int _currentIndex = 0;

  /// Bumped when an add-to-cart flight lands; only the cart icon listens.
  final ValueNotifier<int> _cartArrival = ValueNotifier<int>(0);
  final _cartIconKey = GlobalKey(debugLabel: 'main-cart-icon');
  // -1 is the reference design's "All" filter.
  int _selectedCategoryIndex = -1;

  /// Owned here, listened to only by the menu tab, the cart tab and the
  /// bottom bar, so a quantity change does not rebuild the whole shell.
  final CartController _cart = CartController();
  MobileOrderType _orderType = MobileOrderType.delivery;
  BranchModel? _selectedBranch;
  String? _deliveryBranchId;
  String _promoCode = '';
  bool _isCheckingOut = false;
  final OrderSubmissionKeys _orderSubmissionKeys = OrderSubmissionKeys();
  StreamSubscription<SessionEndReason>? _sessionEndedSubscription;
  bool _pushNavigationScheduled = false;
  bool _startupBirthDatePromptChecked = false;
  bool _cartReconciliationScheduled = false;
  List<MenuProduct>? _lastReconciledProducts;
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

  @override
  void initState() {
    super.initState();
    _backend = context.read<MobileBackendController>();
    unawaited(_restoreSavedCart());
    _sessionEndedSubscription = _backend.sessionEnded.listen(
      _handleSessionEnded,
    );
    // Push taps are consumed from a listener, not from build: the shell no
    // longer rebuilds on every backend notification.
    _backend.addListener(_takePendingPushMessage);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _takePendingPushMessage(),
    );
  }

  @override
  void dispose() {
    _backend.removeListener(_takePendingPushMessage);
    unawaited(_sessionEndedSubscription?.cancel());
    _tabPageController.dispose();
    _cart.dispose();
    _cartArrival.dispose();
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
      }
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  /// After an explicit sign-out or account deletion the next person to use
  /// the device must not inherit the cart, promo code or typed address. An
  /// expired session keeps them: it is almost always the same customer.
  void _handleSessionEnded(SessionEndReason reason) {
    if (!mounted || reason == SessionEndReason.expired) return;
    _cart.clear();
    setState(() => _promoCode = '');
    context.read<LocationController>().clearPersonalData();
  }

  Future<void> _restoreSavedCart() async {
    final savedCart = await CartStorage.readSelections();
    if (!mounted || _cart.editedSinceLaunch || savedCart.isEmpty) return;
    final products = context.read<MobileBackendController>().menuProducts;
    final restored = products.isEmpty
        ? <String, CartSelection>{for (final line in savedCart) line.key: line}
        : _reconciledCart(savedCart, products);
    final changed = products.isNotEmpty && restored.length != savedCart.length;
    // Only re-save when reconciliation dropped something.
    _cart.replaceAll(restored.values, persist: changed);
    if (changed) {
      _notifyUnavailableLines(
        _unavailableSelections(savedCart, products),
        products,
      );
    }
  }

  Map<String, CartSelection> _reconciledCart(
    Iterable<CartSelection> selections,
    List<MenuProduct> products,
  ) {
    final productsById = <String, MenuProduct>{
      for (final product in products) product.id: product,
    };
    final reconciled = <String, CartSelection>{};
    for (final selection in selections) {
      final product = productsById[selection.productId];
      if (product == null) continue;
      final current = reconcileCartSelection(selection, product);
      if (current == null || current.quantity <= 0) continue;
      final existing = reconciled[current.key];
      reconciled[current.key] = current.copyWith(
        quantity: current.quantity + (existing?.quantity ?? 0),
      );
    }
    return reconciled;
  }

  void _scheduleCartReconciliation(List<MenuProduct> products) {
    if (products.isEmpty ||
        identical(_lastReconciledProducts, products) ||
        _cartReconciliationScheduled) {
      return;
    }
    _cartReconciliationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cartReconciliationScheduled = false;
      if (!mounted) return;
      final previousProducts = _lastReconciledProducts;
      _lastReconciledProducts = products;
      final current = _cart.selections.toList(growable: false);
      final next = _reconciledCart(current, products);
      final currentJson = jsonEncode(
        current
            .map(
              (selection) => <String, Object?>{
                'key': selection.key,
                ...selection.toJson(),
              },
            )
            .toList(growable: false),
      );
      final nextJson = jsonEncode(
        next.entries
            .map(
              (entry) => <String, Object?>{
                'key': entry.key,
                ...entry.value.toJson(),
              },
            )
            .toList(growable: false),
      );
      if (currentJson == nextJson) return;
      final removed = _unavailableSelections(current, products);
      _cart.replaceAll(next.values);
      _notifyUnavailableLines(removed, [...products, ...?previousProducts]);
    });
  }

  /// Saved lines the [products] catalog can no longer fulfil: the product is
  /// gone or its saved configuration is no longer valid.
  List<CartSelection> _unavailableSelections(
    Iterable<CartSelection> selections,
    List<MenuProduct> products,
  ) {
    final productsById = <String, MenuProduct>{
      for (final product in products) product.id: product,
    };
    return selections
        .where((selection) {
          final product = productsById[selection.productId];
          return product == null ||
              reconcileCartSelection(selection, product) == null;
        })
        .toList(growable: false);
  }

  /// Tells the customer which lines were removed, by name when every removed
  /// product is known from [knownProducts].
  void _notifyUnavailableLines(
    List<CartSelection> removed,
    List<MenuProduct> knownProducts,
  ) {
    if (removed.isEmpty || !mounted) return;
    final titles = <String, String>{
      for (final product in knownProducts) product.id: product.title,
    };
    final names = <String>{
      for (final selection in removed) ?titles[selection.productId],
    };
    final t = L.of(context);
    final allNamed = removed.every(
      (selection) => titles.containsKey(selection.productId),
    );
    _showSnack(
      allNamed && names.isNotEmpty
          ? t.cartItemsUnavailable(names.join(', '))
          : t.cartSomeItemsUnavailable,
    );
  }

  Future<void> _shareApp(L t) async {
    await AppShareService.share(t);
  }

  Future<bool> _ensureAuthenticated() async {
    if (context.read<MobileBackendController>().isAuthenticated) return true;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const AuthorizationScreen()),
    );
    return mounted && context.read<MobileBackendController>().isAuthenticated;
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
    MobileBackendStatus status,
    ClientProfile? client,
  ) {
    if (_startupBirthDatePromptChecked ||
        status != MobileBackendStatus.loaded ||
        _pushNavigationScheduled) {
      return;
    }

    _startupBirthDatePromptChecked = true;
    if (client == null || client.birthDate != null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(showBirthDatePromptSheet(context));
    });
  }

  void _applyAssignedPromoCode(String code) {
    final normalized = code.trim();
    if (normalized.isEmpty || !mounted) return;
    final products = context.read<MobileBackendController>().menuProducts;
    final hasCartItems = !_cart.snapshot(products).isEmpty;
    setState(() => _promoCode = normalized);
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

  void _addToCart(MenuProduct product) {
    _addCartSelection(CartSelection(productId: product.id, quantity: 1));
  }

  void _addConfiguredToCart(CartSelection selection) {
    _addCartSelection(selection);
  }

  /// Adds [selection], capped at [maxCartLineQuantity]. Throws
  /// [CartLineLimitReached] when nothing could be added, so the menu's
  /// add-to-cart flow reports the limit instead of a false "added".
  void _addCartSelection(CartSelection selection) {
    final existingQuantity = _cart.lineFor(selection.key)?.quantity ?? 0;
    final quantity = _cappedQuantity(existingQuantity + selection.quantity);
    if (quantity == existingQuantity) throw const CartLineLimitReached();
    _cart.put(selection.copyWith(quantity: quantity));
  }

  int _cappedQuantity(int quantity) =>
      quantity > maxCartLineQuantity ? maxCartLineQuantity : quantity;

  void _showQuantityLimit() {
    _showSnack(L.of(context).cartQuantityLimitReached(maxCartLineQuantity));
  }

  void _updateCart(MenuProduct product, int delta) {
    final matching = _cart.selections
        .where((selection) => selection.productId == product.id)
        .toList(growable: false);
    if (delta > 0) {
      if (matching.isEmpty) {
        _addToCart(product);
      } else {
        final line = matching.last;
        _setCartSelectionQuantity(line, line.quantity + delta);
      }
      return;
    }
    if (matching.isEmpty) return;
    final line = matching.last;
    _setCartSelectionQuantity(line, line.quantity + delta, product: product);
  }

  void _updateCartLine(CartLine line, int delta) {
    final selection = _cart.lineFor(line.key);
    if (selection == null) return;
    _setCartSelectionQuantity(
      selection,
      selection.quantity + delta,
      product: line.product,
    );
  }

  void _setCartSelectionQuantity(
    CartSelection selection,
    int requestedQuantity, {
    MenuProduct? product,
  }) {
    final previousQuantity = selection.quantity;
    final nextQuantity = _cappedQuantity(requestedQuantity);
    if (requestedQuantity > nextQuantity) _showQuantityLimit();
    if (nextQuantity == previousQuantity) return;
    final removedLine = nextQuantity <= 0 && previousQuantity > 0;
    _cart.put(selection.copyWith(quantity: nextQuantity));

    if (removedLine && product != null) {
      final messenger = ScaffoldMessenger.of(context);
      showAutoClosingAppSnackBar(
        messenger,
        L.of(context).itemRemovedFromCart(product.title),
        actionLabel: L.of(context).undo,
        onAction: () {
          if (!mounted) return;
          _cart.put(selection.copyWith(quantity: previousQuantity));
        },
      );
    }
  }

  void _setSelectedCategory(int index) {
    if (_selectedCategoryIndex == index) {
      return;
    }
    setState(() => _selectedCategoryIndex = index);
  }

  void _selectTab(int index) {
    assert(index >= 0 && index < _tabCount);
    if (_currentIndex == index) return;
    final previousIndex = _currentIndex;
    setState(() => _currentIndex = index);
    _animateToSelectedTab(
      index,
      jump:
          (previousIndex - index).abs() > 1 ||
          previousIndex == _cartPageIndex ||
          index == _cartPageIndex,
    );
  }

  Future<void> _openOrderContextPicker() {
    return showOrderContextSheet(
      context: context,
      currentType: _orderType,
      selectedBranch: _selectedBranch,
      branches: context.read<MobileBackendController>().branches,
      deliveryAddress: _currentDeliveryAddressText(),
      onTypeChanged: _setOrderType,
      onBranchSelected: _setPickupBranch,
    );
  }

  void _repeatOrder(CustomerOrderModel order) {
    final products = context.read<MobileBackendController>().menuProducts;
    final productsById = <String, MenuProduct>{
      for (final product in products) product.id: product,
      for (final product in products)
        if (product.iikoId?.trim().isNotEmpty == true)
          product.iikoId!.trim(): product,
    };

    final t = L.of(context);
    final language = Localizations.localeOf(context).languageCode;
    var added = 0;
    final skipped = <String>[];
    final merged = <String, CartSelection>{
      for (final selection in _cart.selections) selection.key: selection,
    };
    for (final item in order.items) {
      if (item.quantity <= 0) continue;
      final product = productsById[item.productId];
      // Order history does not keep modifier choices, so the product's
      // standard configuration is used. A product that needs a choice (or
      // is gone from the menu) is named to the customer instead of being
      // dropped silently by cart reconciliation.
      final selection = product == null
          ? null
          : standardCartSelection(product, quantity: item.quantity);
      if (selection == null) {
        skipped.add(
          product?.title ?? item.localizedName(language) ?? item.productId,
        );
        continue;
      }
      final existing = merged[selection.key];
      merged[selection.key] = selection.copyWith(
        quantity: _cappedQuantity(
          (existing?.quantity ?? 0) + selection.quantity,
        ),
      );
      added += item.quantity;
    }

    if (skipped.isNotEmpty) {
      _showSnack(t.repeatOrderSkipped(skipped.join(', ')));
    }
    if (added == 0) {
      if (skipped.isEmpty) _showSnack(t.noProductsFound);
      _selectTab(_menuTabIndex);
      return;
    }
    _cart.replaceAll(merged.values, edited: true);
    _selectTab(_cartPageIndex);
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
    setState(() => _currentIndex = index);
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

  void _setOrderType(MobileOrderType type) {
    final shouldReloadCatalog =
        type == MobileOrderType.delivery && _selectedBranch != null;

    setState(() {
      _orderType = type;
      if (type == MobileOrderType.delivery) {
        _selectedBranch = null;
      } else {
        _deliveryBranchId = null;
      }
    });

    if (shouldReloadCatalog) {
      unawaited(_refreshCatalogForBranch(null));
    }
    if (type == MobileOrderType.delivery) {
      unawaited(_refreshPaymentMethodsForBranch(null));
    }
  }

  Future<void> _setPickupBranch(BranchModel? branch) async {
    setState(() {
      _selectedBranch = branch;
      if (branch != null) {
        _orderType = MobileOrderType.pickup;
      }
    });

    await Future.wait<void>([
      _refreshCatalogForBranch(branch?.id),
      _refreshPaymentMethodsForBranch(branch?.id),
    ]);
  }

  Future<void> _refreshCatalogForBranch(String? branchId) async {
    final language = context.read<LocaleController>().locale.languageCode;
    await context.read<MobileBackendController>().refreshCatalog(
      language: language,
      branchId: branchId,
    );
  }

  Future<void> _refreshPaymentMethodsForBranch(String? branchId) async {
    final language = context.read<LocaleController>().locale.languageCode;
    await context.read<MobileBackendController>().refreshPaymentMethods(
      language: language,
      branchId: branchId,
    );
  }

  Future<void> _refreshMenuData() {
    return context.read<MobileBackendController>().bootstrap(
      language: context.read<LocaleController>().locale.languageCode,
      branchId: _selectedBranch?.id,
    );
  }

  Future<void> _refreshProfileData() {
    return context.read<MobileBackendController>().refreshCustomerData();
  }

  List<CartItemInput> _buildOrderItems(List<CartLine> cartLines) {
    return cartLines
        .map(
          (line) => CartItemInput(
            productId: _orderProductId(line.product),
            quantity: line.quantity,
            modifiers: line.modifiers
                .map(
                  (modifier) => CartModifierInput(
                    modifierId: modifier.modifierId,
                    quantity: modifier.quantity,
                  ),
                )
                .toList(growable: false),
          ),
        )
        .toList(growable: false);
  }

  String _orderProductId(MenuProduct product) {
    final iikoId = product.iikoId?.trim();
    return iikoId == null || iikoId.isEmpty ? product.id : iikoId;
  }

  CreateOrderAddressInput? _inlineAddressFromLocation(
    LocationController location,
  ) {
    final latitude = location.latitude;
    final longitude = location.longitude;
    if (latitude == null || longitude == null) return null;

    final addressName = _trimmedOrNull(location.addressName);
    final fullAddress = _trimmedOrNull(location.fullAddress) ?? addressName;

    return CreateOrderAddressInput(
      latitude: latitude,
      longitude: longitude,
      label: addressName,
      text: fullAddress,
      street: addressName,
      houseNumber: _trimmedOrNull(location.houseNumber),
      apartmentNumber: _trimmedOrNull(location.apartment),
      entrance: _trimmedOrNull(location.entrance),
      floor: _trimmedOrNull(location.floor),
      comment: _trimmedOrNull(location.comment),
    );
  }

  ClientAddress? _defaultAddress(List<ClientAddress> addresses) {
    if (addresses.isEmpty) return null;

    for (final address in addresses) {
      if (address.isDefault) return address;
    }
    return addresses.first;
  }

  String? _formatClientAddressText(ClientAddress address) {
    final parts = <String>[
      if (address.street.trim().isNotEmpty) address.street.trim(),
      if (address.houseNumber?.trim().isNotEmpty == true)
        address.houseNumber!.trim(),
      if (address.apartmentNumber?.trim().isNotEmpty == true)
        address.apartmentNumber!.trim(),
    ];
    if (parts.isEmpty) return _trimmedOrNull(address.label);
    return parts.join(', ');
  }

  String? _currentDeliveryAddressText() {
    final location = context.read<LocationController>();
    final addressName = _trimmedOrNull(location.addressName);
    final fullAddress = _trimmedOrNull(location.fullAddress) ?? addressName;
    if (fullAddress != null) return fullAddress;

    final savedAddress = _defaultAddress(
      context.read<MobileBackendController>().addresses,
    );
    if (savedAddress == null) return null;
    return _formatClientAddressText(savedAddress);
  }

  BranchModel? _branchById(String? id) {
    final branchId = id?.trim();
    if (branchId == null || branchId.isEmpty) return null;

    final selectedBranch = _selectedBranch;
    if (selectedBranch != null && selectedBranch.id == branchId) {
      return selectedBranch;
    }

    for (final branch in context.read<MobileBackendController>().branches) {
      if (branch.id == branchId) return branch;
    }
    return null;
  }

  _CheckoutAddressDetails? _checkoutAddressDetails(CartPreviewRequest request) {
    final addresses = context.read<MobileBackendController>().addresses;
    final requestedAddressId = _trimmedOrNull(request.addressId);
    if (requestedAddressId != null) {
      for (final address in addresses) {
        if (address.id == requestedAddressId) {
          return _CheckoutAddressDetails(
            label: _trimmedOrNull(address.label),
            text: _formatClientAddressText(address),
          );
        }
      }
    }

    final input = request.address;
    if (input == null) return null;

    final location = context.read<LocationController>();
    if (_coordinatesMatch(
      input.latitude,
      input.longitude,
      location.latitude,
      location.longitude,
    )) {
      final label = _trimmedOrNull(location.addressName);
      final text = _trimmedOrNull(location.fullAddress) ?? label;
      if (label != null || text != null) {
        return _CheckoutAddressDetails(label: label, text: text);
      }
    }

    for (final address in addresses) {
      if (_coordinatesMatch(
        input.latitude,
        input.longitude,
        address.latitude,
        address.longitude,
      )) {
        return _CheckoutAddressDetails(
          label: _trimmedOrNull(address.label),
          text: _formatClientAddressText(address),
        );
      }
    }

    final fallbackAddress = _defaultAddress(addresses);
    if (fallbackAddress != null) {
      return _CheckoutAddressDetails(
        label: _trimmedOrNull(fallbackAddress.label),
        text: _formatClientAddressText(fallbackAddress),
      );
    }

    return _CheckoutAddressDetails(
      text:
          '${input.latitude.toStringAsFixed(5)}, '
          '${input.longitude.toStringAsFixed(5)}',
    );
  }

  bool _coordinatesMatch(
    double latitude,
    double longitude,
    double? otherLatitude,
    double? otherLongitude,
  ) {
    if (otherLatitude == null || otherLongitude == null) return false;
    return (latitude - otherLatitude).abs() < 0.000001 &&
        (longitude - otherLongitude).abs() < 0.000001;
  }

  _CheckoutPreviewDetails _checkoutPreviewDetails({
    required CartPreviewRequest request,
    required CartPreviewModel preview,
  }) {
    final branchId = request.type == MobileOrderType.pickup
        ? request.branchId
        : preview.branchId;
    final branch = _branchById(branchId);

    return _CheckoutPreviewDetails(
      preview: preview,
      orderType: request.type,
      branchName: _trimmedOrNull(branch?.name),
      branchAddress: _trimmedOrNull(branch?.address),
      address: request.type == MobileOrderType.delivery
          ? _checkoutAddressDetails(request)
          : null,
    );
  }

  String? _trimmedOrNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  String? _normalizePromoCode(String? promoCode) {
    final trimmedPromoCode = promoCode?.trim();
    if (trimmedPromoCode == null || trimmedPromoCode.isEmpty) return null;
    return trimmedPromoCode;
  }

  CartPreviewAddressInput? _previewAddressFromLocation(
    LocationController location,
  ) {
    final latitude = location.latitude;
    final longitude = location.longitude;
    if (latitude == null || longitude == null) return null;

    return CartPreviewAddressInput(latitude: latitude, longitude: longitude);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(appSnackBar(message));
  }

  Future<_OrderFailureAction> _showOrderCreationError(
    Failure failure, {
    bool allowRetry = false,
    bool allowRemovePoints = false,
  }) async {
    if (!mounted) return _OrderFailureAction.close;

    final t = L.of(context);
    final title = switch (failure) {
      AuthFailure() => t.errorAuthorizationExpired,
      NetworkFailure() => t.errorConnectionProblem,
      TimeoutFailure() => t.errorSlowNetwork,
      ServerFailure(errorCode: 'ORDERING_CLOSED') => t.orderingClosed,
      ServerFailure() => t.errorBackend,
      _ => t.errorGenericTitle,
    };
    final orderingClosedMessage =
        failure is ServerFailure && failure.errorCode == 'ORDERING_CLOSED'
        ? _orderingClosedMessage(failure)
        : null;
    final message =
        orderingClosedMessage ??
        failureDetail(t, failure, fallback: t.orderCreateFailed);

    return await showDialog<_OrderFailureAction>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            scrollable: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            title: Row(
              children: <Widget>[
                const Icon(
                  Icons.error_outline_rounded,
                  color: BaseColors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TypographyText(
                    title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            content: SelectableText(
              message,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
            actions: <Widget>[
              TextButton.icon(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(_OrderFailureAction.close),
                icon: const Icon(Icons.close_rounded, size: 18),
                label: TypographyText(t.close),
              ),
              if (allowRemovePoints)
                TextButton.icon(
                  onPressed: () => Navigator.of(
                    dialogContext,
                  ).pop(_OrderFailureAction.removePoints),
                  icon: const Icon(Icons.stars_outlined, size: 18),
                  label: TypographyText(t.continueWithoutPoints),
                ),
              if (allowRetry)
                FilledButton.icon(
                  onPressed: () => Navigator.of(
                    dialogContext,
                  ).pop(_OrderFailureAction.retry),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: TypographyText(t.retry),
                ),
            ],
          ),
        ) ??
        _OrderFailureAction.close;
  }

  String _orderingClosedMessage(ServerFailure failure) {
    final t = L.of(context);
    final metadata = OrderingClosedMetadataModel.fromJson(failure.metadata);
    final nextOpening = metadata.nextOpeningAt;
    if (nextOpening == null) return t.orderingClosedAction;
    final locale = Localizations.localeOf(context).languageCode;
    final formatted = DateFormat(
      'd MMM, HH:mm',
      locale,
    ).format(nextOpening.toLocal());
    final timezone = metadata.timezone.trim();
    return timezone.isEmpty
        ? t.orderingNextOpening(formatted)
        : '${t.orderingNextOpening(formatted)} · $timezone';
  }

  Future<CartPreviewRequest?> _buildCartPreviewRequest(
    List<CartLine> cartLines, {
    required MobileOrderType orderType,
    required MobilePaymentMethod paymentMethod,
    int loyaltyRedemptionAmount = 0,
    String? promoCode,
  }) async {
    final t = L.of(context);
    final items = _buildOrderItems(cartLines);
    final normalizedPromoCode = _normalizePromoCode(promoCode);

    if (orderType == MobileOrderType.pickup) {
      var branch = _selectedBranch;
      if (branch == null) {
        branch = await showBranchBottomSheet(context);
        if (!mounted) return null;
        if (branch != null) {
          await _setPickupBranch(branch);
        }
      }

      if (branch == null) {
        _showSnack(t.selectPickupBranchFirst);
        return null;
      }

      return CartPreviewRequest(
        type: MobileOrderType.pickup,
        branchId: branch.id,
        items: items,
        paymentMethod: paymentMethod,
        promoCode: normalizedPromoCode,
        loyaltyRedemptionAmount: loyaltyRedemptionAmount,
      );
    }

    final backend = context.read<MobileBackendController>();
    final location = context.read<LocationController>();
    var address = _previewAddressFromLocation(location);
    String? addressId;
    final savedAddress = _defaultAddress(backend.addresses);
    if (address == null && savedAddress != null) {
      addressId = savedAddress.id;
    }

    if (address == null && addressId == null) {
      await showAddressBottomSheet(context);
      if (!mounted) return null;
      address = _previewAddressFromLocation(location);
      final fallbackSavedAddress = _defaultAddress(
        context.read<MobileBackendController>().addresses,
      );
      if (address == null && fallbackSavedAddress != null) {
        addressId = fallbackSavedAddress.id;
      }
    }

    if (address == null && addressId == null) {
      _showSnack(t.selectDeliveryAddressFirst);
      return null;
    }

    return CartPreviewRequest(
      type: MobileOrderType.delivery,
      addressId: addressId,
      address: address,
      items: items,
      paymentMethod: paymentMethod,
      promoCode: normalizedPromoCode,
      loyaltyRedemptionAmount: loyaltyRedemptionAmount,
    );
  }

  Future<Result<_CheckoutPreviewDetails>?> _previewCartForCheckout(
    List<CartLine> cartLines, {
    required MobileOrderType orderType,
    required MobilePaymentMethod paymentMethod,
    required int loyaltyRedemptionAmount,
    String? promoCode,
  }) async {
    final request = await _buildCartPreviewRequest(
      cartLines,
      orderType: orderType,
      paymentMethod: paymentMethod,
      promoCode: promoCode,
      loyaltyRedemptionAmount: loyaltyRedemptionAmount,
    );
    if (!mounted || request == null) return null;

    _logOrderPreview('request', request.toJson());
    final backend = context.read<MobileBackendController>();
    final result = await backend.previewCart(request);
    if (result case Success(:final data)) {
      _logOrderPreview('response', _cartPreviewLogPayload(data));
      final branchId = data.branchId?.trim();
      if (orderType == MobileOrderType.delivery) {
        _deliveryBranchId = branchId?.isNotEmpty == true ? branchId : null;
        final paymentMethodsBranchId = backend.paymentMethodsBranchId?.trim();
        if (_deliveryBranchId != null &&
            paymentMethodsBranchId != _deliveryBranchId) {
          unawaited(_refreshPaymentMethodsForBranch(_deliveryBranchId));
        }
      }
      return Success(_checkoutPreviewDetails(request: request, preview: data));
    }
    if (result case Error(:final failure)) {
      _logOrderPreview('error', {
        'type': failure.runtimeType.toString(),
        'message': failure.message,
      });
      return Error<_CheckoutPreviewDetails>(failure);
    }
    return null;
  }

  void _logOrderPreview(String label, Object? payload) {
    _logCheckoutPayload('OrderPreview', label, payload);
  }

  void _logOrderCreation(String label, Object? payload) {
    _logCheckoutPayload('OrderCreate', label, payload);
  }

  /// Debug builds only. Checkout payloads carry the delivery address, door
  /// code and payment link, which must never reach the device log in release.
  void _logCheckoutPayload(String scope, String label, Object? payload) {
    if (!kDebugMode) return;
    final redacted = redactSensitiveLogFields(payload);
    try {
      const encoder = JsonEncoder.withIndent('  ');
      debugPrint('[$scope] $label:\n${encoder.convert(redacted)}');
    } catch (_) {
      debugPrint('[$scope] $label: $redacted');
    }
  }

  Map<String, Object?> _cartPreviewLogPayload(CartPreviewModel preview) {
    return {
      'branchId': preview.branchId,
      'deliveryDistanceMeters': preview.deliveryDistanceMeters,
      'deliveryDistanceSource': preview.deliveryDistanceSource.value,
      'itemsAmount': preview.itemsAmount,
      'modifiersAmount': preview.modifiersAmount,
      'discountAmount': preview.discountAmount,
      'deliveryAmount': preview.deliveryAmount,
      'promotionDeliveryDiscountAmount':
          preview.promotionDeliveryDiscountAmount,
      'serviceFeeAmount': preview.serviceFeeAmount,
      'totalAmount': preview.totalAmount,
      'totalBeforePointsAmount': preview.totalBeforePointsAmount,
      'loyalty': preview.loyalty == null
          ? null
          : {
              'requestedPoints': preview.loyalty!.requestedPoints,
              'appliedPoints': preview.loyalty!.appliedPoints,
              'maxPointsToSpend': preview.loyalty!.maxPointsToSpend,
              'estimatedEarnPoints': preview.loyalty!.estimatedEarnPoints,
            },
      'promotionStatus': preview.hasPromotionStatus
          ? preview.promotionStatus.value
          : null,
      'promotionStatusReason': preview.promotionStatusReason,
      'bonusItems': preview.bonusItems,
      'appliedPromotion': preview.appliedPromotion == null
          ? null
          : {
              'id': preview.appliedPromotion!.id,
              'code': preview.appliedPromotion!.code,
              'title': preview.appliedPromotion!.title,
              'discountAmount': preview.appliedPromotion!.discountAmount,
            },
    };
  }

  Future<CreateOrderRequest?> _buildCreateOrderRequest(
    List<CartLine> cartLines, {
    required MobileOrderType orderType,
    required MobilePaymentMethod paymentMethod,
    int loyaltyRedemptionAmount = 0,
    String? promoCode,
    String? comment,
  }) async {
    final t = L.of(context);
    final items = _buildOrderItems(cartLines);
    final normalizedPromoCode = _normalizePromoCode(promoCode);
    final normalizedComment = _trimmedOrNull(comment);

    if (orderType == MobileOrderType.pickup) {
      var branch = _selectedBranch;
      if (branch == null) {
        branch = await showBranchBottomSheet(context);
        if (!mounted) return null;
        if (branch != null) {
          await _setPickupBranch(branch);
        }
      }

      if (branch == null) {
        _showSnack(t.selectPickupBranchFirst);
        return null;
      }

      return CreateOrderRequest(
        type: MobileOrderType.pickup,
        branchId: branch.id,
        items: items,
        paymentMethod: paymentMethod,
        promoCode: normalizedPromoCode,
        comment: normalizedComment,
        loyaltyRedemptionAmount: loyaltyRedemptionAmount,
      );
    }

    final backend = context.read<MobileBackendController>();
    final location = context.read<LocationController>();
    var address = _inlineAddressFromLocation(location);
    String? addressId;
    final savedAddress = _defaultAddress(backend.addresses);
    if (address == null && savedAddress != null) {
      addressId = savedAddress.id;
    }

    if (address == null && addressId == null) {
      await showAddressBottomSheet(context);
      if (!mounted) return null;
      address = _inlineAddressFromLocation(location);
      final fallbackSavedAddress = _defaultAddress(
        context.read<MobileBackendController>().addresses,
      );
      if (address == null && fallbackSavedAddress != null) {
        addressId = fallbackSavedAddress.id;
      }
    }

    if (address == null && addressId == null) {
      _showSnack(t.selectDeliveryAddressFirst);
      return null;
    }

    return CreateOrderRequest(
      type: MobileOrderType.delivery,
      address: address,
      addressId: addressId,
      branchId: address == null ? null : _deliveryBranchId,
      items: items,
      paymentMethod: paymentMethod,
      promoCode: normalizedPromoCode,
      comment: normalizedComment,
      loyaltyRedemptionAmount: loyaltyRedemptionAmount,
    );
  }

  Future<_OrderCreationResult?> _showOrderConfirmation(
    List<CartLine> cartLines,
  ) async {
    return Navigator.of(context).push<_OrderCreationResult>(
      MaterialPageRoute<_OrderCreationResult>(
        builder: (context) => _OrderConfirmationSheet(
          cartLines: cartLines,
          initialOrderType: _orderType,
          initialPromoCode: _promoCode,
          initialComment: _orderType == MobileOrderType.delivery
              ? _trimmedOrNull(context.read<LocationController>().comment)
              : null,
          initialPickupBranchId: _selectedBranch?.id,
          initialPickupBranchText: _trimmedOrNull(_selectedBranch?.name),
          initialDeliveryAddressText: _currentDeliveryAddressText(),
          onBranchSelected: _setPickupBranch,
          onPreviewRequested:
              ({
                required MobileOrderType orderType,
                required MobilePaymentMethod paymentMethod,
                required int loyaltyRedemptionAmount,
                String? promoCode,
              }) {
                return _previewCartForCheckout(
                  cartLines,
                  orderType: orderType,
                  paymentMethod: paymentMethod,
                  loyaltyRedemptionAmount: loyaltyRedemptionAmount,
                  promoCode: promoCode,
                );
              },
        ),
      ),
    );
  }

  Future<void> _handleCheckout(List<CartLine> cartLines) async {
    if (cartLines.isEmpty || _isCheckingOut) return;

    var backend = context.read<MobileBackendController>();
    if (!backend.isAuthenticated) {
      final didAuthenticate = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(builder: (_) => const AuthorizationScreen()),
      );
      if (!mounted) return;

      backend = context.read<MobileBackendController>();
      if (didAuthenticate != true && !backend.isAuthenticated) {
        return;
      }
    }

    final orderDetails = await _showOrderConfirmation(cartLines);
    if (!mounted || orderDetails == null) return;

    setState(() => _promoCode = orderDetails.promoCode ?? '');

    final request = await _buildCreateOrderRequest(
      cartLines,
      orderType: orderDetails.orderType,
      paymentMethod: orderDetails.paymentMethod,
      promoCode: orderDetails.promoCode,
      comment: orderDetails.comment,
      loyaltyRedemptionAmount: orderDetails.loyaltyRedemptionAmount,
    );
    if (!mounted || request == null) return;

    if (_orderType != orderDetails.orderType) {
      _setOrderType(orderDetails.orderType);
    }

    _logOrderCreation('request', request.toJson());
    setState(() => _isCheckingOut = true);
    final idempotencyKey = _orderSubmissionKeys.keyFor(request.toJson());
    late Result<CustomerOrderModel> result;
    var creationErrorShown = false;
    var removePointsRequested = false;
    do {
      creationErrorShown = false;
      result = await backend.createOrder(
        request,
        idempotencyKey: idempotencyKey,
      );
      if (!mounted) return;
      if (result case Error(:final failure)) {
        if (OrderSubmissionKeys.isOutcomeUnknown(failure)) {
          creationErrorShown = true;
          final canRemovePoints =
              request.loyaltyRedemptionAmount > 0 &&
              failure is ServerFailure &&
              const <String>{
                'LOYALTY_UNAVAILABLE',
                'IIKO_LOYALTY_TENDER_UNAVAILABLE',
              }.contains(failure.errorCode);
          final action = await _showOrderCreationError(
            failure,
            allowRetry: true,
            allowRemovePoints: canRemovePoints,
          );
          if (action == _OrderFailureAction.retry) {
            continue;
          }
          removePointsRequested = action == _OrderFailureAction.removePoints;
        }
      }
      break;
    } while (true);
    _orderSubmissionKeys.resolve(
      succeeded: result.isSuccess,
      failure: result.failureOrNull,
    );
    if (result case Error(
      :final failure,
    ) when OrderSubmissionKeys.isOutcomeUnknown(failure)) {
      // The order may exist even though the request failed; reload history so
      // it shows up instead of the customer ordering again.
      unawaited(backend.refreshCustomerData());
    }
    if (result case Success(:final data)) {
      _logOrderCreation('response', data.raw);
    }
    if (result case Error(:final failure)) {
      _logOrderCreation('error', {
        'type': failure.runtimeType.toString(),
        'message': failure.message,
      });
    }
    if (!mounted) return;

    setState(() => _isCheckingOut = false);
    switch (result) {
      case Success(:final data):
        _cart.clear();
        setState(() => _promoCode = '');
        _selectTab(_profileTabIndex);
        final paymentUrl = data.totalAmount == 0
            ? null
            : data.paymentUrl?.trim();
        await Navigator.of(context).push<void>(
          PageRouteBuilder<void>(
            transitionDuration: AppMotion.duration(context, AppMotion.state),
            reverseTransitionDuration: AppMotion.duration(
              context,
              AppMotion.micro,
            ),
            pageBuilder: (_, _, _) => OrderSuccessScreen(
              order: data,
              openPaymentPage: paymentUrl?.isNotEmpty == true
                  ? () => ExternalUrlLauncher.open(
                      paymentUrl!,
                      allowedHosts: paymentLinkHosts,
                    )
                  : null,
              onTrackOrder: () => _openCreatedOrder(data),
              onBackHome: () => _selectTab(_homeTabIndex),
            ),
            transitionsBuilder: (_, animation, _, child) =>
                CurvedFadeTransition(
                  animation: animation,
                  curve: AppMotion.enter,
                  reverseCurve: AppMotion.exit,
                  child: child,
                ),
          ),
        );
      case Error(:final failure):
        final loyaltyCode = failure is ServerFailure ? failure.errorCode : null;
        final resetLoyalty = const <String>{
          'LOYALTY_AMOUNT_CHANGED',
          'LOYALTY_DEBT_OUTSTANDING',
          'LOYALTY_REDEMPTION_DISABLED',
          'LOYALTY_PROGRAM_DISABLED',
          'IDEMPOTENCY_KEY_REUSED',
        }.contains(loyaltyCode);
        if (resetLoyalty) {
          await context.read<MobileBackendController>().refreshLoyaltyWallet();
        }
        if (!creationErrorShown) {
          await _showOrderCreationError(failure);
        }
        if (!mounted) return;
        if (failure is AuthFailure) {
          await Navigator.of(context).push<bool>(
            MaterialPageRoute<bool>(
              builder: (_) => const AuthorizationScreen(),
            ),
          );
          return;
        }
        if (resetLoyalty || removePointsRequested) {
          unawaited(_handleCheckout(cartLines));
        }
    }
  }

  void _openCreatedOrder(CustomerOrderModel createdOrder) {
    if (!mounted) return;

    _selectTab(_profileTabIndex);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final backend = context.read<MobileBackendController>();
      var order = createdOrder;
      for (final candidate in backend.orders) {
        if (candidate.id == createdOrder.id) {
          order = candidate;
          break;
        }
      }

      unawaited(
        showProfileOrderDetailsSheet(
          context: context,
          order: order,
          locale: context.read<LocaleController>().locale.languageCode,
          branches: backend.branches,
          addresses: backend.addresses,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = L.of(context);
    // Only the fields rendered here: notifications, payment methods,
    // addresses, loyalty pages and loading flags no longer rebuild the shell.
    final backend = context.select<MobileBackendController, _ShellData>(
      (controller) => (
        status: controller.status,
        failure: controller.failure,
        client: controller.client,
        menuCategories: controller.menuCategories,
        menuCategoryItems: controller.menuCategoryItems,
        menuProducts: controller.menuProducts,
        promotions: controller.promotions,
        banners: controller.banners,
        loyaltyWallet: controller.loyaltyWallet,
        notificationUnreadCount: controller.notificationUnreadCount,
        orders: controller.orders,
        isAuthenticated: controller.isAuthenticated,
      ),
    );
    // Home's delivery label follows address edits.
    context.select<LocationController, String>(
      (location) => location.fullAddress,
    );
    _maybeShowStartupBirthDatePrompt(backend.status, backend.client);
    final categories = backend.menuCategories;
    final products = backend.menuProducts;
    _scheduleCartReconciliation(products);
    final promotions = backend.promotions
        .where((promotion) => promotion.isActive)
        .toList(growable: false);
    final selectedCategoryIndex = categories.isEmpty
        ? -1
        : _selectedCategoryIndex.clamp(-1, categories.length - 1);

    return PopScope(
      canPop: _currentIndex == _homeTabIndex,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentIndex != _homeTabIndex) {
          _selectTab(
            _currentIndex == _cartPageIndex ? _menuTabIndex : _homeTabIndex,
          );
        }
      },
      child: Scaffold(
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
                active: _currentIndex == _homeTabIndex,
                child: HomeScreen(
                  customerName: _homeCustomerName(backend.client, t),
                  loyaltyBalance:
                      backend.loyaltyWallet?.spendableBalance ??
                      backend.client?.bonusBalance ??
                      0,
                  orderModeLabel: _orderType == MobileOrderType.delivery
                      ? t.delivery
                      : t.pickup,
                  orderContextLabel: _orderContextLabel(t),
                  categories: backend.menuCategoryItems,
                  products: products,
                  banners: backend.banners,
                  onBannerLinkTap: (uri) => unawaited(_openBannerLink(uri)),
                  locale: context.watch<LocaleController>().locale.languageCode,
                  notificationUnreadCount: backend.notificationUnreadCount,
                  lastOrder: backend.orders.isEmpty
                      ? null
                      : backend.orders.first,
                  isLoading:
                      backend.status == MobileBackendStatus.loading &&
                      products.isEmpty,
                  failure:
                      backend.status == MobileBackendStatus.error &&
                          products.isEmpty
                      ? backend.failure
                      : null,
                  onOrderContextTap: () => unawaited(_openOrderContextPicker()),
                  onNotificationsTap: () => unawaited(_openNotifications()),
                  onLoyaltyTap: () => unawaited(_openLoyaltyWallet()),
                  onMenuTap: () => _selectTab(_menuTabIndex),
                  onCategoryTap: (index) {
                    _setSelectedCategory(index);
                    _selectTab(_menuTabIndex);
                  },
                  onRepeatOrder: backend.orders.isEmpty
                      ? null
                      : () => _repeatOrder(backend.orders.first),
                  onRefresh: _refreshMenuData,
                ),
              ),
              _KeepAliveTabPage(
                active: _currentIndex == _menuTabIndex,
                child: ListenableBuilder(
                  listenable: _cart,
                  builder: (context, _) {
                    final cart = _cart.snapshot(products);
                    return MenuScreen(
                      isDark: isDark,
                      isMenuLoading:
                          backend.status == MobileBackendStatus.loading &&
                          products.isEmpty,
                      menuErrorText:
                          backend.status == MobileBackendStatus.error &&
                              products.isEmpty
                          ? switch (backend.failure) {
                              final Failure failure => failureDetail(
                                t,
                                failure,
                              ),
                              null => null,
                            }
                          : null,
                      menuFailure:
                          backend.status == MobileBackendStatus.error &&
                              products.isEmpty
                          ? backend.failure
                          : null,
                      selectedCategoryIndex: selectedCategoryIndex,
                      categories: categories,
                      products: products,
                      promotions: promotions,
                      orderType: _orderType,
                      selectedBranch: _selectedBranch,
                      onCategorySelected: _setSelectedCategory,
                      onAddToCart: _addToCart,
                      onAddConfiguredToCart: _addConfiguredToCart,
                      onDecreaseFromCart: (product) => _updateCart(product, -1),
                      onCartTap: () => _selectTab(_cartPageIndex),
                      onOrderContextTap: () =>
                          unawaited(_openOrderContextPicker()),
                      showCartSummary: false,
                      isActive: _currentIndex == _menuTabIndex,
                      cartTargetKey: _cartIconKey,
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
                      cartCount: cart.totalItems,
                      cartTotal: cart.totalAmount,
                      cartQuantities: cart.quantitiesByProduct,
                      notificationUnreadCount: backend.notificationUnreadCount,
                      onNotificationsTap: () => unawaited(_openNotifications()),
                    );
                  },
                ),
              ),
              _KeepAliveTabPage(
                active: _currentIndex == _promotionsTabIndex,
                child: backend.isAuthenticated
                    ? _promotionsTab
                    : const SizedBox.shrink(),
              ),
              _KeepAliveTabPage(
                active: _currentIndex == _cartPageIndex,
                child: ListenableBuilder(
                  listenable: _cart,
                  builder: (context, _) {
                    final cart = _cart.snapshot(products);
                    return CartScreen(
                      isDark: isDark,
                      items: cart.lines,
                      totalAmount: cart.totalAmount,
                      isCheckingOut: _isCheckingOut,
                      onDecrease: (line) => _updateCartLine(line, -1),
                      onIncrease: (line) => _updateCartLine(line, 1),
                      onBrowseMenu: () => _selectTab(_menuTabIndex),
                      onCheckout: () => unawaited(_handleCheckout(cart.lines)),
                    );
                  },
                ),
              ),
              _KeepAliveTabPage(
                active: _currentIndex == _profileTabIndex,
                child: _profileTab,
              ),
            ],
          ),
        ),
        bottomNavigationBar: ListenableBuilder(
          listenable: Listenable.merge(<Listenable>[_cart, _cartArrival]),
          builder: (context, _) {
            final cart = _cart.snapshot(products);
            return _MainTabsBottomNavigation(
              cartIconKey: _cartIconKey,
              cartArrival: _cartArrival.value,
              isDark: isDark,
              currentIndex: _currentIndex,
              totalItems: cart.totalItems,
              totalAmount: cart.totalAmount,
              showCartPill:
                  cart.totalItems > 0 &&
                  (_currentIndex == _homeTabIndex ||
                      _currentIndex == _menuTabIndex),
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
      ),
    );
  }

  String _homeCustomerName(ClientProfile? client, L t) {
    final fullName = client?.fullName.trim();
    if (fullName == null || fullName.isEmpty) return t.guest;
    return fullName.split(RegExp(r'\s+')).first;
  }

  String _orderContextLabel(L t) {
    if (_orderType == MobileOrderType.pickup) {
      final branchName = _selectedBranch?.name.trim();
      return branchName?.isNotEmpty == true ? branchName! : t.pickupBranch;
    }
    return _currentDeliveryAddressText() ?? t.tapToSelectAddress;
  }
}

/// Keeps a tab's state while it is off screen and freezes its animations
/// there: tickers on an inactive tab would otherwise keep scheduling frames.
class _KeepAliveTabPage extends StatefulWidget {
  const _KeepAliveTabPage({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<_KeepAliveTabPage> createState() => _KeepAliveTabPageState();
}

class _KeepAliveTabPageState extends State<_KeepAliveTabPage>
    with AutomaticKeepAliveClientMixin<_KeepAliveTabPage> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return TickerMode(enabled: widget.active, child: widget.child);
  }
}
