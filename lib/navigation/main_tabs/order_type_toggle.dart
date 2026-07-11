part of 'package:enjoy_lavash_mobile/navigation/main_tabs.dart';

class _OrderTypeToggle extends OrderTypeSlidingToggle {
  const _OrderTypeToggle({
    required super.orderType,
    required super.onDeliveryTap,
    required super.onPickupTap,
    super.deliverySubtitle,
    super.pickupSubtitle,
  });
}

/// A two-option order-type control with one shared selection surface.
///
/// The options never move or resize. Only the surface underneath them travels,
/// keeping both choices easy to target while the state change remains clear.
class OrderTypeSlidingToggle extends StatelessWidget {
  const OrderTypeSlidingToggle({
    super.key,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final duration = AppMotion.duration(context, AppMotion.state);
    final deliverySelected = orderType == MobileOrderType.delivery;

    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF201C19) : const Color(0xFFF0ECE6),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedAlign(
                key: const ValueKey<String>('order-type-selection-surface'),
                alignment: deliverySelected
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                duration: duration,
                curve: AppMotion.standard,
                child: FractionallySizedBox(
                  widthFactor: 0.5,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A2521) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.18 : 0.07,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: _OrderTypeToggleTarget(
                  key: const ValueKey<String>('order-type-delivery-target'),
                  icon: Icons.location_on_rounded,
                  title: t.address,
                  subtitle: deliverySubtitle ?? t.tapToSelectAddress,
                  selected: deliverySelected,
                  duration: duration,
                  onTap: onDeliveryTap,
                ),
              ),
              Expanded(
                child: _OrderTypeToggleTarget(
                  key: const ValueKey<String>('order-type-pickup-target'),
                  icon: Icons.shopping_bag_outlined,
                  title: t.pickup,
                  subtitle: pickupSubtitle ?? t.pickupBranch,
                  selected: !deliverySelected,
                  duration: duration,
                  onTap: onPickupTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderTypeToggleTarget extends StatelessWidget {
  const _OrderTypeToggleTarget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.duration,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final Duration duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Semantics(
        button: true,
        selected: selected,
        label: '$title, $subtitle',
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            customBorder: const StadiumBorder(),
            child: Center(
              child: AnimatedSwitcher(
                duration: duration,
                switchInCurve: AppMotion.enter,
                switchOutCurve: AppMotion.exit,
                layoutBuilder: (currentChild, previousChildren) {
                  return Stack(
                    alignment: Alignment.center,
                    children: <Widget>[...previousChildren, ?currentChild],
                  );
                },
                child: _OrderTypeToggleContent(
                  key: ValueKey<bool>(selected),
                  icon: icon,
                  title: title,
                  subtitle: subtitle,
                  selected: selected,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderTypeToggleContent extends StatelessWidget {
  const _OrderTypeToggleContent({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark ? const Color(0xFF9E9790) : BaseColors.textGray;
    final titleColor = selected ? BaseColors.primary : muted;
    final subtitleColor = selected
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurface.withValues(alpha: 0.72);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: selected ? BaseColors.primary : muted, size: 21),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TypographyText(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: titleColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 1),
                TypographyText(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: subtitleColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
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
