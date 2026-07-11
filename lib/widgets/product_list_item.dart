import 'package:enjoy_lavash_mobile/features/models/menu_product.dart';
import 'package:enjoy_lavash_mobile/theme/app_motion.dart';
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
    this.onAddOrigin,
    this.imageHeroTag,
  });

  final MenuProduct product;
  final bool isDark;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback? onImageTap;
  final ValueChanged<Rect>? onAddOrigin;
  final Object? imageHeroTag;

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
            child: imageHeroTag == null
                ? ProductImage(product: product)
                : Hero(
                    tag: imageHeroTag!,
                    createRectTween: (begin, end) =>
                        MaterialRectCenterArcTween(begin: begin, end: end),
                    child: ProductImage(product: product),
                  ),
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
                      onAddOrigin: onAddOrigin,
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
    this.onAddOrigin,
  });

  final bool isDark;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final ValueChanged<Rect>? onAddOrigin;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 116,
      height: 44,
      child: AnimatedSwitcher(
        duration: AppMotion.duration(context, AppMotion.micro),
        switchInCurve: AppMotion.enter,
        switchOutCurve: AppMotion.exit,
        child: quantity <= 0
            ? Align(
                key: const ValueKey<String>('add'),
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 56,
                  height: 44,
                  child: Builder(
                    builder: (buttonContext) => FilledButton(
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
                      onPressed: () {
                        final renderObject = buttonContext.findRenderObject();
                        final origin =
                            renderObject is RenderBox && renderObject.hasSize
                            ? renderObject.localToGlobal(Offset.zero) &
                                  renderObject.size
                            : null;

                        // State changes immediately. The optional origin is
                        // only decorative feedback and never gates the add.
                        onAdd();
                        if (origin != null) onAddOrigin?.call(origin);
                      },
                      child: const Icon(Icons.add_rounded, size: 24),
                    ),
                  ),
                ),
              )
            : Row(
                key: const ValueKey<String>('stepper'),
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  QuantityButton(icon: Icons.remove_rounded, onTap: onDecrease),
                  Expanded(child: AnimatedQuantityText(quantity: quantity)),
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
