import 'package:enjoy_lavash_mobile/features/checkout/payment_method_label.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/cart_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/json_helpers.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
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

  test('parses click payment method code case-insensitively', () {
    final method = PaymentMethodModel.fromJson({
      'id': 'pm-click',
      'code': 'click',
      'name': 'Click',
      'is_online': true,
      'sort_order': 3,
    });

    expect(method.code, MobilePaymentMethod.click);
    expect(method.name, 'Click');
    expect(method.isOnline, isTrue);
    expect(method.sortOrder, 3);
  });

  test('payment labels: localized cash and card, brand names online', () {
    final t = lookupL(const Locale('en'));
    expect(paymentMethodLabel(MobilePaymentMethod.cash, t), t.paymentCash);
    expect(
      paymentMethodLabel(MobilePaymentMethod.cardTerminal, t),
      t.paymentCardTerminal,
    );
    expect(paymentMethodLabel(MobilePaymentMethod.payme, t), 'Payme');
    expect(paymentMethodLabel(MobilePaymentMethod.click, t), 'Click');
    expect(paymentMethodLabel(MobilePaymentMethod.unknown, t), t.unknown);
  });

  test('optional ints: first non-null key wins, strings parsed', () {
    expect(readOptionalInt({'a': null, 'b': 5}, const ['a', 'b']), 5);
    expect(readOptionalInt({'a': 2.9}, const ['a']), 2);
    expect(readOptionalInt({'a': '7'}, const ['a']), 7);
    // An unparseable string ends the search, as the models always did.
    expect(readOptionalInt({'a': 'x', 'b': 3}, const ['a', 'b']), isNull);
    expect(readOptionalInt({'a': true, 'b': 3}, const ['a', 'b']), 3);
    expect(readOptionalInt(const {}, const ['a']), isNull);
  });
}
