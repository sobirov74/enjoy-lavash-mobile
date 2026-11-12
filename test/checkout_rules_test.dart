// Pure rules moved out of the app shell: delivery address text, cart
// reconciliation and repeat order, and checkout request pieces.

import 'package:enjoy_lavash_mobile/features/address/delivery_address_text.dart';
import 'package:enjoy_lavash_mobile/features/cart/domain/cart_rules.dart';
import 'package:enjoy_lavash_mobile/features/checkout/checkout_requests.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/address_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/order_model.dart';
import 'package:enjoy_lavash_mobile/features/models/cart_line.dart';
import 'package:enjoy_lavash_mobile/features/models/menu_product.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const MenuProduct _lavash = MenuProduct(
  id: 'lavash',
  title: 'Lavash',
  price: 30000,
  category: 'Lavash',
  emoji: '🌯',
  tint: Colors.orange,
  highlight: Colors.amber,
);

const MenuProduct _burger = MenuProduct(
  id: 'burger',
  iikoId: ' iiko-burger ',
  title: 'Burger',
  price: 40000,
  category: 'Burger',
  emoji: '🍔',
  tint: Colors.orange,
  highlight: Colors.amber,
);

ClientAddress _address(
  String id, {
  String street = '',
  String? house,
  String? apartment,
  String label = '',
  bool isDefault = false,
}) {
  return ClientAddress(
    id: id,
    label: label,
    street: street,
    houseNumber: house,
    apartmentNumber: apartment,
    latitude: 41.3,
    longitude: 69.2,
    isDefault: isDefault,
  );
}

