import 'dart:async';
import 'dart:math' as math;

import 'package:enjoy_lavash_mobile/app/location_controller.dart';
import 'package:enjoy_lavash_mobile/core/error/failures.dart';
import 'package:enjoy_lavash_mobile/features/models/cart_line.dart';
import 'package:enjoy_lavash_mobile/features/models/menu_product.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/address_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/branch_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/cart_model.dart';
import 'package:enjoy_lavash_mobile/features/cart/presentation/cart_controller.dart';
import 'package:enjoy_lavash_mobile/features/cart/presentation/product_quantities.dart';
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
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:enjoy_lavash_mobile/widgets/app_snack_bar.dart';
import 'package:enjoy_lavash_mobile/widgets/cart_animation/cart_animation_controller.dart';
import 'package:enjoy_lavash_mobile/widgets/cart_animation/cart_animation_source.dart';
import 'package:enjoy_lavash_mobile/widgets/cart_animation/cart_arrival_feedback.dart';
import 'package:enjoy_lavash_mobile/widgets/cart_animation/packaging_visual.dart';
import 'package:provider/provider.dart';
import 'package:enjoy_lavash_mobile/widgets/curved_fade_transition.dart';

part 'menu/menu_add_to_cart.dart';
part 'menu/menu_categories.dart';
part 'menu/menu_order_context.dart';
part 'menu/menu_sections.dart';
part 'menu/menu_widgets.dart';
part 'menu/product_detail_page.dart';

const double _stickyCategoryHeaderHeight = 56;

// ---------------------------------------------------------------------------
// MenuScreen — main scrollable menu with sticky category tabs
// ---------------------------------------------------------------------------

const double _productGridSpacing = 12;
const double _productGridWideBreakpoint = 720;

class MenuScreen extends StatefulWidget {
  const MenuScreen({
    super.key,
    required this.isDark,
    required this.isMenuLoading,
    required this.selectedCategoryIndex,
    required this.categories,
    required this.products,
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
    required this.cart,
    this.onAddConfiguredToCart,
    this.onOrderContextTap,
    this.showCartSummary = true,
    this.active,
    this.cartTargetKey,
    this.onCartArrival,
    this.packagingAssets = const {},
    this.menuFailure,
    this.menuErrorText,
  });

  final bool isDark;
  final bool isMenuLoading;
  final int selectedCategoryIndex;
  final List<String> categories;
  final List<MenuProduct> products;
  final MobileOrderType orderType;
  final BranchModel? selectedBranch;
  final ValueChanged<int> onCategorySelected;
  final FutureOr<void> Function(MenuProduct) onAddToCart;
  final FutureOr<void> Function(CartSelection)? onAddConfiguredToCart;
  final ValueChanged<MenuProduct> onDecreaseFromCart;
  final VoidCallback onCartTap;
  final ValueChanged<MobileOrderType> onOrderTypeChanged;
  final Future<void> Function(BranchModel?) onBranchSelected;
  final VoidCallback onRetryMenu;
  final Future<void> Function() onRefresh;

  /// The cart this menu shows quantities for. The menu listens to it itself,
  /// so a quantity change rebuilds only the affected card (and the optional
  /// summary bar), not the whole grid.
  final CartController cart;
  final VoidCallback? onOrderContextTap;
  final bool showCartSummary;

  /// Whether this menu is the visible tab; null means always. Turning false
  /// cancels a running add-to-cart flight.
  final ValueListenable<bool>? active;
  final GlobalKey? cartTargetKey;
  final VoidCallback? onCartArrival;

  /// Optional product-specific artwork overrides. Built-in packaging presets
  /// wrap the displayed photo when a matching, preloaded override is absent.
  final Map<String, CartPackagingAssets> packagingAssets;
  final Failure? menuFailure;
  final String? menuErrorText;

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  /// `setState` for this state's part-file extensions, which may not call
  /// the protected member directly.
  void _updateState(VoidCallback change) => setState(change);

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

  /// Position of the shared selection pill behind the category chips. Only
  /// the category header listens, so measuring it does not rebuild the grid.
  final ValueNotifier<({double left, double width})?> _categoryPill =
      ValueNotifier<({double left, double width})?>(null);
  final _cartAnimation = CartAnimationController();
  final ProductQuantities _quantities = ProductQuantities();

  /// Cart item count for the product detail page's badge.
  late final ValueNotifier<int> _cartCount = ValueNotifier(
    _cartSnapshot.totalItems,
  );
  int _cartArrivalPulse = 0;

  /// Box of a grid card's photo, measured by the grid; see [_ProductDetailPage.gridImageBox].
  Size? _gridImageBox;

  List<MenuProduct>? _visibleProductsSource;
  String? _visibleProductsCategory;
  List<MenuProduct> _visibleProducts = const <MenuProduct>[];

