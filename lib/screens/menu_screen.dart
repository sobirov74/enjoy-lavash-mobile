import 'dart:async';

import 'package:enjoy_lavash_mobile/app/location_controller.dart';
import 'package:enjoy_lavash_mobile/core/error/failures.dart';
import 'package:enjoy_lavash_mobile/features/models/cart_line.dart';
import 'package:enjoy_lavash_mobile/features/models/menu_product.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/address_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/branch_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/cart_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/promotion_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/presentation/mobile_backend_controller.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/screens/order_context_sheet.dart';
import 'package:enjoy_lavash_mobile/theme/app_design_tokens.dart';
import 'package:enjoy_lavash_mobile/theme/app_motion.dart';
import 'package:enjoy_lavash_mobile/utils/price_formatter.dart';
import 'package:enjoy_lavash_mobile/widgets/animated_error_message.dart';
import 'package:enjoy_lavash_mobile/widgets/fade_slide_in.dart';
import 'package:enjoy_lavash_mobile/widgets/product_image.dart';
import 'package:enjoy_lavash_mobile/widgets/product_list_item.dart';
import 'package:enjoy_lavash_mobile/widgets/redesign/order_context_pill.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'package:enjoy_lavash_mobile/widgets/typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

const double _stickyCategoryHeaderHeight = 56;

// ---------------------------------------------------------------------------
// MenuScreen — main scrollable menu with sticky category tabs
// ---------------------------------------------------------------------------

class MenuScreen extends StatefulWidget {
  const MenuScreen({
    super.key,
    required this.isDark,
    required this.isMenuLoading,
    required this.selectedCategoryIndex,
    required this.categories,
    required this.products,
    required this.promotions,
    required this.orderType,
    required this.selectedBranch,
    required this.onCategorySelected,
    required this.onAddToCart,
    required this.onDecreaseFromCart,
    required this.onCartTap,
    required this.onOrderTypeChanged,
    required this.onBranchSelected,
    required this.onRetryMenu,
    required this.onRefresh,
    required this.cartCount,
    required this.cartTotal,
    required this.cartQuantities,
    this.notificationUnreadCount = 0,
    this.onAddConfiguredToCart,
    this.onNotificationsTap,
    this.onOrderContextTap,
    this.showCartSummary = true,
    this.menuFailure,
    this.menuErrorText,
  });

  final bool isDark;
  final bool isMenuLoading;
  final int selectedCategoryIndex;
  final List<String> categories;
  final List<MenuProduct> products;
  final List<PromotionModel> promotions;
  final MobileOrderType orderType;
  final BranchModel? selectedBranch;
  final ValueChanged<int> onCategorySelected;
  final ValueChanged<MenuProduct> onAddToCart;
  final ValueChanged<CartSelection>? onAddConfiguredToCart;
  final ValueChanged<MenuProduct> onDecreaseFromCart;
  final VoidCallback onCartTap;
  final ValueChanged<MobileOrderType> onOrderTypeChanged;
  final Future<void> Function(BranchModel?) onBranchSelected;
  final VoidCallback onRetryMenu;
  final Future<void> Function() onRefresh;
  final int cartCount;
  final int cartTotal;
  final Map<String, int> cartQuantities;
  final int notificationUnreadCount;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onOrderContextTap;
  final bool showCartSummary;
  final Failure? menuFailure;
  final String? menuErrorText;

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _categoryScrollController = ScrollController();
  final GlobalKey _categoryPillTrackKey = GlobalKey(
    debugLabel: 'category-pill-track',
  );
  final GlobalKey _cartFlightTargetKey = GlobalKey(
    debugLabel: 'cart-flight-target',
  );

  late final List<GlobalKey> _categoryChipKeys = _buildKeys(
    widget.categories.length + 1,
  );

