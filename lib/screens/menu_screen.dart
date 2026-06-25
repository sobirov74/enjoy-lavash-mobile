import 'package:enjoy_lavash_mobile/app/locale_controller.dart';
import 'package:enjoy_lavash_mobile/app/location_controller.dart';
import 'package:enjoy_lavash_mobile/features/models/menu_product.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/branch_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/cart_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/promotion_model.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/screens/address_bottom_sheet.dart';
import 'package:enjoy_lavash_mobile/screens/branch_bottom_sheet.dart';
import 'package:enjoy_lavash_mobile/widgets/action_icon_button.dart';
import 'package:enjoy_lavash_mobile/widgets/delivery_chip.dart';
import 'package:enjoy_lavash_mobile/widgets/product_list_item.dart';
import 'package:enjoy_lavash_mobile/widgets/promo_slider.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'package:enjoy_lavash_mobile/widgets/typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
    required this.cartQuantities,
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
  final ValueChanged<BranchModel?> onBranchSelected;
  final VoidCallback onRetryMenu;
  final Future<void> Function() onRefresh;
  final int cartCount;
  final Map<String, int> cartQuantities;
  final String? menuErrorText;

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _categoryScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  late final List<GlobalKey> _sectionKeys = _buildKeys(
    widget.categories.length,
  );
  late final List<GlobalKey> _categoryChipKeys = _buildKeys(
    widget.categories.length,
  );

  /// Cached products grouped by category — rebuilt only when products change.
  late Map<String, List<MenuProduct>> _groupedProducts = _groupProducts();

  bool _isProgrammaticScroll = false;
  bool _scrollSpyScheduled = false;
  String _searchQuery = '';

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScrollChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollSelectedChipIntoView();
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
    }

    if (oldWidget.selectedCategoryIndex != widget.selectedCategoryIndex ||
        oldWidget.categories.length != widget.categories.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollSelectedChipIntoView();
      });
    }
  }

  @override
  void dispose() {
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

  double get _activeStickyHeaderHeight =>
      _hasSearchQuery ? _stickySearchHeaderHeight : _stickyProductsHeaderHeight;

  List<MenuProduct> _filteredProducts() {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return widget.products;

    return widget.products
        .where((product) {
          return product.title.toLowerCase().contains(query) ||
              product.category.toLowerCase().contains(query) ||
              product.price.toString().contains(query);
        })
        .toList(growable: false);
  }

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

    await _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
    );
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

    await _scrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
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

    _categoryScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
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

    return RefreshIndicator(
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
                  _buildTopBar(),
                  const SizedBox(height: 10),
                  _buildAddressBar(context),
                  const SizedBox(height: 10),
                  _buildDeliveryToggle(t),
                  if (widget.promotions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    PromoSlider(
                      promotions: widget.promotions,
                      locale: context
                          .watch<LocaleController>()
                          .locale
                          .languageCode,
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
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Extracted widgets
  // -------------------------------------------------------------------------

  Widget _buildTopBar() {
    return Row(
      children: [
        ActionIconButton(
          icon: Icons.menu_rounded,
          isDark: widget.isDark,
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
                const TypographyText(
                  'Enjoy Lavash',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.9,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        _buildCartButton(),
      ],
    );
  }

  Widget _buildMenuState(ThemeData theme, L t) {
    final errorText = widget.menuErrorText;

    if (widget.isMenuLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: widget.isDark ? Colors.white : BaseColors.primary,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 96),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            errorText == null
                ? Icons.restaurant_menu_rounded
                : Icons.cloud_off_rounded,
            size: 44,
            color: widget.isDark
                ? BaseColors.lightTextGray
                : BaseColors.textGray,
          ),
          const SizedBox(height: 16),
          TypographyText(
            errorText ?? t.emptyList,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: widget.isDark
                  ? BaseColors.lightTextGray
                  : BaseColors.textGray,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (errorText != null) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: widget.onRetryMenu,
              icon: const Icon(Icons.refresh_rounded),
              label: const TypographyText('Retry'),
              style: FilledButton.styleFrom(
                backgroundColor: BaseColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddressBar(BuildContext context) {
    final loc = context.watch<LocationController>();
    final t = L.of(context);
    final isLoading = loc.status == LocationStatus.loading;
    final hasAddress = loc.addressName.isNotEmpty;

    return GestureDetector(
      onTap: () => showAddressBottomSheet(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: widget.isDark ? const Color(0xFF1D1A18) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_on_rounded,
              color: BaseColors.primary,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TypographyText(
                    t.deliveryAddress,
                    style: TextStyle(
                      fontSize: 11,
                      color: widget.isDark
                          ? const Color(0xFF9E9790)
                          : BaseColors.textGray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  isLoading
                      ? SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: BaseColors.primary,
                          ),
                        )
                      : TypographyText(
                          hasAddress ? loc.fullAddress : t.tapToSelectAddress,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: hasAddress ? null : BaseColors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: widget.isDark
                  ? const Color(0xFF9E9790)
                  : BaseColors.textGray,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartButton() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ActionIconButton(
          icon: Icons.shopping_bag_outlined,
          isDark: widget.isDark,
          onTap: widget.onCartTap,
        ),
        if (widget.cartCount > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
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
            ),
          ),
      ],
    );
  }

  Widget _buildDeliveryToggle(L t) {
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
              onTap: () => widget.onOrderTypeChanged(MobileOrderType.delivery),
              child: DeliveryChip(
                icon: Icons.delivery_dining_rounded,
                title: t.delivery,
                active: widget.orderType == MobileOrderType.delivery,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final branch = await showBranchBottomSheet(context);
                if (branch != null) {
                  widget.onBranchSelected(branch);
                }
              },
              child: DeliveryChip(
                icon: Icons.shopping_bag_outlined,
                title: widget.selectedBranch != null
                    ? widget.selectedBranch!.name.split(' — ').last
                    : t.pickup,
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
                height: 46,
                child: ListView.separated(
                  controller: _categoryScrollController,
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (_, index) => _buildCategoryChip(index),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchField(L t) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
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
                hintText: _menuText(
                  t,
                  en: 'Search products',
                  ru: 'Поиск товаров',
                  uz: 'Mahsulot qidirish',
                ),
                hintStyle: TextStyle(
                  color: widget.isDark
                      ? const Color(0xFF9E9790)
                      : BaseColors.textGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                if (value.trim().isNotEmpty && _scrollController.hasClients) {
                  _scrollController.animateTo(
                    _scrollController.offset.clamp(
                      0.0,
                      _scrollController.position.maxScrollExtent,
                    ),
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOutCubic,
                  );
                }
              },
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: _hasSearchQuery
                ? IconButton(
                    key: const ValueKey<String>('clear-search'),
                    tooltip: _menuText(
                      t,
                      en: 'Clear search',
                      ru: 'Очистить поиск',
                      uz: 'Qidiruvni tozalash',
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollSelectedChipIntoView();
                      });
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
                _menuText(
                  t,
                  en: '${products.length} result${products.length == 1 ? '' : 's'}',
                  ru: 'Найдено: ${products.length}',
                  uz: '${products.length} ta natija',
                ),
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
                onAdd: () => widget.onAddToCart(product),
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
            _menuText(
              t,
              en: 'No products found',
              ru: 'Товары не найдены',
              uz: 'Mahsulot topilmadi',
            ),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: widget.isDark
                  ? BaseColors.lightTextGray
                  : BaseColors.textGray,
              fontWeight: FontWeight.w800,
            ),
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

    return KeyedSubtree(
      key: _categoryChipKeys[index],
      child: ChoiceChip(
        label: TypographyText(
          widget.categories[index],
          style: TextStyle(
            color: labelColor,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        selected: isActive,
        showCheckmark: false,
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        backgroundColor: widget.isDark
            ? const Color(0xFF201C19)
            : const Color(0xFFF1EDE7),
        selectedColor: BaseColors.primary,
        onSelected: (_) => _scrollToCategory(index),
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
                    product: product,
                    isDark: widget.isDark,
                    quantity: widget.cartQuantities[product.id] ?? 0,
                    onAdd: () => widget.onAddToCart(product),
                    onDecrease: () => widget.onDecreaseFromCart(product),
                    onIncrease: () => widget.onAddToCart(product),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _menuText(
  L t, {
  required String en,
  required String ru,
  required String uz,
}) {
  return switch (t.localeName.split('_').first) {
    'ru' => ru,
    'uz' => uz,
    _ => en,
  };
}

// ---------------------------------------------------------------------------
// Sticky header delegate for the category tab bar
// ---------------------------------------------------------------------------

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
