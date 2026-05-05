class Country {
  final String id;
  final String name;
  final String timezone;

  Country({required this.id, required this.name, required this.timezone});

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      id: json['id'],
      name: json['name'],
      timezone: json['timezone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'timezone': timezone};
  }
}
