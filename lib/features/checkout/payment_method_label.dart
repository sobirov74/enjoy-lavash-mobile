import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/cart_model.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';

/// The customer-facing name of [method]: localized for cash and card, the
/// brand name for online payments. Checkout and order details use it.
String paymentMethodLabel(MobilePaymentMethod method, L t) {
  return switch (method) {
    MobilePaymentMethod.cash => t.paymentCash,
    MobilePaymentMethod.cardTerminal => t.paymentCardTerminal,
    MobilePaymentMethod.payme => 'Payme',
    MobilePaymentMethod.click => 'Click',
    MobilePaymentMethod.unknown => t.unknown,
  };
}