void main() {
  group('delivery address text', () {
    test('a picked point wins, its full text before its name', () {
      expect(
        deliveryAddressText(
          addressName: 'Amir Temur',
          fullAddress: 'Amir Temur, 12',
          savedAddresses: [_address('a', street: 'Saved', isDefault: true)],
        ),
        'Amir Temur, 12',
      );
      expect(
        deliveryAddressText(
          addressName: ' Amir Temur ',
          fullAddress: '  ',
          savedAddresses: const [],
        ),
        'Amir Temur',
      );
    });

    test('without a picked point the default saved address is used', () {
      final saved = [
        _address('work', street: 'Navoi'),
        _address(
          'home',
          street: 'Bunyodkor',
          house: '12',
          apartment: '5',
          isDefault: true,
        ),
      ];
      expect(
        deliveryAddressText(
          addressName: '',
          fullAddress: '',
          savedAddresses: saved,
        ),
        'Bunyodkor, 12, 5',
      );
      expect(defaultClientAddress([_address('only')])!.id, 'only');
      expect(defaultClientAddress(const []), isNull);
    });

    test('a saved address without a street shows its label', () {
      expect(clientAddressText(_address('a', label: ' Office ')), 'Office');
    });

    test('a point without an address is not shown, even with a house number '
        'typed for it', () {
      final saved = [_address('home', street: 'Bunyodkor', isDefault: true)];
      expect(
        deliveryAddressText(
          addressName: '',
          fullAddress: ', 12',
          savedAddresses: saved,
        ),
        'Bunyodkor',
      );
      expect(
        deliveryAddressText(
          addressName: ' ',
          fullAddress: ', 12',
          savedAddresses: const [],
        ),
        isNull,
      );
    });
  });

  group('delivery target', () {
    const named = (
      latitude: 41.31,
      longitude: 69.28,
      addressName: 'Amir Temur',
      fullAddress: 'Amir Temur, 12',
      houseNumber: '12',
      apartment: '',
      entrance: '',
      floor: '',
      comment: '',
    );
    const unnamed = (
      latitude: 41.4,
      longitude: 69.4,
      addressName: '',
      fullAddress: '',
      houseNumber: '',
      apartment: '',
      entrance: '',
      floor: '',
      comment: '',
    );
    final saved = [
      _address('work', street: 'Navoi'),
      _address('home', street: 'Bunyodkor', isDefault: true),
    ];

    test('a point with an address wins over saved addresses', () {
      final target = resolveDeliveryTarget(point: named, savedAddresses: saved);
      expect(target!.point, named);
      expect(target.addressId, isNull);
    });

    test('a point without an address yields to the default saved address', () {
      final target = resolveDeliveryTarget(
        point: unnamed,
        savedAddresses: saved,
      );
      expect(target!.addressId, 'home');
      expect(target.point, isNull);
    });

    test('a point without an address is used when nothing is saved', () {
      final target = resolveDeliveryTarget(
        point: unnamed,
        savedAddresses: const [],
      );
      expect(target!.point, unnamed);
    });

    test('no point: the default saved address, or nothing to go by', () {
      expect(
        resolveDeliveryTarget(point: null, savedAddresses: saved)!.addressId,
        'home',
      );
      expect(
        resolveDeliveryTarget(point: null, savedAddresses: const []),
        isNull,
      );
    });

    test('what is shown is what is sent', () {
      for (final point in [named, unnamed, null]) {
        for (final addresses in [saved, const <ClientAddress>[]]) {
          final target = resolveDeliveryTarget(
            point: point,
            savedAddresses: addresses,
          );
          final shown = deliveryAddressText(
            addressName: point?.addressName ?? '',
            fullAddress: point?.fullAddress ?? '',
            savedAddresses: addresses,
          );
          if (target?.addressId != null) {
            expect(shown, 'Bunyodkor');
          } else if (target?.point == named) {
            expect(shown, 'Amir Temur, 12');
          } else {
            // Nothing to show: no target, or bare coordinates.
            expect(shown, isNull);
          }
        }
      }
    });
  });

  group('cart rules', () {
    test('reconciliation drops lines whose product is gone', () {
      final reconciled = reconcileCartSelections(
        [
          CartSelection(productId: 'lavash', quantity: 2),
          CartSelection(productId: 'retired', quantity: 1),
        ],
        const [_lavash],
      );
      expect(reconciled.keys, ['lavash']);
      expect(
        unavailableCartSelections(
          [
            CartSelection(productId: 'lavash', quantity: 2),
            CartSelection(productId: 'retired', quantity: 1),
          ],
          const [_lavash],
        ).map((line) => line.productId),
        ['retired'],
      );
    });

    test('quantities are capped per line', () {
      expect(capCartQuantity(maxCartLineQuantity + 5), maxCartLineQuantity);
      expect(capCartQuantity(3), 3);
    });

    test(
      'repeat order adds what it can, by iiko id too, and names the rest',
      () {
        final order = CustomerOrderModel.fromJson({
          'id': 'order-1',
          'type': 'PICKUP',
          'status': 'DELIVERED',
          'paymentMethod': 'CASH',
          'totalAmount': 100000,
          'items': [
            {'productId': 'lavash', 'quantity': 2, 'name': 'Lavash'},
            {'productId': 'iiko-burger', 'quantity': 1, 'name': 'Burger'},
            {'productId': 'retired', 'quantity': 1, 'name': 'Old combo'},
          ],
          'statusLog': const [],
        });

        final plan = planRepeatOrder(
          order: order,
          current: [CartSelection(productId: 'lavash', quantity: 98)],
          products: const [_lavash, _burger],
          language: 'en',
        );

        expect(plan.addedUnits, 3);
        expect(plan.skipped, ['Old combo']);
        expect(
          {for (final line in plan.selections) line.productId: line.quantity},
          {'lavash': maxCartLineQuantity, 'burger': 1},
        );
      },
    );
  });

  group('checkout requests', () {
    test('order lines use the iiko id when the product has one', () {
      final items = checkoutItems(const [
        CartLine(product: _lavash, quantity: 2),
        CartLine(product: _burger, quantity: 1),
      ]);
      expect(items.map((item) => item.toJson()), [
        {'productId': 'lavash', 'quantity': 2, 'modifiers': []},
        {'productId': 'iiko-burger', 'quantity': 1, 'modifiers': []},
      ]);
    });

    test('a picked point becomes the inline order address', () {
      const point = (
        latitude: 41.31,
        longitude: 69.28,
        addressName: 'Amir Temur',
        fullAddress: 'Amir Temur, 12',
        houseNumber: '12',
        apartment: ' ',
        entrance: '2',
        floor: '',
        comment: 'Ring twice',
      );
      expect(inlineOrderAddress(point).toJson(), {
        'latitude': 41.31,
        'longitude': 69.28,
        'label': 'Amir Temur',
        'text': 'Amir Temur, 12',
        'street': 'Amir Temur',
        'houseNumber': '12',
        'entrance': '2',
        'comment': 'Ring twice',
      });
      expect(previewDeliveryAddress(point).toJson(), {
        'latitude': 41.31,
        'longitude': 69.28,
      });
    });
  });
}
