import 'package:enjoy_lavash_mobile/core/storage/cart_storage.dart';
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
}
