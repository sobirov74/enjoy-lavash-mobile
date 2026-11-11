part of 'package:enjoy_lavash_mobile/navigation/main_tabs.dart';

/// The backend fields the menu renders; the loading flag and failure only
/// matter while there is no catalog yet.
typedef _MenuData = ({
  List<String> categories,
  List<MenuProduct> products,
  bool isLoading,
  Failure? failure,
});

/// The Menu tab. It selects only the catalog state and listens to the
/// category filter itself, so a category tap rebuilds the menu alone; cart
/// quantities reach each card through [cart] without rebuilding the menu.
class _MenuTab extends StatelessWidget {
  const _MenuTab({
    required this.isDark,
    required this.selectedCategory,
    required this.cart,
    required this.active,
    required this.orderType,
    required this.selectedBranch,
    required this.cartTargetKey,
    required this.onCategorySelected,
    required this.onAddToCart,
    required this.onAddConfiguredToCart,
    required this.onDecreaseFromCart,
    required this.onCartTap,
    required this.onOrderContextTap,
    required this.onCartArrival,
    required this.onOrderTypeChanged,
    required this.onBranchSelected,
    required this.onRefresh,
    required this.onRetryMenu,
  });

  final bool isDark;
  final ValueListenable<int> selectedCategory;
  final CartController cart;
  final ValueListenable<bool> active;
  final MobileOrderType orderType;
  final BranchModel? selectedBranch;
  final GlobalKey cartTargetKey;
  final ValueChanged<int> onCategorySelected;
  final ValueChanged<MenuProduct> onAddToCart;
  final ValueChanged<CartSelection> onAddConfiguredToCart;
  final ValueChanged<MenuProduct> onDecreaseFromCart;
  final VoidCallback onCartTap;
  final VoidCallback onOrderContextTap;
  final VoidCallback onCartArrival;
  final ValueChanged<MobileOrderType> onOrderTypeChanged;
  final Future<void> Function(BranchModel?) onBranchSelected;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetryMenu;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final menu = context.select<MobileBackendController, _MenuData>((backend) {
      final products = backend.menuProducts;
      return (
        categories: backend.menuCategories,
        products: products,
        isLoading:
            backend.status == MobileBackendStatus.loading && products.isEmpty,
        failure: backend.status == MobileBackendStatus.error && products.isEmpty
            ? backend.failure
            : null,
      );
    });
    final failure = menu.failure;
    final categories = menu.categories;

    return ValueListenableBuilder<int>(
      valueListenable: selectedCategory,
      builder: (context, selected, _) => MenuScreen(
        isDark: isDark,
        isMenuLoading: menu.isLoading,
        menuErrorText: failure == null ? null : failureDetail(t, failure),
        menuFailure: failure,
        selectedCategoryIndex: categories.isEmpty
            ? -1
            : selected.clamp(-1, categories.length - 1),
        categories: categories,
        products: menu.products,
        orderType: orderType,
        selectedBranch: selectedBranch,
        onCategorySelected: onCategorySelected,
        onAddToCart: onAddToCart,
        onAddConfiguredToCart: onAddConfiguredToCart,
        onDecreaseFromCart: onDecreaseFromCart,
        onCartTap: onCartTap,
        onOrderContextTap: onOrderContextTap,
        showCartSummary: false,
        active: active,
        cartTargetKey: cartTargetKey,
        onCartArrival: onCartArrival,
        onOrderTypeChanged: onOrderTypeChanged,
        onBranchSelected: onBranchSelected,
        onRefresh: onRefresh,
        onRetryMenu: onRetryMenu,
        cart: cart,
      ),
    );
  }
}
