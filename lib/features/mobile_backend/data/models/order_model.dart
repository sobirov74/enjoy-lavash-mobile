import 'cart_model.dart';
import 'json_helpers.dart';
import 'loyalty_model.dart';

enum MobileOrderStatus {
  newOrder('NEW'),
  confirmed('CONFIRMED'),
  cooking('COOKING'),
  ready('READY'),
  courierAssigned('COURIER_ASSIGNED'),
  onTheWay('ON_THE_WAY'),
  delivered('DELIVERED'),
  cancelled('CANCELLED'),
  refunded('REFUNDED'),
  unknown('UNKNOWN');

  const MobileOrderStatus(this.value);
  final String value;

  factory MobileOrderStatus.fromJson(String? value) {
    return switch (value) {
      'NEW' => MobileOrderStatus.newOrder,
      'CONFIRMED' => MobileOrderStatus.confirmed,
      'COOKING' => MobileOrderStatus.cooking,
      'READY' => MobileOrderStatus.ready,
      'COURIER_ASSIGNED' => MobileOrderStatus.courierAssigned,
      'ON_THE_WAY' => MobileOrderStatus.onTheWay,
      'DELIVERED' => MobileOrderStatus.delivered,
      'CANCELLED' => MobileOrderStatus.cancelled,
      'REFUNDED' => MobileOrderStatus.refunded,
      _ => MobileOrderStatus.unknown,
    };
  }
}

enum MobilePaymentStatus {
  pending('PENDING'),
  paid('PAID'),
  failed('FAILED'),
  refunded('REFUNDED'),
  unknown('UNKNOWN');

  const MobilePaymentStatus(this.value);
  final String value;

  factory MobilePaymentStatus.fromJson(String? value) {
    return switch (value) {
      'PENDING' => MobilePaymentStatus.pending,
      'PAID' => MobilePaymentStatus.paid,
      'FAILED' => MobilePaymentStatus.failed,
      'REFUNDED' => MobilePaymentStatus.refunded,
      _ => MobilePaymentStatus.unknown,
    };
  }
}

class CreateOrderRequest {
  const CreateOrderRequest({
    required this.type,
    required this.items,
    required this.paymentMethod,
    this.address,
    this.addressId,
    this.branchId,
    this.promoCode,
    this.comment,
    this.scheduledFor,
    this.loyaltyRedemptionAmount = 0,
  });

  final MobileOrderType type;
  final CreateOrderAddressInput? address;
  final String? addressId;
  final String? branchId;
  final List<CartItemInput> items;
  final MobilePaymentMethod paymentMethod;
  final String? promoCode;
  final String? comment;
  final DateTime? scheduledFor;
  final int loyaltyRedemptionAmount;

  Map<String, Object?> toJson() {
    return withoutNulls({
      'type': type.value,
      'address': address?.toJson(),
      'addressId': addressId,
      'branchId': branchId,
      'items': items.map((item) => item.toJson()).toList(growable: false),
      'paymentMethod': paymentMethod.value,
      'promoCode': promoCode,
      'comment': comment,
      'scheduledFor': scheduledFor?.toIso8601String(),
      'loyaltyRedemptionAmount': loyaltyRedemptionAmount,
    });
  }
}

class CreateOrderAddressInput {
  const CreateOrderAddressInput({
    required this.latitude,
    required this.longitude,
    this.label,
    this.text,
    this.street,
    this.houseNumber,
    this.apartmentNumber,
    this.entrance,
    this.floor,
    this.doorCode,
    this.comment,
  });

  final double latitude;
  final double longitude;
  final String? label;
  final String? text;
  final String? street;
  final String? houseNumber;
  final String? apartmentNumber;
  final String? entrance;
  final String? floor;
  final String? doorCode;
  final String? comment;

