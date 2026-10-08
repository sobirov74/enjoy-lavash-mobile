import 'dart:async';

import 'package:enjoy_lavash_mobile/core/storage/cart_storage.dart';
import 'package:enjoy_lavash_mobile/features/models/cart_line.dart';
import 'package:enjoy_lavash_mobile/features/models/menu_product.dart';
import 'package:flutter/foundation.dart';

/// Cart lines resolved against one catalog snapshot.
@immutable
class CartSnapshot {
  const CartSnapshot._({
    required this.lines,
    required this.totalItems,
    required this.totalAmount,
    required this.quantitiesByProduct,
  });

  static const CartSnapshot empty = CartSnapshot._(
    lines: <CartLine>[],
    totalItems: 0,
    totalAmount: 0,
    quantitiesByProduct: <String, int>{},
  );

  final List<CartLine> lines;
  final int totalItems;
  final int totalAmount;

  /// Units per product id across all of its configurations.
  final Map<String, int> quantitiesByProduct;

  bool get isEmpty => lines.isEmpty;
}

/// The customer's cart: configured lines keyed by product and modifiers,
/// persisted with [CartStorage] after every change.
///
/// The app shell owns it and passes it to the widgets that show cart data,
/// which listen to it directly. A quantity tap therefore rebuilds the menu,
/// the cart tab and the bottom bar, not every tab of the app.
class CartController extends ChangeNotifier {
  CartController({Future<void> Function(Iterable<CartSelection>)? persist})
    : _persist = persist ?? CartStorage.saveSelections;

  final Future<void> Function(Iterable<CartSelection>) _persist;
  final Map<String, CartSelection> _lines = <String, CartSelection>{};
  bool _editedSinceLaunch = false;
  bool _disposed = false;

  int _version = 0;
  int _snapshotVersion = -1;
  List<MenuProduct>? _snapshotProducts;
  CartSnapshot _snapshot = CartSnapshot.empty;

  Iterable<CartSelection> get selections => _lines.values;
  bool get isEmpty => _lines.isEmpty;

  /// Whether the customer changed the cart in this app session. A saved cart
  /// read late from storage must not overwrite those changes.
  bool get editedSinceLaunch => _editedSinceLaunch;

  CartSelection? lineFor(String key) => _lines[key];

  /// Lines for [products], cached until the cart or the catalog changes.
  CartSnapshot snapshot(List<MenuProduct> products) {
    if (_snapshotVersion == _version &&
        identical(_snapshotProducts, products)) {
      return _snapshot;
    }
    _snapshotVersion = _version;
    _snapshotProducts = products;
    return _snapshot = _resolve(products);
  }

  /// Sets one line; a quantity of zero or less removes it.
  void put(CartSelection selection) {
    if (selection.quantity <= 0) {
      if (_lines.remove(selection.key) == null) return;
    } else {
      _lines[selection.key] = selection;
    }
    _changed(edited: true);
  }

  void remove(String key) {
    if (_lines.remove(key) == null) return;
    _changed(edited: true);
  }

  /// Replaces every line. [edited] marks a customer action; catalog
  /// reconciliation and restoring the saved cart are not.
  void replaceAll(
    Iterable<CartSelection> selections, {
    bool edited = false,
    bool persist = true,
  }) {
    _lines
      ..clear()
      ..addEntries(
        selections.map((selection) => MapEntry(selection.key, selection)),
      );
    _changed(edited: edited, persist: persist);
  }

  void clear() {
    if (_lines.isEmpty) {
      _editedSinceLaunch = true;
      unawaited(_persist(const <CartSelection>[]));
      return;
    }
    _lines.clear();
    _changed(edited: true);
  }

  void _changed({required bool edited, bool persist = true}) {
    _version++;
    if (edited) _editedSinceLaunch = true;
    if (persist) unawaited(_persist(List<CartSelection>.of(_lines.values)));
    if (!_disposed) notifyListeners();
  }

  CartSnapshot _resolve(List<MenuProduct> products) {
    if (_lines.isEmpty) return CartSnapshot.empty;
    final productById = <String, MenuProduct>{
      for (final product in products) product.id: product,
    };
    final lines = <CartLine>[];
    final quantities = <String, int>{};
    var totalItems = 0;
    var totalAmount = 0;
    for (final selection in _lines.values) {
      final product = productById[selection.productId];
      if (product == null) continue;
      final reconciled = reconcileCartSelection(selection, product);
      if (reconciled == null) continue;
      final line = CartLine(
        product: product,
        quantity: reconciled.quantity,
        modifiers: reconciled.modifiers,
      );
      lines.add(line);
      totalItems += line.quantity;
      totalAmount += line.lineTotal;
      quantities.update(
        product.id,
        (quantity) => quantity + line.quantity,
        ifAbsent: () => line.quantity,
      );
    }
    return CartSnapshot._(
      lines: List<CartLine>.unmodifiable(lines),
      totalItems: totalItems,
      totalAmount: totalAmount,
      quantitiesByProduct: Map<String, int>.unmodifiable(quantities),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
