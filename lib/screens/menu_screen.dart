import 'package:enjoy_lavash_mobile/app/locale_controller.dart';
import 'package:enjoy_lavash_mobile/app/location_controller.dart';
import 'package:enjoy_lavash_mobile/core/error/failures.dart';
import 'package:enjoy_lavash_mobile/features/models/menu_product.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/address_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/branch_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/cart_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/promotion_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/presentation/mobile_backend_controller.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/screens/address_bottom_sheet.dart';
import 'package:enjoy_lavash_mobile/screens/branch_bottom_sheet.dart';
import 'package:enjoy_lavash_mobile/theme/app_motion.dart';
import 'package:enjoy_lavash_mobile/utils/price_formatter.dart';
import 'package:enjoy_lavash_mobile/widgets/action_icon_button.dart';
import 'package:enjoy_lavash_mobile/widgets/animated_error_message.dart';
import 'package:enjoy_lavash_mobile/widgets/delivery_chip.dart';
import 'package:enjoy_lavash_mobile/widgets/fade_slide_in.dart';
import 'package:enjoy_lavash_mobile/widgets/product_image.dart';
import 'package:enjoy_lavash_mobile/widgets/product_list_item.dart';
import 'package:enjoy_lavash_mobile/widgets/promo_slider.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'package:enjoy_lavash_mobile/widgets/typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

