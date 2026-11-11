part of 'package:enjoy_lavash_mobile/navigation/main_tabs.dart';

/// The backend fields Home renders. Lists compare by identity because the
/// controller replaces them; the last order is the first one in history.
typedef _HomeData = ({
  String? fullName,
  int loyaltyBalance,
  List<MenuCategory> categories,
  List<MenuProduct> products,
  List<BannerModel> banners,
  int notificationUnreadCount,
  CustomerOrderModel? lastOrder,
  bool isLoading,
  Failure? failure,
});

/// The Home tab. It selects only what [HomeScreen] shows, so cart taps, tab
/// switches and unrelated backend updates do not rebuild it.
class _HomeTab extends StatelessWidget {
  const _HomeTab({
    required this.orderType,
    required this.selectedBranch,
    required this.onBannerLinkTap,
    required this.onOrderContextTap,
    required this.onNotificationsTap,
    required this.onLoyaltyTap,
    required this.onMenuTap,
    required this.onCategoryTap,
    required this.onRepeatOrder,
    required this.onRefresh,
  });

  final MobileOrderType orderType;
  final BranchModel? selectedBranch;
  final ValueChanged<Uri> onBannerLinkTap;
  final VoidCallback onOrderContextTap;
  final VoidCallback onNotificationsTap;
  final VoidCallback onLoyaltyTap;
  final VoidCallback onMenuTap;
  final ValueChanged<int> onCategoryTap;
  final ValueChanged<CustomerOrderModel> onRepeatOrder;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final home = context.select<MobileBackendController, _HomeData>((backend) {
      final products = backend.menuProducts;
      final orders = backend.orders;
      return (
        fullName: backend.client?.fullName,
        loyaltyBalance:
            backend.loyaltyWallet?.spendableBalance ??
            backend.client?.bonusBalance ??
            0,
        categories: backend.menuCategoryItems,
        products: products,
        banners: backend.banners,
        notificationUnreadCount: backend.notificationUnreadCount,
        lastOrder: orders.isEmpty ? null : orders.first,
        isLoading:
            backend.status == MobileBackendStatus.loading && products.isEmpty,
        failure: backend.status == MobileBackendStatus.error && products.isEmpty
            ? backend.failure
            : null,
      );
    });
    final locale = context.select<LocaleController, String>(
      (controller) => controller.locale.languageCode,
    );
    final lastOrder = home.lastOrder;

    return HomeScreen(
      customerName: _homeCustomerName(home.fullName, t),
      loyaltyBalance: home.loyaltyBalance,
      orderModeLabel: orderType == MobileOrderType.delivery
          ? t.delivery
          : t.pickup,
      orderContextLabel: _orderContextLabel(context, t),
      categories: home.categories,
      products: home.products,
      banners: home.banners,
      onBannerLinkTap: onBannerLinkTap,
      locale: locale,
      notificationUnreadCount: home.notificationUnreadCount,
      lastOrder: lastOrder,
      isLoading: home.isLoading,
      failure: home.failure,
      onOrderContextTap: onOrderContextTap,
      onNotificationsTap: onNotificationsTap,
      onLoyaltyTap: onLoyaltyTap,
      onMenuTap: onMenuTap,
      onCategoryTap: onCategoryTap,
      onRepeatOrder: lastOrder == null ? null : () => onRepeatOrder(lastOrder),
      onRefresh: onRefresh,
    );
  }

  /// Pickup shows the branch; delivery the picked point or, when nothing was
  /// picked on this device, the default saved address. Only the inputs that
  /// matter for the current mode are listened to.
  String _orderContextLabel(BuildContext context, L t) {
    if (orderType == MobileOrderType.pickup) {
      final branchName = selectedBranch?.name.trim();
      return branchName?.isNotEmpty == true ? branchName! : t.pickupBranch;
    }
    final (addressName, fullAddress) = context
        .select<LocationController, (String, String)>(
          (location) => (location.addressName, location.fullAddress),
        );
    final picked = _trimmedText(fullAddress) ?? _trimmedText(addressName);
    if (picked != null) return picked;
    final savedAddresses = context
        .select<MobileBackendController, List<ClientAddress>>(
          (backend) => backend.addresses,
        );
    return _deliveryAddressText(
          addressName: addressName,
          fullAddress: fullAddress,
          savedAddresses: savedAddresses,
        ) ??
        t.tapToSelectAddress;
  }
}

String _homeCustomerName(String? fullName, L t) {
  final name = fullName?.trim();
  if (name == null || name.isEmpty) return t.guest;
  return name.split(RegExp(r'\s+')).first;
}
