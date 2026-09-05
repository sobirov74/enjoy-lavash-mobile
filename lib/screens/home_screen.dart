import 'dart:async';

import 'package:enjoy_lavash_mobile/features/models/menu_product.dart';
import 'package:enjoy_lavash_mobile/features/models/menu_category.dart';
import 'package:enjoy_lavash_mobile/core/error/failures.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/order_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/promotion_model.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/theme/app_design_tokens.dart';
import 'package:enjoy_lavash_mobile/utils/price_formatter.dart';
import 'package:enjoy_lavash_mobile/widgets/product_image.dart';
import 'package:enjoy_lavash_mobile/widgets/redesign/app_surface_card.dart';
import 'package:enjoy_lavash_mobile/widgets/redesign/order_context_pill.dart';
import 'package:enjoy_lavash_mobile/widgets/animated_error_message.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.customerName,
    required this.loyaltyBalance,
    required this.orderModeLabel,
    required this.orderContextLabel,
    required this.categories,
    required this.products,
    required this.promotions,
    required this.locale,
    required this.onOrderContextTap,
    required this.onNotificationsTap,
    required this.onLoyaltyTap,
    required this.onMenuTap,
    required this.onCategoryTap,
    required this.onRefresh,
    super.key,
    this.notificationUnreadCount = 0,
    this.lastOrder,
    this.onRepeatOrder,
    this.isLoading = false,
    this.failure,
  });

  final String customerName;
  final int loyaltyBalance;
  final String orderModeLabel;
  final String orderContextLabel;
  final List<MenuCategory> categories;
  final List<MenuProduct> products;
  final List<PromotionModel> promotions;
  final String locale;
  final int notificationUnreadCount;
  final CustomerOrderModel? lastOrder;
  final VoidCallback onOrderContextTap;
  final VoidCallback onNotificationsTap;
  final VoidCallback onLoyaltyTap;
  final VoidCallback onMenuTap;
  final ValueChanged<int> onCategoryTap;
  final Future<void> Function() onRefresh;
  final VoidCallback? onRepeatOrder;
  final bool isLoading;
  final Failure? failure;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    if (isLoading && products.isEmpty) {
      return _HomeLoadingState(onRefresh: onRefresh);
    }
    if (failure != null && products.isEmpty) {
      return _HomeFailureState(failure: failure!, onRetry: onRefresh);
    }
    return RefreshIndicator(
      color: AppDesignTokens.action,
      onRefresh: onRefresh,
      child: CustomScrollView(
        key: const PageStorageKey<String>('home-scroll'),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDesignTokens.gutter,
                8,
                AppDesignTokens.gutter,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OrderContextPill(
                          modeLabel: orderModeLabel,
                          contextLabel: orderContextLabel,
                          onTap: onOrderContextTap,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _NotificationButton(
                        unreadCount: notificationUnreadCount,
                        label: t.notificationInbox,
                        onTap: onNotificationsTap,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    t.homeGreeting(customerName),
                    style: AppTextStyles.display(
                      size: 34,
                      height: 1.08,
                      color: AppDesignTokens.primaryText(context),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _LoyaltyCard(
                    balance: loyaltyBalance,
                    hint: t.loyaltyMoneyHint,
                    onTap: onLoyaltyTap,
                  ),
                  if (lastOrder != null && onRepeatOrder != null) ...<Widget>[
                    const SizedBox(height: 14),
                    _RepeatOrderCard(
                      order: lastOrder!,
                      locale: locale,
                      title: t.repeatOrderTitle,
                      actionLabel: t.repeatOrderAction(
                        formatSum(context, lastOrder!.totalAmount),
                      ),
                      onTap: onRepeatOrder!,
                    ),
                  ],
                  if (promotions.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 18),
                    _PromotionHero(
                      promotion: promotions.first,
                      fallbackTitle: t.specialOffer,
                      fallbackDescription: t.specialOfferDesc,
                      actionLabel: t.specialOfferCta,
                      onTap: onMenuTap,
                    ),
                  ],
                  const SizedBox(height: 22),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          t.menu,
                          style: AppTextStyles.ui(
                            size: 17,
                            weight: FontWeight.w600,
                            color: AppDesignTokens.primaryText(context),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: onMenuTap,
                        child: Text(
                          t.all,
                          style: AppTextStyles.ui(
                            size: 13.5,
                            weight: FontWeight.w600,
                            color: AppDesignTokens.action,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 118,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDesignTokens.gutter,
                ),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final product = _firstProductForCategory(category.name);
                  return _CategoryCard(
                    category: category,
                    product: product,
                    onTap: () => onCategoryTap(index),
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 116)),
        ],
      ),
    );
  }

  MenuProduct? _firstProductForCategory(String category) {
    for (final product in products) {
      if (product.category == category) return product;
    }
    return null;
  }
}

