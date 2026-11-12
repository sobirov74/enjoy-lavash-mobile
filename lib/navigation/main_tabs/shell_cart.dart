part of 'package:enjoy_lavash_mobile/navigation/main_tabs.dart';

/// Cart edits from the menu and cart tabs, saved-cart restore, catalog
/// reconciliation and repeat order.
extension _ShellCart on _MainTabsState {
  Future<void> _restoreSavedCart() async {
    final savedCart = await CartStorage.readSelections();
    if (!mounted || _cart.editedSinceLaunch || savedCart.isEmpty) return;
    final backend = context.read<MobileBackendController>();
    // A saved menu is not confirmed by the server yet: every line is restored
    // as saved, and the first network catalog reconciles them.
    final products = backend.isShowingCachedContent
        ? const <MenuProduct>[]
        : backend.menuProducts;
    final restored = products.isEmpty
        ? <String, CartSelection>{for (final line in savedCart) line.key: line}
        : reconcileCartSelections(savedCart, products);
    final changed = products.isNotEmpty && restored.length != savedCart.length;
    // Only re-save when reconciliation dropped something.
    _cart.replaceAll(restored.values, persist: changed);
    if (changed) {
      _notifyUnavailableLines(
        unavailableCartSelections(savedCart, products),
        products,
      );
    }
  }

  void _scheduleCartReconciliation(List<MenuProduct> products) {
    if (products.isEmpty ||
        identical(_lastReconciledProducts, products) ||
        _cartReconciliationScheduled) {
      return;
    }
    _cartReconciliationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cartReconciliationScheduled = false;
      if (!mounted) return;
      final previousProducts = _lastReconciledProducts;
      _lastReconciledProducts = products;
      final current = _cart.selections.toList(growable: false);
      final next = reconcileCartSelections(current, products);
      final currentJson = jsonEncode(
        current
            .map(
              (selection) => <String, Object?>{
                'key': selection.key,
                ...selection.toJson(),
              },
            )
            .toList(growable: false),
      );
      final nextJson = jsonEncode(
        next.entries
            .map(
              (entry) => <String, Object?>{
                'key': entry.key,
                ...entry.value.toJson(),
              },
            )
            .toList(growable: false),
      );
      if (currentJson == nextJson) return;
      final removed = unavailableCartSelections(current, products);
      _cart.replaceAll(next.values);
      _notifyUnavailableLines(removed, <MenuProduct>[
        ...products,
        ...?previousProducts,
        ...?_cachedCatalogProducts,
      ]);
    });
  }

  /// Tells the customer which lines were removed, by name when every removed
  /// product is known from [knownProducts].
  void _notifyUnavailableLines(
    List<CartSelection> removed,
    List<MenuProduct> knownProducts,
  ) {
    if (removed.isEmpty || !mounted) return;
    final titles = <String, String>{
      for (final product in knownProducts) product.id: product.title,
    };
    final names = <String>{
      for (final selection in removed) ?titles[selection.productId],
    };
    final t = L.of(context);
    final allNamed = removed.every(
      (selection) => titles.containsKey(selection.productId),
    );
    _showSnack(
      allNamed && names.isNotEmpty
          ? t.cartItemsUnavailable(names.join(', '))
          : t.cartSomeItemsUnavailable,
    );
  }

  void _addToCart(MenuProduct product) {
    _addCartSelection(CartSelection(productId: product.id, quantity: 1));
  }

  void _addConfiguredToCart(CartSelection selection) {
    _addCartSelection(selection);
  }

  /// Adds [selection], capped at [maxCartLineQuantity]. Throws
  /// [CartLineLimitReached] when nothing could be added, so the menu's
  /// add-to-cart flow reports the limit instead of a false "added".
  void _addCartSelection(CartSelection selection) {
    final existingQuantity = _cart.lineFor(selection.key)?.quantity ?? 0;
    final quantity = capCartQuantity(existingQuantity + selection.quantity);
    if (quantity == existingQuantity) throw const CartLineLimitReached();
    _cart.put(selection.copyWith(quantity: quantity));
  }

  void _showQuantityLimit() {
    _showSnack(L.of(context).cartQuantityLimitReached(maxCartLineQuantity));
  }

  void _updateCart(MenuProduct product, int delta) {
    final matching = _cart.selections
        .where((selection) => selection.productId == product.id)
        .toList(growable: false);
    if (delta > 0) {
      if (matching.isEmpty) {
        _addToCart(product);
      } else {
        final line = matching.last;
        _setCartSelectionQuantity(line, line.quantity + delta);
      }
      return;
    }
    if (matching.isEmpty) return;
    final line = matching.last;
    _setCartSelectionQuantity(line, line.quantity + delta, product: product);
  }

  void _updateCartLine(CartLine line, int delta) {
    final selection = _cart.lineFor(line.key);
    if (selection == null) return;
    _setCartSelectionQuantity(
      selection,
      selection.quantity + delta,
      product: line.product,
    );
  }

  void _setCartSelectionQuantity(
    CartSelection selection,
    int requestedQuantity, {
    MenuProduct? product,
  }) {
    final previousQuantity = selection.quantity;
    final nextQuantity = capCartQuantity(requestedQuantity);
    if (requestedQuantity > nextQuantity) _showQuantityLimit();
    if (nextQuantity == previousQuantity) return;
    final removedLine = nextQuantity <= 0 && previousQuantity > 0;
    _cart.put(selection.copyWith(quantity: nextQuantity));

    if (removedLine && product != null) {
      final messenger = ScaffoldMessenger.of(context);
      showAutoClosingAppSnackBar(
        messenger,
        L.of(context).itemRemovedFromCart(product.title),
        actionLabel: L.of(context).undo,
        onAction: () {
          if (!mounted) return;
          _cart.put(selection.copyWith(quantity: previousQuantity));
        },
      );
    }
  }

  void _repeatOrder(CustomerOrderModel order) {
    final t = L.of(context);
    final plan = planRepeatOrder(
      order: order,
      current: _cart.selections,
      products: context.read<MobileBackendController>().menuProducts,
      language: Localizations.localeOf(context).languageCode,
    );
    if (plan.skipped.isNotEmpty) {
      _showSnack(t.repeatOrderSkipped(plan.skipped.join(', ')));
    }
    if (plan.addedUnits == 0) {
      if (plan.skipped.isEmpty) _showSnack(t.noProductsFound);
      _selectTab(_menuTabIndex);
      return;
    }
    _cart.replaceAll(plan.selections, edited: true);
    _selectTab(_cartPageIndex);
  }
}
