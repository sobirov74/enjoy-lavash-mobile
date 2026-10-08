import 'package:enjoy_lavash_mobile/features/cart/presentation/cart_controller.dart';
import 'package:enjoy_lavash_mobile/features/models/cart_line.dart';
import 'package:enjoy_lavash_mobile/features/models/menu_product.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<List<CartSelection>> saved;
  late CartController cart;

  setUp(() {
    saved = <List<CartSelection>>[];
    cart = CartController(
      persist: (selections) async => saved.add(selections.toList()),
    );
  });

  tearDown(() => cart.dispose());

  test('put, remove and clear persist and notify', () {
    var notifications = 0;
    cart.addListener(() => notifications++);

    cart.put(CartSelection(productId: 'lavash', quantity: 2));
    cart.put(CartSelection(productId: 'fries', quantity: 1));
    cart.remove('fries');
    cart.put(CartSelection(productId: 'lavash', quantity: 0));

    expect(cart.isEmpty, isTrue);
    expect(cart.editedSinceLaunch, isTrue);
    expect(notifications, 4);
    expect(saved.last, isEmpty);
    expect(saved[1].map((line) => line.productId), ['lavash', 'fries']);
  });

  test('reconciliation and restore do not count as customer edits', () {
    cart.replaceAll([CartSelection(productId: 'lavash', quantity: 1)]);
    expect(cart.editedSinceLaunch, isFalse);
    expect(cart.selections.single.productId, 'lavash');
  });

  test('the snapshot is cached until the cart or catalog changes', () {
    cart.put(CartSelection(productId: 'lavash', quantity: 2));
    final first = cart.snapshot(_products);
    expect(identical(cart.snapshot(_products), first), isTrue);
    expect(first.totalItems, 2);
    expect(first.totalAmount, 64000);
    expect(first.quantitiesByProduct, {'lavash': 2});

    cart.put(CartSelection(productId: 'lavash', quantity: 3));
    expect(cart.snapshot(_products).totalItems, 3);

    final newCatalog = List<MenuProduct>.of(_products);
    expect(
      identical(cart.snapshot(newCatalog), cart.snapshot(_products)),
      isFalse,
    );
  });

  test('lines missing from the catalog are left out of the snapshot', () {
    cart.put(CartSelection(productId: 'retired', quantity: 1));
    expect(cart.snapshot(_products).isEmpty, isTrue);
    // The saved line itself stays until reconciliation removes it.
    expect(cart.isEmpty, isFalse);
  });
}

const List<MenuProduct> _products = <MenuProduct>[
  MenuProduct(
    id: 'lavash',
    title: 'Lavash',
    price: 32000,
    category: 'Lavash',
    emoji: '🌯',
    tint: Colors.orange,
    highlight: Colors.amber,
  ),
];
