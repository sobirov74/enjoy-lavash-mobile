part of 'package:enjoy_lavash_mobile/navigation/main_tabs.dart';

class _OrderCreationResult {
  const _OrderCreationResult({
    required this.orderType,
    required this.paymentMethod,
    this.promoCode,
    this.comment,
  });

  final MobileOrderType orderType;
  final MobilePaymentMethod paymentMethod;
  final String? promoCode;
  final String? comment;
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
  });

  final CartPreviewModel preview;
  final MobileOrderType orderType;
  final String? branchName;
  final String? branchAddress;
  final _CheckoutAddressDetails? address;
}

typedef _CartPreviewRequester =
    Future<Result<_CheckoutPreviewDetails>?> Function({
      required MobileOrderType orderType,
      required MobilePaymentMethod paymentMethod,
      String? promoCode,
    });
