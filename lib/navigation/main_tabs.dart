import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:enjoy_lavash_mobile/app/locale_controller.dart';
import 'package:enjoy_lavash_mobile/app/location_controller.dart';
import 'package:enjoy_lavash_mobile/core/error/failures.dart';
import 'package:enjoy_lavash_mobile/core/error/result.dart';
import 'package:enjoy_lavash_mobile/core/services/app_share_service.dart';
import 'package:enjoy_lavash_mobile/core/services/external_url_launcher.dart';
import 'package:enjoy_lavash_mobile/core/services/mobile_push_notification_service.dart';
import 'package:enjoy_lavash_mobile/core/storage/cart_storage.dart';
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
import 'package:enjoy_lavash_mobile/utils/price_formatter.dart';
import 'package:enjoy_lavash_mobile/widgets/app_bottom_sheet_drag_handle.dart';
import 'package:enjoy_lavash_mobile/widgets/app_modal_bottom_sheet.dart';
import 'package:enjoy_lavash_mobile/widgets/app_snack_bar.dart';
import 'package:enjoy_lavash_mobile/widgets/redesign/cart_pill.dart';
import 'package:enjoy_lavash_mobile/widgets/typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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
  return NumberFormat.decimalPattern(
    Localizations.localeOf(context).toLanguageTag(),
  ).format(value);
}

class MainTabs extends StatefulWidget {
  const MainTabs({super.key});

  @override
  State<MainTabs> createState() => _MainTabsState();
}

class _MainTabsState extends State<MainTabs> {
  static const int _homeTabIndex = 0;
  static const int _menuTabIndex = 1;
  static const int _notificationsTabIndex = 2;
  static const int _profileTabIndex = 3;
  static const int _cartPageIndex = 4;
  static const int _tabCount = 5;