const String _brandMarkAsset = 'assets/images/enjoy-logo.png';
const double _stickySearchHeaderHeight = 76;
const double _stickyCategoryHeaderHeight = 66;
const double _stickyProductsHeaderHeight =
    _stickySearchHeaderHeight + _stickyCategoryHeaderHeight;

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
    this.onNotificationsTap,
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
  final Failure? menuFailure;
  final String? menuErrorText;

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _categoryScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _categoryPillTrackKey = GlobalKey(
    debugLabel: 'category-pill-track',
  );
  final GlobalKey _cartFlightTargetKey = GlobalKey(
    debugLabel: 'cart-flight-target',
  );

  late final List<GlobalKey> _sectionKeys = _buildKeys(
    widget.categories.length,
  );
  late final List<GlobalKey> _categoryChipKeys = _buildKeys(
    widget.categories.length,
  );

  /// Cached products grouped by category — rebuilt only when products change.
  late Map<String, List<MenuProduct>> _groupedProducts = _groupProducts();

  /// Cached lowercase haystacks so search doesn't re-lowercase every product
  /// on each keystroke.
  late List<({MenuProduct product, String haystack})> _searchIndex =
      _buildSearchIndex();

  bool _isProgrammaticScroll = false;
  bool _scrollSpyScheduled = false;
  String _searchQuery = '';
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
    _scrollController.addListener(_onScrollChanged);
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

    if (oldWidget.products != widget.products) {
      _groupedProducts = _groupProducts();
      _searchIndex = _buildSearchIndex();
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
    _searchController.dispose();
    _scrollController
      ..removeListener(_onScrollChanged)
      ..dispose();
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
    _syncKeyList(_sectionKeys, widget.categories.length);
    _syncKeyList(_categoryChipKeys, widget.categories.length);
  }

  void _syncKeyList(List<GlobalKey> keys, int count) {
    if (keys.length == count) return;

    if (keys.length < count) {
      keys.addAll(_buildKeys(count - keys.length));
      return;
    }

    keys.removeRange(count, keys.length);
  }

  Map<String, List<MenuProduct>> _groupProducts() {
    final map = <String, List<MenuProduct>>{};
    for (final product in widget.products) {
      (map[product.category] ??= []).add(product);
    }
    return map;
  }

  bool get _hasSearchQuery => _searchQuery.trim().isNotEmpty;

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

  String? _pickupButtonSubtitle() {
    final branchName = widget.selectedBranch?.name.trim();
    return branchName == null || branchName.isEmpty ? null : branchName;
  }

  double get _activeStickyHeaderHeight =>
      _hasSearchQuery ? _stickySearchHeaderHeight : _stickyProductsHeaderHeight;

  List<({MenuProduct product, String haystack})> _buildSearchIndex() {
    return widget.products
        .map(
          (product) => (
            product: product,
            haystack: '${product.title} ${product.category} ${product.price}'
                .toLowerCase(),
          ),
        )
        .toList(growable: false);
  }

  List<MenuProduct> _filteredProducts() {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return widget.products;

    return _searchIndex
        .where((entry) => entry.haystack.contains(query))
        .map((entry) => entry.product)
        .toList(growable: false);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollSelectedChipIntoView();
      _updateCategoryPillGeometry();
    });
  }

  void _updateCategoryPillGeometry() {
    if (!mounted || widget.categories.isEmpty || _hasSearchQuery) return;

    final selectedIndex = widget.selectedCategoryIndex.clamp(
      0,
      widget.categories.length - 1,
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
        ),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: AppMotion.enter),
          child: child,
        ),
      ),
    );
  }

  String _productHeroTag(MenuProduct product) => 'menu-product-${product.id}';

  // -------------------------------------------------------------------------
  // Scroll-spy: detect which category section is in view
  // -------------------------------------------------------------------------

  void _onScrollChanged() {
    if (!_scrollController.hasClients || _isProgrammaticScroll) return;
    if (_scrollSpyScheduled) return;

    _scrollSpyScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollSpyScheduled = false;
      if (!mounted || _isProgrammaticScroll) return;
      _updateSelectedCategoryFromScroll();
    });
  }

  void _updateSelectedCategoryFromScroll() {
    if (_hasSearchQuery) return;
    if (!_scrollController.hasClients || widget.categories.isEmpty) return;
    final position = _scrollController.position;

    if (position.pixels >= position.maxScrollExtent - 24) {
      widget.onCategorySelected(widget.categories.length - 1);
      return;
    }

    final viewportCenter =
        _scrollController.offset +
        _activeStickyHeaderHeight +
        (position.viewportDimension - _activeStickyHeaderHeight) / 2;

    var bestIndex = widget.selectedCategoryIndex;
    var bestDistance = double.infinity;

    for (var i = 0; i < _sectionKeys.length; i++) {
      final context = _sectionKeys[i].currentContext;
      if (context == null) continue;

      final box = context.findRenderObject();
      if (box == null || !box.attached) continue;

      final renderBox = box as RenderBox;
      final sectionTop =
          _scrollController.offset +
          renderBox.localToGlobal(Offset.zero).dy -
          _activeStickyHeaderHeight;
      final sectionBottom = sectionTop + renderBox.size.height;

      if (viewportCenter >= sectionTop && viewportCenter < sectionBottom) {
        bestIndex = i;
        break;
      }

      final distance = viewportCenter < sectionTop
          ? sectionTop - viewportCenter
          : viewportCenter - sectionBottom;

      if (distance < bestDistance) {
        bestDistance = distance;
        bestIndex = i;
      }
    }

    if (bestIndex != widget.selectedCategoryIndex) {
      widget.onCategorySelected(bestIndex);
    }
  }

  // -------------------------------------------------------------------------
  // Programmatic scroll to a category section
  // -------------------------------------------------------------------------

  Future<void> _scrollToCategory(int index) async {
    if (index < 0 || index >= _sectionKeys.length) return;

    widget.onCategorySelected(index);
    _isProgrammaticScroll = true;

    try {
      var sectionContext = _sectionKeys[index].currentContext;
      if (sectionContext == null) {
        await _scrollNearCategory(index);
        if (!mounted) return;
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) return;
        sectionContext = _sectionKeys[index].currentContext;
      }

      if (sectionContext != null && sectionContext.mounted) {
        await _scrollToSectionContext(sectionContext);
      }
    } finally {
      if (mounted) {
        _isProgrammaticScroll = false;
        _scrollSelectedChipIntoView();
      }
    }
  }

  Future<void> _scrollNearCategory(int index) async {
    if (!_scrollController.hasClients || widget.categories.length <= 1) return;

    final maxExtent = _scrollController.position.maxScrollExtent;
    final ratio = index / (widget.categories.length - 1);
    final targetOffset = (maxExtent * ratio).clamp(0.0, maxExtent);

    if (AppMotion.reduced(context)) {
      _scrollController.jumpTo(targetOffset);
    } else {
      await _scrollController.animateTo(
        targetOffset,
        duration: AppMotion.micro,
        curve: AppMotion.enter,
      );
    }
  }

  Future<void> _scrollToSectionContext(BuildContext sectionContext) async {
    final renderObject = sectionContext.findRenderObject();
    final viewport = renderObject == null
        ? null
        : RenderAbstractViewport.maybeOf(renderObject);

    if (renderObject == null ||
        viewport == null ||
        !_scrollController.hasClients) {
      return;
    }

    final targetOffset =
        viewport.getOffsetToReveal(renderObject, 0).offset -
        _activeStickyHeaderHeight;
    final clampedOffset = targetOffset.clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    if (AppMotion.reduced(context)) {
      _scrollController.jumpTo(clampedOffset);
    } else {
      await _scrollController.animateTo(
        clampedOffset,
        duration: AppMotion.spatial,
        curve: AppMotion.enter,
      );
    }
  }

  // -------------------------------------------------------------------------
  // Keep the active category chip centered in the horizontal list
  // -------------------------------------------------------------------------

  void _scrollSelectedChipIntoView() {
    if (_hasSearchQuery ||
        !_categoryScrollController.hasClients ||
        widget.categories.isEmpty) {
      return;
    }

    final chipContext =
        _categoryChipKeys[widget.selectedCategoryIndex].currentContext;
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
    final searchResults = _hasSearchQuery
        ? _filteredProducts()
        : const <MenuProduct>[];

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
              // -- Top bar, delivery toggle, promo banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeSlideIn(child: _buildTopBar(t)),
                      const SizedBox(height: 10),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 50),
                        child: _buildDeliveryToggle(t),
                      ),
                      if (widget.promotions.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 100),
                          child: PromoSlider(
                            promotions: widget.promotions,
                            locale: context
                                .watch<LocaleController>()
                                .locale
                                .languageCode,
                          ),
                        ),
                      ],
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
                // -- Sticky product search and category tabs
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _CategoryHeaderDelegate(
                    height: _activeStickyHeaderHeight,
                    child: _buildProductsHeader(theme, t),
                  ),
                ),

                if (_hasSearchQuery)
                  if (searchResults.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildSearchEmptyState(theme, t),
                    )
                  else
                    _buildSearchResultsSliver(searchResults, theme, t)
                else
                  // -- Product sections per category
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, index) => _buildCategorySection(index, theme),
                        childCount: widget.categories.length,
                      ),
                    ),
                  ),
              ],
              if (widget.cartCount > 0)
                const SliverToBoxAdapter(child: SizedBox(height: 90)),
            ],
          ),
        ),
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

  // -------------------------------------------------------------------------
  // Extracted widgets
  // -------------------------------------------------------------------------

  Widget _buildTopBar(L t) {
    return Row(
      children: [
        ActionIconButton(
          icon: Icons.menu_rounded,
          isDark: widget.isDark,
          tooltip: t.menu,
          onTap: () => Scaffold.of(context).openDrawer(),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: widget.isDark ? const Color(0xFF1D1A18) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Image.asset(_brandMarkAsset, height: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: TypographyText(
                    'Enjoy Lavash',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.9,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        _buildNotificationButton(t),
        const SizedBox(width: 8),
        _buildCartButton(t),
      ],
    );
  }

  Widget _buildNotificationButton(L t) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        ActionIconButton(
          icon: Icons.notifications_none_rounded,
          isDark: widget.isDark,
          tooltip: t.notificationInbox,
          onTap: widget.onNotificationsTap,
        ),
        if (widget.notificationUnreadCount > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              constraints: const BoxConstraints(minWidth: 22),
              height: 22,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 5),
              decoration: const BoxDecoration(
                color: BaseColors.primary,
                borderRadius: BorderRadius.all(Radius.circular(99)),
              ),
              child: TypographyText(
                widget.notificationUnreadCount > 99
                    ? '99+'
                    : '${widget.notificationUnreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }

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

  Widget _buildCartButton(L t) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ActionIconButton(
          icon: Icons.shopping_bag_outlined,
          isDark: widget.isDark,
          tooltip: t.cart,
          onTap: widget.onCartTap,
        ),
        Positioned(
          top: -4,
          right: -4,
          child: AnimatedSwitcher(
            duration: AppMotion.duration(context, AppMotion.state),
            switchInCurve: AppMotion.enter,
            switchOutCurve: AppMotion.exit,
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: widget.cartCount > 0
                ? Container(
                    key: ValueKey<int>(widget.cartCount),
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: BaseColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: TypographyText(
                      '${widget.cartCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey<String>('empty-badge')),
          ),
        ),
      ],
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
          '${formatSum(widget.cartTotal)}',
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
                        formatSum(widget.cartTotal),
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

  Widget _buildDeliveryToggle(L t) {
    final deliverySubtitle = _deliveryButtonSubtitle(context);
    final pickupSubtitle = _pickupButtonSubtitle();

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: widget.isDark
            ? const Color(0xFF201C19)
            : const Color(0xFFF0ECE6),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                widget.onOrderTypeChanged(MobileOrderType.delivery);
                showAddressBottomSheet(context);
              },
              child: DeliveryChip(
                icon: Icons.location_on_rounded,
                title: t.address,
                subtitle: deliverySubtitle ?? t.tapToSelectAddress,
                active: widget.orderType == MobileOrderType.delivery,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final branch = await showBranchBottomSheet(
                  context,
                  selectedBranchId: widget.selectedBranch?.id,
                );
                if (branch != null) {
                  await widget.onBranchSelected(branch);
                }
              },
              child: DeliveryChip(
                icon: Icons.shopping_bag_outlined,
                title: t.pickup,
                subtitle: pickupSubtitle ?? t.pickupBranch,
                active: widget.orderType == MobileOrderType.pickup,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsHeader(ThemeData theme, L t) {
    return Container(
      color: theme.scaffoldBackgroundColor,
      child: FadeSlideIn(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: _buildSearchField(t),
            ),
            if (!_hasSearchQuery)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: SizedBox(
                  height: 48,
                  child: SingleChildScrollView(
                    controller: _categoryScrollController,
                    physics: const BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    child: Stack(
                      key: _categoryPillTrackKey,
                      alignment: Alignment.centerLeft,
                      children: <Widget>[
                        if (_categoryPillLeft != null &&
                            _categoryPillWidth != null)
                          AnimatedPositioned(
                            duration: AppMotion.duration(
                              context,
                              AppMotion.state,
                            ),
                            curve: AppMotion.standard,
                            left: _categoryPillLeft,
                            top: 0,
                            width: _categoryPillWidth,
                            height: 48,
                            child: const DecoratedBox(
                              decoration: BoxDecoration(
                                color: BaseColors.primary,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(18),
                                ),
                              ),
                            ),
                          ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            for (
                              var index = 0;
                              index < widget.categories.length;
                              index++
                            ) ...<Widget>[
                              _buildCategoryChip(index),
                              if (index < widget.categories.length - 1)
                                const SizedBox(width: 10),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(L t) {
    return AnimatedContainer(
      duration: AppMotion.duration(context, AppMotion.micro),
      curve: AppMotion.enter,
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1D1A18) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _hasSearchQuery
              ? BaseColors.primary.withValues(alpha: 0.55)
              : Colors.transparent,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDark ? 0.14 : 0.05),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.search_rounded, color: BaseColors.primary, size: 23),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              cursorColor: BaseColors.primary,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: t.searchProducts,
                hintStyle: TextStyle(
                  color: widget.isDark
                      ? const Color(0xFF9E9790)
                      : BaseColors.textGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          AnimatedSwitcher(
            duration: AppMotion.duration(context, AppMotion.micro),
            child: _hasSearchQuery
                ? IconButton(
                    key: const ValueKey<String>('clear-search'),
                    tooltip: t.clearSearch,
                    onPressed: () {
                      _clearSearch();
                    },
                    icon: const Icon(Icons.close_rounded),
                  )
                : const SizedBox(
                    key: ValueKey<String>('empty-search-action'),
                    width: 40,
                    height: 40,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultsSliver(
    List<MenuProduct> products,
    ThemeData theme,
    L t,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      sliver: SliverList.builder(
        itemCount: products.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TypographyText(
                t.searchProductsResultCount(products.length),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: widget.isDark
                      ? BaseColors.lightTextGray
                      : BaseColors.textGray,
                  fontWeight: FontWeight.w800,
                ),
              ),
            );
          }

          final product = products[index - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: RepaintBoundary(
              child: ProductListItem(
                key: ValueKey<String>('search-${product.id}'),
                product: product,
                isDark: widget.isDark,
                quantity: widget.cartQuantities[product.id] ?? 0,
                imageHeroTag: _productHeroTag(product),
                onImageTap: () => _showProductImagePreview(product),
                onAdd: () => widget.onAddToCart(product),
                onAddOrigin: (origin) => _animateProductToCart(product, origin),
                onDecrease: () => widget.onDecreaseFromCart(product),
                onIncrease: () => widget.onAddToCart(product),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchEmptyState(ThemeData theme, L t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 96),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.search_off_rounded,
            size: 44,
            color: widget.isDark
                ? BaseColors.lightTextGray
                : BaseColors.textGray,
          ),
          const SizedBox(height: 16),
          TypographyText(
            t.noProductsFound,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: widget.isDark
                  ? BaseColors.lightTextGray
                  : BaseColors.textGray,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: _clearSearch,
            icon: const Icon(Icons.close_rounded, size: 19),
            label: TypographyText(t.searchAgain),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(int index) {
    final isActive = index == widget.selectedCategoryIndex;
    final labelColor = isActive || widget.isDark
        ? Colors.white
        : const Color(0xFF14110F);
    final hasSharedPill = _categoryPillLeft != null;

    return KeyedSubtree(
      key: _categoryChipKeys[index],
      child: Semantics(
        button: true,
        selected: isActive,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              color: hasSharedPill
                  ? Colors.transparent
                  : isActive
                  ? BaseColors.primary
                  : widget.isDark
                  ? const Color(0xFF201C19)
                  : const Color(0xFFF1EDE7),
              borderRadius: BorderRadius.circular(18),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _scrollToCategory(index),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: AppMotion.duration(context, AppMotion.micro),
                      curve: AppMotion.standard,
                      style: TextStyle(
                        color: labelColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                      child: TypographyText(widget.categories[index]),
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

  Widget _buildCategorySection(int index, ThemeData theme) {
    final category = widget.categories[index];
    final products = _groupedProducts[category] ?? const [];

    return KeyedSubtree(
      key: _sectionKeys[index],
      child: Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: FadeSlideIn(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TypographyText(
                  category,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              for (final product in products)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: RepaintBoundary(
                    child: ProductListItem(
                      key: ValueKey<String>('menu-${product.id}'),
                      product: product,
                      isDark: widget.isDark,
                      quantity: widget.cartQuantities[product.id] ?? 0,
                      imageHeroTag: _productHeroTag(product),
                      onImageTap: () => _showProductImagePreview(product),
                      onAdd: () => widget.onAddToCart(product),
                      onAddOrigin: (origin) =>
                          _animateProductToCart(product, origin),
                      onDecrease: () => widget.onDecreaseFromCart(product),
                      onIncrease: () => widget.onAddToCart(product),
                    ),
                  ),
                ),
            ],
          ),
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

class _ProductDetailPage extends StatelessWidget {
  const _ProductDetailPage({
    required this.product,
    required this.animation,
    required this.heroTag,
  });

  final MenuProduct product;
  final Animation<double> animation;
  final Object heroTag;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetAnimation = animation.drive(CurveTween(curve: AppMotion.enter));
    final detailsAnimation = animation.drive(
      CurveTween(curve: const Interval(0.28, 1, curve: Curves.easeOutCubic)),
    );

    return Semantics(
      key: const ValueKey<String>('product-detail-page'),
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: product.title,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            SafeArea(
              minimum: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.06),
                    end: Offset.zero,
                  ).animate(sheetAnimation),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 520,
                      maxHeight: MediaQuery.sizeOf(context).height * 0.9,
                    ),
                    child: Material(
                      color: isDark ? const Color(0xFF1D1A18) : Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      clipBehavior: Clip.antiAlias,
                      elevation: 18,
                      shadowColor: Colors.black.withValues(alpha: 0.28),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final previewSize = (constraints.maxWidth - 8)
                                .clamp(180.0, 360.0)
                                .toDouble();
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Stack(
                                  alignment: Alignment.center,
                                  children: <Widget>[
                                    Container(
                                      width: 38,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.2,
                                              )
                                            : Colors.black.withValues(
                                                alpha: 0.1,
                                              ),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: IconButton(
                                        tooltip: MaterialLocalizations.of(
                                          context,
                                        ).closeButtonTooltip,
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        icon: const Icon(Icons.close_rounded),
                                      ),
                                    ),
                                  ],
                                ),
                                Center(
                                  child: Hero(
                                    tag: heroTag,
                                    createRectTween: (begin, end) =>
                                        MaterialRectCenterArcTween(
                                          begin: begin,
                                          end: end,
                                        ),
                                    child: ProductImage(
                                      product: product,
                                      width: previewSize,
                                      height: previewSize,
                                      borderRadius: 26,
                                      fallbackFontSize: 96,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                FadeTransition(
                                  opacity: detailsAnimation,
                                  child: SizeTransition(
                                    sizeFactor: detailsAnimation,
                                    axisAlignment: -1,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        TypographyText(
                                          product.title,
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w900,
                                            height: 1.08,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        TypographyText(
                                          product.category,
                                          style: TextStyle(
                                            color: isDark
                                                ? BaseColors.lightTextGray
                                                : BaseColors.textGray,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        TypographyText(
                                          formatSum(product.price),
                                          style: const TextStyle(
                                            color: BaseColors.primary,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
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
