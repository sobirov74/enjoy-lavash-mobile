import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/cart_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses documented payment method response item', () {
    final method = PaymentMethodModel.fromJson({
      'id': 'pm-payme',
      'code': 'PAYME',
      'name': 'Payme',
      'isOnline': true,
      'sortOrder': 2,
      'icon': null,
    });

    expect(method.id, 'pm-payme');
    expect(method.code, MobilePaymentMethod.payme);
    expect(method.name, 'Payme');
    expect(method.isOnline, isTrue);
    expect(method.sortOrder, 2);
  });
}
