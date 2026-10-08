import 'package:enjoy_lavash_mobile/core/error/failures.dart';
import 'package:enjoy_lavash_mobile/features/checkout/order_submission_keys.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late int generated;
  late OrderSubmissionKeys keys;

  Map<String, Object?> order({int quantity = 1}) => <String, Object?>{
    'type': 'DELIVERY',
    'items': [
      {'productId': 'p1', 'quantity': quantity},
    ],
    'paymentMethod': 'CASH',
  };

  setUp(() {
    generated = 0;
    keys = OrderSubmissionKeys(generateKey: () => 'key-${++generated}');
  });

  test('reuses the key for the same order after an unknown outcome', () {
    final first = keys.keyFor(order());
    keys.resolve(succeeded: false, failure: const TimeoutFailure());

    // The customer closed the error dialog and submitted the same cart again.
    expect(keys.keyFor(order()), first);
  });

  test('keeps the key after network errors and 5xx responses', () {
    for (final failure in <Failure>[
      const NetworkFailure(),
      const ServerFailure(500),
      const ServiceUnavailableFailure(),
    ]) {
      final key = keys.keyFor(order());
      keys.resolve(succeeded: false, failure: failure);
      expect(keys.keyFor(order()), key, reason: failure.toString());
    }
  });

  test('issues a new key once the server answered definitively', () {
    final first = keys.keyFor(order());
    keys.resolve(succeeded: false, failure: const ServerFailure(422));
    final second = keys.keyFor(order());
    expect(second, isNot(first));

    keys.resolve(succeeded: true);
    expect(keys.keyFor(order()), isNot(second));
  });

  test('a changed order never reuses the previous key', () {
    final first = keys.keyFor(order());
    keys.resolve(succeeded: false, failure: const NetworkFailure());
    expect(keys.keyFor(order(quantity: 2)), isNot(first));
  });

  test('generated keys are version-4 UUIDs', () {
    final key = newIdempotencyKey();
    expect(
      key,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
    expect(newIdempotencyKey(), isNot(key));
  });
}
