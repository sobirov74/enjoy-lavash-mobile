part of 'package:enjoy_lavash_mobile/screens/profile.dart';

class _OrderRow extends StatelessWidget {
  const _OrderRow({
    required this.order,
    required this.locale,
    required this.branches,
    required this.addresses,
  });

  final CustomerOrderModel order;
  final String locale;
  final List<BranchModel> branches;
  final List<ClientAddress> addresses;

  void _showDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _OrderDetailsSheet(
          order: order,
          locale: locale,
          branches: branches,
          addresses: addresses,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final colors = _statusColors(order.status);
    final date = _formatOrderDate(order.createdAt, locale);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = _statusSurfaceColors(order.status, isDark);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: surface.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: surface.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: surface.accent.withValues(alpha: isDark ? 0.12 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showDetails(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: surface.accent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: surface.accent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          TypographyText(
                            '#${_shortOrderId(order.id)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (date.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Row(
                              children: <Widget>[
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 13,
                                  color: BaseColors.textGray,
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: TypographyText(
                                    date,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: BaseColors.textGray,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _OrderStatusChip(
                      label: _statusLabel(order.status, t),
                      colors: colors,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(
                      Icons.fastfood_outlined,
                      size: 17,
                      color: BaseColors.textGray,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: TypographyText(
                        _orderProductSummary(order, t),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0x1A8C8278)),
                const SizedBox(height: 9),
                Row(
                  children: <Widget>[
                    Flexible(
                      child: _OrderMiniBadge(
                        icon: _orderTypeIcon(order.type),
                        label: _orderTypeLabel(order.type, t),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TypographyText(
                      _formatOrderAmount(order.totalAmount),
                      style: const TextStyle(
                        color: BaseColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: BaseColors.textGray,
                      size: 22,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderStatusChip extends StatelessWidget {
  const _OrderStatusChip({required this.label, required this.colors});

  final String label;
  final ({Color bg, Color text}) colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 136),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: TypographyText(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: colors.text,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _OrderMiniBadge extends StatelessWidget {
  const _OrderMiniBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 32),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: BaseColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: BaseColors.primary, size: 16),
          const SizedBox(width: 5),
          Flexible(
            child: TypographyText(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: BaseColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
