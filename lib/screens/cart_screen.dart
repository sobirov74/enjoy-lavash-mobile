import 'package:enjoy_lavash_mobile/features/models/cart_line.dart';
import 'package:enjoy_lavash_mobile/features/models/menu_product.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/utils/price_formatter.dart';
import 'package:enjoy_lavash_mobile/widgets/cart_item_card.dart';
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
  });

  final bool isDark;
  final List<CartLine> items;
  final int totalAmount;
  final ValueChanged<MenuProduct> onDecrease;
  final ValueChanged<MenuProduct> onIncrease;
  final VoidCallback onBrowseMenu;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = L.of(context);

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 120,
                height: 120,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: BaseColors.surfaceTint,
                  shape: BoxShape.circle,
                ),
                child: const TypographyText(
                  '🛒',
                  style: TextStyle(fontSize: 52),
                ),
              ),
              const SizedBox(height: 24),
              TypographyText(
                t.cartEmpty,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              TypographyText(
                t.cartEmptyDesc,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? const Color(0xFFAAA39A) : BaseColors.textGray,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: BaseColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
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
      );
    }

    return CustomScrollView(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
            child: TypographyText(
              t.cart,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final line = items[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: RepaintBoundary(
                  child: CartItemCard(
                    item: line,
                    isDark: isDark,
                    onDecrease: () => onDecrease(line.product),
                    onIncrease: () => onIncrease(line.product),
                  ),
                ),
              );
            },
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1D1A18) : Colors.white,
                  borderRadius: BorderRadius.circular(28),
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
                        TypographyText(
                          formatSum(totalAmount),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: BaseColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: BaseColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () {},
                        child: TypographyText(
                          t.checkout,
                          style: const TextStyle(color: BaseColors.white),
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
