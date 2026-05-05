import 'package:enjoy_lavash_mobile/core/data/models/country.dart';
import 'package:enjoy_lavash_mobile/core/data/models/organisation_parent.dart';
import 'package:enjoy_lavash_mobile/core/data/models/simple_entity.dart';

class Organisation {
  final String id;
  final String name;
  final String organisationType;
  final String purpose;
  final Country? country;
  final OrganisationParent? parent;
  final SimpleEntity? supplier;
  final bool? includeInOrderGeneration;
  final bool? isActive;
  final String? sapCode;
  final List<String>? activeSections;
  final bool? useSapIntegration;
  final String? rootOrganisationId;

  Organisation({
    required this.id,
    required this.name,
    required this.organisationType,
    required this.purpose,
    this.country,
    this.parent,
    this.supplier,
    this.includeInOrderGeneration,
    this.isActive,
    this.sapCode,
    this.activeSections,
    this.useSapIntegration,
    this.rootOrganisationId,
  });

  factory Organisation.fromJson(Map<String, dynamic> json) {
    return Organisation(
      id: json['id'],
      name: json['name'],
      organisationType: json['organisation_type'],
      purpose: json['purpose'],
      country: json['country'] != null
          ? Country.fromJson(json['country'])
          : null,
      parent: json['parent'] != null
          ? OrganisationParent.fromJson(json['parent'])
          : null,
      supplier: json['supplier'] != null
          ? SimpleEntity.fromJson(json['supplier'])
          : null,
      includeInOrderGeneration: json['include_in_order_generation'],
      isActive: json['is_active'],
      sapCode: json['sap_code'],
      activeSections: json['active_sections'] != null
          ? List<String>.from(json['active_sections'])
          : null,
      useSapIntegration: json['use_sap_integration'],
      rootOrganisationId: json['root_organisation_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'organisation_type': organisationType,
      'purpose': purpose,
      'country': country?.toJson(),
      'parent': parent?.toJson(),
      'supplier': supplier?.toJson(),
      'include_in_order_generation': includeInOrderGeneration,
      'is_active': isActive,
      'sap_code': sapCode,
      'active_sections': activeSections,
      'use_sap_integration': useSapIntegration,
      'root_organisation_id': rootOrganisationId,
    };
  }
}
