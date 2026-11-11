import 'package:enjoy_lavash_mobile/core/storage/cart_storage.dart';
import 'package:enjoy_lavash_mobile/features/models/cart_line.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'a cart saved by an older build is read without invalid lines',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'mobile_cart_quantities': '{"lavash": 2, "fries": 1, "invalid": 0}',
      });

      expect(await CartStorage.read(), <String, int>{'lavash': 2, 'fries': 1});
      final restored = await CartStorage.readSelections();
      expect(
        {for (final line in restored) line.productId: line.quantity},
        <String, int>{'lavash': 2, 'fries': 1},
      );
    },
  );

  test('saving an empty cart clears the current and the legacy data', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'mobile_cart_quantities': '{"lavash": 1}',
      'mobile_cart_lines_v2': '[{"productId": "lavash", "quantity": 1}]',
    });

    await CartStorage.saveSelections(const <CartSelection>[]);

    expect(await CartStorage.readSelections(), isEmpty);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('mobile_cart_quantities'), isNull);
    expect(preferences.getString('mobile_cart_lines_v2'), isNull);
  });

  test('recovers safely from malformed stored data', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'mobile_cart_quantities': '{not-json',
    });

    expect(await CartStorage.read(), isEmpty);
  });

  test(
    'wrong-typed saved lines are coerced or dropped, never thrown',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'mobile_cart_lines_v2':
            '[{"productId": 42, "quantity": "2", "modifiers": '
            '[{"groupId": "g", "modifierId": 7, "price": "3000"}]},'
            '{"productId": "fries", "quantity": {"bad": true}}]',
      });

      final restored = await CartStorage.readSelections();

      expect(restored, hasLength(1));
      expect(restored.single.productId, '42');
      expect(restored.single.quantity, 2);
      expect(restored.single.modifiers.single.modifierId, '7');
      expect(restored.single.modifiers.single.price, 3000);
    },
  );

  test('a structurally broken saved cart is discarded once', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'mobile_cart_lines_v2': '[{"productId": "lavash", "modifiers": "x"}',
    });

    expect(await CartStorage.readSelections(), isEmpty);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('mobile_cart_lines_v2'), isNull);
  });

  test('persists configured cart lines without losing modifiers', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final selection = CartSelection(
      productId: 'lavash',
      quantity: 2,
      modifiers: const <CartModifierSelection>[
        CartModifierSelection(
          groupId: 'sauce',
          modifierId: 'garlic',
          name: 'Garlic sauce',
          price: 3000,
        ),
      ],
    );

    await CartStorage.saveSelections(<CartSelection>[selection]);
    final restored = await CartStorage.readSelections();

    expect(restored, hasLength(1));
    expect(restored.single.key, selection.key);
    expect(restored.single.quantity, 2);
    expect(restored.single.modifiers.single.modifierId, 'garlic');
    expect(restored.single.modifiers.single.price, 3000);
  });
}
