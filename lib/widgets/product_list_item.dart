import 'package:enjoy_lavash_mobile/features/models/menu_product.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/theme/app_motion.dart';
import 'package:enjoy_lavash_mobile/theme/app_design_tokens.dart';
import 'package:enjoy_lavash_mobile/utils/price_formatter.dart';
import 'package:enjoy_lavash_mobile/widgets/product_image.dart';
import 'package:enjoy_lavash_mobile/widgets/quantity_button.dart';
import 'package:enjoy_lavash_mobile/widgets/typography.dart';
import 'package:flutter/material.dart';
import 'package:enjoy_lavash_mobile/widgets/cart_animation/cart_animation_source.dart';

class ProductListItem extends StatefulWidget {
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
    this.onAddRequested,
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
  final void Function(CartAnimationSource? source)? onAddRequested;

  @override
  State<ProductListItem> createState() => _ProductListItemState();
}

class _ProductListItemState extends State<ProductListItem> {
  final _imageKey = GlobalKey<CartAnimationAnchorState>();

  void _add(VoidCallback legacy) {
    final callback = widget.onAddRequested;
    if (callback == null) {
      legacy();
    } else {
      callback(_imageKey.currentState?.capture());
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final isDark = widget.isDark;
    final quantity = widget.quantity;
    final onImageTap = widget.onImageTap;
    final imageHeroTag = widget.imageHeroTag;
    final onAddOrigin = widget.onAddOrigin;
    final onDecrease = widget.onDecrease;
    void onAdd() => _add(widget.onAdd);
    void onIncrease() => _add(widget.onIncrease);
    final image = CartAnimationAnchor(
      key: _imageKey,
      child: ProductImage(
        product: product,
        width: double.infinity,
        height: 106,
        borderRadius: AppDesignTokens.radiusThumb,
        fallbackFontSize: 44,
      ),
    );
    final t = L.of(context);
    final description = product.description?.trim();
    final metadata = <String>[
      if (product.calories != null) t.caloriesLabel(product.calories!),
      if (product.weightGrams != null) t.weightGramsLabel(product.weightGrams!),
    ];
    final textScaler = MediaQuery.textScalerOf(context);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppDesignTokens.surface(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppDesignTokens.cardShadow(context),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          GestureDetector(
            onTap: onImageTap,
            child: imageHeroTag == null
                ? image
                : Hero(
                    tag: imageHeroTag,
                    createRectTween: (begin, end) =>
                        MaterialRectCenterArcTween(begin: begin, end: end),
                    child: image,
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _ProductTextSlot(
                  text: product.title,
                  maxLines: 2,
                  style: AppTextStyles.ui(
                    size: 15,
                    height: 1.22,
                    weight: FontWeight.w600,
                    color: AppDesignTokens.primaryText(context),
                  ),
                ),
                const SizedBox(height: 4),
                _ProductTextSlot(
                  text: description?.isNotEmpty == true
                      ? description!
                      : product.category,
                  maxLines: 2,
                  style: AppTextStyles.ui(
                    size: 11.5,
                    height: 1.3,
                    color: AppDesignTokens.tertiaryText(context),
                  ),
                ),
                const SizedBox(height: 4),
                _ProductTextSlot(
                  text: metadata.join(' · '),
                  maxLines: 1,
                  style: AppTextStyles.ui(
                    size: 11,
                    height: 1.3,
                    weight: FontWeight.w600,
                    color: AppDesignTokens.secondaryText(context),
                  ),
                ),
                const SizedBox(height: 8),
                // Both quantity states use the same footer. Adding a product
                // must not change the card height or move neighbouring cards.
                SizedBox(
                  height: (textScaler.scale(18) * 1.15).ceilToDouble() + 2,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _ProductPrice(product: product),
                  ),
                ),
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
            ),
          ),
        ],
      ),
    );
  }
}

/// Reserve the same number of lines for every card, including empty metadata.
/// The slots grow together with the system text size instead of clipping text
/// to a fixed overall card height.
class _ProductTextSlot extends StatelessWidget {
  const _ProductTextSlot({
    required this.text,
    required this.style,
    required this.maxLines,
  });

  final String text;
  final TextStyle style;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final lineHeight =
        MediaQuery.textScalerOf(context).scale(style.fontSize!) * style.height!;
    return SizedBox(
      height: (lineHeight * maxLines).ceilToDouble() + 2,
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: text.isEmpty
            ? null
            : TypographyText(
                text,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
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
    return CartAddFeedback(
      child: SizedBox(
        // Keep room for the outgoing stepper while it fades back to Add.
        width: 132,
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
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: AnimatedQuantityText(quantity: quantity),
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
        ),
      ),
    );
  }
}
