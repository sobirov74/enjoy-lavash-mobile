import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/order_model.dart';
import 'package:enjoy_lavash_mobile/features/models/cart_line.dart';
import 'package:enjoy_lavash_mobile/features/models/menu_product.dart';

/// [quantity] limited to [maxCartLineQuantity].
int capCartQuantity(int quantity) =>
    quantity > maxCartLineQuantity ? maxCartLineQuantity : quantity;

/// [selections] checked against the [products] catalog, keyed by line: lines
/// whose product is gone or whose configuration is no longer valid are
/// dropped, and lines that now resolve to the same configuration are merged.
Map<String, CartSelection> reconcileCartSelections(
  Iterable<CartSelection> selections,
  List<MenuProduct> products,
) {
  final productsById = <String, MenuProduct>{
    for (final product in products) product.id: product,
  };
  final reconciled = <String, CartSelection>{};
  for (final selection in selections) {
    final product = productsById[selection.productId];
    if (product == null) continue;
    final current = reconcileCartSelection(selection, product);
    if (current == null || current.quantity <= 0) continue;
    final existing = reconciled[current.key];
    reconciled[current.key] = current.copyWith(
      quantity: current.quantity + (existing?.quantity ?? 0),
    );
  }
  return reconciled;
}

/// Saved lines the [products] catalog can no longer fulfil: the product is
/// gone or its saved configuration is no longer valid.
List<CartSelection> unavailableCartSelections(
  Iterable<CartSelection> selections,
  List<MenuProduct> products,
) {
  final productsById = <String, MenuProduct>{
    for (final product in products) product.id: product,
  };
  return selections
      .where((selection) {
        final product = productsById[selection.productId];
        return product == null ||
            reconcileCartSelection(selection, product) == null;
      })
      .toList(growable: false);
}

/// What repeating an order does to the cart: the resulting [selections], how
/// many units were added, and the names of items that could not be added.
typedef RepeatOrderPlan = ({
  List<CartSelection> selections,
  int addedUnits,
  List<String> skipped,
});

/// Adds [order]'s items to [current] using today's [products].
///
/// Order history does not keep modifier choices, so each product's standard
/// configuration is used. A product that needs a choice, or is gone from the
/// menu, is listed in `skipped` (by its [language] name) instead of being
/// dropped silently. Quantities are capped per line.
RepeatOrderPlan planRepeatOrder({
  required CustomerOrderModel order,
  required Iterable<CartSelection> current,
  required List<MenuProduct> products,
  required String language,
}) {
  final productsById = <String, MenuProduct>{
    for (final product in products) product.id: product,
    for (final product in products)
      if (product.iikoId?.trim().isNotEmpty == true)
        product.iikoId!.trim(): product,
  };

  var added = 0;
  final skipped = <String>[];
  final merged = <String, CartSelection>{
    for (final selection in current) selection.key: selection,
  };
  for (final item in order.items) {
    if (item.quantity <= 0) continue;
    final product = productsById[item.productId];
    final selection = product == null
        ? null
        : standardCartSelection(product, quantity: item.quantity);
    if (selection == null) {
      skipped.add(
        product?.title ?? item.localizedName(language) ?? item.productId,
      );
      continue;
    }
    final existing = merged[selection.key];
    merged[selection.key] = selection.copyWith(
      quantity: capCartQuantity((existing?.quantity ?? 0) + selection.quantity),
    );
    added += item.quantity;
  }
  return (
    selections: merged.values.toList(growable: false),
    addedUnits: added,
    skipped: skipped,
  );
}
