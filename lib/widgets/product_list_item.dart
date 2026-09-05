import 'package:enjoy_lavash_mobile/features/models/menu_product.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/theme/app_motion.dart';
import 'package:enjoy_lavash_mobile/theme/app_design_tokens.dart';
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
    final t = L.of(context);
    final description = product.description?.trim();
    final metadata = <String>[
      if (product.calories != null) t.caloriesLabel(product.calories!),
      if (product.weightGrams != null) t.weightGramsLabel(product.weightGrams!),
    ];
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppDesignTokens.surface(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppDesignTokens.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          GestureDetector(
            onTap: onImageTap,
            child: imageHeroTag == null
                ? ProductImage(
                    product: product,
                    width: double.infinity,
                    height: 106,
                    borderRadius: AppDesignTokens.radiusThumb,
                    fallbackFontSize: 44,
                  )
                : Hero(
                    tag: imageHeroTag!,
                    createRectTween: (begin, end) =>
                        MaterialRectCenterArcTween(begin: begin, end: end),
                    child: ProductImage(
                      product: product,
                      width: double.infinity,
                      height: 106,
                      borderRadius: AppDesignTokens.radiusThumb,
                      fallbackFontSize: 44,
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TypographyText(
                  product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.ui(
                    size: 15,
                    height: 1.22,
                    weight: FontWeight.w600,
                    color: AppDesignTokens.primaryText(context),
                  ),
                ),
                const SizedBox(height: 4),
                TypographyText(
                  description?.isNotEmpty == true
                      ? description!
                      : product.category,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.ui(
                    size: 11.5,
                    color: AppDesignTokens.tertiaryText(context),
                  ),
                ),
                if (metadata.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 4),
                  TypographyText(
                    metadata.join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.ui(
                      size: 11,
                      weight: FontWeight.w600,
                      color: AppDesignTokens.secondaryText(context),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                if (quantity <= 0)
                  Row(
                    children: <Widget>[
                      Expanded(child: _ProductPrice(product: product)),
                      const SizedBox(width: 6),
                      _ProductQuantityControl(
                        isDark: isDark,
                        quantity: quantity,
                        onAdd: onAdd,
                        onAddOrigin: onAddOrigin,
                        onDecrease: onDecrease,
                        onIncrease: onIncrease,
                      ),
                    ],
                  )
                else ...<Widget>[
                  _ProductPrice(product: product),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _ProductQuantityControl(
                      isDark: isDark,
                      quantity: quantity,
                      onAdd: onAdd,
                      onAddOrigin: onAddOrigin,
                      onDecrease: onDecrease,
                      onIncrease: onIncrease,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductPrice extends StatelessWidget {
  const _ProductPrice({required this.product});

  final MenuProduct product;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      alignment: Alignment.centerLeft,
      fit: BoxFit.scaleDown,
      child: TypographyText(
        formatSum(context, product.price),
        maxLines: 1,
        style: AppTextStyles.display(
          size: 18,
          height: 1.15,
          color: AppDesignTokens.primaryText(context),
        ),
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
      width: quantity <= 0 ? 48 : 132,
      height: 48,
      child: AnimatedSwitcher(
        duration: AppMotion.duration(context, AppMotion.micro),
        switchInCurve: AppMotion.enter,
        switchOutCurve: AppMotion.exit,
        child: quantity <= 0
            ? Align(
                key: const ValueKey<String>('add'),
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Builder(
                    builder: (buttonContext) => FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: isDark
                            ? AppDesignTokens.action.withValues(alpha: 0.18)
                            : AppDesignTokens.actionSoft,
                        foregroundColor: isDark
                            ? const Color(0xFFFF8A80)
                            : AppDesignTokens.action,
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        shape: const CircleBorder(),
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
                      child: const Icon(Icons.add_rounded, size: 20),
                    ),
                  ),
                ),
              )
            : SizedBox(
                key: const ValueKey<String>('stepper'),
                width: 132,
                height: 48,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    QuantityButton(
                      icon: Icons.remove_rounded,
                      onTap: onDecrease,
                    ),
                    Expanded(child: AnimatedQuantityText(quantity: quantity)),
                    QuantityButton(
                      icon: Icons.add_rounded,
                      onTap: onIncrease,
                      emphasized: true,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
