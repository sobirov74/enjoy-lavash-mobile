import 'package:flutter/foundation.dart';

/// Cart units per product as one listenable per product, so a menu card
/// rebuilds only when its own quantity changes instead of on every cart tap.
///
/// The owner feeds it from `CartSnapshot.quantitiesByProduct` whenever the
/// cart or the catalog changes; notifiers are created lazily as cards ask
/// for them and live until [dispose].
class ProductQuantities {
  final Map<String, ValueNotifier<int>> _notifiers =
      <String, ValueNotifier<int>>{};
  Map<String, int> _quantities = const <String, int>{};

  /// Units of [productId] in the cart, across all of its configurations.
  ValueListenable<int> of(String productId) {
    return _notifiers.putIfAbsent(
      productId,
      () => ValueNotifier<int>(_quantities[productId] ?? 0),
    );
  }

  /// Applies new totals; only products whose quantity changed notify.
  void update(Map<String, int> quantities) {
    _quantities = quantities;
    for (final MapEntry(key: productId, value: notifier)
        in _notifiers.entries) {
      notifier.value = quantities[productId] ?? 0;
    }
  }

  void dispose() {
    for (final notifier in _notifiers.values) {
      notifier.dispose();
    }
    _notifiers.clear();
  }
}
