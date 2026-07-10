part of 'package:enjoy_lavash_mobile/screens/profile.dart';

class _OrderInfoPill extends StatelessWidget {
  const _OrderInfoPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2522) : const Color(0xFFF8F4EF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: BaseColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TypographyText(
                  label,
                  style: const TextStyle(
                    color: BaseColors.textGray,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                TypographyText(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
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

class _OrderDetailSection extends StatelessWidget {
  const _OrderDetailSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2522) : const Color(0xFFF8F4EF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TypographyText(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _OrderProductDetailLine extends StatelessWidget {
  const _OrderProductDetailLine({required this.item});

  final CustomerOrderItemModel item;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final amount = item.amount > 0 ? _formatOrderAmount(item.amount) : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          constraints: const BoxConstraints(minWidth: 34),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: BaseColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: TypographyText(
            '${item.quantity}x',
            style: const TextStyle(
              color: BaseColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TypographyText(
                _orderProductTitle(item, t),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              if (item.comment?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 4),
                TypographyText(
                  item.comment!.trim(),
                  style: const TextStyle(
                    color: BaseColors.textGray,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (amount != null) ...[
          const SizedBox(width: 8),
          TypographyText(
            amount,
            style: const TextStyle(
              color: BaseColors.textGray,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ],
    );
  }
}

class _OrderStatusLogLine extends StatelessWidget {
  const _OrderStatusLogLine({required this.entry, required this.locale});

  final OrderStatusLogModel entry;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final colors = _statusColors(entry.status);
    final changedAt = _formatOrderDateTime(entry.changedAt, locale);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: colors.bg, shape: BoxShape.circle),
          child: Icon(Icons.check_rounded, color: colors.text, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TypographyText(
                _statusLabel(entry.status, t),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (changedAt.isNotEmpty) ...[
                const SizedBox(height: 2),
                TypographyText(
                  changedAt,
                  style: const TextStyle(
                    color: BaseColors.textGray,
                    fontSize: 12,
                  ),
                ),
              ],
              if (entry.comment?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 4),
                TypographyText(
                  entry.comment!.trim(),
                  style: const TextStyle(
                    color: BaseColors.textGray,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _OrderTextDetail extends StatelessWidget {
  const _OrderTextDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TypographyText(
          label,
          style: const TextStyle(
            color: BaseColors.textGray,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        TypographyText(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}
