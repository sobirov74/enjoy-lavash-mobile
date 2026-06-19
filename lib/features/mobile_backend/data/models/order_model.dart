import 'cart_model.dart';
import 'json_helpers.dart';

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
    });
  }
}

class CreateOrderAddressInput {
  const CreateOrderAddressInput({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;

  Map<String, Object?> toJson() {
    return {'latitude': latitude, 'longitude': longitude};
  }
}

class CustomerOrderModel {
  CustomerOrderModel({
    required this.id,
    required this.type,
    required this.status,
    required this.totalAmount,
    required this.paymentMethod,
    required List<CustomerOrderItemModel> items,
    required List<OrderStatusLogModel> statusLog,
    this.branchId,
    this.addressId,
    this.promoCode,
    this.comment,
    this.scheduledFor,
    this.iikoOrderId,
    this.createdAt,
    this.updatedAt,
    this.raw = const <String, dynamic>{},
  }) : items = List<CustomerOrderItemModel>.unmodifiable(items),
       statusLog = List<OrderStatusLogModel>.unmodifiable(statusLog);

  final String id;
  final MobileOrderType type;
  final MobileOrderStatus status;
  final int totalAmount;
  final MobilePaymentMethod paymentMethod;
  final List<CustomerOrderItemModel> items;
  final List<OrderStatusLogModel> statusLog;
  final String? branchId;
  final String? addressId;
  final String? promoCode;
  final String? comment;
  final DateTime? scheduledFor;
  final String? iikoOrderId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> raw;

  factory CustomerOrderModel.fromJson(Map<String, dynamic> json) {
    return CustomerOrderModel(
      id: readString(json, const ['id']),
      type: MobileOrderType.fromJson(stringOrNull(json['type'])),
      status: MobileOrderStatus.fromJson(stringOrNull(json['status'])),
      totalAmount: readInt(json, const ['totalAmount', 'total_amount']),
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
      createdAt: readDateTime(json, const ['createdAt', 'created_at']),
      updatedAt: readDateTime(json, const ['updatedAt', 'updated_at']),
      raw: Map<String, dynamic>.unmodifiable(json),
    );
  }
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
