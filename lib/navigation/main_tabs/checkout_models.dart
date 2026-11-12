part of 'package:enjoy_lavash_mobile/navigation/main_tabs.dart';

enum _OrderFailureAction { close, retry, removePoints }

class _OrderCreationResult {
  const _OrderCreationResult({
    required this.orderType,
    required this.paymentMethod,
    required this.loyaltyRedemptionAmount,
    this.promoCode,
    this.comment,
    this.deliveryTarget,
  });

  final MobileOrderType orderType;
  final MobilePaymentMethod paymentMethod;
  final int loyaltyRedemptionAmount;
  final String? promoCode;
  final String? comment;

  /// Where the preview the customer confirmed was priced for; the order
  /// goes there, not to wherever the phone is by then. Null for pickup.
  final DeliveryTarget? deliveryTarget;
}

class _CheckoutAddressDetails {
  const _CheckoutAddressDetails({this.label, this.text});

  final String? label;
  final String? text;
}

class _CheckoutPreviewDetails {
  const _CheckoutPreviewDetails({
    required this.preview,
    required this.orderType,
    this.branchName,
    this.branchAddress,
    this.address,
    this.deliveryTarget,
  });

  final CartPreviewModel preview;
  final MobileOrderType orderType;
  final String? branchName;
  final String? branchAddress;
  final _CheckoutAddressDetails? address;

  /// The delivery target this preview was requested for; null for pickup.
  final DeliveryTarget? deliveryTarget;
}

typedef _CartPreviewRequester =
    Future<Result<_CheckoutPreviewDetails>?> Function({
      required MobileOrderType orderType,
      required MobilePaymentMethod paymentMethod,
      required int loyaltyRedemptionAmount,
      String? promoCode,
    });