  Map<String, Object?> toJson() {
    return withoutNulls({
      'latitude': latitude,
      'longitude': longitude,
      'label': label,
      'text': text,
      'street': street,
      'houseNumber': houseNumber,
      'apartmentNumber': apartmentNumber,
      'entrance': entrance,
      'floor': floor,
      'doorCode': doorCode,
      'comment': comment,
    });
  }
}

class CustomerOrderModel {
  CustomerOrderModel({
    required this.id,
    required this.type,
    required this.status,
    required this.totalAmount,
    this.totalBeforePointsAmount = 0,
    this.loyaltyRedeemedAmount = 0,
    required this.paymentMethod,
    required List<CustomerOrderItemModel> items,
    required List<OrderStatusLogModel> statusLog,
    this.branchId,
    this.addressId,
    this.promoCode,
    this.comment,
    this.scheduledFor,
    this.iikoOrderId,
    this.paymentStatus,
    this.paymentUrl,
    this.paymentExpiresAt,
    this.paymentRetryAvailable = false,
    this.paymentAttemptCount = 0,
    this.createdAt,
    this.updatedAt,
    this.raw = const <String, dynamic>{},
    this.loyalty = const OrderLoyaltySummaryModel.legacy(),
  }) : items = List<CustomerOrderItemModel>.unmodifiable(items),
       statusLog = List<OrderStatusLogModel>.unmodifiable(statusLog);

  final String id;
  final MobileOrderType type;
  final MobileOrderStatus status;
  final int totalAmount;
  final int totalBeforePointsAmount;
  final int loyaltyRedeemedAmount;
  final MobilePaymentMethod paymentMethod;
  final List<CustomerOrderItemModel> items;
  final List<OrderStatusLogModel> statusLog;
  final String? branchId;
  final String? addressId;
  final String? promoCode;
  final String? comment;
  final DateTime? scheduledFor;
  final String? iikoOrderId;
  final MobilePaymentStatus? paymentStatus;
  final String? paymentUrl;
  final DateTime? paymentExpiresAt;
  final bool paymentRetryAvailable;
  final int paymentAttemptCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> raw;
  final OrderLoyaltySummaryModel loyalty;

  factory CustomerOrderModel.fromJson(Map<String, dynamic> json) {
    final totalAmount = readInt(json, const ['totalAmount', 'total_amount']);
    final loyaltyJson = asJsonMap(json['loyalty']);
    final redemptionJson = asJsonMap(loyaltyJson['redemption']);
    final loyaltyRedeemedAmount =
        _orderOptionalInt(json, const [
          'loyaltyRedeemedAmount',
          'loyalty_redeemed_amount',
        ]) ??
        readInt(redemptionJson, const ['amount']);
    return CustomerOrderModel(
      id: readString(json, const ['id']),
      type: MobileOrderType.fromJson(stringOrNull(json['type'])),
      status: MobileOrderStatus.fromJson(stringOrNull(json['status'])),
      totalAmount: totalAmount,
      totalBeforePointsAmount:
          _orderOptionalInt(json, const [
            'totalBeforePointsAmount',
            'total_before_points_amount',
          ]) ??
          (totalAmount + loyaltyRedeemedAmount),
      loyaltyRedeemedAmount: loyaltyRedeemedAmount,
      paymentMethod: MobilePaymentMethod.fromJson(
        stringOrNull(json['paymentMethod']) ??
            stringOrNull(json['payment_method']),
      ),
      items: asJsonMapList(
        json['items'] ?? json['products'],
      ).map(CustomerOrderItemModel.fromJson).toList(growable: false),
      statusLog: asJsonMapList(
        json['statusLog'] ?? json['status_log'],
      ).map(OrderStatusLogModel.fromJson).toList(growable: false),
      branchId:
          stringOrNull(json['branchId']) ?? stringOrNull(json['branch_id']),
      addressId:
          stringOrNull(json['addressId']) ?? stringOrNull(json['address_id']),
      promoCode:
          stringOrNull(json['promoCode']) ?? stringOrNull(json['promo_code']),
      comment: stringOrNull(json['comment']),
      scheduledFor: readDateTime(json, const ['scheduledFor', 'scheduled_for']),
      iikoOrderId:
          stringOrNull(json['iikoOrderId']) ??
          stringOrNull(json['iiko_order_id']),
      paymentStatus: MobilePaymentStatus.fromJson(
        stringOrNull(json['paymentStatus']) ??
            stringOrNull(json['payment_status']),
      ),
      paymentUrl:
          stringOrNull(json['paymentUrl']) ?? stringOrNull(json['payment_url']),
      paymentExpiresAt: readDateTime(json, const [
        'paymentExpiresAt',
        'payment_expires_at',
      ]),
      paymentRetryAvailable: readBool(json, const [
        'paymentRetryAvailable',
        'payment_retry_available',
      ]),
      paymentAttemptCount: readInt(json, const [
        'paymentAttemptCount',
        'payment_attempt_count',
      ]),
      createdAt: readDateTime(json, const ['createdAt', 'created_at']),
      updatedAt: readDateTime(json, const ['updatedAt', 'updated_at']),
      raw: Map<String, dynamic>.unmodifiable(json),
      loyalty: loyaltyJson.isEmpty
          ? const OrderLoyaltySummaryModel.legacy()
          : OrderLoyaltySummaryModel.fromJson(loyaltyJson),
    );
  }
}

