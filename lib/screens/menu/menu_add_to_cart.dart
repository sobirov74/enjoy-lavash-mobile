part of 'package:enjoy_lavash_mobile/screens/menu_screen.dart';

/// Adding to the cart from the grid and the product detail page, with the
/// add-to-cart flight and its confirmation or retry message.
extension _MenuAddToCart on _MenuScreenState {
  Future<void> _commitSelection(
    MenuProduct product,
    CartSelection selection,
  ) async {
    final callback = widget.onAddConfiguredToCart;
    if (callback != null) {
      await callback(selection);
    } else {
      for (var index = 0; index < selection.quantity; index++) {
        try {
          await widget.onAddToCart(product);
        } on CartLineLimitReached {
          rethrow;
        } catch (error) {
          throw _PartialCartAddition(
            selection.copyWith(quantity: selection.quantity - index),
          );
        }
      }
    }
  }

  Future<bool> _addSelection(
    MenuProduct product,
    CartSelection selection,
    CartAnimationSource? source, {
    BuildContext? animationContext,
    Rect? Function()? destination,
    VoidCallback? onArrival,
    CartAnimationSource? Function()? fallbackSource,
    Rect? Function()? stagingBounds,
    double packagingSize = 360,
  }) {
    final host = animationContext ?? context;
    final candidate = widget.packagingAssets[product.id];
    final artwork =
        selection.modifiers.isEmpty && candidate?.matches(product) == true
        ? candidate
        : null;
    return _cartAnimation.add(
      context: host,
      source: source,
      packaging: artwork,
      packagingKind: classifyCartPackaging(product),
      fallbackSource: fallbackSource,
      stagingBounds: stagingBounds,
      packagingSize: packagingSize,
      operation: () => _commitSelection(product, selection),
      destination:
          destination ??
          () =>
              cartAnimationBounds(widget.cartTargetKey ?? _cartFlightTargetKey),
      onConfirmed: () {
        if (!mounted || !_isActive || !host.mounted) return;
        if (onArrival != null) {
          onArrival();
        } else if (widget.onCartArrival != null) {
          widget.onCartArrival!();
        } else {
          _updateState(() => _cartArrivalPulse++);
        }
        final message = L.of(host).itemAddedToCart(product.title);
        ScaffoldMessenger.of(host)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            appSnackBar(message, duration: const Duration(milliseconds: 1100)),
          );
        // Flutter's SnackBar is a semantics live region. It announces the
        // localized confirmation once, without a duplicate platform event.
      },
      onFailed: (error, stack) {
        if (!mounted || !host.mounted) return;
        if (error is CartLineLimitReached) {
          ScaffoldMessenger.of(host)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              appSnackBar(
                L.of(host).cartQuantityLimitReached(maxCartLineQuantity),
              ),
            );
          return;
        }
        final retrySelection = error is _PartialCartAddition
            ? error.remaining
            : selection;
        // Mutation/reconciliation belongs to the cart owner. A rejection never
        // increments a decorative count, and retry invokes exactly one new add.
        ScaffoldMessenger.of(host)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            appSnackBar(
              L.of(host).errorGenericBody,
              actionLabel: L.of(host).retry,
              onAction: () {
                if (mounted && host.mounted) {
                  unawaited(
                    _addSelection(
                      product,
                      retrySelection,
                      null,
                      animationContext: host,
                      destination: destination,
                      onArrival: onArrival,
                      fallbackSource: fallbackSource,
                      stagingBounds: stagingBounds,
                      packagingSize: packagingSize,
                    ),
                  );
                }
              },
            ),
          );
      },
    );
  }

  void _showProductImagePreview(MenuProduct product) {
    _cartAnimation.cancel();
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
          gridImageBox: _gridImageBox,
          animation: animation,
          heroTag: _productHeroTag(product),
          cartCount: _cartCount,
          onCancelAnimation: _cartAnimation.cancel,
          onCartTap: () {
            _cartAnimation.cancel();
            Navigator.of(routeContext).pop();
            widget.onCartTap();
          },
          onAdd:
              (
                selection,
                source,
                destination,
                onArrival, {
                required fallbackSource,
                required stagingBounds,
              }) => _addSelection(
                product,
                selection,
                source,
                animationContext: routeContext,
                destination: destination,
                onArrival: onArrival,
                fallbackSource: fallbackSource,
                stagingBounds: stagingBounds,
              ),
        ),
        transitionsBuilder: (_, animation, _, child) => CurvedFadeTransition(
          animation: animation,
          curve: AppMotion.enter,
          child: child,
        ),
      ),
    );
  }

  String _productHeroTag(MenuProduct product) => 'menu-product-${product.id}';

  void _quickAdd(MenuProduct product, [CartAnimationSource? source]) {
    final selection = standardCartSelection(product);
    if (selection == null) {
      _showProductImagePreview(product);
      return;
    }
    unawaited(_addSelection(product, selection, _visibleGridSource(source)));
  }

  CartAnimationSource? _visibleGridSource(CartAnimationSource? source) {
    if (!mounted || source == null) return null;
    final header = cartAnimationBounds(_categoryPillTrackKey);
    if (header != null && source.bounds.top < header.bottom) return null;
    return CartAnimationSource(
      bounds: source.bounds,
      child: source.child,
      setHidden: source.setHidden,
      recapture: () => _visibleGridSource(
        source.recapture == null ? source : source.recapture!(),
      ),
    );
  }
}
