import 'package:enjoy_lavash_mobile/features/data/menu_catalog.dart';
import 'package:enjoy_lavash_mobile/features/models/cart_line.dart';
import 'package:enjoy_lavash_mobile/features/models/menu_product.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/screens/cart_screen.dart';
import 'package:enjoy_lavash_mobile/screens/menu_screen.dart';
import 'package:enjoy_lavash_mobile/screens/profile.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'package:enjoy_lavash_mobile/widgets/theme/theme_extensions.dart';
import 'package:enjoy_lavash_mobile/widgets/typography.dart';
import 'package:flutter/material.dart';

class MainTabs extends StatefulWidget {
  const MainTabs({super.key});

  @override
  State<MainTabs> createState() => _MainTabsState();
}

class _MainTabsState extends State<MainTabs> {
  int _currentIndex = 0;
  int _selectedCategoryIndex = 0;
  final Map<String, int> _cart = <String, int>{};

  List<CartLine> get _cartLines {
    return _cart.entries
        .map(
          (entry) => CartLine(
            product: menuProducts.firstWhere(
              (product) => product.id == entry.key,
            ),
            quantity: entry.value,
          ),
        )
        .toList(growable: false);
  }

  int get _totalItems =>
      _cart.values.fold<int>(0, (sum, quantity) => sum + quantity);

  int get _totalAmount => _cartLines.fold<int>(
    0,
    (sum, item) => sum + item.product.price * item.quantity,
  );

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = L.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: <Widget>[
            MenuScreen(
              isDark: isDark,
              selectedCategoryIndex: _selectedCategoryIndex,
              categories: menuCategories,
              products: menuProducts,
              onCategorySelected: _setSelectedCategory,
              onAddToCart: _addToCart,
              cartCount: _totalItems,
            ),
            CartScreen(
              isDark: isDark,
              items: _cartLines,
              totalAmount: _totalAmount,
              onDecrease: (product) => _updateCart(product, -1),
              onIncrease: (product) => _updateCart(product, 1),
              onBrowseMenu: () => setState(() => _currentIndex = 0),
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
                        : (isDark ? const Color(0xFF9E9790) : BaseColors.textGray),
                  );
                }),
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  final isSelected = states.contains(WidgetState.selected);
                  return IconThemeData(
                    color: isSelected
                        ? BaseColors.primary
                        : (isDark ? const Color(0xFF9E9790) : BaseColors.textGray),
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
                    isLabelVisible: _totalItems > 0,
                    label: TypographyText(
                      '$_totalItems',
                      style: TextStyle(color: BaseColors.white, fontSize: 12),
                    ),
                    child: const Icon(Icons.shopping_cart_outlined),
                  ),
                  selectedIcon: Badge(
                    isLabelVisible: _totalItems > 0,
                    label: TypographyText(
                      '$_totalItems',
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
