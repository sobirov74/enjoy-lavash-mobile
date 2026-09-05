import 'json_helpers.dart';
import 'loyalty_model.dart';

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
    this.loyaltyRedemptionAmount = 0,
  });

  final MobileOrderType type;
  final String? branchId;
  final String? addressId;
  final CartPreviewAddressInput? address;
  final List<CartItemInput> items;
  final MobilePaymentMethod paymentMethod;
  final String? promoCode;
  final int loyaltyRedemptionAmount;

  Map<String, Object?> toJson() {
    return withoutNulls({
      'type': type.value,
      'branchId': branchId,
      'addressId': addressId,
      'address': address?.toJson(),
      'items': items.map((item) => item.toJson()).toList(growable: false),
      'paymentMethod': paymentMethod.value,
      'promoCode': promoCode,
      'loyaltyRedemptionAmount': loyaltyRedemptionAmount,
    });
  }
}

enum CartDeliveryDistanceSource {
  road('ROAD'),
  straightLineFallback('STRAIGHT_LINE_FALLBACK'),
  unknown('UNKNOWN');

  const CartDeliveryDistanceSource(this.value);

  final String value;

  static CartDeliveryDistanceSource fromJson(String? value) {
    return switch (value?.trim().toUpperCase()) {
      'ROAD' => CartDeliveryDistanceSource.road,
      'STRAIGHT_LINE_FALLBACK' =>
        CartDeliveryDistanceSource.straightLineFallback,
      _ => CartDeliveryDistanceSource.unknown,
    };
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
    required this.totalBeforePointsAmount,
    this.promotionStatus = CartPromotionStatus.none,
    this.hasPromotionStatus = false,
    this.promotionStatusReason,
    this.promotionDeliveryDiscountAmount = 0,
    this.bonusItems = const <Map<String, dynamic>>[],
    this.pricedItems = const <PricedCartItemModel>[],
    this.pricedBonusItems = const <PricedCartItemModel>[],
    this.appliedPromotion,
    this.branchId,
    this.deliveryDistanceMeters,
    this.deliveryDistanceSource = CartDeliveryDistanceSource.unknown,
    this.loyalty,
  });

  final int itemsAmount;
  final int modifiersAmount;
  final int discountAmount;
  final int deliveryAmount;
  final int serviceFeeAmount;
  final int totalAmount;
  final int totalBeforePointsAmount;
  final CartPromotionStatus promotionStatus;
  final bool hasPromotionStatus;
  final String? promotionStatusReason;
  final int promotionDeliveryDiscountAmount;
  final List<Map<String, dynamic>> bonusItems;
  final List<PricedCartItemModel> pricedItems;
  final List<PricedCartItemModel> pricedBonusItems;

  bool acceptsPromoCode(String? promoCode) {
    if (promoCode == null || promoCode.trim().isEmpty) return true;
    if (!hasPromotionStatus) return true;
    return promotionStatus == CartPromotionStatus.applied;
  }

  final AppliedPromotionModel? appliedPromotion;
  final String? branchId;
  final int? deliveryDistanceMeters;
  final CartDeliveryDistanceSource deliveryDistanceSource;
  final CartLoyaltyPreviewModel? loyalty;

  factory CartPreviewModel.fromJson(Map<String, dynamic> json) {
    final totalAmount = readInt(json, const ['totalAmount', 'total_amount']);
    final loyaltyJson = asJsonMap(json['loyalty']);
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
      totalAmount: totalAmount,
      totalBeforePointsAmount:
          _optionalInt(json, const [
            'totalBeforePointsAmount',
            'total_before_points_amount',
          ]) ??
          totalAmount,
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
      pricedItems: asJsonMapList(
        json['items'],
      ).map(PricedCartItemModel.fromJson).toList(growable: false),
      pricedBonusItems: asJsonMapList(
        json['bonusItems'] ?? json['bonus_items'],
      ).map(PricedCartItemModel.fromJson).toList(growable: false),
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
      deliveryDistanceSource: CartDeliveryDistanceSource.fromJson(
        stringOrNull(json['deliveryDistanceSource']) ??
            stringOrNull(json['delivery_distance_source']),
      ),
      loyalty: loyaltyJson.isEmpty
          ? null
          : CartLoyaltyPreviewModel.fromJson(loyaltyJson),
    );
  }
}

