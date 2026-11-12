part of 'package:enjoy_lavash_mobile/screens/menu_screen.dart';

class _ProductDetailPage extends StatefulWidget {
  const _ProductDetailPage({
    required this.product,
    required this.animation,
    required this.heroTag,
    required this.onAdd,
    required this.cartCount,
    required this.onCartTap,
    required this.onCancelAnimation,
    this.gridImageBox,
  });

  /// The menu card's photo box; that smaller decode shows until this page's
  /// own photo is ready, so the Hero never lands on an empty frame.
  final Size? gridImageBox;

  final ValueNotifier<int> cartCount;
  final VoidCallback onCartTap;
  final VoidCallback onCancelAnimation;
  final MenuProduct product;
  final Animation<double> animation;
  final Object heroTag;
  final Future<bool> Function(
    CartSelection,
    CartAnimationSource?,
    Rect? Function(),
    VoidCallback, {
    required CartAnimationSource? Function() fallbackSource,
    required Rect? Function() stagingBounds,
  })
  onAdd;

  @override
  State<_ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<_ProductDetailPage> {
  static const double _photoHeight = 300;

  final Map<String, Set<String>> _selectedByGroup = <String, Set<String>>{};
  int _quantity = 1;
  int _arrival = 0;
  final _imageKey = GlobalKey<CartAnimationAnchorState>();
  final _cartKey = GlobalKey();
  final _bodyKey = GlobalKey();

  @override
  void dispose() {
    widget.onCancelAnimation();
    super.dispose();
  }

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
    unawaited(
      widget.onAdd(
        CartSelection(
          productId: product.id,
          quantity: _quantity,
          modifiers: _selectedModifiers,
        ),
        _imageKey.currentState?.capture(),
        () => cartAnimationBounds(_cartKey),
        () {
          if (mounted) setState(() => _arrival++);
        },
        fallbackSource: _stagedProductSource,
        stagingBounds: () => cartAnimationBounds(_bodyKey),
      ),
    );
  }

  /// The photo spans the page width; it is measured here, outside the Hero,
  /// because a Hero flight would otherwise decode it at every in-between size.
  Widget _productPhoto() => ProductImage(
    product: product,
    width: double.infinity,
    height: _photoHeight,
    layoutWidth: MediaQuery.sizeOf(context).width,
    placeholderBox: widget.gridImageBox,
    borderRadius: 0,
    fallbackFontSize: 110,
  );

  CartAnimationSource? _stagedProductSource() {
    if (!mounted) return null;
    final body = cartAnimationBounds(_bodyKey);
    if (body == null || body.width <= 48 || body.height <= 48) return null;
    // The lazy list may have disposed the hero. Recreate the same photo/crop
    // inside the visible body without scrolling away from selected options.
    final photoSize = Size(body.width, _photoHeight);
    final scale = math.min(
      200 / photoSize.width,
      (body.height - 48) / photoSize.height,
    );
    return CartAnimationSource(
      bounds: Rect.fromCenter(
        center: body.center,
        width: photoSize.width * scale,
        height: photoSize.height * scale,
      ),
      fadeIn: true,
      child: InheritedTheme.captureAll(
        context,
        MediaQuery(
          data: MediaQuery.of(context),
          child: FittedBox(
            child: SizedBox.fromSize(size: photoSize, child: _productPhoto()),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailsAnimation = widget.animation.drive(
      CurveTween(curve: const Interval(0.28, 1, curve: Curves.easeOutCubic)),
    );
    final description = product.description?.trim();

    return PopScope<void>(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) widget.onCancelAnimation();
      },
      child: Semantics(
        key: const ValueKey<String>('product-detail-page'),
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        label: product.title,
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            toolbarHeight: 48,
            leading: IconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
            ),
            actions: [
              ValueListenableBuilder<int>(
                valueListenable: widget.cartCount,
                builder: (context, count, _) => CartArrivalFeedback(
                  revision: _arrival,
                  child: IconButton(
                    tooltip:
                        '${L.of(context).viewCart}, ${L.of(context).cartItemsCount(count)}',
                    onPressed: widget.onCartTap,
                    icon: Badge(
                      isLabelVisible: count > 0,
                      label: Text('$count'),
                      child: Icon(Icons.shopping_bag_outlined, key: _cartKey),
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
              const SizedBox(width: 8),
            ],
          ),
          bottomNavigationBar: _buildBottomBar(context),
          body: Column(
            key: _bodyKey,
            children: <Widget>[
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  physics: const BouncingScrollPhysics(),
                  children: <Widget>[
                    SizedBox(
                      height: _photoHeight,
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
                            child: CartAnimationAnchor(
                              key: _imageKey,
                              child: _productPhoto(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.zero,
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
                                    color: AppDesignTokens.secondaryText(
                                      context,
                                    ),
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
                                      icon:
                                          Icons.local_fire_department_outlined,
                                      label: L
                                          .of(context)
                                          .caloriesLabel(product.calories!),
                                    ),
                                  if (product.weightGrams != null)
                                    _ProductMetaChip(
                                      icon: Icons.scale_outlined,
                                      label: L
                                          .of(context)
                                          .weightGramsLabel(
                                            product.weightGrams!,
                                          ),
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
            ],
          ),
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
                child: CartAddFeedback(
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
            ),
          ],
        ),
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
