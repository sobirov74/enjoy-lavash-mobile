import 'package:enjoy_lavash_mobile/features/models/menu_product.dart';
import 'package:enjoy_lavash_mobile/utils/price_formatter.dart';
import 'package:enjoy_lavash_mobile/widgets/product_image.dart';
import 'package:enjoy_lavash_mobile/widgets/quantity_button.dart';
import 'package:enjoy_lavash_mobile/widgets/typography.dart';
import 'package:flutter/material.dart';

class ProductListItem extends StatelessWidget {
  const ProductListItem({
    super.key,
    required this.product,
    required this.isDark,
    required this.quantity,
    required this.onAdd,
    required this.onDecrease,
    required this.onIncrease,
    this.onImageTap,
  });

  final MenuProduct product;
  final bool isDark;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback? onImageTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D1A18) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GestureDetector(
            onTap: onImageTap,
            child: ProductImage(product: product),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TypographyText(
                  product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.6,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                TypographyText(
                  product.category,
                  style: TextStyle(
                    color: isDark ? const Color(0xFFAAA39A) : Colors.black54,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: FittedBox(
                        alignment: Alignment.centerLeft,
                        fit: BoxFit.scaleDown,
                        child: TypographyText(
                          formatSum(product.price),
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _ProductQuantityControl(
                      isDark: isDark,
                      quantity: quantity,
                      onAdd: onAdd,
                      onDecrease: onDecrease,
                      onIncrease: onIncrease,
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

class _ProductQuantityControl extends StatelessWidget {
  const _ProductQuantityControl({
    required this.isDark,
    required this.quantity,
    required this.onAdd,
    required this.onDecrease,
    required this.onIncrease,
  });

  final bool isDark;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 116,
      height: 44,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 160),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: quantity <= 0
            ? Align(
                key: const ValueKey<String>('add'),
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 56,
                  height: 44,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFF2B2622)
                          : const Color(0xFFF6F3EF),
                      foregroundColor: isDark
                          ? Colors.white
                          : const Color(0xFF14110F),
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: onAdd,
                    child: const Icon(Icons.add_rounded, size: 24),
                  ),
                ),
              )
            : Row(
                key: const ValueKey<String>('stepper'),
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  QuantityButton(icon: Icons.remove_rounded, onTap: onDecrease),
                  SizedBox(
                    width: 40,
                    child: TypographyText(
                      '$quantity',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  QuantityButton(
                    icon: Icons.add_rounded,
                    onTap: onIncrease,
                    emphasized: true,
                  ),
                ],
              ),
      ),
    );
  }
}
