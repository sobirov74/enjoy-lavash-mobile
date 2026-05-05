import 'package:enjoy_lavash_mobile/app/location_controller.dart';
import 'package:enjoy_lavash_mobile/features/models/menu_product.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/screens/address_bottom_sheet.dart';
import 'package:enjoy_lavash_mobile/screens/branch_bottom_sheet.dart';
import 'package:enjoy_lavash_mobile/widgets/action_icon_button.dart';
import 'package:enjoy_lavash_mobile/widgets/delivery_chip.dart';
import 'package:enjoy_lavash_mobile/widgets/product_list_item.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'package:enjoy_lavash_mobile/widgets/typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

const String _brandMarkAsset =
    'web-design/Mobile app design request/src/imports/image-1.png';
const double _stickyCategoryHeaderHeight = 78;

// ---------------------------------------------------------------------------
// MenuScreen — main scrollable menu with sticky category tabs
// ---------------------------------------------------------------------------

class MenuScreen extends StatefulWidget {
  const MenuScreen({
    super.key,
    required this.isDark,
    required this.selectedCategoryIndex,
    required this.categories,
    required this.products,
    required this.onCategorySelected,
    required this.onAddToCart,
    required this.cartCount,
  });

  final bool isDark;
  final int selectedCategoryIndex;
  final List<String> categories;
  final List<MenuProduct> products;
  final ValueChanged<int> onCategorySelected;
  final ValueChanged<MenuProduct> onAddToCart;
  final int cartCount;

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _categoryScrollController = ScrollController();

  late final List<GlobalKey> _sectionKeys = List<GlobalKey>.generate(
    widget.categories.length,
    (_) => GlobalKey(),
  );
  late final List<GlobalKey> _categoryChipKeys = List<GlobalKey>.generate(
    widget.categories.length,
    (_) => GlobalKey(),
  );

  /// Cached products grouped by category — rebuilt only when products change.
  late Map<String, List<MenuProduct>> _groupedProducts = _groupProducts();

  bool _isProgrammaticScroll = false;
  bool _isDelivery = true;
  Branch? _selectedBranch;

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

    if (oldWidget.products != widget.products) {
      _groupedProducts = _groupProducts();
    }

    if (oldWidget.selectedCategoryIndex != widget.selectedCategoryIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollSelectedChipIntoView();
      });
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScrollChanged)
      ..dispose();
    _categoryScrollController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  Map<String, List<MenuProduct>> _groupProducts() {
    final map = <String, List<MenuProduct>>{};
    for (final product in widget.products) {
      (map[product.category] ??= []).add(product);
    }
    return map;
  }

  // -------------------------------------------------------------------------
  // Scroll-spy: detect which category section is in view
  // -------------------------------------------------------------------------

  void _onScrollChanged() {
    if (!_scrollController.hasClients || _isProgrammaticScroll) return;

    final position = _scrollController.position;

    if (position.pixels >= position.maxScrollExtent - 24) {
      widget.onCategorySelected(widget.categories.length - 1);
      return;
    }

    final viewportCenter =
        _scrollController.offset +
        _stickyCategoryHeaderHeight +
        (position.viewportDimension - _stickyCategoryHeaderHeight) / 2;

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
          _stickyCategoryHeaderHeight;
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
    final sectionContext = _sectionKeys[index].currentContext;
    if (sectionContext == null) {
      widget.onCategorySelected(index);
      return;
    }

    widget.onCategorySelected(index);
    _isProgrammaticScroll = true;

    final renderObject = sectionContext.findRenderObject();
    final viewport = renderObject == null
        ? null
        : RenderAbstractViewport.maybeOf(renderObject);

    if (renderObject != null &&
        viewport != null &&
        _scrollController.hasClients) {
      final targetOffset =
          viewport.getOffsetToReveal(renderObject, 0).offset -
          _stickyCategoryHeaderHeight;
      final clampedOffset = targetOffset.clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );

      await _scrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeInOutCubic,
      );
    }

    if (!mounted) return;

    _isProgrammaticScroll = false;
    _scrollSelectedChipIntoView();
  }

  // -------------------------------------------------------------------------
  // Keep the active category chip centered in the horizontal list
  // -------------------------------------------------------------------------

  void _scrollSelectedChipIntoView() {
    if (!_categoryScrollController.hasClients) return;

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

    return CustomScrollView(
      controller: _scrollController,
      cacheExtent: 1200,
      slivers: [
        // -- Top bar, delivery toggle, promo banner
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(),
                const SizedBox(height: 14),
                _buildAddressBar(context),
                const SizedBox(height: 14),
                _buildDeliveryToggle(t),
                const SizedBox(height: 20),
                _buildPromoBanner(theme, t),
              ],
            ),
          ),
        ),

        // -- Sticky category tabs
        SliverPersistentHeader(
          pinned: true,
          delegate: _CategoryHeaderDelegate(
            height: _stickyCategoryHeaderHeight,
            child: Container(
              color: theme.scaffoldBackgroundColor,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
              child: SizedBox(
                height: 50,
                child: ListView.separated(
                  controller: _categoryScrollController,
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (_, index) => _buildCategoryChip(index),
                ),
              ),
            ),
          ),
        ),

        // -- Product sections per category
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, index) => _buildCategorySection(index, theme),
              childCount: widget.categories.length,
            ),
          ),
        ),
      ],
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
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 18),
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
                  'EnjoyLavash',
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      padding: const EdgeInsets.all(6),
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
              onTap: () => setState(() {
                _isDelivery = true;
                _selectedBranch = null;
              }),
              child: DeliveryChip(
                icon: Icons.delivery_dining_rounded,
                title: t.delivery,
                active: _isDelivery,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final branch = await showBranchBottomSheet(context);
                if (branch != null) {
                  setState(() {
                    _isDelivery = false;
                    _selectedBranch = branch;
                  });
                }
              },
              child: DeliveryChip(
                icon: Icons.shopping_bag_outlined,
                title: _selectedBranch != null
                    ? _selectedBranch!.name.split(' — ').last
                    : t.pickup,
                active: !_isDelivery,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoBanner(ThemeData theme, L t) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB74D), BaseColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TypographyText(
            t.specialOffer,
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          TypographyText(
            t.specialOfferDesc,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(999),
            ),
            child: TypographyText(
              t.specialOfferCta,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
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
                padding: const EdgeInsets.only(bottom: 14),
                child: RepaintBoundary(
                  child: ProductListItem(
                    product: product,
                    isDark: widget.isDark,
                    onAdd: () => widget.onAddToCart(product),
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