class _HomeLoadingState extends StatelessWidget {
  const _HomeLoadingState({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        key: const ValueKey<String>('home-loading'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: _HomeSkeleton(height: 46, radius: 23)),
              const SizedBox(width: 10),
              const _HomeSkeleton(height: 46, width: 46, radius: 23),
            ],
          ),
          const SizedBox(height: 22),
          const _HomeSkeleton(height: 40, width: 220),
          const SizedBox(height: 16),
          const _HomeSkeleton(height: 76, radius: 22),
          const SizedBox(height: 16),
          const _HomeSkeleton(height: 180, radius: 26),
          const SizedBox(height: 20),
          const _HomeSkeleton(height: 24, width: 120),
          const SizedBox(height: 12),
          const Row(
            children: <Widget>[
              Expanded(child: _HomeSkeleton(height: 110, radius: 20)),
              SizedBox(width: 12),
              Expanded(child: _HomeSkeleton(height: 110, radius: 20)),
              SizedBox(width: 12),
              Expanded(child: _HomeSkeleton(height: 110, radius: 20)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeFailureState extends StatelessWidget {
  const _HomeFailureState({required this.failure, required this.onRetry});

  final Failure failure;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey<String>('home-error'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 120, 24, 100),
      children: <Widget>[
        AnimatedErrorMessage(
          failure: failure,
          onRetry: () => unawaited(onRetry()),
        ),
      ],
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton({required this.height, this.width, this.radius = 16});

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppDesignTokens.surface(context),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({
    required this.unreadCount,
    required this.label,
    required this.onTap,
  });

  final int unreadCount;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: Colors.transparent,
          child: Ink(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppDesignTokens.surface(context),
              shape: BoxShape.circle,
              boxShadow: AppDesignTokens.cardShadow(context),
            ),
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 22,
                    color: AppDesignTokens.primaryText(context),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 9,
                      right: 9,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: AppDesignTokens.action,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppDesignTokens.surface(context),
                            width: 1.5,
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
    );
  }
}

class _LoyaltyCard extends StatelessWidget {
  const _LoyaltyCard({
    required this.balance,
    required this.hint,
    required this.onTap,
  });

  final int balance;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final formatted = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(balance);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppSurfaceCard(
      color: isDark
          ? AppDesignTokens.gold.withValues(alpha: 0.13)
          : AppDesignTokens.goldWash,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppDesignTokens.gold,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.stars_rounded,
              color: AppDesignTokens.goldInk,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  L.of(context).loyaltyBalancePoints(formatted),
                  style: AppTextStyles.display(
                    size: 21,
                    height: 1.15,
                    color: isDark
                        ? const Color(0xFFF0C763)
                        : AppDesignTokens.goldInk,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hint,
                  style: AppTextStyles.ui(
                    size: 11.5,
                    color:
                        (isDark
                                ? const Color(0xFFF0C763)
                                : AppDesignTokens.goldInk)
                            .withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: isDark
                ? const Color(0xFFF0C763)
                : AppDesignTokens.goldInk.withValues(alpha: 0.60),
          ),
        ],
      ),
    );
  }
}

class _RepeatOrderCard extends StatelessWidget {
  const _RepeatOrderCard({
    required this.order,
    required this.locale,
    required this.title,
    required this.actionLabel,
    required this.onTap,
  });

