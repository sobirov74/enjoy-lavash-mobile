import 'dart:async';

import 'package:enjoy_lavash_mobile/app/locale_controller.dart';
import 'package:enjoy_lavash_mobile/app/location_controller.dart';
import 'package:enjoy_lavash_mobile/core/error/result.dart';
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

    return CreateOrderAddressInput(latitude: latitude, longitude: longitude);
  }

  ClientAddress? _defaultAddress(List<ClientAddress> addresses) {
    if (addresses.isEmpty) return null;

    for (final address in addresses) {
      if (address.isDefault) return address;
    }
    return addresses.first;
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

  Future<Result<CartPreviewModel>?> _previewCartForCheckout(
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
    }
    return result;
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
    final savedAddressId = address == null
        ? _defaultAddress(backend.addresses)?.id
        : null;

    if (address == null && savedAddressId == null) {
      await showAddressBottomSheet(context);
      if (!mounted) return null;
      address = _inlineAddressFromLocation(location);
    }

    if (address == null && savedAddressId == null) {
      _showSnack(t.selectDeliveryAddressFirst);
      return null;
    }

    final comment = location.comment.trim();
    return CreateOrderRequest(
      type: MobileOrderType.delivery,
      address: address,
      addressId: address == null ? savedAddressId : null,
      branchId: address == null ? null : _deliveryBranchId,
      items: items,
      paymentMethod: paymentMethod,
      promoCode: normalizedPromoCode,
      comment: comment.isEmpty ? null : comment,
    );
  }

  Future<_OrderCreationResult?> _showOrderConfirmation(
    List<CartLine> cartLines,
  ) async {
    final totalAmount = _calculateTotalAmount(cartLines);
    return showModalBottomSheet<_OrderCreationResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _OrderConfirmationSheet(
          cartLines: cartLines,
          totalAmount: totalAmount,
          initialOrderType: _orderType,
          initialPromoCode: _promoCode,
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
                ? _mainTabsText(
                    L.of(context),
                    en: 'Order created. Complete payment online.',
                    ru: 'Заказ создан. Завершите онлайн-оплату.',
                    uz: "Buyurtma yaratildi. Onlayn to'lovni yakunlang.",
                  )
                : _mainTabsText(
                    L.of(context),
                    en: 'Order created, but payment page could not be opened.',
                    ru: 'Заказ создан, но страницу оплаты открыть не удалось.',
                    uz: "Buyurtma yaratildi, ammo to'lov sahifasi ochilmadi.",
                  ),
          );
        } else {
          _showSnack(L.of(context).orderCreated);
        }
      case Error(:final failure):
        _showSnack(
          failure.message.isNotEmpty
              ? failure.message
              : L.of(context).orderCreateFailed,
        );
    }
  }

  Widget _buildDrawer(BuildContext context, bool isDark, L t) {
    return Drawer(
      backgroundColor: isDark ? const Color(0xFF1D1A18) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Row(
                children: [
                  Image.asset(
                    'web-design/Mobile app design request/src/imports/image-1.png',
                    height: 36,
                  ),
                  const SizedBox(width: 12),
                  const TypographyText(
                    'EnjoyLavash',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.9,
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              color: isDark ? const Color(0xFF2A2522) : const Color(0xFFE0DBD5),
              height: 1,
            ),
            const SizedBox(height: 8),
            _DrawerItem(
              icon: Icons.restaurant_menu_rounded,
              title: t.tabMenu,
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 0);
              },
            ),
            _DrawerItem(
              icon: Icons.shopping_cart_rounded,
              title: t.tabCart,
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 1);
              },
            ),
            _DrawerItem(
              icon: Icons.person_rounded,
              title: t.tabProfile,
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 2);
              },
            ),
            const Spacer(),
            Divider(
              color: isDark ? const Color(0xFF2A2522) : const Color(0xFFE0DBD5),
              height: 1,
            ),
            _DrawerItem(
              icon: Icons.share_rounded,
              title: t.shareApp,
              isDark: isDark,
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
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
      drawer: _buildDrawer(context, isDark, t),
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
              onCartTap: () => setState(() => _currentIndex = 1),
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
              onBrowseMenu: () => setState(() => _currentIndex = 0),
              onCheckout: () => unawaited(_handleCheckout(cartLines)),
            ),
            _profileTab,
          ],
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1D1A18) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF2A2521) : BaseColors.borderLight,
            ),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.06),
              blurRadius: 24,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Theme(
            data: theme.copyWith(
              navigationBarTheme: NavigationBarThemeData(
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  final isSelected = states.contains(WidgetState.selected);
                  return TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? BaseColors.primary
                        : (isDark
                              ? const Color(0xFF9E9790)
                              : BaseColors.textGray),
                  );
                }),
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  final isSelected = states.contains(WidgetState.selected);
                  return IconThemeData(
                    color: isSelected
                        ? BaseColors.primary
                        : (isDark
                              ? const Color(0xFF9E9790)
                              : BaseColors.textGray),
                  );
                }),
              ),
            ),
            child: NavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedIndex: _currentIndex,
              indicatorColor: isDark
                  ? BaseColors.primary.withValues(alpha: 0.16)
                  : BaseColors.primary.withValues(alpha: 0.12),
              onDestinationSelected: (index) {
                if (_currentIndex == index) return;
                setState(() => _currentIndex = index);
              },
              destinations: <NavigationDestination>[
                NavigationDestination(
                  icon: const Icon(Icons.restaurant_menu_outlined),
                  selectedIcon: const Icon(Icons.restaurant_menu),
                  label: t.tabMenu,
                ),
                NavigationDestination(
                  icon: Badge(
                    backgroundColor: context.colors.danger,
                    isLabelVisible: totalItems > 0,
                    label: TypographyText(
                      '$totalItems',
                      style: TextStyle(color: BaseColors.white, fontSize: 12),
                    ),
                    child: const Icon(Icons.shopping_cart_outlined),
                  ),
                  selectedIcon: Badge(
                    isLabelVisible: totalItems > 0,
                    label: TypographyText(
                      '$totalItems',
                      style: TextStyle(fontSize: 12, color: BaseColors.white),
                    ),
                    child: const Icon(Icons.shopping_cart),
                  ),
                  label: t.tabCart,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.person_outline_rounded),
                  selectedIcon: const Icon(Icons.person_rounded),
                  label: t.tabProfile,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderCreationResult {
  const _OrderCreationResult({
    required this.orderType,
    required this.paymentMethod,
    this.promoCode,
  });

  final MobileOrderType orderType;
  final MobilePaymentMethod paymentMethod;
  final String? promoCode;
}

typedef _CartPreviewRequester =
    Future<Result<CartPreviewModel>?> Function({
      required MobileOrderType orderType,
      required MobilePaymentMethod paymentMethod,
      String? promoCode,
    });

class _OrderConfirmationSheet extends StatefulWidget {
  const _OrderConfirmationSheet({
    required this.cartLines,
    required this.totalAmount,
    required this.initialOrderType,
    required this.initialPromoCode,
    required this.onPreviewRequested,
  });

  final List<CartLine> cartLines;
  final int totalAmount;
  final MobileOrderType initialOrderType;
  final String initialPromoCode;
  final _CartPreviewRequester onPreviewRequested;

  @override
  State<_OrderConfirmationSheet> createState() =>
      _OrderConfirmationSheetState();
}

class _OrderConfirmationSheetState extends State<_OrderConfirmationSheet> {
  late MobileOrderType _orderType;
  MobilePaymentMethod _paymentMethod = MobilePaymentMethod.cash;
  late final TextEditingController _promoCodeController;
  CartPreviewModel? _preview;
  MobileOrderType? _lastPreviewOrderType;
  MobilePaymentMethod? _lastPreviewPaymentMethod;
  String? _lastPreviewPromoCode;
  String? _previewErrorText;
  bool _isPreviewLoading = false;

  @override
  void initState() {
    super.initState();
    _orderType = widget.initialOrderType;
    _promoCodeController = TextEditingController(text: widget.initialPromoCode);
    _promoCodeController.addListener(_onPromoCodeChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_loadPreview());
    });
  }

  @override
  void dispose() {
    _promoCodeController.removeListener(_onPromoCodeChanged);
    _promoCodeController.dispose();
    super.dispose();
  }

  String? get _normalizedPromoCode {
    final promoCode = _promoCodeController.text.trim();
    return promoCode.isEmpty ? null : promoCode;
  }

  bool get _hasPromoCodeInput => _normalizedPromoCode != null;

  bool get _previewMatchesCurrentInput {
    return _preview != null &&
        _lastPreviewOrderType == _orderType &&
        _lastPreviewPaymentMethod == _currentPaymentMethod &&
        _lastPreviewPromoCode == _normalizedPromoCode;
  }

  List<PaymentMethodModel> get _availablePaymentMethods {
    return _resolvePaymentMethods(
      context.read<MobileBackendController>().paymentMethods,
    );
  }

  MobilePaymentMethod get _currentPaymentMethod {
    final methods = _availablePaymentMethods;
    final hasSelected = methods.any((method) => method.code == _paymentMethod);
    return hasSelected ? _paymentMethod : methods.first.code;
  }

  void _onPromoCodeChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<bool> _loadPreview() async {
    if (_isPreviewLoading) return false;

    final orderType = _orderType;
    final paymentMethod = _currentPaymentMethod;
    final promoCode = _normalizedPromoCode;
    setState(() {
      _isPreviewLoading = true;
      _previewErrorText = null;
      _preview = null;
    });

    final result = await widget.onPreviewRequested(
      orderType: orderType,
      paymentMethod: paymentMethod,
      promoCode: promoCode,
    );
    if (!mounted) return false;

    if (orderType != _orderType ||
        paymentMethod != _currentPaymentMethod ||
        promoCode != _normalizedPromoCode) {
      setState(() => _isPreviewLoading = false);
      unawaited(_loadPreview());
      return false;
    }

    if (result == null) {
      setState(() => _isPreviewLoading = false);
      return false;
    }

    return switch (result) {
      Success(:final data) => _applyPreview(
        data,
        orderType,
        paymentMethod,
        promoCode,
      ),
      Error(:final failure) => _showPreviewError(failure.message),
    };
  }

  bool _applyPreview(
    CartPreviewModel preview,
    MobileOrderType orderType,
    MobilePaymentMethod paymentMethod,
    String? promoCode,
  ) {
    setState(() {
      _preview = preview;
      _lastPreviewOrderType = orderType;
      _lastPreviewPaymentMethod = paymentMethod;
      _lastPreviewPromoCode = promoCode;
      _previewErrorText = null;
      _isPreviewLoading = false;
    });
    return true;
  }

  bool _showPreviewError(String message) {
    setState(() {
      _preview = null;
      _previewErrorText = message;
      _isPreviewLoading = false;
    });
    return false;
  }

  Future<void> _confirmOrder() async {
    if (!_previewMatchesCurrentInput) {
      final didPreview = await _loadPreview();
      if (!didPreview || !mounted) return;
    }

    Navigator.of(context).pop(
      _OrderCreationResult(
        orderType: _orderType,
        paymentMethod: _currentPaymentMethod,
        promoCode: _normalizedPromoCode,
      ),
    );
  }

  void _selectOrderType(MobileOrderType type) {
    if (_orderType == type) return;
    setState(() => _orderType = type);
    unawaited(_loadPreview());
  }

  void _selectPaymentMethod(MobilePaymentMethod method) {
    if (_paymentMethod == method) return;
    setState(() => _paymentMethod = method);
    unawaited(_loadPreview());
  }

  List<PaymentMethodModel> _resolvePaymentMethods(
    List<PaymentMethodModel> methods,
  ) {
    if (methods.isEmpty) {
      return const <PaymentMethodModel>[
        PaymentMethodModel(
          id: 'cash-fallback',
          code: MobilePaymentMethod.cash,
          name: 'Cash',
          isOnline: false,
          sortOrder: 0,
        ),
      ];
    }
    return methods;
  }

  Widget _buildOrderTypeToggle(L t) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF201C19) : const Color(0xFFF0ECE6),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: GestureDetector(
              onTap: () => _selectOrderType(MobileOrderType.delivery),
              child: DeliveryChip(
                icon: Icons.delivery_dining_rounded,
                title: t.delivery,
                active: _orderType == MobileOrderType.delivery,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: GestureDetector(
              onTap: () => _selectOrderType(MobileOrderType.pickup),
              child: DeliveryChip(
                icon: Icons.shopping_bag_outlined,
                title: t.pickup,
                active: _orderType == MobileOrderType.pickup,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCodeField(L t) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2522) : const Color(0xFFF8F4EF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF3A332D) : const Color(0xFFEDE2D7),
        ),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.local_offer_outlined, color: BaseColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _promoCodeController,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              cursorColor: BaseColors.primary,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: _mainTabsText(
                  t,
                  en: 'Enter promo code',
                  ru: 'Введите промокод',
                  uz: 'Promokodni kiriting',
                ),
                hintStyle: TextStyle(
                  color: isDark ? const Color(0xFF9E9790) : BaseColors.textGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onSubmitted: (_) => unawaited(_loadPreview()),
            ),
          ),
          if (_hasPromoCodeInput) ...[
            const SizedBox(width: 8),
            SizedBox(
              height: 38,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: BaseColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _isPreviewLoading
                    ? null
                    : () => unawaited(_loadPreview()),
                child: _isPreviewLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: BaseColors.white,
                        ),
                      )
                    : TypographyText(
                        _mainTabsText(
                          t,
                          en: 'Apply',
                          ru: 'Применить',
                          uz: "Qo'llash",
                        ),
                        style: const TextStyle(
                          color: BaseColors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewSummary(L t) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final preview = _preview;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2522) : const Color(0xFFF8F4EF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: _isPreviewLoading && preview == null
            ? const _PreviewLoadingState(key: ValueKey<String>('loading'))
            : preview == null
            ? _PreviewErrorState(
                key: const ValueKey<String>('error'),
                message:
                    _previewErrorText ??
                    _mainTabsText(
                      t,
                      en: 'Could not calculate total',
                      ru: 'Не удалось рассчитать итог',
                      uz: "Jami summani hisoblab bo'lmadi",
                    ),
                onRetry: () => unawaited(_loadPreview()),
              )
            : _PreviewTotals(
                key: const ValueKey<String>('totals'),
                preview: preview,
                orderType: _orderType,
                isRefreshing: _isPreviewLoading,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final paymentMethods = _resolvePaymentMethods(
      context.watch<MobileBackendController>().paymentMethods,
    );
    final currentPaymentMethod =
        paymentMethods.any((method) => method.code == _paymentMethod)
        ? _paymentMethod
        : paymentMethods.first.code;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D1A18) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          18,
          10,
          18,
          20 + MediaQuery.paddingOf(context).bottom + bottomInset,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF4A4038)
                      : const Color(0xFFE5DAD0),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: TypographyText(
                    _mainTabsText(
                      t,
                      en: 'Create order',
                      ru: 'Оформить заказ',
                      uz: 'Buyurtma berish',
                    ),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TypographyText(
              _mainTabsText(
                t,
                en: 'Order type',
                ru: 'Тип заказа',
                uz: 'Buyurtma turi',
              ),
              style: const TextStyle(
                color: BaseColors.textGray,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            _buildOrderTypeToggle(t),
            const SizedBox(height: 14),
            TypographyText(
              t.promoCode,
              style: const TextStyle(
                color: BaseColors.textGray,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            _buildPromoCodeField(t),
            const SizedBox(height: 14),
            _PaymentMethodSelector(
              methods: paymentMethods,
              selectedMethod: currentPaymentMethod,
              onChanged: _selectPaymentMethod,
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2A2522)
                    : const Color(0xFFF8F4EF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TypographyText(
                    _mainTabsText(
                      t,
                      en: 'Order items',
                      ru: 'Состав заказа',
                      uz: 'Buyurtma mahsulotlari',
                    ),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (int i = 0; i < widget.cartLines.length; i++) ...[
                    _ConfirmationItemRow(line: widget.cartLines[i]),
                    if (i < widget.cartLines.length - 1)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(height: 1, color: Color(0x1A8C8278)),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            _buildPreviewSummary(t),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: BaseColors.textGray,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: TypographyText(
                      _mainTabsText(
                        t,
                        en: 'Cancel',
                        ru: 'Отмена',
                        uz: 'Bekor qilish',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: BaseColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _isPreviewLoading
                        ? null
                        : () => unawaited(_confirmOrder()),
                    child: TypographyText(
                      _mainTabsText(
                        t,
                        en: 'Create order',
                        ru: 'Создать заказ',
                        uz: 'Buyurtma berish',
                      ),
                      style: const TextStyle(color: BaseColors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodSelector extends StatelessWidget {
  const _PaymentMethodSelector({
    required this.methods,
    required this.selectedMethod,
    required this.onChanged,
  });

  final List<PaymentMethodModel> methods;
  final MobilePaymentMethod selectedMethod;
  final ValueChanged<MobilePaymentMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2522) : const Color(0xFFF8F4EF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.payments_outlined,
                color: BaseColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              TypographyText(
                _mainTabsText(t, en: 'Payment', ru: 'Оплата', uz: "To'lov"),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final method in methods)
                _PaymentMethodChip(
                  method: method,
                  selected: method.code == selectedMethod,
                  onTap: () => onChanged(method.code),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodChip extends StatelessWidget {
  const _PaymentMethodChip({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final PaymentMethodModel method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = method.name.trim().isEmpty
        ? _confirmationPaymentLabel(method.code, t)
        : method.name.trim();

    return Material(
      color: selected
          ? BaseColors.primary.withValues(alpha: isDark ? 0.22 : 0.12)
          : isDark
          ? const Color(0xFF201C19)
          : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: selected ? null : onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? BaseColors.primary
                  : isDark
                  ? const Color(0xFF3A332D)
                  : const Color(0xFFEDE2D7),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                _paymentMethodIcon(method.code),
                color: selected ? BaseColors.primary : BaseColors.textGray,
                size: 18,
              ),
              const SizedBox(width: 8),
              TypographyText(
                label,
                style: TextStyle(
                  color: selected
                      ? BaseColors.primary
                      : isDark
                      ? const Color(0xFFF6EFE7)
                      : BaseColors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (method.isOnline) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: BaseColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: TypographyText(
                    _mainTabsText(t, en: 'Online', ru: 'Онлайн', uz: 'Online'),
                    style: const TextStyle(
                      color: BaseColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmationItemRow extends StatelessWidget {
  const _ConfirmationItemRow({required this.line});

  final CartLine line;

  @override
  Widget build(BuildContext context) {
    final subtotal = line.product.price * line.quantity;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          constraints: const BoxConstraints(minWidth: 34),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: BaseColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: TypographyText(
            '${line.quantity}x',
            style: const TextStyle(
              color: BaseColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TypographyText(
            line.product.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
        ),
        const SizedBox(width: 8),
        TypographyText(
          formatSum(subtotal),
          style: const TextStyle(
            color: BaseColors.textGray,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _PreviewLoadingState extends StatelessWidget {
  const _PreviewLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);

    return Row(
      children: <Widget>[
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: BaseColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TypographyText(
            _mainTabsText(
              t,
              en: 'Calculating total',
              ru: 'Считаем итог',
              uz: 'Jami hisoblanmoqda',
            ),
            style: const TextStyle(
              color: BaseColors.textGray,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewErrorState extends StatelessWidget {
  const _PreviewErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(
              Icons.info_outline_rounded,
              color: BaseColors.danger,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TypographyText(
                message,
                style: const TextStyle(
                  color: BaseColors.danger,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: BaseColors.primary,
            side: const BorderSide(color: BaseColors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: TypographyText(
            _mainTabsText(
              t,
              en: 'Recalculate',
              ru: 'Пересчитать',
              uz: 'Qayta hisoblash',
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewTotals extends StatelessWidget {
  const _PreviewTotals({
    super.key,
    required this.preview,
    required this.orderType,
    required this.isRefreshing,
  });

  final CartPreviewModel preview;
  final MobileOrderType orderType;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final appliedPromotion = preview.appliedPromotion;
    final promoCode = appliedPromotion?.code?.trim();
    final promoTitle = appliedPromotion?.title?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: TypographyText(
                _mainTabsText(
                  t,
                  en: 'Order preview',
                  ru: 'Расчет заказа',
                  uz: 'Buyurtma hisobi',
                ),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (isRefreshing)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: BaseColors.primary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _PreviewAmountRow(
          label: _mainTabsText(t, en: 'Items', ru: 'Товары', uz: 'Mahsulotlar'),
          value: formatSum(preview.itemsAmount),
        ),
        if (preview.modifiersAmount > 0)
          _PreviewAmountRow(
            label: _mainTabsText(
              t,
              en: 'Modifiers',
              ru: 'Добавки',
              uz: "Qo'shimchalar",
            ),
            value: formatSum(preview.modifiersAmount),
          ),
        if (preview.discountAmount > 0)
          _PreviewAmountRow(
            label: t.discount,
            value: '-${formatSum(preview.discountAmount)}',
            valueColor: BaseColors.primary,
          ),
        if (orderType == MobileOrderType.delivery || preview.deliveryAmount > 0)
          _PreviewAmountRow(
            label: t.delivery,
            value: formatSum(preview.deliveryAmount),
          ),
        if (preview.serviceFeeAmount > 0)
          _PreviewAmountRow(
            label: _mainTabsText(
              t,
              en: 'Service fee',
              ru: 'Сервисный сбор',
              uz: 'Xizmat haqi',
            ),
            value: formatSum(preview.serviceFeeAmount),
          ),
        if (appliedPromotion != null) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: BaseColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.local_offer_outlined,
                  color: BaseColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TypographyText(
                    [
                      if (promoCode?.isNotEmpty == true) promoCode!,
                      if (promoTitle?.isNotEmpty == true) promoTitle!,
                    ].join(' - '),
                    style: const TextStyle(
                      color: BaseColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Divider(height: 1, color: Color(0x1A8C8278)),
        ),
        _PreviewAmountRow(
          label: t.total,
          value: formatSum(preview.totalAmount),
          isTotal: true,
          valueColor: BaseColors.primary,
        ),
      ],
    );
  }
}

class _PreviewAmountRow extends StatelessWidget {
  const _PreviewAmountRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isTotal = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isTotal ? 0 : 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TypographyText(
              label,
              style: TextStyle(
                color: BaseColors.textGray,
                fontSize: isTotal ? 15 : 13,
                fontWeight: isTotal ? FontWeight.w800 : FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          TypographyText(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: isTotal ? 22 : 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

String _mainTabsText(
  L t, {
  required String en,
  required String ru,
  required String uz,
}) {
  return switch (t.localeName.split('_').first) {
    'ru' => ru,
    'uz' => uz,
    _ => en,
  };
}

String _confirmationPaymentLabel(MobilePaymentMethod method, L t) {
  return switch (method) {
    MobilePaymentMethod.cash => _mainTabsText(
      t,
      en: 'Cash',
      ru: 'Наличные',
      uz: 'Naqd',
    ),
    MobilePaymentMethod.cardTerminal => _mainTabsText(
      t,
      en: 'Card terminal',
      ru: 'Терминал',
      uz: 'Terminal',
    ),
    MobilePaymentMethod.payme => 'Payme',
    MobilePaymentMethod.click => 'Click',
    MobilePaymentMethod.unknown => _mainTabsText(
      t,
      en: 'Unknown',
      ru: 'Неизвестно',
      uz: "Noma'lum",
    ),
  };
}

IconData _paymentMethodIcon(MobilePaymentMethod method) {
  return switch (method) {
    MobilePaymentMethod.cash => Icons.payments_outlined,
    MobilePaymentMethod.cardTerminal => Icons.credit_card_rounded,
    MobilePaymentMethod.payme => Icons.account_balance_wallet_outlined,
    MobilePaymentMethod.click => Icons.touch_app_outlined,
    MobilePaymentMethod.unknown => Icons.help_outline_rounded,
  };
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: BaseColors.primary),
      title: TypographyText(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      onTap: onTap,
    );
  }
}
