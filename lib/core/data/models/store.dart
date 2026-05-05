import 'package:enjoy_lavash_mobile/core/data/models/organisation.dart';
import 'package:enjoy_lavash_mobile/core/data/models/simple_entity.dart';

class ShipmentStore {
  final String id;
  final String name;
  final String organisationType;
  final String purpose;

  final Organisation? parent;
  final SimpleEntity? supplier;

  ShipmentStore({
    required this.id,
    required this.name,
    required this.organisationType,
    required this.purpose,
    this.parent,
    this.supplier,
  });

  factory ShipmentStore.fromJson(Map<String, dynamic> json) {
    return ShipmentStore(
      id: json['id'],
      name: json['name'],
      organisationType: json['organisation_type'],
      purpose: json['purpose'],
      parent: json['parent'] != null
          ? Organisation.fromJson(json['parent'])
          : null,
      supplier: json['supplier'] != null
          ? SimpleEntity.fromJson(json['supplier'])
          : null,
    );
  }
}
