class SimpleEntity {
  final String id;
  final String name;

  SimpleEntity({required this.id, required this.name});

  factory SimpleEntity.fromJson(Map<String, dynamic> json) {
    return SimpleEntity(id: json['id'], name: json['name']);
  }
}
