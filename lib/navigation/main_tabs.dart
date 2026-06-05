import 'dart:async';

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
    setState(() {
      _orderType = type;
      if (type == MobileOrderType.delivery) {
        _selectedBranch = null;
      }
    });
  }

  void _setPickupBranch(BranchModel? branch) {
    setState(() {
      _selectedBranch = branch;
      if (branch != null) {
        _orderType = MobileOrderType.pickup;
      }
    });
  }

  List<CartItemInput> _buildOrderItems(List<CartLine> cartLines) {
    return cartLines
        .map(
          (line) => CartItemInput(
            productId: line.product.id,
            quantity: line.quantity,
          ),
        )
        .toList(growable: false);
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
      ..showSnackBar(SnackBar(content: TypographyText(message)));
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
              selectedCategoryIndex: selectedCategoryIndex,
              categories: categories,
              products: products,
              promotions: promotions,
              orderType: _orderType,
              selectedBranch: _selectedBranch,
              onCategorySelected: _setSelectedCategory,
              onAddToCart: _addToCart,
              onCartTap: () => setState(() => _currentIndex = 1),
              onOrderTypeChanged: _setOrderType,
              onBranchSelected: _setPickupBranch,
              cartCount: totalItems,
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
            const Profile(),
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