  int _currentIndex = 0;
  // -1 is the reference design's "All" filter.
  int _selectedCategoryIndex = -1;
  final Map<String, CartSelection> _cart = <String, CartSelection>{};
  MobileOrderType _orderType = MobileOrderType.delivery;
  BranchModel? _selectedBranch;
  String? _deliveryBranchId;
  String _promoCode = '';
  bool _isCheckingOut = false;
  bool _cartEditedSinceLaunch = false;
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
  );
  late final Widget _notificationsTab = NotificationsScreen(
    embedded: true,
    onPromoSelected: _applyAssignedPromoCode,
    onBrowseMenu: () => _selectTab(_menuTabIndex),
  );

  @override
  void initState() {
    super.initState();
    unawaited(_restoreSavedCart());
  }

  @override
  void dispose() {
    _tabPageController.dispose();
    super.dispose();
  }

  Future<void> _restoreSavedCart() async {
    final savedCart = await CartStorage.readSelections();
    if (!mounted || _cartEditedSinceLaunch || savedCart.isEmpty) return;
    final products = context.read<MobileBackendController>().menuProducts;
    final restored = products.isEmpty
        ? <String, CartSelection>{for (final line in savedCart) line.key: line}
        : _reconciledCart(savedCart, products);
    setState(() {
      for (final line in restored.values) {
        _cart[line.key] = line;
      }
    });
    if (products.isNotEmpty && restored.length != savedCart.length) {
      _persistCart();
    }
  }

  void _persistCart() {
    unawaited(CartStorage.saveSelections(_cart.values));
  }

  List<CartLine> _buildCartLines(List<MenuProduct> products) {
    final productById = <String, MenuProduct>{
      for (final product in products) product.id: product,
    };
    final lines = <CartLine>[];
    for (final selection in _cart.values) {
      final product = productById[selection.productId];
      if (product == null) continue;
      final reconciled = reconcileCartSelection(selection, product);
      if (reconciled == null) continue;
      lines.add(
        CartLine(
          product: product,
          quantity: reconciled.quantity,
          modifiers: reconciled.modifiers,
        ),
      );
    }
    return lines;
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
      _lastReconciledProducts = products;
      final next = _reconciledCart(_cart.values, products);
      final currentJson = jsonEncode(
        _cart.entries
            .map(
              (entry) => <String, Object?>{
                'key': entry.key,
                ...entry.value.toJson(),
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
      setState(() {
        _cart
          ..clear()
          ..addAll(next);
      });
      _persistCart();
    });
  }

  int _calculateTotalAmount(List<CartLine> cartLines) {
    return cartLines.fold<int>(0, (sum, item) => sum + item.lineTotal);
  }

  int _calculateTotalItems(List<CartLine> cartLines) {
    return cartLines.fold<int>(0, (sum, item) => sum + item.quantity);
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

  Future<void> _openNotifications() async {
    if (!await _ensureAuthenticated() || !mounted) return;
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const NotificationsScreen()),
    );
    if (code != null && mounted) {
      _applyAssignedPromoCode(code);
    }
  }

  Future<void> _selectNotificationsTab() async {
    if (!await _ensureAuthenticated() || !mounted) return;
    _selectTab(_notificationsTabIndex);
  }

  Future<void> _openLoyaltyWallet() async {
    if (!await _ensureAuthenticated() || !mounted) return;
    await context.read<MobileBackendController>().refreshLoyaltyWallet();
    if (!mounted) return;
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

  void _maybeShowStartupBirthDatePrompt(MobileBackendController backend) {
    if (_startupBirthDatePromptChecked ||
        backend.status != MobileBackendStatus.loaded ||
        _pushNavigationScheduled) {
      return;
    }

    _startupBirthDatePromptChecked = true;
    final client = backend.client;
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
    final hasCartItems = _buildCartLines(products).isNotEmpty;
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
      await context.read<MobileBackendController>().refreshLoyaltyWallet();
      if (!mounted) return;
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

  void _addCartSelection(CartSelection selection) {
    setState(() {
      _cartEditedSinceLaunch = true;
      final existing = _cart[selection.key];
      _cart[selection.key] = selection.copyWith(
        quantity: (existing?.quantity ?? 0) + selection.quantity,
      );
    });
    _persistCart();
  }

  void _updateCart(MenuProduct product, int delta) {
    final matchingKeys = _cart.entries
        .where((entry) => entry.value.productId == product.id)
        .map((entry) => entry.key)
        .toList(growable: false);
    if (delta > 0) {
      if (matchingKeys.isEmpty) {
        _addToCart(product);
      } else {
        final key = matchingKeys.last;
        final line = _cart[key]!;
        _setCartSelectionQuantity(line, line.quantity + delta);
      }
      return;
    }
    if (matchingKeys.isEmpty) return;
    final line = _cart[matchingKeys.last]!;
    _setCartSelectionQuantity(line, line.quantity + delta, product: product);
  }

  void _updateCartLine(CartLine line, int delta) {
    final selection = _cart[line.key];
    if (selection == null) return;
    _setCartSelectionQuantity(
      selection,
      selection.quantity + delta,
      product: line.product,
    );
  }

  void _setCartSelectionQuantity(
    CartSelection selection,
    int nextQuantity, {
    MenuProduct? product,
  }) {
    final previousQuantity = selection.quantity;
    var removedLine = false;
    setState(() {
      _cartEditedSinceLaunch = true;
      if (nextQuantity <= 0) {
        _cart.remove(selection.key);
        removedLine = previousQuantity > 0;
      } else {
        _cart[selection.key] = selection.copyWith(quantity: nextQuantity);
      }
    });
    _persistCart();

    if (removedLine && product != null) {
      final messenger = ScaffoldMessenger.of(context);
      showAutoClosingAppSnackBar(
        messenger,
        L.of(context).itemRemovedFromCart(product.title),
        actionLabel: L.of(context).undo,
        onAction: () {
          if (!mounted) return;
          setState(() {
            _cartEditedSinceLaunch = true;
            _cart[selection.key] = selection.copyWith(
              quantity: previousQuantity,
            );
          });
          _persistCart();
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
      jump: previousIndex == _cartPageIndex || index == _cartPageIndex,
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

    var added = 0;
    setState(() {
      _cartEditedSinceLaunch = true;
      for (final item in order.items) {
        final product = productsById[item.productId];
        if (product == null || item.quantity <= 0) continue;
        final selection = CartSelection(
          productId: product.id,
          quantity: item.quantity,
        );
        final existing = _cart[selection.key];
        _cart[selection.key] = selection.copyWith(
          quantity: (existing?.quantity ?? 0) + item.quantity,
        );
        added += item.quantity;
      }
    });

    if (added == 0) {
      _showSnack(L.of(context).noProductsFound);
      _selectTab(_menuTabIndex);
      return;
    }
    _persistCart();
    _selectTab(_cartPageIndex);
  }

  void _handleTabPageChanged(int index) {
    if (_currentIndex == index) return;
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
        (failure.message.trim().isEmpty
            ? t.orderCreateFailed
            : failure.message.trim());

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

  void _logCheckoutPayload(String scope, String label, Object? payload) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      debugPrint('[$scope] $label:\n${encoder.convert(payload)}');
    } catch (_) {
      debugPrint('[$scope] $label: $payload');
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
    final idempotencyKey = _newIdempotencyKey();
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
        final retryable =
            failure is NetworkFailure ||
            failure is TimeoutFailure ||
            (failure is ServerFailure && failure.statusCode >= 500);
        if (retryable) {
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
        setState(() {
          _cartEditedSinceLaunch = true;
          _cart.clear();
          _promoCode = '';
        });
        _selectTab(_profileTabIndex);
        _persistCart();
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
                  ? () => ExternalUrlLauncher.open(paymentUrl!)
                  : null,
              onTrackOrder: () => _openCreatedOrder(data),
              onBackHome: () => _selectTab(_homeTabIndex),
            ),
            transitionsBuilder: (_, animation, _, child) => FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: AppMotion.enter,
                reverseCurve: AppMotion.exit,
              ),
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

  String _newIdempotencyKey() {
    final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final value = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
        '${value.substring(12, 16)}-${value.substring(16, 20)}-'
        '${value.substring(20)}';
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
    final backend = context.watch<MobileBackendController>();
    final pendingPushMessage = backend.pendingPushMessage;
    if (pendingPushMessage != null && !_pushNavigationScheduled) {
      final message = backend.takePendingPushMessage();
      if (message != null) {
        _pushNavigationScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          try {
            await _handlePushNavigation(message);
          } finally {
            if (mounted) {
              setState(() => _pushNavigationScheduled = false);
            } else {
              _pushNavigationScheduled = false;
            }
          }
        });
      }
    }
    _maybeShowStartupBirthDatePrompt(backend);
    final categories = backend.menuCategories;
    final products = backend.menuProducts;
    _scheduleCartReconciliation(products);
    final promotions = backend.promotions
        .where((promotion) => promotion.isActive)
        .toList(growable: false);
    final cartLines = _buildCartLines(products);
    final totalItems = _calculateTotalItems(cartLines);
    final totalAmount = _calculateTotalAmount(cartLines);
    final cartQuantities = <String, int>{};
    for (final line in cartLines) {
      cartQuantities.update(
        line.product.id,
        (quantity) => quantity + line.quantity,
        ifAbsent: () => line.quantity,
      );
    }
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
          onPromotionsTap: () => unawaited(_openAssignedPromotions()),
          onOrdersTap: () => unawaited(_openOrders()),
          onShareApp: () => unawaited(_shareApp(t)),
        ),
        body: SafeArea(
          child: PageView(
            key: const ValueKey<String>('main-tabs-page-view'),
            controller: _tabPageController,
            onPageChanged: _handleTabPageChanged,
            physics: const NeverScrollableScrollPhysics(),
            children: <Widget>[
              _KeepAliveTabPage(
                child: HomeScreen(
                  customerName: _homeCustomerName(backend, t),
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
                  promotions: promotions,
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
                  onNotificationsTap: () =>
                      unawaited(_selectNotificationsTab()),
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
                child: MenuScreen(
                  isDark: isDark,
                  isMenuLoading:
                      backend.status == MobileBackendStatus.loading &&
                      products.isEmpty,
                  menuErrorText:
                      backend.status == MobileBackendStatus.error &&
                          products.isEmpty
                      ? backend.failure?.message
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
                  onOrderContextTap: () => unawaited(_openOrderContextPicker()),
                  showCartSummary: false,
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
                  cartCount: totalItems,
                  cartTotal: totalAmount,
                  cartQuantities: cartQuantities,
                  notificationUnreadCount: backend.notificationUnreadCount,
                  onNotificationsTap: () => unawaited(_openNotifications()),
                ),
              ),
              _KeepAliveTabPage(
                child: backend.isAuthenticated
                    ? _notificationsTab
                    : const SizedBox.shrink(),
              ),
              _KeepAliveTabPage(child: _profileTab),
              _KeepAliveTabPage(
                child: CartScreen(
                  isDark: isDark,
                  items: cartLines,
                  totalAmount: totalAmount,
                  isCheckingOut: _isCheckingOut,
                  onDecrease: (line) => _updateCartLine(line, -1),
                  onIncrease: (line) => _updateCartLine(line, 1),
                  onBrowseMenu: () => _selectTab(_menuTabIndex),
                  onCheckout: () => unawaited(_handleCheckout(cartLines)),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _currentIndex == _cartPageIndex
            ? null
            : _MainTabsBottomNavigation(
                isDark: isDark,
                currentIndex: _currentIndex,
                totalItems: totalItems,
                totalAmount: totalAmount,
                notificationUnreadCount: backend.notificationUnreadCount,
                showCartPill:
                    totalItems > 0 &&
                    (_currentIndex == _homeTabIndex ||
                        _currentIndex == _menuTabIndex),
                t: t,
                onCartTap: () => _selectTab(_cartPageIndex),
                onDestinationSelected: (index) {
                  if (index == _notificationsTabIndex) {
                    unawaited(_selectNotificationsTab());
                  } else {
                    _selectTab(index);
                  }
                },
              ),
      ),
    );
  }

  String _homeCustomerName(MobileBackendController backend, L t) {
    final fullName = backend.client?.fullName.trim();
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

class _KeepAliveTabPage extends StatefulWidget {
  const _KeepAliveTabPage({required this.child});

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
    return widget.child;
  }
}
