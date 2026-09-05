import 'package:enjoy_lavash_mobile/features/models/cart_line.dart';
import 'package:enjoy_lavash_mobile/utils/price_formatter.dart';
import 'package:enjoy_lavash_mobile/widgets/product_image.dart';
import 'package:enjoy_lavash_mobile/widgets/quantity_button.dart';
import 'package:enjoy_lavash_mobile/theme/app_design_tokens.dart';
import 'package:enjoy_lavash_mobile/widgets/typography.dart';
import 'package:flutter/material.dart';

class CartItemCard extends StatelessWidget {
  const CartItemCard({
    super.key,
    required this.item,
    required this.isDark,
    required this.onDecrease,
    required this.onIncrease,
  });

  final CartLine item;
  final bool isDark;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppDesignTokens.surface(context),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusCard),
        boxShadow: AppDesignTokens.cardShadow(context),
      ),
      child: Row(
        children: <Widget>[
          ProductImage(
            product: item.product,
            width: 52,
            height: 52,
            borderRadius: AppDesignTokens.radiusThumb,
            fallbackFontSize: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TypographyText(
                  item.product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.ui(
                    size: 15,
                    weight: FontWeight.w600,
                    color: AppDesignTokens.primaryText(context),
                  ),
                ),
                const SizedBox(height: 4),
                TypographyText(
                  item.modifierSummary.isEmpty
                      ? formatSum(context, item.unitPrice)
                      : item.modifierSummary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.ui(
                    size: item.modifierSummary.isEmpty ? 14.5 : 11.5,
                    color: item.modifierSummary.isEmpty
                        ? AppDesignTokens.primaryText(context)
                        : AppDesignTokens.tertiaryText(context),
                    weight: item.modifierSummary.isEmpty
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
                if (item.modifierSummary.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 3),
                  TypographyText(
                    formatSum(context, item.unitPrice),
                    style: AppTextStyles.ui(
                      size: 14.5,
                      color: AppDesignTokens.primaryText(context),
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    QuantityButton(
                      icon: Icons.remove_rounded,
                      onTap: onDecrease,
                    ),
                    SizedBox(
                      width: 42,
                      child: AnimatedQuantityText(quantity: item.quantity),
                    ),
                    QuantityButton(
                      icon: Icons.add_rounded,
                      onTap: onIncrease,
                      emphasized: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
