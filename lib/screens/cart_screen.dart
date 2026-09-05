import 'package:enjoy_lavash_mobile/features/models/cart_line.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/utils/price_formatter.dart';
import 'package:enjoy_lavash_mobile/widgets/cart_item_card.dart';
import 'package:enjoy_lavash_mobile/widgets/fade_slide_in.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'package:enjoy_lavash_mobile/theme/app_design_tokens.dart';
import 'package:enjoy_lavash_mobile/widgets/typography.dart';
import 'package:flutter/material.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({
    super.key,
    required this.isDark,
    required this.items,
    required this.totalAmount,
    required this.onDecrease,
    required this.onIncrease,
    required this.onBrowseMenu,
    required this.onCheckout,
    this.isCheckingOut = false,
  });

  final bool isDark;
  final List<CartLine> items;
  final int totalAmount;
  final ValueChanged<CartLine> onDecrease;
  final ValueChanged<CartLine> onIncrease;
  final VoidCallback onBrowseMenu;
  final VoidCallback onCheckout;
  final bool isCheckingOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = L.of(context);
    final totalItems = items.fold<int>(0, (sum, line) => sum + line.quantity);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: items.isEmpty
          ? KeyedSubtree(
              key: const ValueKey<String>('cart-empty'),
              child: _buildEmptyState(context, theme, t),
            )
          : KeyedSubtree(
              key: const ValueKey<String>('cart-content'),
              child: _buildCartContent(context, theme, t, totalItems),
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme, L t) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: FadeSlideIn(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppDesignTokens.primaryText(
                    context,
                  ).withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shopping_bag_outlined,
                  color: AppDesignTokens.tertiaryText(context),
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              TypographyText(
                t.cartEmpty,
                style: AppTextStyles.display(
                  size: 18,
                  height: 1.2,
                  color: AppDesignTokens.primaryText(context),
                ),
              ),
              const SizedBox(height: 8),
              TypographyText(
                t.cartEmptyDesc,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppDesignTokens.secondaryText(context),
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppDesignTokens.ink,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppDesignTokens.radiusPill,
                    ),
                  ),
                ),
                onPressed: onBrowseMenu,
                child: TypographyText(
                  t.browseMenu,
                  style: const TextStyle(color: BaseColors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartContent(
    BuildContext context,
    ThemeData theme,
    L t,
    int totalItems,
  ) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
          child: Row(
            children: <Widget>[
              Material(
                color: AppDesignTokens.surface(context),
                shape: const CircleBorder(),
                child: IconButton(
                  onPressed: onBrowseMenu,
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 17),
                ),
              ),
              const SizedBox(width: 12),
              TypographyText(
                t.cart,
                style: AppTextStyles.display(
                  size: 26,
                  height: 1.15,
                  color: AppDesignTokens.primaryText(context),
                ),
              ),
              const SizedBox(width: 12),
              Semantics(
                label: t.cartItemsCount(totalItems),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutBack,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: Container(
                    key: ValueKey<int>(totalItems),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppDesignTokens.actionSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: TypographyText(
                      '$totalItems',
                      style: const TextStyle(
                        color: AppDesignTokens.action,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            itemCount: items.length,
            findChildIndexCallback: (key) {
              final valueKey = key as ValueKey<String>;
              final index = items.indexWhere(
                (line) => line.key == valueKey.value,
              );
              return index == -1 ? null : index;
            },
            itemBuilder: (context, index) {
              final line = items[index];
              return KeyedSubtree(
                key: ValueKey<String>(line.key),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: FadeSlideIn(
                    child: RepaintBoundary(
                      child: CartItemCard(
                        item: line,
                        isDark: isDark,
                        onDecrease: () => onDecrease(line),
                        onIncrease: () => onIncrease(line),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        _buildCheckoutBar(context, theme, t),
      ],
    );
  }

  Widget _buildCheckoutBar(BuildContext context, ThemeData theme, L t) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppDesignTokens.surface(context),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusCard),
        boxShadow: AppDesignTokens.cardShadow(context),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: TypographyText(
                  t.total,
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFFAAA39A)
                        : BaseColors.textGray,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.35),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: TypographyText(
                      formatSum(context, totalAmount),
                      key: ValueKey<int>(totalAmount),
                      style: AppTextStyles.display(
                        size: 21,
                        height: 1.15,
                        color: AppDesignTokens.primaryText(context),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppDesignTokens.gold,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.stars_rounded,
                  size: 15,
                  color: isDark ? AppDesignTokens.ink : AppDesignTokens.goldInk,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t.loyaltyEarningInfo,
                  style: AppTextStyles.ui(
                    size: 13,
                    weight: FontWeight.w500,
                    color: isDark
                        ? const Color(0xFFF0C763)
                        : AppDesignTokens.goldInk,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDesignTokens.radiusPill),
                boxShadow: AppDesignTokens.actionGlow,
              ),
              child: FilledButton(
                onPressed: isCheckingOut ? null : onCheckout,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(
                        begin: 0.8,
                        end: 1,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: isCheckingOut
                      ? const SizedBox(
                          key: ValueKey<String>('checkout-loading'),
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: BaseColors.white,
                          ),
                        )
                      : Row(
                          key: const ValueKey<String>('checkout-label'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            TypographyText(
                              t.checkout,
                              style: const TextStyle(color: BaseColors.white),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
