import 'dart:async';

import 'package:enjoy_lavash_mobile/app/locale_controller.dart';
import 'package:enjoy_lavash_mobile/app/location_controller.dart';
import 'package:enjoy_lavash_mobile/core/error/failures.dart';
import 'package:enjoy_lavash_mobile/core/error/result.dart';
import 'package:enjoy_lavash_mobile/core/services/app_share_service.dart';
import 'package:enjoy_lavash_mobile/core/services/external_url_launcher.dart';
import 'package:enjoy_lavash_mobile/features/models/cart_line.dart';
import 'package:enjoy_lavash_mobile/features/models/menu_product.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/address_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/branch_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/cart_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/order_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/presentation/mobile_backend_controller.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/screens/address_bottom_sheet.dart';
import 'package:enjoy_lavash_mobile/screens/authorization_screen.dart';
import 'package:enjoy_lavash_mobile/screens/branch_bottom_sheet.dart';
import 'package:enjoy_lavash_mobile/screens/cart_screen.dart';
import 'package:enjoy_lavash_mobile/screens/menu_screen.dart';
import 'package:enjoy_lavash_mobile/screens/profile.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'package:enjoy_lavash_mobile/theme/theme_extensions.dart';
import 'package:enjoy_lavash_mobile/utils/price_formatter.dart';
import 'package:enjoy_lavash_mobile/widgets/app_snack_bar.dart';
import 'package:enjoy_lavash_mobile/widgets/delivery_chip.dart';
import 'package:enjoy_lavash_mobile/widgets/fade_slide_in.dart';
import 'package:enjoy_lavash_mobile/widgets/typography.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

part 'main_tabs/checkout_models.dart';
part 'main_tabs/main_tabs_bottom_navigation.dart';
part 'main_tabs/main_tabs_drawer.dart';
part 'main_tabs/order_confirmation_sheet.dart';
part 'main_tabs/order_type_toggle.dart';
part 'main_tabs/payment_method_selector.dart';
part 'main_tabs/promo_code_field.dart';
part 'main_tabs/order_confirmation_items.dart';
part 'main_tabs/checkout_preview_summary.dart';

class MainTabs extends StatefulWidget {
  const MainTabs({super.key});

  @override
  State<MainTabs> createState() => _MainTabsState();
}

class _MainTabsState extends State<MainTabs> {
  int _currentIndex = 0;
  int _selectedCategoryIndex = 0;
  final Map<String, int> _cart = <String, int>{};
  MobileOrderType _orderType = MobileOrderType.delivery;
  BranchModel? _selectedBranch;
  String? _deliveryBranchId;
  String _promoCode = '';
  bool _isCheckingOut = false;

  /// Built once so cart/category updates don't rebuild the profile subtree;
  /// it listens to its providers internally.
  late final Widget _profileTab = Profile(onRefresh: _refreshProfileData);

  List<CartLine> _buildCartLines(List<MenuProduct> products) {
    final productById = <String, MenuProduct>{
      for (final product in products) product.id: product,
    };
    final lines = <CartLine>[];
    for (final entry in _cart.entries) {
      final product = productById[entry.key];
      if (product == null) continue;
      lines.add(CartLine(product: product, quantity: entry.value));
    }
    return lines;
  }

  int _calculateTotalAmount(List<CartLine> cartLines) {
    return cartLines.fold<int>(
      0,
      (sum, item) => sum + item.product.price * item.quantity,
    );
  }

  int _calculateTotalItems(List<CartLine> cartLines) {
    return cartLines.fold<int>(0, (sum, item) => sum + item.quantity);
  }

  Future<void> _shareApp(L t) async {
    await AppShareService.share(t);
  }

  void _addToCart(MenuProduct product) {
    setState(() {
      _cart.update(product.id, (value) => value + 1, ifAbsent: () => 1);
    });
  }

  void _updateCart(MenuProduct product, int delta) {
    setState(() {
      final current = _cart[product.id] ?? 0;
      final next = current + delta;
      if (next <= 0) {
        _cart.remove(product.id);
      } else {
        _cart[product.id] = next;
      }
    });
  }

  void _setSelectedCategory(int index) {
    if (_selectedCategoryIndex == index) {
      return;
    }
    setState(() => _selectedCategoryIndex = index);
  }

