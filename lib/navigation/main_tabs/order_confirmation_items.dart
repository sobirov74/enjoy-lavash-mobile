part of 'package:enjoy_lavash_mobile/navigation/main_tabs.dart';

class _OrderItemsSection extends StatelessWidget {
  const _OrderItemsSection({
    required this.cartLines,
    this.previewItems = const <PricedCartItemModel>[],
  });

  final List<CartLine> cartLines;
  final List<PricedCartItemModel> previewItems;

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
          if (previewItems.isNotEmpty)
            for (int i = 0; i < previewItems.length; i++) ...[
              _PreviewConfirmationItemRow(item: previewItems[i]),
              if (i < previewItems.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1, color: Color(0x1A8C8278)),
                ),
            ]
          else
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

class _PreviewConfirmationItemRow extends StatelessWidget {
  const _PreviewConfirmationItemRow({required this.item});

  final PricedCartItemModel item;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final modifierSummary = item.modifiers
        .map((modifier) {
          final name = modifier.nameFor(language);
          return modifier.quantity > 1 ? '$name ×${modifier.quantity}' : name;
        })
        .join(' · ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          constraints: const BoxConstraints(minWidth: 34),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: item.isBonus
                ? AppDesignTokens.successWash
                : BaseColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: TypographyText(
            '${item.quantity}x',
            style: TextStyle(
              color: item.isBonus
                  ? AppDesignTokens.successText(context)
                  : BaseColors.primary,
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
                item.nameFor(language),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              if (modifierSummary.isNotEmpty) ...<Widget>[
                const SizedBox(height: 3),
                TypographyText(
                  modifierSummary,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppDesignTokens.secondaryText(context),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        TypographyText(
          item.isBonus ? t.promotionGift : formatSum(context, item.totalPrice),
          style: TextStyle(
            color: item.isBonus
                ? AppDesignTokens.successText(context)
                : BaseColors.textGray,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ConfirmationItemRow extends StatelessWidget {
  const _ConfirmationItemRow({required this.line});

  final CartLine line;

  @override
  Widget build(BuildContext context) {
    final subtotal = line.lineTotal;

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
          formatSum(context, subtotal),
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