class PricedCartModifierModel {
  const PricedCartModifierModel({
    required this.modifierId,
    required this.nameSnapshot,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  final String modifierId;
  final Object? nameSnapshot;
  final int quantity;
  final int unitPrice;
  final int totalPrice;

  String nameFor(String language) =>
      localizedText(nameSnapshot, language, fallback: modifierId);

  factory PricedCartModifierModel.fromJson(Map<String, dynamic> json) {
    return PricedCartModifierModel(
      modifierId: readString(json, const ['modifierId', 'modifier_id']),
      nameSnapshot:
          json['modifierNameSnapshotI18n'] ??
          json['modifier_name_snapshot_i18n'] ??
          json['name'],
      quantity: readInt(json, const ['quantity'], fallback: 1),
      unitPrice: readInt(json, const ['unitPrice', 'unit_price']),
      totalPrice: readInt(json, const ['totalPrice', 'total_price']),
    );
  }
}

class PricedCartItemModel {
  const PricedCartItemModel({
    required this.productId,
    required this.nameSnapshot,
    required this.categoryId,
    required this.quantity,
    required this.unitPrice,
    required this.modifiersAmount,
    required this.totalPrice,
    required this.modifiers,
    required this.isBonus,
    this.comment,
    this.originalUnitPrice,
    this.promotionId,
    this.promotionCode,
  });

  final String productId;
  final Object? nameSnapshot;
  final String categoryId;
  final int quantity;
  final int unitPrice;
  final int modifiersAmount;
  final int totalPrice;
  final List<PricedCartModifierModel> modifiers;
  final bool isBonus;
  final String? comment;
  final int? originalUnitPrice;
  final String? promotionId;
  final String? promotionCode;

  String nameFor(String language) =>
      localizedText(nameSnapshot, language, fallback: productId);

  factory PricedCartItemModel.fromJson(Map<String, dynamic> json) {
    return PricedCartItemModel(
      productId: readString(json, const ['productId', 'product_id']),
      nameSnapshot:
          json['productNameSnapshotI18n'] ??
          json['product_name_snapshot_i18n'] ??
          json['name'],
      categoryId: readString(json, const ['categoryId', 'category_id']),
      quantity: readInt(json, const ['quantity'], fallback: 1),
      unitPrice: readInt(json, const ['unitPrice', 'unit_price']),
      modifiersAmount: readInt(json, const [
        'modifiersAmount',
        'modifiers_amount',
      ]),
      totalPrice: readInt(json, const ['totalPrice', 'total_price']),
      modifiers: asJsonMapList(
        json['modifiers'],
      ).map(PricedCartModifierModel.fromJson).toList(growable: false),
      isBonus: readBool(json, const ['isBonus', 'is_bonus']),
      comment: stringOrNull(json['comment']),
      originalUnitPrice: _optionalInt(json, const [
        'originalUnitPrice',
        'original_unit_price',
      ]),
      promotionId:
          stringOrNull(json['promotionId']) ??
          stringOrNull(json['promotion_id']),
      promotionCode:
          stringOrNull(json['promotionCode']) ??
          stringOrNull(json['promotion_code']),
    );
  }
}

class AppliedPromotionModel {
  const AppliedPromotionModel({
    required this.id,
    this.code,
    this.title,
    this.titleSnapshot,
    this.discountAmount,
  });

  final String id;
  final String? code;
  final String? title;
  final Object? titleSnapshot;
  final int? discountAmount;

  String? titleFor(String language) {
    final localized = localizedText(
      titleSnapshot,
      language,
      fallback: title ?? '',
    ).trim();
    return localized.isEmpty ? null : localized;
  }

  factory AppliedPromotionModel.fromJson(Map<String, dynamic> json) {
    final titleSnapshot =
        json['titleI18n'] ??
        json['title_i18n'] ??
        json['title'] ??
        json['name'];
    final defaultTitle = localizedText(
      titleSnapshot,
      'ru',
      fallback: stringOrNull(json['title']) ?? stringOrNull(json['name']) ?? '',
    ).trim();
    return AppliedPromotionModel(
      id: readString(json, const ['id']),
      code: stringOrNull(json['code']) ?? stringOrNull(json['promoCode']),
      title: defaultTitle.isEmpty ? null : defaultTitle,
      titleSnapshot: titleSnapshot,
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
