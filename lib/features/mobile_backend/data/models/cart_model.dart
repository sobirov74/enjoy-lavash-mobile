import 'json_helpers.dart';

enum MobileOrderType {
  delivery('DELIVERY'),
  pickup('PICKUP');

  const MobileOrderType(this.value);
  final String value;

  factory MobileOrderType.fromJson(String? value) {
    return switch (value) {
      'PICKUP' => MobileOrderType.pickup,
      _ => MobileOrderType.delivery,
    };
  }
}

enum MobilePaymentMethod {
  cash('CASH'),
  cardTerminal('CARD_TERMINAL'),
  payme('PAYME'),
  click('CLICK'),
  unknown('UNKNOWN');

  const MobilePaymentMethod(this.value);
  final String value;

  factory MobilePaymentMethod.fromJson(String? value) {
    return switch (_normalizePaymentMethodCode(value)) {
      'CARD_TERMINAL' => MobilePaymentMethod.cardTerminal,
      'PAYME' => MobilePaymentMethod.payme,
      'CLICK' => MobilePaymentMethod.click,
      'CASH' => MobilePaymentMethod.cash,
      _ => MobilePaymentMethod.unknown,
    };
  }
}

String? _normalizePaymentMethodCode(String? value) {
  final normalized = value?.trim().toUpperCase().replaceAll('-', '_');
  return normalized?.isEmpty == true ? null : normalized;
}

class PaymentMethodModel {
  const PaymentMethodModel({
    required this.id,
    required this.code,
    required this.name,
    required this.isOnline,
    required this.sortOrder,
    this.icon,
  });

  final String id;
  final MobilePaymentMethod code;
  final String name;
  final bool isOnline;
  final int sortOrder;
  final String? icon;

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: readString(json, const ['id']),
      code: MobilePaymentMethod.fromJson(stringOrNull(json['code'])),
      name: readString(json, const ['name']),
      isOnline: readBool(json, const ['isOnline', 'is_online']),
      sortOrder: readInt(json, const ['sortOrder', 'sort_order']),
      icon: stringOrNull(json['icon']),
    );
  }
}

enum CartPromotionStatus {
  none('NONE'),
  applied('APPLIED'),
  notFound('NOT_FOUND'),
  inactive('INACTIVE'),
  notStarted('NOT_STARTED'),
  expired('EXPIRED'),
  globalLimitReached('GLOBAL_LIMIT_REACHED'),
  clientLimitReached('CLIENT_LIMIT_REACHED'),
  clientRequired('CLIENT_REQUIRED'),
  conditionsNotMet('CONDITIONS_NOT_MET'),
  configurationError('CONFIGURATION_ERROR'),
  unknown('UNKNOWN');

  const CartPromotionStatus(this.value);
  final String value;

  factory CartPromotionStatus.fromJson(String? value) {
    return switch (value?.trim().toUpperCase()) {
      'APPLIED' => CartPromotionStatus.applied,
      'NOT_FOUND' => CartPromotionStatus.notFound,
      'INACTIVE' => CartPromotionStatus.inactive,
      'NOT_STARTED' => CartPromotionStatus.notStarted,
      'EXPIRED' => CartPromotionStatus.expired,
      'GLOBAL_LIMIT_REACHED' => CartPromotionStatus.globalLimitReached,
      'CLIENT_LIMIT_REACHED' => CartPromotionStatus.clientLimitReached,
      'CLIENT_REQUIRED' => CartPromotionStatus.clientRequired,
      'CONDITIONS_NOT_MET' => CartPromotionStatus.conditionsNotMet,
      'CONFIGURATION_ERROR' => CartPromotionStatus.configurationError,
      'NONE' || null || '' => CartPromotionStatus.none,
      _ => CartPromotionStatus.unknown,
    };
  }
}

class CartModifierInput {
  const CartModifierInput({required this.modifierId, this.quantity});

  final String modifierId;
  final int? quantity;

  Map<String, Object?> toJson() {
    return withoutNulls({'modifierId': modifierId, 'quantity': quantity});
  }
}

class CartItemInput {
  const CartItemInput({
    required this.productId,
    required this.quantity,
    this.modifiers = const <CartModifierInput>[],
    this.comment,
  });

  final String productId;
  final int quantity;
  final List<CartModifierInput> modifiers;
  final String? comment;

  Map<String, Object?> toJson() {
    return withoutNulls({
      'productId': productId,
      'quantity': quantity,
      'modifiers': modifiers.map((modifier) => modifier.toJson()).toList(),
      'comment': comment,
    });
  }
}

