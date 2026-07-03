// ignore_for_file: constant_identifier_names

import 'package:enjoy_lavash_mobile/core/data/models/organisation.dart';
import 'package:enjoy_lavash_mobile/core/data/models/simple_entity.dart';

enum OrderTypes { SPECIAL, EXORD, SELLS }

enum OrderStatus { NEW, ACCEPTED, IN_PROGRESS, FAILED, COMPLETED, CANCELLED }

class OrderItem {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int number;
  final List<String>? groups;

  final Organisation? fromOrganisation;
  final Organisation? shipmentStore;
  final SimpleEntity? supplier;
  final SimpleEntity? category;

  final int productsCount;
  final double orderedUnitsTotal;
  final double shippedUnitsTotal;
  final double deliveredUnitsTotal;

  final DateTime? deliveryDatetime;
  final String status;
  final String type;

  final String? comment;
  final String? senderComment;
  final String? name;
  final String? phoneNumber;

  final num extraExpenses;

  final DateTime? acceptedAt;
  final DateTime? shippedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;

  OrderItem({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.number,
    required this.fromOrganisation,
    required this.shipmentStore,
    required this.supplier,
    required this.category,
    required this.productsCount,
    required this.orderedUnitsTotal,
    required this.shippedUnitsTotal,
    required this.deliveredUnitsTotal,
    required this.deliveryDatetime,
    required this.status,
    required this.type,
    this.comment,
    this.groups,
    this.senderComment,
    this.name,
    this.phoneNumber,
    required this.extraExpenses,
    this.acceptedAt,
    this.shippedAt,
    this.completedAt,
    this.cancelledAt,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      groups: List<String>.from(json['group'] ?? []),
      number: json['number'],
      fromOrganisation: json['from_organisation'] != null
          ? Organisation.fromJson(json['from_organisation'])
          : null,
      shipmentStore: json['shipment_store'] != null
          ? Organisation.fromJson(json['shipment_store'])
          : null,
      supplier: json['supplier'] != null
          ? SimpleEntity.fromJson(json['supplier'])
          : null,
      category: json['category'] != null
          ? SimpleEntity.fromJson(json['category'])
          : null,
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'number': number,
      'groups': groups,
      'from_organisation': fromOrganisation?.toJson(),
      'shipment_store': shipmentStore?.toJson(),
      'supplier': supplier?.toJson(),
      'category': category?.toJson(),
      'products_count': productsCount,
      'ordered_units_total': orderedUnitsTotal,
      'shipped_units_total': shippedUnitsTotal,
      'delivered_units_total': deliveredUnitsTotal,
      'delivery_datetime': deliveryDatetime?.toIso8601String(),
      'status': status,
      'type': type,
      'comment': comment,
      'sender_comment': senderComment,
      'name': name,
      'phone_number': phoneNumber,
      'extra_expenses': extraExpenses,
      'accepted_at': acceptedAt?.toIso8601String(),
      'shipped_at': shippedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
    };
  }
}
