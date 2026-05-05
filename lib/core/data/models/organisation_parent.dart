class OrganisationParent {
  final String id;
  final String name;
  final String organisationType;
  final String purpose;

  OrganisationParent({
    required this.id,
    required this.name,
    required this.organisationType,
    required this.purpose,
  });

  factory OrganisationParent.fromJson(Map<String, dynamic> json) {
    return OrganisationParent(
      id: json['id'],
      name: json['name'],
      organisationType: json['organisation_type'],
      purpose: json['purpose'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'organisation_type': organisationType,
      'purpose': purpose,
    };
  }
}