class CartPreviewAddressInput {
  const CartPreviewAddressInput({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;

  Map<String, Object?> toJson() {
    return {'latitude': latitude, 'longitude': longitude};
  }
}

class CartPreviewRequest {
  const CartPreviewRequest({
    required this.type,
    required this.items,
    required this.paymentMethod,
    this.branchId,
    this.addressId,
    this.address,
    this.promoCode,
  });

  final MobileOrderType type;
  final String? branchId;
  final String? addressId;
  final CartPreviewAddressInput? address;
  final List<CartItemInput> items;
  final MobilePaymentMethod paymentMethod;
  final String? promoCode;

  Map<String, Object?> toJson() {
    return withoutNulls({
      'type': type.value,
      'branchId': branchId,
      'addressId': addressId,
      'address': address?.toJson(),
      'items': items.map((item) => item.toJson()).toList(growable: false),
      'paymentMethod': paymentMethod.value,
      'promoCode': promoCode,
    });
  }
}

class CartPreviewModel {
  const CartPreviewModel({
    required this.itemsAmount,
    required this.modifiersAmount,
    required this.discountAmount,
    required this.deliveryAmount,
    required this.serviceFeeAmount,
    required this.totalAmount,
    this.promotionStatus = CartPromotionStatus.none,
    this.hasPromotionStatus = false,
    this.promotionStatusReason,
    this.promotionDeliveryDiscountAmount = 0,
    this.bonusItems = const <Map<String, dynamic>>[],
    this.appliedPromotion,
    this.branchId,
    this.deliveryDistanceMeters,
  });

  final int itemsAmount;
  final int modifiersAmount;
  final int discountAmount;
  final int deliveryAmount;
  final int serviceFeeAmount;
  final int totalAmount;
  final CartPromotionStatus promotionStatus;
  final bool hasPromotionStatus;
  final String? promotionStatusReason;
  final int promotionDeliveryDiscountAmount;
  final List<Map<String, dynamic>> bonusItems;
  final AppliedPromotionModel? appliedPromotion;
  final String? branchId;
  final int? deliveryDistanceMeters;

  factory CartPreviewModel.fromJson(Map<String, dynamic> json) {
    return CartPreviewModel(
      itemsAmount: readInt(json, const ['itemsAmount', 'items_amount']),
      modifiersAmount: readInt(json, const [
        'modifiersAmount',
        'modifiers_amount',
      ]),
      discountAmount: readInt(json, const [
        'discountAmount',
        'discount_amount',
      ]),
      deliveryAmount: readInt(json, const [
        'deliveryAmount',
        'delivery_amount',
      ]),
      serviceFeeAmount: readInt(json, const [
        'serviceFeeAmount',
        'service_fee_amount',
      ]),
      totalAmount: readInt(json, const ['totalAmount', 'total_amount']),
      promotionStatus: CartPromotionStatus.fromJson(
        stringOrNull(json['promotionStatus']) ??
            stringOrNull(json['promotion_status']),
      ),
      hasPromotionStatus:
          json.containsKey('promotionStatus') ||
          json.containsKey('promotion_status'),
      promotionStatusReason: _previewMessage(json, const [
        'promotionStatusReason',
        'promotion_status_reason',
        'errorMessage',
        'error_message',
        'message',
      ]),
      promotionDeliveryDiscountAmount: readInt(json, const [
        'promotionDeliveryDiscountAmount',
        'promotion_delivery_discount_amount',
      ]),
      bonusItems: asJsonMapList(json['bonusItems'] ?? json['bonus_items']),
      appliedPromotion:
          json['appliedPromotion'] == null && json['applied_promotion'] == null
          ? null
          : AppliedPromotionModel.fromJson(
              asJsonMap(json['appliedPromotion'] ?? json['applied_promotion']),
            ),
      branchId:
          stringOrNull(json['branchId']) ?? stringOrNull(json['branch_id']),
      deliveryDistanceMeters: _optionalInt(json, const [
        'deliveryDistanceMeters',
        'delivery_distance_meters',
      ]),
    );
  }
}

class AppliedPromotionModel {
  const AppliedPromotionModel({
    required this.id,
    this.code,
    this.title,
    this.discountAmount,
  });

  final String id;
  final String? code;
  final String? title;
  final int? discountAmount;

  factory AppliedPromotionModel.fromJson(Map<String, dynamic> json) {
    return AppliedPromotionModel(
      id: readString(json, const ['id']),
      code: stringOrNull(json['code']) ?? stringOrNull(json['promoCode']),
      title: stringOrNull(json['title']) ?? stringOrNull(json['name']),
      discountAmount: _optionalInt(json, const [
        'discountAmount',
        'discount_amount',
      ]),
    );
  }
}

int? _optionalInt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
  }
  return null;
}

String? _previewMessage(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    if (value is List) {
      final messages = <String>[];
      for (final item in value) {
        final message = stringOrNull(item)?.trim();
        if (message?.isNotEmpty == true) messages.add(message!);
      }
      final message = messages.join('\n');
      if (message.isNotEmpty) return message;
      continue;
    }

    final message = stringOrNull(value)?.trim();
    if (message?.isNotEmpty == true) return message;
  }
  return null;
}