  void _selectTab(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
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
      _refreshCatalogForBranch(null);
    }
    if (type == MobileOrderType.delivery) {
      _refreshPaymentMethodsForBranch(null);
    }
  }

  void _setPickupBranch(BranchModel? branch) {
    setState(() {
      _selectedBranch = branch;
      if (branch != null) {
        _orderType = MobileOrderType.pickup;
      }
    });

    _refreshCatalogForBranch(branch?.id);
    _refreshPaymentMethodsForBranch(branch?.id);
  }

  void _refreshCatalogForBranch(String? branchId) {
    final language = context.read<LocaleController>().locale.languageCode;
    unawaited(
      context.read<MobileBackendController>().refreshCatalog(
        language: language,
        branchId: branchId,
      ),
    );
  }

  void _refreshPaymentMethodsForBranch(String? branchId) {
    final language = context.read<LocaleController>().locale.languageCode;
    unawaited(
      context.read<MobileBackendController>().refreshPaymentMethods(
        language: language,
        branchId: branchId,
      ),
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

  CreateOrderAddressInput _inlineAddressFromClientAddress(
    ClientAddress address,
  ) {
    return CreateOrderAddressInput(
      latitude: address.latitude,
      longitude: address.longitude,
      label: _trimmedOrNull(address.label),
      text: _formatClientAddressText(address),
      street: _trimmedOrNull(address.street),
      houseNumber: _trimmedOrNull(address.houseNumber),
      apartmentNumber: _trimmedOrNull(address.apartmentNumber),
      entrance: _trimmedOrNull(address.entrance),
      floor: _trimmedOrNull(address.floor),
      doorCode: _trimmedOrNull(address.doorCode),
      comment: _trimmedOrNull(address.comment),
    );
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

  _CheckoutAddressDetails? _checkoutAddressDetails(
    CartPreviewAddressInput? input,
  ) {
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

    final addresses = context.read<MobileBackendController>().addresses;
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
          ? _checkoutAddressDetails(request.address)
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

  CartPreviewAddressInput _previewAddressFromClientAddress(
    ClientAddress address,
  ) {
    return CartPreviewAddressInput(
      latitude: address.latitude,
      longitude: address.longitude,
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(appSnackBar(message));
  }

  Future<CartPreviewRequest?> _buildCartPreviewRequest(
    List<CartLine> cartLines, {
    required MobileOrderType orderType,
    required MobilePaymentMethod paymentMethod,
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
          _setPickupBranch(branch);
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
      );
    }

    final backend = context.read<MobileBackendController>();
    final location = context.read<LocationController>();
    var address = _previewAddressFromLocation(location);
    final savedAddress = _defaultAddress(backend.addresses);
    if (address == null && savedAddress != null) {
      address = _previewAddressFromClientAddress(savedAddress);
    }

    if (address == null) {
      await showAddressBottomSheet(context);
      if (!mounted) return null;
      address = _previewAddressFromLocation(location);
      final fallbackSavedAddress = _defaultAddress(
        context.read<MobileBackendController>().addresses,
      );
      if (address == null && fallbackSavedAddress != null) {
        address = _previewAddressFromClientAddress(fallbackSavedAddress);
      }
    }

    if (address == null) {
      _showSnack(t.selectDeliveryAddressFirst);
      return null;
    }

    return CartPreviewRequest(
      type: MobileOrderType.delivery,
      address: address,
      items: items,
      paymentMethod: paymentMethod,
      promoCode: normalizedPromoCode,
    );
  }

  Future<Result<_CheckoutPreviewDetails>?> _previewCartForCheckout(
    List<CartLine> cartLines, {
    required MobileOrderType orderType,
    required MobilePaymentMethod paymentMethod,
    String? promoCode,
  }) async {
    final request = await _buildCartPreviewRequest(
      cartLines,
      orderType: orderType,
      paymentMethod: paymentMethod,
      promoCode: promoCode,
    );
    if (!mounted || request == null) return null;

    final result = await context.read<MobileBackendController>().previewCart(
      request,
    );
    if (result case Success(:final data)) {
      final branchId = data.branchId?.trim();
      if (orderType == MobileOrderType.delivery) {
        _deliveryBranchId = branchId?.isNotEmpty == true ? branchId : null;
        if (_deliveryBranchId != null) {
          _refreshPaymentMethodsForBranch(_deliveryBranchId);
        }
      }
      return Success(_checkoutPreviewDetails(request: request, preview: data));
    }
    if (result case Error(:final failure)) {
      return Error<_CheckoutPreviewDetails>(failure);
    }
    return null;
  }

  Future<CreateOrderRequest?> _buildCreateOrderRequest(
    List<CartLine> cartLines, {
    required MobileOrderType orderType,
    required MobilePaymentMethod paymentMethod,
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
          _setPickupBranch(branch);
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
      );
    }

    final backend = context.read<MobileBackendController>();
    final location = context.read<LocationController>();
    var address = _inlineAddressFromLocation(location);
    final savedAddress = _defaultAddress(backend.addresses);
    if (address == null && savedAddress != null) {
      address = _inlineAddressFromClientAddress(savedAddress);
    }

    if (address == null) {
      await showAddressBottomSheet(context);
      if (!mounted) return null;
      address = _inlineAddressFromLocation(location);
      final fallbackSavedAddress = _defaultAddress(
        context.read<MobileBackendController>().addresses,
      );
      if (address == null && fallbackSavedAddress != null) {
        address = _inlineAddressFromClientAddress(fallbackSavedAddress);
      }
    }

    if (address == null) {
      _showSnack(t.selectDeliveryAddressFirst);
      return null;
    }

    final comment = location.comment.trim();
    return CreateOrderRequest(
      type: MobileOrderType.delivery,
      address: address,
      branchId: _deliveryBranchId,
      items: items,
      paymentMethod: paymentMethod,
      promoCode: normalizedPromoCode,
      comment: comment.isEmpty ? null : comment,
    );
  }

  Future<_OrderCreationResult?> _showOrderConfirmation(
    List<CartLine> cartLines,
  ) async {
    return showModalBottomSheet<_OrderCreationResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _OrderConfirmationSheet(
          cartLines: cartLines,
          initialOrderType: _orderType,
          initialPromoCode: _promoCode,
          initialPickupBranchText: _trimmedOrNull(_selectedBranch?.name),
          initialDeliveryAddressText: _currentDeliveryAddressText(),
          onBranchSelected: _setPickupBranch,
          onPreviewRequested:
              ({
                required MobileOrderType orderType,
                required MobilePaymentMethod paymentMethod,
                String? promoCode,
              }) {
                return _previewCartForCheckout(
                  cartLines,
                  orderType: orderType,
                  paymentMethod: paymentMethod,
                  promoCode: promoCode,
                );
              },
        );
      },
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

    if (_orderType != orderDetails.orderType) {
      _setOrderType(orderDetails.orderType);
    }
    setState(() => _promoCode = orderDetails.promoCode ?? '');

    final request = await _buildCreateOrderRequest(
      cartLines,
      orderType: orderDetails.orderType,
      paymentMethod: orderDetails.paymentMethod,
      promoCode: orderDetails.promoCode,
    );
    if (!mounted || request == null) return;

    setState(() => _isCheckingOut = true);
    final result = await context.read<MobileBackendController>().createOrder(
      request,
    );
    if (!mounted) return;

    setState(() => _isCheckingOut = false);
    switch (result) {
      case Success(:final data):
        setState(() {
          _cart.clear();
          _promoCode = '';
          _currentIndex = 2;
        });
        final paymentUrl = data.paymentUrl?.trim();
        if (paymentUrl?.isNotEmpty == true) {
          final opened = await ExternalUrlLauncher.open(paymentUrl!);
          if (!mounted) return;
          _showSnack(
            opened
                ? L.of(context).orderCreatedPaymentOnline
                : L.of(context).orderCreatedPaymentPageOpenFailed,
          );
        } else {
          _showSnack(L.of(context).orderCreated);
        }
      case Error(:final failure):
        if (failure is AuthFailure) {
          await Navigator.of(context).push<bool>(
            MaterialPageRoute<bool>(
              builder: (_) => const AuthorizationScreen(),
            ),
          );
          return;
        }
        _showSnack(
          failure.message.isNotEmpty
              ? failure.message
              : L.of(context).orderCreateFailed,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = L.of(context);
    final backend = context.watch<MobileBackendController>();
    final categories = backend.menuCategories;
    final products = backend.menuProducts;
    final promotions = backend.promotions
        .where((promotion) => promotion.isActive)
        .toList(growable: false);
    final cartLines = _buildCartLines(products);
    final totalItems = _calculateTotalItems(cartLines);
    final totalAmount = _calculateTotalAmount(cartLines);
    final selectedCategoryIndex = categories.isEmpty
        ? 0
        : _selectedCategoryIndex.clamp(0, categories.length - 1);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: _MainTabsDrawer(
        isDark: isDark,
        t: t,
        onTabSelected: _selectTab,
        onShareApp: () => unawaited(_shareApp(t)),
      ),
      body: SafeArea(
        child: FadeIndexedStack(
          index: _currentIndex,
          children: <Widget>[
            MenuScreen(
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
              onDecreaseFromCart: (product) => _updateCart(product, -1),
              onCartTap: () => _selectTab(1),
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
              cartQuantities: _cart,
            ),
            CartScreen(
              isDark: isDark,
              items: cartLines,
              totalAmount: totalAmount,
              isCheckingOut: _isCheckingOut,
              onDecrease: (product) => _updateCart(product, -1),
              onIncrease: (product) => _updateCart(product, 1),
              onBrowseMenu: () => _selectTab(0),
              onCheckout: () => unawaited(_handleCheckout(cartLines)),
            ),
            _profileTab,
          ],
        ),
      ),
      bottomNavigationBar: _MainTabsBottomNavigation(
        theme: theme,
        isDark: isDark,
        currentIndex: _currentIndex,
        totalItems: totalItems,
        t: t,
        onDestinationSelected: _selectTab,
      ),
    );
  }
}
