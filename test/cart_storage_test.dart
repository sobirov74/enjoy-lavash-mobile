import 'package:enjoy_lavash_mobile/core/storage/cart_storage.dart';
import 'package:enjoy_lavash_mobile/features/models/cart_line.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('persists only valid cart quantities', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await CartStorage.save(<String, int>{
      'lavash': 2,
      'fries': 1,
      'invalid': 0,
    });

    expect(await CartStorage.read(), <String, int>{'lavash': 2, 'fries': 1});
  });

  test('clears the stored cart when it becomes empty', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await CartStorage.save(<String, int>{'lavash': 1});

    await CartStorage.save(<String, int>{});

    expect(await CartStorage.read(), isEmpty);
  });

  test('recovers safely from malformed stored data', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'mobile_cart_quantities': '{not-json',
    });

    expect(await CartStorage.read(), isEmpty);
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
