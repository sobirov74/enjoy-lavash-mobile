part of 'package:enjoy_lavash_mobile/screens/menu_screen.dart';

/// The menu's parts: loading/error/empty states, the category header, the
/// lazily built product grid and the optional cart summary bar.
extension _MenuSections on _MenuScreenState {
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

  Widget _buildCartSummaryBar(L t, {required int count, required int total}) {
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
          '${t.viewCart}, ${t.cartItemsCount(count)}, '
          '${formatSum(context, total)}',
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
          onTap: () {
            _cartAnimation.cancel();
            widget.onCartTap();
          },
          splashColor: BaseColors.primary.withValues(alpha: 0.08),
          highlightColor: BaseColors.primary.withValues(alpha: 0.04),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 68),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: <Widget>[
                  CartArrivalFeedback(
                    revision: _cartArrivalPulse,
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
                      child: Badge(
                        label: Text('$count'),
                        child: const Icon(
                          Icons.shopping_bag_outlined,
                          color: Colors.white,
                          size: 24,
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
                          t.cartItemsCount(count),
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
                        formatSum(context, total),
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
              // Only the chips and the pill follow the measured pill position.
              child: ValueListenableBuilder<({double left, double width})?>(
                valueListenable: _categoryPill,
                builder: (context, pill, _) => Stack(
                  key: _categoryPillTrackKey,
                  alignment: Alignment.centerLeft,
                  children: <Widget>[
                    if (pill != null)
                      AnimatedPositioned(
                        duration: AppMotion.duration(context, AppMotion.state),
                        curve: AppMotion.standard,
                        left: pill.left,
                        top: 0,
                        width: pill.width,
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
                          _buildCategoryChip(
                            displayIndex,
                            hasSharedPill: pill != null,
                          ),
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
      ),
    );
  }

  Widget _buildCategoryChip(int displayIndex, {required bool hasSharedPill}) {
    final categoryIndex = displayIndex - 1;
    final isActive = categoryIndex == widget.selectedCategoryIndex;
    final labelColor = isActive
        ? AppDesignTokens.onInk(context)
        : AppDesignTokens.primaryText(context);

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

  /// Lazily built grid: one sliver row per [columns] products, created only
  /// as it scrolls into view. (A `Wrap` in a box adapter built, laid out and
  /// painted every card of the category at once.) Rows keep the cards'
  /// natural height, which the card itself keeps uniform.
  Widget _buildProductGrid(List<MenuProduct> products) {
    // The layout builder runs on every layout of the sliver, and scrolling
    // changes its constraints each frame. Returning a new list each time
    // rebuilt every visible card per frame, so the list made for this menu
    // build is reused while the grid's width stays the same (scrolling does
    // not change it). The width, not only the column count: the cards decode
    // their photos for the column width captured below.
    ({double width, Widget sliver})? built;
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final columns =
            constraints.crossAxisExtent >= _productGridWideBreakpoint ? 3 : 2;
        final reusable = built;
        if (reusable != null && reusable.width == constraints.crossAxisExtent) {
          return reusable.sliver;
        }
        final columnWidth =
            (constraints.crossAxisExtent -
                (columns - 1) * _productGridSpacing) /
            columns;
        // The detail page shows this decoded card photo while its own,
        // larger one loads.
        _gridImageBox = Size(columnWidth, ProductListItem.imageHeight);
        final rowCount = (products.length / columns).ceil();
        final sliver = SliverList.separated(
          itemCount: rowCount,
          separatorBuilder: (_, _) =>
              const SizedBox(height: _productGridSpacing),
          itemBuilder: (context, row) {
            final start = row * columns;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (var column = 0; column < columns; column++) ...<Widget>[
                  if (column > 0) const SizedBox(width: _productGridSpacing),
                  Expanded(
                    child: start + column < products.length
                        ? _buildProductCard(
                            products[start + column],
                            imageWidth: columnWidth,
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            );
          },
        );
        built = (width: constraints.crossAxisExtent, sliver: sliver);
        return sliver;
      },
    );
  }

  Widget _buildProductCard(MenuProduct product, {double? imageWidth}) {
    return RepaintBoundary(
      // Rebuilt on its own when this product's cart quantity changes.
      child: ValueListenableBuilder<int>(
        valueListenable: _quantities.of(product.id),
        builder: (context, quantity, _) => ProductListItem(
          key: ValueKey<String>('menu-${product.id}'),
          product: product,
          isDark: widget.isDark,
          quantity: quantity,
          imageHeroTag: _productHeroTag(product),
          imageWidth: imageWidth,
          onImageTap: () => _showProductImagePreview(product),
          onAdd: () => _quickAdd(product),
          onAddRequested: (source) => _quickAdd(product, source),
          onDecrease: () => widget.onDecreaseFromCart(product),
          onIncrease: () => _quickAdd(product),
        ),
      ),
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