  CartSnapshot get _cartSnapshot => widget.cart.snapshot(widget.products);

  bool get _isActive => widget.active?.value ?? true;

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _quantities.update(_cartSnapshot.quantitiesByProduct);
    widget.cart.addListener(_handleCartChanged);
    widget.active?.addListener(_handleActiveChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollSelectedChipIntoView();
      _updateCategoryPillGeometry();
    });
  }

  /// A cart change outside the build phase (a tap, a restore, a
  /// reconciliation): only the cards whose quantity changed rebuild.
  void _handleCartChanged() {
    final snapshot = _cartSnapshot;
    _quantities.update(snapshot.quantitiesByProduct);
    _cartCount.value = snapshot.totalItems;
  }

  void _handleActiveChanged() {
    if (!_isActive) _cartAnimation.cancel();
  }

  bool _packagingPreloaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Dependencies change on every theme, locale or text-scale update; the
    // packaging artwork only needs warming once (and again if it changes).
    if (!_packagingPreloaded) {
      _packagingPreloaded = true;
      unawaited(_cartAnimation.preload(context, widget.packagingAssets.values));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateCategoryPillGeometry();
    });
  }

  @override
  void didUpdateWidget(covariant MenuScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      oldWidget.active?.removeListener(_handleActiveChanged);
      widget.active?.addListener(_handleActiveChanged);
      if (!_isActive) _cartAnimation.cancel();
    }
    if (oldWidget.packagingAssets != widget.packagingAssets) {
      unawaited(_cartAnimation.preload(context, widget.packagingAssets.values));
    }
    if (oldWidget.cart != widget.cart ||
        !identical(oldWidget.products, widget.products)) {
      oldWidget.cart.removeListener(_handleCartChanged);
      widget.cart.addListener(_handleCartChanged);
      final snapshot = _cartSnapshot;
      // The cards are descendants about to rebuild anyway; the detail page's
      // badge is another route, so it is updated after this frame.
      _quantities.update(snapshot.quantitiesByProduct);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _cartCount.value = snapshot.totalItems;
      });
    }

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
    widget.cart.removeListener(_handleCartChanged);
    widget.active?.removeListener(_handleActiveChanged);
    _cartAnimation.dispose();
    _cartCount.dispose();
    _quantities.dispose();
    _categoryPill.dispose();
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

  double get _activeStickyHeaderHeight => _stickyCategoryHeaderHeight;

  // -------------------------------------------------------------------------
  // Keep the active category chip centered in the horizontal list
  // -------------------------------------------------------------------------

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
    final visibleProducts = _productsIn(selectedCategory);

    return Stack(
      children: <Widget>[
        RefreshIndicator(
          color: BaseColors.primary,
          onRefresh: widget.onRefresh,
          child: CustomScrollView(
            controller: _scrollController,
            scrollCacheExtent: const ScrollCacheExtent.pixels(1200),
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
                    sliver: _buildProductGrid(visibleProducts),
                  ),
              ],
              if (widget.showCartSummary)
                SliverToBoxAdapter(
                  child: ListenableBuilder(
                    listenable: widget.cart,
                    builder: (context, _) =>
                        SizedBox(height: _cartSnapshot.totalItems > 0 ? 90 : 0),
                  ),
                ),
            ],
          ),
        ),
        if (widget.showCartSummary)
          Positioned(
            left: 16,
            right: 16,
            bottom: 12,
            child: ListenableBuilder(
              listenable: widget.cart,
              builder: (context, _) {
                final cart = _cartSnapshot;
                final hasItems = cart.totalItems > 0;
                return AnimatedSlide(
                  duration: AppMotion.duration(context, AppMotion.state),
                  curve: AppMotion.enter,
                  offset: hasItems ? Offset.zero : const Offset(0, 1.4),
                  child: AnimatedOpacity(
                    duration: AppMotion.duration(context, AppMotion.micro),
                    opacity: hasItems ? 1 : 0,
                    child: IgnorePointer(
                      ignoring: !hasItems,
                      child: _buildCartSummaryBar(
                        t,
                        count: cart.totalItems,
                        total: cart.totalAmount,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  /// Products of [category] (all of them for null), filtered once per
  /// catalog and category instead of on every build.
  List<MenuProduct> _productsIn(String? category) {
    if (category == null) return widget.products;
    if (!identical(_visibleProductsSource, widget.products) ||
        _visibleProductsCategory != category) {
      _visibleProductsSource = widget.products;
      _visibleProductsCategory = category;
      _visibleProducts = widget.products
          .where((product) => product.category == category)
          .toList(growable: false);
    }
    return _visibleProducts;
  }

  // -------------------------------------------------------------------------
  // Extracted widgets
  // -------------------------------------------------------------------------
}

// ---------------------------------------------------------------------------
// Sticky header delegate for the category tab bar
// ---------------------------------------------------------------------------