  double? _categoryPillLeft;
  double? _categoryPillWidth;
  OverlayEntry? _cartFlightEntry;
  DateTime? _lastCartFlightAt;
  int _cartArrivalPulse = 0;

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollSelectedChipIntoView();
      _updateCategoryPillGeometry();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateCategoryPillGeometry();
    });
  }

  @override
  void didUpdateWidget(covariant MenuScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.categories.length != widget.categories.length) {
      _syncCategoryKeys();
    }

    if (oldWidget.selectedCategoryIndex != widget.selectedCategoryIndex ||
        oldWidget.categories.length != widget.categories.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollSelectedChipIntoView();
        _updateCategoryPillGeometry();
      });
    }
  }

  @override
  void dispose() {
    _cartFlightEntry?.remove();
    _cartFlightEntry = null;
    _scrollController.dispose();
    _categoryScrollController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  List<GlobalKey> _buildKeys(int count) {
    return List<GlobalKey>.generate(count, (_) => GlobalKey());
  }

  void _syncCategoryKeys() {
    _syncKeyList(_categoryChipKeys, widget.categories.length + 1);
  }

  void _syncKeyList(List<GlobalKey> keys, int count) {
    if (keys.length == count) return;

    if (keys.length < count) {
      keys.addAll(_buildKeys(count - keys.length));
      return;
    }

    keys.removeRange(count, keys.length);
  }

  ClientAddress? _defaultAddress(List<ClientAddress> addresses) {
    if (addresses.isEmpty) return null;

    for (final address in addresses) {
      if (address.isDefault) return address;
    }
    return addresses.first;
  }

  String? _formatSavedAddress(ClientAddress? address) {
    if (address == null) return null;

    final parts = <String>[
      if (address.street.trim().isNotEmpty) address.street.trim(),
      if (address.houseNumber?.trim().isNotEmpty == true)
        address.houseNumber!.trim(),
      if (address.apartmentNumber?.trim().isNotEmpty == true)
        address.apartmentNumber!.trim(),
    ];
    if (parts.isNotEmpty) return parts.join(', ');

    final label = address.label.trim();
    return label.isEmpty ? null : label;
  }

  String? _deliveryButtonSubtitle(BuildContext context) {
    final loc = context.watch<LocationController>();
    if (loc.addressName.trim().isNotEmpty) {
      final fullAddress = loc.fullAddress.trim();
      return fullAddress.isEmpty ? loc.addressName.trim() : fullAddress;
    }

    final addresses = context.watch<MobileBackendController>().addresses;
    return _formatSavedAddress(_defaultAddress(addresses));
  }

  double get _activeStickyHeaderHeight => _stickyCategoryHeaderHeight;

  void _updateCategoryPillGeometry() {
    if (!mounted || _categoryChipKeys.isEmpty) return;

    final selectedIndex = (widget.selectedCategoryIndex + 1).clamp(
      0,
      widget.categories.length,
    );
    final chipRenderObject = _categoryChipKeys[selectedIndex].currentContext
        ?.findRenderObject();
    final trackRenderObject = _categoryPillTrackKey.currentContext
        ?.findRenderObject();
    if (chipRenderObject is! RenderBox ||
        trackRenderObject is! RenderBox ||
        !chipRenderObject.hasSize ||
        !trackRenderObject.hasSize) {
      return;
    }

    final chipOffset = chipRenderObject.localToGlobal(
      Offset.zero,
      ancestor: trackRenderObject,
    );
    final nextLeft = chipOffset.dx;
    final nextWidth = chipRenderObject.size.width;
    if (_categoryPillLeft != null &&
        (nextLeft - _categoryPillLeft!).abs() < 0.5 &&
        _categoryPillWidth != null &&
        (nextWidth - _categoryPillWidth!).abs() < 0.5) {
      return;
    }

    setState(() {
      _categoryPillLeft = nextLeft;
      _categoryPillWidth = nextWidth;
    });
  }

  void _animateProductToCart(MenuProduct product, Rect origin) {
    final now = DateTime.now();
    final previousFlight = _lastCartFlightAt;
    if (AppMotion.reduced(context) ||
        (previousFlight != null &&
            now.difference(previousFlight) < AppMotion.spatial)) {
      HapticFeedback.selectionClick();
      return;
    }
    _lastCartFlightAt = now;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final targetRenderObject = _cartFlightTargetKey.currentContext
          ?.findRenderObject();
      final overlay = Overlay.maybeOf(context, rootOverlay: true);
      final overlayRenderObject = overlay?.context.findRenderObject();
      if (targetRenderObject is! RenderBox ||
          !targetRenderObject.hasSize ||
          overlay == null ||
          overlayRenderObject is! RenderBox ||
          !overlayRenderObject.hasSize) {
        HapticFeedback.selectionClick();
        return;
      }

      final targetRect =
          targetRenderObject.localToGlobal(Offset.zero) &
          targetRenderObject.size;
      final start = overlayRenderObject.globalToLocal(origin.center);
      final end = overlayRenderObject.globalToLocal(targetRect.center);

      final previousEntry = _cartFlightEntry;
      if (previousEntry?.mounted == true) previousEntry!.remove();

      late final OverlayEntry entry;
      entry = OverlayEntry(
        builder: (_) => _WrapToCartFlight(
          product: product,
          start: start,
          end: end,
          onCompleted: () {
            if (_cartFlightEntry != entry) return;
            if (entry.mounted) entry.remove();
            _cartFlightEntry = null;
            HapticFeedback.selectionClick();
            if (mounted) {
              setState(() => _cartArrivalPulse += 1);
            }
          },
        ),
      );
      _cartFlightEntry = entry;
      overlay.insert(entry);
    });
  }

  void _showProductImagePreview(MenuProduct product) {
    Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.48),
        barrierLabel: MaterialLocalizations.of(
          context,
        ).modalBarrierDismissLabel,
        transitionDuration: AppMotion.duration(context, AppMotion.spatial),
        reverseTransitionDuration: AppMotion.duration(context, AppMotion.state),
        pageBuilder: (routeContext, animation, _) => _ProductDetailPage(
          product: product,
          animation: animation,
          heroTag: _productHeroTag(product),
          onAdd: (selection) {
            final callback = widget.onAddConfiguredToCart;
            if (callback == null) {
              for (var index = 0; index < selection.quantity; index++) {
                widget.onAddToCart(product);
              }
              return;
            }
            callback(selection);
          },
        ),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: AppMotion.enter),
          child: child,
        ),
      ),
    );
  }

  String _productHeroTag(MenuProduct product) => 'menu-product-${product.id}';

  void _quickAdd(MenuProduct product) {
    final selection = standardCartSelection(product);
    if (selection == null) {
      _showProductImagePreview(product);
      return;
    }
    final callback = widget.onAddConfiguredToCart;
    if (callback != null) {
      callback(selection);
    } else {
      widget.onAddToCart(product);
    }
  }

  void _selectCategory(int index) {
    if (index < -1 || index >= widget.categories.length) return;
    widget.onCategorySelected(index);
    if (!_scrollController.hasClients) return;
    if (AppMotion.reduced(context)) {
      _scrollController.jumpTo(0);
    } else {
      unawaited(
        _scrollController.animateTo(
          0,
          duration: AppMotion.state,
          curve: AppMotion.enter,
        ),
      );
    }
  }

  // -------------------------------------------------------------------------
  // Keep the active category chip centered in the horizontal list
  // -------------------------------------------------------------------------

  void _scrollSelectedChipIntoView() {
    if (!_categoryScrollController.hasClients || _categoryChipKeys.isEmpty) {
      return;
    }

    final displayIndex = (widget.selectedCategoryIndex + 1).clamp(
      0,
      widget.categories.length,
    );
    final chipContext = _categoryChipKeys[displayIndex].currentContext;
    if (chipContext == null) return;

    final chipBox = chipContext.findRenderObject();
    final listBox = _categoryScrollController.position.context.storageContext
        .findRenderObject();

    if (chipBox is! RenderBox || listBox is! RenderBox) return;

    final chipOffset = chipBox.localToGlobal(Offset.zero, ancestor: listBox);
    final chipCenter = chipOffset.dx + chipBox.size.width / 2;
    final viewportCenter =
        _categoryScrollController.position.viewportDimension / 2;

    final targetOffset =
        (_categoryScrollController.offset + chipCenter - viewportCenter).clamp(
          0.0,
          _categoryScrollController.position.maxScrollExtent,
        );

    if ((targetOffset - _categoryScrollController.offset).abs() < 1) return;

    if (AppMotion.reduced(context)) {
      _categoryScrollController.jumpTo(targetOffset);
    } else {
      _categoryScrollController.animateTo(
        targetOffset,
        duration: AppMotion.state,
        curve: AppMotion.enter,
      );
    }
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = L.of(context);
    final selectedCategory =
        widget.selectedCategoryIndex >= 0 &&
            widget.selectedCategoryIndex < widget.categories.length
        ? widget.categories[widget.selectedCategoryIndex]
        : null;
    final visibleProducts = selectedCategory == null
        ? widget.products
        : widget.products
              .where((product) => product.category == selectedCategory)
              .toList(growable: false);

    return Stack(
      children: <Widget>[
        RefreshIndicator(
          color: BaseColors.primary,
          onRefresh: widget.onRefresh,
          child: CustomScrollView(
            controller: _scrollController,
            cacheExtent: 1200,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // -- The redesign keeps order context visible without spending
              //    a second row on separate delivery and pickup controls.
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      FadeSlideIn(
                        child: OrderContextPill(
                          compact: true,
                          modeLabel:
                              widget.orderType == MobileOrderType.delivery
                              ? t.delivery
                              : t.pickup,
                          contextLabel: _orderContextLabel(t),
                          onTap:
                              widget.onOrderContextTap ??
                              () => unawaited(_showOrderContextPicker()),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        t.menu,
                        style: AppTextStyles.display(
                          size: 26,
                          height: 1.15,
                          color: AppDesignTokens.primaryText(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (widget.products.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildMenuState(theme, t),
                )
              else ...[
                // -- Sticky category pills from the reference prototype.
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _CategoryHeaderDelegate(
                    height: _activeStickyHeaderHeight,
                    child: _buildProductsHeader(theme, t),
                  ),
                ),

                if (visibleProducts.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildFilteredEmptyState(t),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    sliver: SliverToBoxAdapter(
                      child: _buildProductGrid(visibleProducts),
                    ),
                  ),
              ],
              if (widget.showCartSummary && widget.cartCount > 0)
                const SliverToBoxAdapter(child: SizedBox(height: 90)),
            ],
          ),
        ),
        if (widget.showCartSummary)
          Positioned(
            left: 16,
            right: 16,
            bottom: 12,
            child: AnimatedSlide(
              duration: AppMotion.duration(context, AppMotion.state),
              curve: AppMotion.enter,
              offset: widget.cartCount > 0 ? Offset.zero : const Offset(0, 1.4),
              child: AnimatedOpacity(
                duration: AppMotion.duration(context, AppMotion.micro),
                opacity: widget.cartCount > 0 ? 1 : 0,
                child: IgnorePointer(
                  ignoring: widget.cartCount <= 0,
                  child: _buildCartSummaryBar(t),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _orderContextLabel(L t) {
    if (widget.orderType == MobileOrderType.pickup) {
      final branchName = widget.selectedBranch?.name.trim();
      return branchName?.isNotEmpty == true ? branchName! : t.pickupBranch;
    }
    return _deliveryButtonSubtitle(context) ?? t.tapToSelectAddress;
  }

  Future<void> _showOrderContextPicker() async {
    final backend = context.read<MobileBackendController>();
    await showOrderContextSheet(
      context: context,
      currentType: widget.orderType,
      selectedBranch: widget.selectedBranch,
      branches: backend.branches,
      deliveryAddress: _deliveryButtonSubtitle(context),
      onTypeChanged: widget.onOrderTypeChanged,
      onBranchSelected: widget.onBranchSelected,
    );
  }

  // -------------------------------------------------------------------------
  // Extracted widgets
  // -------------------------------------------------------------------------

  Widget _buildMenuState(ThemeData theme, L t) {
    final errorText = widget.menuErrorText;

    final Widget state;
    if (widget.isMenuLoading) {
      state = Padding(
        key: const ValueKey<String>('menu-loading'),
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 96),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.6),
            ),
            const SizedBox(height: 14),
            TypographyText(
              t.menuLoading,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 22),
            for (var index = 0; index < 3; index++) ...[
              _MenuSkeletonCard(isDark: widget.isDark),
              if (index < 2) const SizedBox(height: 10),
            ],
          ],
        ),
      );
    } else {
      state = Padding(
        key: ValueKey<String>(errorText != null ? 'menu-error' : 'menu-empty'),
        padding: const EdgeInsets.fromLTRB(32, 48, 32, 96),
        child: Center(
          child: errorText != null
              ? AnimatedErrorMessage(
                  failure: widget.menuFailure,
                  message: errorText,
                  onRetry: widget.onRetryMenu,
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.restaurant_menu_rounded,
                      size: 44,
                      color: widget.isDark
                          ? BaseColors.lightTextGray
                          : BaseColors.textGray,
                    ),
                    const SizedBox(height: 16),
                    TypographyText(
                      t.emptyList,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: widget.isDark
                            ? BaseColors.lightTextGray
                            : BaseColors.textGray,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: AppMotion.duration(context, AppMotion.state),
      switchInCurve: AppMotion.enter,
      switchOutCurve: AppMotion.exit,
      child: state,
    );
  }

  Widget _buildCartSummaryBar(L t) {
    final isDark = widget.isDark;
    final surface = isDark ? const Color(0xFF29231F) : Colors.white;
    final foreground = isDark ? Colors.white : const Color(0xFF201C19);
    final muted = isDark ? const Color(0xFFC9C1BA) : BaseColors.textGray;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : BaseColors.primary.withValues(alpha: 0.22);
    final shadow = isDark
        ? Colors.black.withValues(alpha: 0.28)
        : BaseColors.primary.withValues(alpha: 0.18);
    final totalSurface = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : BaseColors.surfaceTint;
    final totalBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : BaseColors.primary.withValues(alpha: 0.16);
    final arrowSurface = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : BaseColors.primary.withValues(alpha: 0.12);

    return Semantics(
      button: true,
      label:
          '${t.viewCart}, ${t.cartItemsCount(widget.cartCount)}, '
          '${formatSum(context, widget.cartTotal)}',
      child: Material(
        key: const ValueKey<String>('menu-cart-summary-bar'),
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: border),
        ),
        elevation: isDark ? 10 : 14,
        shadowColor: shadow,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onCartTap,
          splashColor: BaseColors.primary.withValues(alpha: 0.08),
          highlightColor: BaseColors.primary.withValues(alpha: 0.04),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 68),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: <Widget>[
                  TweenAnimationBuilder<double>(
                    key: ValueKey<int>(_cartArrivalPulse),
                    duration: AppMotion.duration(context, AppMotion.micro),
                    curve: AppMotion.enter,
                    tween: Tween<double>(
                      begin: _cartArrivalPulse == 0 ? 1 : 0.86,
                      end: 1,
                    ),
                    builder: (context, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: Container(
                      key: _cartFlightTargetKey,
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: <Color>[
                            BaseColors.primary,
                            BaseColors.primaryDark,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: BaseColors.primary.withValues(alpha: 0.26),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: TypographyText(
                        '${widget.cartCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        TypographyText(
                          t.viewCart,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: foreground,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        TypographyText(
                          t.cartItemsCount(widget.cartCount),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 136),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: totalSurface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: totalBorder),
                      ),
                      child: TypographyText(
                        formatSum(context, widget.cartTotal),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          color: isDark ? Colors.white : BaseColors.primaryDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: arrowSurface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: isDark ? Colors.white : BaseColors.primaryDark,
                      size: 19,
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

  Widget _buildProductsHeader(ThemeData theme, L t) {
    return Container(
      color: theme.scaffoldBackgroundColor,
      child: FadeSlideIn(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
          child: SizedBox(
            height: AppDesignTokens.chipHeight,
            child: SingleChildScrollView(
              controller: _categoryScrollController,
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              child: Stack(
                key: _categoryPillTrackKey,
                alignment: Alignment.centerLeft,
                children: <Widget>[
                  if (_categoryPillLeft != null && _categoryPillWidth != null)
                    AnimatedPositioned(
                      duration: AppMotion.duration(context, AppMotion.state),
                      curve: AppMotion.standard,
                      left: _categoryPillLeft,
                      top: 0,
                      width: _categoryPillWidth,
                      height: AppDesignTokens.chipHeight,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppDesignTokens.inkSurface(context),
                          borderRadius: BorderRadius.all(
                            Radius.circular(AppDesignTokens.radiusPill),
                          ),
                        ),
                      ),
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      for (
                        var displayIndex = 0;
                        displayIndex <= widget.categories.length;
                        displayIndex++
                      ) ...<Widget>[
                        _buildCategoryChip(displayIndex),
                        if (displayIndex < widget.categories.length)
                          const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(int displayIndex) {
    final categoryIndex = displayIndex - 1;
    final isActive = categoryIndex == widget.selectedCategoryIndex;
    final labelColor = isActive
        ? AppDesignTokens.onInk(context)
        : AppDesignTokens.primaryText(context);
    final hasSharedPill = _categoryPillLeft != null;

    return KeyedSubtree(
      key: _categoryChipKeys[displayIndex],
      child: Semantics(
        button: true,
        selected: isActive,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusPill),
          child: Ink(
            decoration: BoxDecoration(
              color: hasSharedPill
                  ? Colors.transparent
                  : isActive
                  ? AppDesignTokens.inkSurface(context)
                  : AppDesignTokens.surface(context),
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusPill),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusPill),
              onTap: () => _selectCategory(categoryIndex),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AppDesignTokens.chipHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: AppMotion.duration(context, AppMotion.micro),
                      curve: AppMotion.standard,
                      style: TextStyle(
                        color: labelColor,
                        fontFamily: 'GolosText',
                        fontWeight: FontWeight.w500,
                        fontSize: 13.5,
                      ),
                      child: Text(
                        key: ValueKey<String>(
                          'menu-category-label-$categoryIndex',
                        ),
                        categoryIndex < 0
                            ? L.of(context).all
                            : widget.categories[categoryIndex],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductGrid(List<MenuProduct> products) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 3 : 2;
        final itemWidth =
            (constraints.maxWidth - (12 * (columns - 1))) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            for (final product in products)
              SizedBox(
                width: itemWidth,
                child: RepaintBoundary(
                  child: ProductListItem(
                    key: ValueKey<String>('menu-${product.id}'),
                    product: product,
                    isDark: widget.isDark,
                    quantity: widget.cartQuantities[product.id] ?? 0,
                    imageHeroTag: _productHeroTag(product),
                    onImageTap: () => _showProductImagePreview(product),
                    onAdd: () => _quickAdd(product),
                    onAddOrigin: (origin) {
                      if (standardCartSelection(product) != null) {
                        _animateProductToCart(product, origin);
                      }
                    },
                    onDecrease: () => widget.onDecreaseFromCart(product),
                    onIncrease: () => _quickAdd(product),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFilteredEmptyState(L t) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 96),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppDesignTokens.surface(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.restaurant_menu_rounded,
                color: AppDesignTokens.tertiaryText(context),
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            TypographyText(
              t.noProductsFound,
              textAlign: TextAlign.center,
              style: AppTextStyles.ui(
                size: 17,
                weight: FontWeight.w600,
                color: AppDesignTokens.primaryText(context),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => _selectCategory(-1),
              child: Text(t.all),
            ),
          ],
        ),
      ),
    );
  }
}

class _WrapToCartFlight extends StatefulWidget {
  const _WrapToCartFlight({
    required this.product,
    required this.start,
    required this.end,
    required this.onCompleted,
  });

  final MenuProduct product;
  final Offset start;
  final Offset end;
  final VoidCallback onCompleted;

  @override
  State<_WrapToCartFlight> createState() => _WrapToCartFlightState();
}

class _WrapToCartFlightState extends State<_WrapToCartFlight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.spatial,
  );
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.enter,
  );

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener(_handleStatus);
    _controller.forward();
  }

  void _handleStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onCompleted();
    });
  }

  @override
  void dispose() {
    _controller
      ..removeStatusListener(_handleStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewSize = MediaQuery.sizeOf(context);
    final lowerEndpoint = widget.start.dy > widget.end.dy
        ? widget.start.dy
        : widget.end.dy;
    final controlY = (lowerEndpoint + 64)
        .clamp(24.0, viewSize.height - 24)
        .toDouble();
    final control = Offset((widget.start.dx + widget.end.dx) / 2, controlY);

    return Positioned.fill(
      key: const ValueKey<String>('wrap-to-cart-flight'),
      child: ExcludeSemantics(
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, _) {
              final progress = _animation.value;
              final firstLeg = Offset.lerp(widget.start, control, progress)!;
              final secondLeg = Offset.lerp(control, widget.end, progress)!;
              final position = Offset.lerp(firstLeg, secondLeg, progress)!;
              final scale = Tween<double>(
                begin: 1,
                end: 0.42,
              ).transform(progress);
              final opacity =
                  (progress < 0.82
                          ? 1.0
                          : ((1 - progress) / 0.18).clamp(0.0, 1.0))
                      .toDouble();

              return Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _SmileTrailPainter(
                        start: widget.start,
                        control: control,
                        end: widget.end,
                        progress: progress,
                      ),
                    ),
                  ),
                  Positioned(
                    left: position.dx - 26,
                    top: position.dy - 26,
                    width: 52,
                    height: 52,
                    child: Opacity(
                      opacity: opacity,
                      child: Transform.rotate(
                        angle: (progress - 0.5) * 0.08,
                        child: Transform.scale(
                          scale: scale,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: BaseColors.primary,
                                width: 2,
                              ),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: ProductImage(
                                product: widget.product,
                                width: 46,
                                height: 46,
                                borderRadius: 14,
                                fallbackFontSize: 26,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SmileTrailPainter extends CustomPainter {
  const _SmileTrailPainter({
    required this.start,
    required this.control,
    required this.end,
    required this.progress,
  });

  final Offset start;
  final Offset control;
  final Offset end;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
    final metrics = path.computeMetrics().toList(growable: false);
    if (metrics.isEmpty) return;

    final metric = metrics.first;
    final visiblePath = metric.extractPath(0, metric.length * progress);
    canvas.drawPath(
      visiblePath,
      Paint()
        ..color = BaseColors.primaryDark.withValues(alpha: 0.3 * (1 - progress))
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _SmileTrailPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.start != start ||
        oldDelegate.control != control ||
        oldDelegate.end != end;
  }
}

class _ProductDetailPage extends StatefulWidget {
  const _ProductDetailPage({
    required this.product,
    required this.animation,
    required this.heroTag,
    required this.onAdd,
  });

  final MenuProduct product;
  final Animation<double> animation;
  final Object heroTag;
  final ValueChanged<CartSelection> onAdd;

  @override
  State<_ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<_ProductDetailPage> {
  final Map<String, Set<String>> _selectedByGroup = <String, Set<String>>{};
  int _quantity = 1;

  MenuProduct get product => widget.product;

  @override
  void initState() {
    super.initState();
    for (final group in product.modifierGroups) {
      final available = group.options
          .where((option) => option.isAvailable)
          .toList(growable: false);
      final selected = available
          .where((option) => option.isDefault)
          .take(group.maxSelected < 1 ? available.length : group.maxSelected)
          .map((option) => option.id)
          .toSet();
      _selectedByGroup[group.id] = selected;
    }
  }

  List<CartModifierSelection> get _selectedModifiers {
    final selections = <CartModifierSelection>[];
    for (final group in product.modifierGroups) {
      final selectedIds = _selectedByGroup[group.id] ?? const <String>{};
      for (final option in group.options) {
        if (!selectedIds.contains(option.id)) continue;
        selections.add(
          CartModifierSelection(
            groupId: group.id,
            modifierId: option.id,
            name: option.name,
            price: option.price,
            quantity: option.defaultQuantity < 1 ? 1 : option.defaultQuantity,
          ),
        );
      }
    }
    return selections;
  }

  bool get _isValid {
    for (final group in product.modifierGroups) {
      final selectedCount = _selectedByGroup[group.id]?.length ?? 0;
      if (selectedCount < group.minSelected) return false;
      if (group.maxSelected > 0 && selectedCount > group.maxSelected) {
        return false;
      }
    }
    return true;
  }

  int get _unitPrice =>
      product.price +
      _selectedModifiers.fold<int>(
        0,
        (sum, modifier) => sum + modifier.totalPrice,
      );

  void _toggleOption(MenuModifierGroup group, MenuModifierOption option) {
    if (!option.isAvailable) return;
    final selected = Set<String>.of(
      _selectedByGroup[group.id] ?? const <String>{},
    );
    if (selected.remove(option.id)) {
      setState(() => _selectedByGroup[group.id] = selected);
      return;
    }

    if (group.maxSelected == 1) {
      selected
        ..clear()
        ..add(option.id);
    } else if (group.maxSelected <= 0 || selected.length < group.maxSelected) {
      selected.add(option.id);
    }
    setState(() => _selectedByGroup[group.id] = selected);
  }

  void _addToCart() {
    if (!_isValid) return;
    widget.onAdd(
      CartSelection(
        productId: product.id,
        quantity: _quantity,
        modifiers: _selectedModifiers,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final detailsAnimation = widget.animation.drive(
      CurveTween(curve: const Interval(0.28, 1, curve: Curves.easeOutCubic)),
    );
    final description = product.description?.trim();

    return Semantics(
      key: const ValueKey<String>('product-detail-page'),
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: product.title,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                physics: const BouncingScrollPhysics(),
                children: <Widget>[
                  SizedBox(
                    height: 300,
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        Hero(
                          tag: widget.heroTag,
                          createRectTween: (begin, end) =>
                              MaterialRectCenterArcTween(
                                begin: begin,
                                end: end,
                              ),
                          child: ProductImage(
                            product: product,
                            width: double.infinity,
                            height: 300,
                            borderRadius: 0,
                            fallbackFontSize: 110,
                          ),
                        ),
                        Positioned(
                          top: MediaQuery.paddingOf(context).top + 10,
                          left: 16,
                          child: _ProductDetailCircleButton(
                            icon: Icons.arrow_back_ios_new_rounded,
                            tooltip: MaterialLocalizations.of(
                              context,
                            ).backButtonTooltip,
                            onTap: () => Navigator.of(context).pop(),
                          ),
                        ),
                        Positioned(
                          top: MediaQuery.paddingOf(context).top + 10,
                          right: 16,
                          child: _ProductDetailCircleButton(
                            icon: Icons.close_rounded,
                            tooltip: L.of(context).close,
                            onTap: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -28),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                      ),
                      child: FadeTransition(
                        opacity: detailsAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            TypographyText(
                              product.title,
                              style: AppTextStyles.display(
                                size: 27,
                                height: 1.08,
                                color: AppDesignTokens.primaryText(context),
                              ),
                            ),
                            if (description?.isNotEmpty == true) ...<Widget>[
                              const SizedBox(height: 8),
                              TypographyText(
                                description!,
                                style: AppTextStyles.ui(
                                  size: 14,
                                  height: 1.45,
                                  color: AppDesignTokens.secondaryText(context),
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: <Widget>[
                                _ProductMetaChip(
                                  icon: Icons.restaurant_menu_rounded,
                                  label: product.category,
                                ),
                                if (product.calories != null)
                                  _ProductMetaChip(
                                    icon: Icons.local_fire_department_outlined,
                                    label: L
                                        .of(context)
                                        .caloriesLabel(product.calories!),
                                  ),
                                if (product.weightGrams != null)
                                  _ProductMetaChip(
                                    icon: Icons.scale_outlined,
                                    label: L
                                        .of(context)
                                        .weightGramsLabel(product.weightGrams!),
                                  ),
                                if (product.cookingTimeMinutes != null)
                                  _ProductMetaChip(
                                    icon: Icons.schedule_rounded,
                                    label: L
                                        .of(context)
                                        .cookingMinutesLabel(
                                          product.cookingTimeMinutes!,
                                        ),
                                  ),
                              ],
                            ),
                            for (final group in product.modifierGroups)
                              _buildModifierGroup(context, group),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildBottomBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildModifierGroup(BuildContext context, MenuModifierGroup group) {
    final t = L.of(context);
    final available = group.options
        .where((option) => option.isAvailable)
        .toList(growable: false);
    if (available.isEmpty) return const SizedBox.shrink();
    final selected = _selectedByGroup[group.id] ?? const <String>{};
    final valid = selected.length >= group.minSelected;

    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: TypographyText(
                  group.name,
                  style: AppTextStyles.display(
                    size: 18,
                    height: 1.2,
                    color: AppDesignTokens.primaryText(context),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TypographyText(
                group.minSelected > 0 ? t.requiredChoice : t.optionalChoice,
                style: AppTextStyles.ui(
                  size: 11,
                  weight: FontWeight.w600,
                  color: valid
                      ? AppDesignTokens.tertiaryText(context)
                      : AppDesignTokens.action,
                ),
              ),
            ],
          ),
          if (!valid) ...<Widget>[
            const SizedBox(height: 4),
            TypographyText(
              t.chooseAtLeastOptions(group.minSelected),
              style: AppTextStyles.ui(size: 12, color: AppDesignTokens.action),
            ),
          ],
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppDesignTokens.surface(context),
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusCard),
              boxShadow: AppDesignTokens.cardShadow(context),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: <Widget>[
                for (
                  var index = 0;
                  index < available.length;
                  index++
                ) ...<Widget>[
                  _ProductModifierRow(
                    option: available[index],
                    selected: selected.contains(available[index].id),
                    radioStyle: group.maxSelected == 1,
                    onTap: () => _toggleOption(group, available[index]),
                  ),
                  if (index < available.length - 1)
                    Divider(
                      height: 1,
                      indent: 54,
                      color: AppDesignTokens.hairline(context),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final t = L.of(context);
    final total = _unitPrice * _quantity;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 22,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            _ProductQuantityStepper(
              quantity: _quantity,
              onDecrease: _quantity <= 1
                  ? null
                  : () => setState(() => _quantity--),
              onIncrease: () => setState(() => _quantity++),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    AppDesignTokens.radiusPill,
                  ),
                  boxShadow: _isValid
                      ? AppDesignTokens.actionGlow
                      : const <BoxShadow>[],
                ),
                child: FilledButton(
                  onPressed: _isValid ? _addToCart : null,
                  child: TypographyText(
                    t.addToCartFor(formatSum(context, total)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white),
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

class _ProductDetailCircleButton extends StatelessWidget {
  const _ProductDetailCircleButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      child: IconButton(
        onPressed: onTap,
        tooltip: tooltip,
        icon: Icon(icon, size: 18, color: AppDesignTokens.ink),
      ),
    );
  }
}

class _ProductMetaChip extends StatelessWidget {
  const _ProductMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: AppDesignTokens.primaryText(context).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: AppDesignTokens.secondaryText(context)),
          const SizedBox(width: 5),
          TypographyText(
            label,
            style: AppTextStyles.ui(
              size: 12,
              weight: FontWeight.w600,
              color: AppDesignTokens.secondaryText(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductModifierRow extends StatelessWidget {
  const _ProductModifierRow({
    required this.option,
    required this.selected,
    required this.radioStyle,
    required this.onTap,
  });

  final MenuModifierOption option;
  final bool selected;
  final bool radioStyle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      enabled: option.isAvailable,
      label: option.name,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: <Widget>[
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: selected ? AppDesignTokens.action : Colors.transparent,
                  shape: radioStyle ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: radioStyle ? null : BorderRadius.circular(8),
                  border: Border.all(
                    color: selected
                        ? AppDesignTokens.action
                        : AppDesignTokens.controlBorder(context),
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? Icon(
                        radioStyle ? Icons.circle : Icons.check_rounded,
                        size: radioStyle ? 8 : 14,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TypographyText(
                  option.name,
                  style: AppTextStyles.ui(
                    size: 14.5,
                    weight: FontWeight.w600,
                    color: AppDesignTokens.primaryText(context),
                  ),
                ),
              ),
              if (option.price > 0)
                TypographyText(
                  '+${formatSum(context, option.price)}',
                  style: AppTextStyles.ui(
                    size: 13.5,
                    weight: FontWeight.w600,
                    color: AppDesignTokens.secondaryText(context),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductQuantityStepper extends StatelessWidget {
  const _ProductQuantityStepper({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int quantity;
  final VoidCallback? onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: AppDesignTokens.surface(context),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            onPressed: onDecrease,
            icon: const Icon(Icons.remove_rounded, size: 18),
          ),
          SizedBox(
            width: 24,
            child: TypographyText(
              '$quantity',
              textAlign: TextAlign.center,
              style: AppTextStyles.ui(
                size: 14,
                weight: FontWeight.w700,
                color: AppDesignTokens.primaryText(context),
              ),
            ),
          ),
          IconButton(
            onPressed: onIncrease,
            icon: const Icon(Icons.add_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sticky header delegate for the category tab bar
// ---------------------------------------------------------------------------

class _MenuSkeletonCard extends StatelessWidget {
  const _MenuSkeletonCard({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final baseColor = isDark
        ? const Color(0xFF1D1A18)
        : const Color(0xFFFFFFFF);
    final highlightColor = isDark
        ? const Color(0xFF302A26)
        : const Color(0xFFF0E8E1);

    return Container(
      height: 118,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 94,
            height: 94,
            decoration: BoxDecoration(
              color: highlightColor,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                FractionallySizedBox(
                  widthFactor: 0.84,
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: highlightColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                FractionallySizedBox(
                  widthFactor: 0.52,
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: highlightColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                FractionallySizedBox(
                  widthFactor: 0.66,
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: highlightColor,
                      borderRadius: BorderRadius.circular(999),
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

class _CategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _CategoryHeaderDelegate({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _CategoryHeaderDelegate oldDelegate) {
    return height != oldDelegate.height || child != oldDelegate.child;
  }
}
