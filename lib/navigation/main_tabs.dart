import 'dart:async';

import 'package:enjoy_lavash_mobile/app/locale_controller.dart';
import 'package:enjoy_lavash_mobile/app/location_controller.dart';
import 'package:enjoy_lavash_mobile/core/error/result.dart';
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
  bool _isCheckingOut = false;

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
      }
    });

    if (shouldReloadCatalog) {
      _refreshCatalogForBranch(null);
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

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(appSnackBar(message));
  }

  Future<CreateOrderRequest?> _buildCreateOrderRequest(
    List<CartLine> cartLines,
  ) async {
    final t = L.of(context);
    final items = _buildOrderItems(cartLines);

    if (_orderType == MobileOrderType.pickup) {
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
        paymentMethod: MobilePaymentMethod.cash,
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
      items: items,
      paymentMethod: MobilePaymentMethod.cash,
      comment: comment.isEmpty ? null : comment,
    );
  }

  BranchModel? _branchById(List<BranchModel> branches, String? id) {
    final branchId = id?.trim();
    if (branchId == null || branchId.isEmpty) return null;
    for (final branch in branches) {
      if (branch.id == branchId) return branch;
    }
    return null;
  }

  ClientAddress? _addressById(List<ClientAddress> addresses, String? id) {
    final addressId = id?.trim();
    if (addressId == null || addressId.isEmpty) return null;
    for (final address in addresses) {
      if (address.id == addressId) return address;
    }
    return null;
  }

  String _formatClientAddress(ClientAddress address) {
    final parts = <String>[
      if (address.street.trim().isNotEmpty) address.street.trim(),
      if (address.houseNumber?.trim().isNotEmpty == true)
        address.houseNumber!.trim(),
    ];
    if (parts.isEmpty) return address.label.trim();
    return parts.join(', ');
  }

  String? _orderConfirmationDestination(CreateOrderRequest request) {
    final backend = context.read<MobileBackendController>();

    if (request.type == MobileOrderType.pickup) {
      final branch = _branchById(backend.branches, request.branchId);
      if (branch == null) return request.branchId;

      final address = branch.address?.trim();
      if (address == null || address.isEmpty) return branch.name;
      return '${branch.name}\n$address';
    }

    final address = _addressById(backend.addresses, request.addressId);
    if (address != null) return _formatClientAddress(address);

    final location = context.read<LocationController>();
    if (location.fullAddress.trim().isNotEmpty) {
      return location.fullAddress.trim();
    }
    if (location.addressName.trim().isNotEmpty) {
      return location.addressName.trim();
    }
    return null;
  }

  Future<bool> _showOrderConfirmation(
    List<CartLine> cartLines,
    CreateOrderRequest request,
  ) async {
    final destination = _orderConfirmationDestination(request);
    final totalAmount = _calculateTotalAmount(cartLines);
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _OrderConfirmationSheet(
          cartLines: cartLines,
          totalAmount: totalAmount,
          request: request,
          destination: destination,
        );
      },
    );

    return result ?? false;
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

    final request = await _buildCreateOrderRequest(cartLines);
    if (!mounted || request == null) return;

    final confirmed = await _showOrderConfirmation(cartLines, request);
    if (!mounted || !confirmed) return;

    setState(() => _isCheckingOut = true);
    final result = await context.read<MobileBackendController>().createOrder(
      request,
    );
    if (!mounted) return;

    setState(() => _isCheckingOut = false);
    switch (result) {
      case Success():
        setState(() {
          _cart.clear();
          _currentIndex = 2;
        });
        _showSnack(L.of(context).orderCreated);
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
        child: IndexedStack(
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
            Profile(onRefresh: _refreshProfileData),
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

class _OrderConfirmationSheet extends StatelessWidget {
  const _OrderConfirmationSheet({
    required this.cartLines,
    required this.totalAmount,
    required this.request,
    required this.destination,
  });

  final List<CartLine> cartLines;
  final int totalAmount;
  final CreateOrderRequest request;
  final String? destination;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          20 + MediaQuery.paddingOf(context).bottom,
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
                      en: 'Confirm order',
                      ru: 'Подтвердите заказ',
                      uz: 'Buyurtmani tasdiqlang',
                    ),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ConfirmationInfoRow(
              icon: request.type == MobileOrderType.delivery
                  ? Icons.delivery_dining_rounded
                  : Icons.storefront_rounded,
              label: _mainTabsText(
                t,
                en: 'Order type',
                ru: 'Тип заказа',
                uz: 'Buyurtma turi',
              ),
              value: _confirmationOrderTypeLabel(request.type, t),
            ),
            if (destination?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 8),
              _ConfirmationInfoRow(
                icon: request.type == MobileOrderType.delivery
                    ? Icons.location_on_outlined
                    : Icons.storefront_rounded,
                label: request.type == MobileOrderType.delivery
                    ? t.deliveryAddress
                    : t.selectBranch,
                value: destination!.trim(),
              ),
            ],
            const SizedBox(height: 8),
            _ConfirmationInfoRow(
              icon: Icons.payments_outlined,
              label: _mainTabsText(
                t,
                en: 'Payment',
                ru: 'Оплата',
                uz: "To'lov",
              ),
              value: _confirmationPaymentLabel(request.paymentMethod, t),
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
                  for (int i = 0; i < cartLines.length; i++) ...[
                    _ConfirmationItemRow(line: cartLines[i]),
                    if (i < cartLines.length - 1)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(height: 1, color: Color(0x1A8C8278)),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: TypographyText(
                    t.total,
                    style: const TextStyle(
                      color: BaseColors.textGray,
                      fontSize: 15,
                    ),
                  ),
                ),
                TypographyText(
                  formatSum(totalAmount),
                  style: const TextStyle(
                    color: BaseColors.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
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
                    onPressed: () => Navigator.of(context).pop(false),
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
                    onPressed: () => Navigator.of(context).pop(true),
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

class _ConfirmationInfoRow extends StatelessWidget {
  const _ConfirmationInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2522) : const Color(0xFFF8F4EF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: BaseColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TypographyText(
                  label,
                  style: const TextStyle(
                    color: BaseColors.textGray,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                TypographyText(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
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

String _confirmationOrderTypeLabel(MobileOrderType type, L t) {
  return switch (type) {
    MobileOrderType.delivery => t.delivery,
    MobileOrderType.pickup => t.pickup,
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