int? _orderOptionalInt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
  }
  return null;
}

class CustomerOrderItemModel {
  const CustomerOrderItemModel({
    required this.productId,
    required this.quantity,
    required this.amount,
    this.productNameSnapshotI18n = const <String, dynamic>{},
    this.name,
    this.comment,
  });

  final String productId;
  final int quantity;
  final int amount;
  final Map<String, dynamic> productNameSnapshotI18n;
  final String? name;
  final String? comment;

  String? localizedName(String language) {
    if (productNameSnapshotI18n.isNotEmpty) {
      final snapshotName = localizedText(productNameSnapshotI18n, language);
      if (snapshotName.trim().isNotEmpty) return snapshotName.trim();
    }

    final fallbackName = name?.trim();
    if (fallbackName?.isNotEmpty == true) return fallbackName;
    return null;
  }

  factory CustomerOrderItemModel.fromJson(Map<String, dynamic> json) {
    final product = asJsonMap(json['product']);
    final productNameSnapshotI18n = asJsonMap(
      json['productNameSnapshotI18n'] ??
          json['product_name_snapshot_i18n'] ??
          json['productNameI18n'] ??
          json['product_name_i18n'] ??
          product['nameI18n'] ??
          product['name_i18n'],
    );
    return CustomerOrderItemModel(
      productId: readString(json, const [
        'productId',
        'product_id',
        'id',
      ], fallback: readString(product, const ['id'])),
      quantity: readInt(json, const ['quantity']),
      amount: readInt(json, const [
        'amount',
        'totalAmount',
        'total_amount',
        'totalPrice',
        'total_price',
      ]),
      productNameSnapshotI18n: productNameSnapshotI18n,
      name:
          stringOrNull(json['name']) ??
          stringOrNull(json['productName']) ??
          stringOrNull(json['product_name']) ??
          localizedText(product['name'], 'ru'),
      comment: stringOrNull(json['comment']),
    );
  }
}

class OrderStatusLogModel {
  const OrderStatusLogModel({
    required this.status,
    this.changedAt,
    this.comment,
  });

  final MobileOrderStatus status;
  final DateTime? changedAt;
  final String? comment;

  factory OrderStatusLogModel.fromJson(Map<String, dynamic> json) {
    return OrderStatusLogModel(
      status: MobileOrderStatus.fromJson(stringOrNull(json['status'])),
      changedAt: readDateTime(json, const [
        'changedAt',
        'changed_at',
        'createdAt',
        'created_at',
        'at',
      ]),
      comment: stringOrNull(json['comment']),
    );
  }
}
