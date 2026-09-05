part of 'package:enjoy_lavash_mobile/navigation/main_tabs.dart';

class _MainTabsBottomNavigation extends StatelessWidget {
  const _MainTabsBottomNavigation({
    required this.isDark,
    required this.currentIndex,
    required this.totalItems,
    required this.totalAmount,
    required this.notificationUnreadCount,
    required this.showCartPill,
    required this.t,
    required this.onCartTap,
    required this.onDestinationSelected,
  });

  final bool isDark;
  final int currentIndex;
  final int totalItems;
  final int totalAmount;
  final int notificationUnreadCount;
  final bool showCartPill;
  final L t;
  final VoidCallback onCartTap;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AnimatedSize(
          duration: AppMotion.duration(context, AppMotion.state),
          curve: AppMotion.enter,
          child: showCartPill
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: CartPill(
                    itemCount: totalItems,
                    totalLabel: formatSum(context, totalAmount),
                    label: t.cartOpen,
                    onTap: onCartTap,
                  ),
                )
              : const SizedBox.shrink(),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xF01D1A18) : const Color(0xF0F6F3EC),
            border: Border(
              top: BorderSide(color: AppDesignTokens.hairline(context)),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Theme(
              data: theme.copyWith(
                navigationBarTheme: NavigationBarThemeData(
                  height: AppDesignTokens.tabBarHeight,
                  labelTextStyle: WidgetStateProperty.resolveWith((states) {
                    final selected = states.contains(WidgetState.selected);
                    return AppTextStyles.ui(
                      size: 10.5,
                      weight: FontWeight.w600,
                      color: _destinationColor(context, selected),
                    );
                  }),
                  iconTheme: WidgetStateProperty.resolveWith((states) {
                    final selected = states.contains(WidgetState.selected);
                    return IconThemeData(
                      color: _destinationColor(context, selected),
                      size: 22,
                    );
                  }),
                ),
              ),
              child: NavigationBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedIndex: currentIndex.clamp(0, 3),
                indicatorColor: Colors.transparent,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                onDestinationSelected: onDestinationSelected,
                destinations: <NavigationDestination>[
                  NavigationDestination(
                    icon: const Icon(Icons.home_outlined),
                    selectedIcon: const Icon(Icons.home_rounded),
                    label: t.tabHome,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.grid_view_rounded),
                    selectedIcon: const Icon(Icons.grid_view_rounded),
                    label: t.tabMenu,
                  ),
                  NavigationDestination(
                    icon: _NotificationNavigationIcon(
                      unreadCount: notificationUnreadCount,
                      selected: false,
                    ),
                    selectedIcon: _NotificationNavigationIcon(
                      unreadCount: notificationUnreadCount,
                      selected: true,
                    ),
                    label: t.notificationInbox,
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
      ],
    );
  }

  Color _destinationColor(BuildContext context, bool isSelected) {
    if (isSelected) return AppDesignTokens.inkSurface(context);
    return isDark ? const Color(0xFF9E9790) : BaseColors.textGray;
  }
}

class _NotificationNavigationIcon extends StatelessWidget {
  const _NotificationNavigationIcon({
    required this.unreadCount,
    required this.selected,
  });

  final int unreadCount;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Badge(
      backgroundColor: AppDesignTokens.action,
      isLabelVisible: unreadCount > 0,
      label: TypographyText(
        unreadCount > 9 ? '9+' : '$unreadCount',
        style: const TextStyle(color: BaseColors.white, fontSize: 10),
      ),
      child: Icon(
        selected
            ? Icons.notifications_rounded
            : Icons.notifications_none_rounded,
      ),
    );
  }
}
