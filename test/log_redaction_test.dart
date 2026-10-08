import 'package:enjoy_lavash_mobile/utils/log_redaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('redacts personal and payment fields at any depth', () {
    final payload = <String, Object?>{
      'orderType': 'DELIVERY',
      'address': {'street': 'Amir Temur', 'doorCode': '1234'},
      'comment': 'ring twice',
      'items': [
        {'productId': 'p1', 'quantity': 2},
      ],
      'payment': {
        'paymentUrl': 'https://checkout.paycom.uz/abc',
        'method': 'PAYME',
      },
      'client': {'phone_number': '+998901234567', 'language': 'uz'},
    };

    final redacted = redactSensitiveLogFields(payload) as Map<String, Object?>;

    expect(redacted['orderType'], 'DELIVERY');
    expect(redacted['address'], redactedLogValue);
    expect(redacted['comment'], redactedLogValue);
    expect(redacted['items'], [
      {'productId': 'p1', 'quantity': 2},
    ]);
    expect(redacted['payment'], {
      'paymentUrl': redactedLogValue,
      'method': 'PAYME',
    });
    expect(redacted['client'], {
      'phone_number': redactedLogValue,
      'language': 'uz',
    });
    // The input is not mutated.
    expect((payload['address'] as Map)['doorCode'], '1234');
  });

  test('passes scalars and lists through untouched', () {
    expect(redactSensitiveLogFields(null), isNull);
    expect(redactSensitiveLogFields(42), 42);
    expect(redactSensitiveLogFields(['a', 1]), ['a', 1]);
  });
}