  final CustomerOrderModel order;
  final String locale;
  final String title;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final names = order.items
        .map((item) => item.localizedName(locale))
        .whereType<String>()
        .take(2)
        .join(', ');
    final date = order.createdAt == null
        ? null
        : DateFormat('d MMM', locale).format(order.createdAt!.toLocal());
    final itemCount = order.items.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.ui(
                    size: 17,
                    weight: FontWeight.w600,
                    color: AppDesignTokens.primaryText(context),
                  ),
                ),
              ),
              if (date != null)
                Text(
                  date,
                  style: AppTextStyles.ui(
                    size: 11.5,
                    color: AppDesignTokens.tertiaryText(context),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppDesignTokens.goldWash,
                  borderRadius: BorderRadius.circular(
                    AppDesignTokens.radiusThumb,
                  ),
                ),
                child: const Icon(
                  Icons.lunch_dining_rounded,
                  color: AppDesignTokens.goldInk,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      names.isEmpty ? '#${order.id}' : names,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.ui(
                        size: 14.5,
                        weight: FontWeight.w600,
                        color: AppDesignTokens.primaryText(context),
                      ),
                    ),
                    Text(
                      '${formatSum(context, order.totalAmount)} · $itemCount',
                      style: AppTextStyles.ui(
                        size: 12.5,
                        color: AppDesignTokens.secondaryText(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: AppDesignTokens.actionSoft,
                foregroundColor: AppDesignTokens.action,
                shadowColor: Colors.transparent,
              ),
              child: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromotionHero extends StatelessWidget {
  const _PromotionHero({
    required this.promotion,
    required this.fallbackTitle,
    required this.fallbackDescription,
    required this.actionLabel,
    required this.onTap,
  });

  final PromotionModel promotion;
  final String fallbackTitle;
  final String fallbackDescription;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = promotion.title.trim().isEmpty
        ? fallbackTitle
        : promotion.title.trim();
    final description = promotion.description?.trim();
    return Container(
      height: 172,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF6E4E36),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusHero),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned(
            right: -32,
            top: -32,
            child: Opacity(
              opacity: 0.32,
              child: Image.asset(
                'assets/images/enjoy-logo-app-icon.png',
                width: 210,
                height: 210,
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[Color(0x08000000), Color(0xD9000000)],
                stops: <double>[0.15, 1],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 14,
            bottom: 14,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        fallbackTitle.toUpperCase(),
                        style: AppTextStyles.ui(
                          size: 11.5,
                          weight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.70),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description?.isNotEmpty == true ? description! : title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.display(
                          size: 20,
                          height: 1.15,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 40,
                  child: FilledButton(
                    onPressed: onTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppDesignTokens.action,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: Text(
                      actionLabel.replaceAll('🔥 ', ''),
                      style: AppTextStyles.ui(
                        size: 13.5,
                        weight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
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

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.product,
    required this.onTap,
  });

  final MenuCategory category;
  final MenuProduct? product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: AppSurfaceCard(
        padding: EdgeInsets.zero,
        radius: AppDesignTokens.radiusTile,
        clipBehavior: Clip.antiAlias,
        onTap: onTap,
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 70,
              width: double.infinity,
              child: _CategoryImage(category: category, product: product),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.ui(
                      size: 12.5,
                      weight: FontWeight.w600,
                      color: AppDesignTokens.primaryText(context),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryImage extends StatelessWidget {
  const _CategoryImage({required this.category, required this.product});

  final MenuCategory category;
  final MenuProduct? product;

  @override
  Widget build(BuildContext context) {
    final imageUrl = category.imageUrl?.trim();
    final image = imageUrl?.isNotEmpty == true
        ? Image.network(
            imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _fallback(),
          )
        : _fallback();

    return ClipRRect(
      key: ValueKey<String>('home-category-image-${category.id}'),
      borderRadius: BorderRadius.circular(AppDesignTokens.radiusThumb),
      clipBehavior: Clip.antiAlias,
      child: image,
    );
  }

  Widget _fallback() {
    final fallbackProduct = product;
    if (fallbackProduct != null) {
      return ProductImage(
        product: fallbackProduct,
        width: double.infinity,
        height: 70,
        borderRadius: AppDesignTokens.radiusThumb,
        fallbackFontSize: 28,
      );
    }
    return const ColoredBox(
      color: AppDesignTokens.actionSoft,
      child: Icon(Icons.restaurant_menu_rounded, color: AppDesignTokens.action),
    );
  }
}
