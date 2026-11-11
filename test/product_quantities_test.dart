import 'package:enjoy_lavash_mobile/features/cart/presentation/product_quantities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a product notifies only when its own quantity changes', () {
    final quantities = ProductQuantities();
    addTearDown(quantities.dispose);
    quantities.update(const {'lavash': 1});

    final lavash = quantities.of('lavash');
    final burger = quantities.of('burger');
    expect(lavash.value, 1);
    expect(burger.value, 0);

    var lavashNotifications = 0;
    var burgerNotifications = 0;
    lavash.addListener(() => lavashNotifications++);
    burger.addListener(() => burgerNotifications++);

    quantities.update(const {'lavash': 2});
    expect(lavash.value, 2);
    expect(lavashNotifications, 1);
    expect(burgerNotifications, 0);

    quantities.update(const {'lavash': 2, 'burger': 1});
    expect(lavashNotifications, 1);
    expect(burgerNotifications, 1);

    quantities.update(const <String, int>{});
    expect(lavash.value, 0);
    expect(burger.value, 0);
  });

  test('a listenable asked for later starts at the current quantity', () {
    final quantities = ProductQuantities();
    addTearDown(quantities.dispose);
    quantities.update(const {'fries': 3});

    expect(quantities.of('fries').value, 3);
    expect(identical(quantities.of('fries'), quantities.of('fries')), isTrue);
  });
}
