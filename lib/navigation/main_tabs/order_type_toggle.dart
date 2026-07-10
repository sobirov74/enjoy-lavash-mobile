part of 'package:enjoy_lavash_mobile/navigation/main_tabs.dart';

class _OrderTypeToggle extends StatelessWidget {
  const _OrderTypeToggle({
    required this.orderType,
    required this.onDeliveryTap,
    required this.onPickupTap,
    this.deliverySubtitle,
    this.pickupSubtitle,
  });

  final MobileOrderType orderType;
  final VoidCallback onDeliveryTap;
  final VoidCallback onPickupTap;
  final String? deliverySubtitle;
  final String? pickupSubtitle;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
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
              onTap: onDeliveryTap,
              child: DeliveryChip(
                icon: Icons.location_on_rounded,
                title: t.address,
                subtitle: deliverySubtitle ?? t.tapToSelectAddress,
                active: orderType == MobileOrderType.delivery,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: GestureDetector(
              onTap: onPickupTap,
              child: DeliveryChip(
                icon: Icons.shopping_bag_outlined,
                title: t.pickup,
                subtitle: pickupSubtitle ?? t.pickupBranch,
                active: orderType == MobileOrderType.pickup,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
