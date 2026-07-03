import 'package:enjoy_lavash_mobile/features/models/cart_line.dart';
import 'package:enjoy_lavash_mobile/features/models/menu_product.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/utils/price_formatter.dart';
import 'package:enjoy_lavash_mobile/widgets/cart_item_card.dart';
import 'package:enjoy_lavash_mobile/widgets/fade_slide_in.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
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
  final ValueChanged<MenuProduct> onDecrease;
  final ValueChanged<MenuProduct> onIncrease;
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
              child: _buildEmptyState(theme, t),
            )
          : KeyedSubtree(
              key: const ValueKey<String>('cart-content'),
              child: _buildCartContent(theme, t, totalItems),
            ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, L t) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: FadeSlideIn(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 104,
                height: 104,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: BaseColors.surfaceTint,
                  shape: BoxShape.circle,
                ),
                child: const TypographyText(
                  '🛒',
                  style: TextStyle(fontSize: 46),
                ),
              ),
              const SizedBox(height: 18),
              TypographyText(
                t.cartEmpty,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              TypographyText(
                t.cartEmptyDesc,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? const Color(0xFFAAA39A) : BaseColors.textGray,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: BaseColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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

  Widget _buildCartContent(ThemeData theme, L t, int totalItems) {
    return CustomScrollView(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              children: <Widget>[
                TypographyText(
                  t.cart,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedSwitcher(
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
                      color: BaseColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: TypographyText(
                      '$totalItems',
                      style: const TextStyle(
                        color: BaseColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.builder(
            itemCount: items.length,
            findChildIndexCallback: (key) {
              final valueKey = key as ValueKey<String>;
              final index = items.indexWhere(
                (line) => line.product.id == valueKey.value,
              );
              return index == -1 ? null : index;
            },
            itemBuilder: (context, index) {
              final line = items[index];
              return KeyedSubtree(
                key: ValueKey<String>(line.product.id),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: FadeSlideIn(
                    child: RepaintBoundary(
                      child: CartItemCard(
                        item: line,
                        isDark: isDark,
                        onDecrease: () => onDecrease(line.product),
                        onIncrease: () => onIncrease(line.product),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1D1A18) : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        TypographyText(
                          t.total,
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFFAAA39A)
                                : BaseColors.textGray,
                            fontSize: 16,
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
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
                            formatSum(totalAmount),
                            key: ValueKey<int>(totalAmount),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: BaseColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: BaseColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: isCheckingOut ? null : onCheckout,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
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
                              : TypographyText(
                                  t.checkout,
                                  key: const ValueKey<String>('checkout-label'),
                                  style: const TextStyle(
                                    color: BaseColors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
