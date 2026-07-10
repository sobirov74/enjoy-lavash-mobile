part of 'package:enjoy_lavash_mobile/navigation/main_tabs.dart';

class _OrderItemsSection extends StatelessWidget {
  const _OrderItemsSection({required this.cartLines});

  final List<CartLine> cartLines;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
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
            t.orderItems,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < cartLines.length; i++) ...[
            _ConfirmationItemRow(line: cartLines[i]),
            if (i < cartLines.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: Color(0x1A8C8278)),
              ),
          ],
        ],
      ),
    );
  }
}

class _ConfirmationItemRow extends StatelessWidget {
  const _ConfirmationItemRow({required this.line});

  final CartLine line;

  @override
  Widget build(BuildContext context) {
    final subtotal = line.product.price * line.quantity;

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
            '${line.quantity}x',
            style: const TextStyle(
              color: BaseColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TypographyText(
            line.product.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
        ),
        const SizedBox(width: 8),
        TypographyText(
          formatSum(subtotal),
          style: const TextStyle(
            color: BaseColors.textGray,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
