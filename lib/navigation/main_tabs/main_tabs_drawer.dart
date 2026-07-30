part of 'package:enjoy_lavash_mobile/navigation/main_tabs.dart';

class _MainTabsDrawer extends StatelessWidget {
  const _MainTabsDrawer({
    required this.isDark,
    required this.t,
    required this.onTabSelected,
    required this.onNotificationsTap,
    required this.onPromotionsTap,
    required this.onOrdersTap,
    required this.onShareApp,
  });

  final bool isDark;
  final L t;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onNotificationsTap;
  final VoidCallback onPromotionsTap;
  final VoidCallback onOrdersTap;
  final VoidCallback onShareApp;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: isDark ? const Color(0xFF1D1A18) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const _MainTabsDrawerHeader(),
            Divider(
              color: isDark ? const Color(0xFF2A2522) : const Color(0xFFE0DBD5),
              height: 1,
            ),
            const SizedBox(height: 8),
            _MainTabsDrawerItem(
              icon: Icons.restaurant_menu_rounded,
              title: t.tabMenu,
              onTap: () => _selectTab(context, 0),
            ),
            _MainTabsDrawerItem(
              icon: Icons.shopping_cart_rounded,
              title: t.tabCart,
              onTap: () => _selectTab(context, 1),
            ),
            _MainTabsDrawerItem(
              icon: Icons.person_rounded,
              title: t.tabProfile,
              onTap: () => _selectTab(context, 2),
            ),
            _MainTabsDrawerItem(
              icon: Icons.notifications_rounded,
              title: t.notifications,
              onTap: () => _openPage(context, onNotificationsTap),
            ),
            _MainTabsDrawerItem(
              icon: Icons.local_offer_rounded,
              title: t.myPromotions,
              onTap: () => _openPage(context, onPromotionsTap),
            ),
            _MainTabsDrawerItem(
              icon: Icons.receipt_long_rounded,
              title: t.allOrders,
              onTap: () => _openPage(context, onOrdersTap),
            ),
            const Spacer(),
            Divider(
              color: isDark ? const Color(0xFF2A2522) : const Color(0xFFE0DBD5),
              height: 1,
            ),
            _MainTabsDrawerItem(
              icon: Icons.share_rounded,
              title: t.shareApp,
              onTap: () {
                Navigator.pop(context);
                onShareApp();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _selectTab(BuildContext context, int index) {
    Navigator.pop(context);
    onTabSelected(index);
  }

  void _openPage(BuildContext context, VoidCallback onTap) {
    Navigator.pop(context);
    onTap();
  }
}

class _MainTabsDrawerHeader extends StatelessWidget {
  const _MainTabsDrawerHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Row(
        children: <Widget>[
          Image.asset('assets/images/enjoy-logo.png', height: 28),
          const SizedBox(width: 12),
          const TypographyText(
            'Enjoy Lavash',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.9,
            ),
          ),
        ],
      ),
    );
  }
}

class _MainTabsDrawerItem extends StatelessWidget {
  const _MainTabsDrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
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
