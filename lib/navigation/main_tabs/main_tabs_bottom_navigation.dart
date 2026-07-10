part of 'package:enjoy_lavash_mobile/navigation/main_tabs.dart';

class _MainTabsBottomNavigation extends StatelessWidget {
  const _MainTabsBottomNavigation({
    required this.theme,
    required this.isDark,
    required this.currentIndex,
    required this.totalItems,
    required this.t,
    required this.onDestinationSelected,
  });

  final ThemeData theme;
  final bool isDark;
  final int currentIndex;
  final int totalItems;
  final L t;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
                  color: _destinationColor(isSelected),
                );
              }),
              iconTheme: WidgetStateProperty.resolveWith((states) {
                final isSelected = states.contains(WidgetState.selected);
                return IconThemeData(color: _destinationColor(isSelected));
              }),
            ),
          ),
          child: NavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedIndex: currentIndex,
            indicatorColor: isDark
                ? BaseColors.primary.withValues(alpha: 0.16)
                : BaseColors.primary.withValues(alpha: 0.12),
            onDestinationSelected: onDestinationSelected,
            destinations: <NavigationDestination>[
              NavigationDestination(
                icon: const Icon(Icons.restaurant_menu_outlined),
                selectedIcon: const Icon(Icons.restaurant_menu),
                label: t.tabMenu,
              ),
              NavigationDestination(
                icon: _CartNavigationIcon(
                  totalItems: totalItems,
                  selected: false,
                ),
                selectedIcon: _CartNavigationIcon(
                  totalItems: totalItems,
                  selected: true,
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
    );
  }

  Color _destinationColor(bool isSelected) {
    if (isSelected) return BaseColors.primary;
    return isDark ? const Color(0xFF9E9790) : BaseColors.textGray;
  }
}

class _CartNavigationIcon extends StatelessWidget {
  const _CartNavigationIcon({
    required this.totalItems,
    required this.selected,
  });

  final int totalItems;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Badge(
      backgroundColor: selected ? null : context.colors.danger,
      isLabelVisible: totalItems > 0,
      label: TypographyText(
        '$totalItems',
        style: const TextStyle(color: BaseColors.white, fontSize: 12),
      ),
      child: Icon(
        selected ? Icons.shopping_cart : Icons.shopping_cart_outlined,
      ),
    );
  }
}
