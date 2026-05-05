import 'package:enjoy_lavash_mobile/core/data/models/organisation.dart';
import 'package:enjoy_lavash_mobile/core/data/models/store.dart';

class OrderDetails {
  final DateTime createdAt;
  final DateTime updatedAt;
  final String id;
  final dynamic number;

  final Organisation? fromOrganisation;
  final ShipmentStore? shipmentStore;
  // final SimpleEntity? supplier;
  // final SimpleEntity? category;

  final dynamic productsCount;
  final dynamic orderedUnitsTotal;
  final dynamic shippedUnitsTotal;
  final dynamic deliveredUnitsTotal;

  final DateTime deliveryDatetime;

  final String status;
  final String type;

  final String? comment;
  final String? senderComment;
  final String? name;
  final String? phoneNumber;

  final dynamic extraExpenses;

  final DateTime? acceptedAt;
  final DateTime? shippedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;

  OrderDetails({
    required this.createdAt,
    required this.updatedAt,
    required this.id,
    required this.number,
    required this.fromOrganisation,
    required this.shipmentStore,
    // required this.supplier,
    // required this.category,
    required this.productsCount,
    required this.orderedUnitsTotal,
    required this.shippedUnitsTotal,
    required this.deliveredUnitsTotal,
    required this.deliveryDatetime,
    required this.status,
    required this.type,
    this.comment,
    this.senderComment,
    this.name,
    this.phoneNumber,
    required this.extraExpenses,
    this.acceptedAt,
    this.shippedAt,
    this.completedAt,
    this.cancelledAt,
  });

  factory OrderDetails.fromJson(Map<String, dynamic> json) {
    return OrderDetails(
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      id: json['id'],
      number: json['number'],
      fromOrganisation: json['from_organisation'] != null
          ? Organisation.fromJson(json['from_organisation'])
          : null,
      shipmentStore: json['shipment_store'] != null
          ? ShipmentStore.fromJson(json['shipment_store'])
          : null,
      // supplier: SimpleEntity.fromJson(json['supplier']),
      // category: SimpleEntity.fromJson(json['category']),
      productsCount: json['products_count'],
      orderedUnitsTotal: json['ordered_units_total'],
      shippedUnitsTotal: json['shipped_units_total'],
      deliveredUnitsTotal: json['delivered_units_total'],
      deliveryDatetime: DateTime.parse(json['delivery_datetime']),
      status: json['status'],
      type: json['type'],
      comment: json['comment'],
      senderComment: json['sender_comment'],
      name: json['name'],
      phoneNumber: json['phone_number'],
      extraExpenses: json['extra_expenses'],
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'])
          : null,
      shippedAt: json['shipped_at'] != null
          ? DateTime.parse(json['shipped_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'])
          : null,
    );
  }
}
