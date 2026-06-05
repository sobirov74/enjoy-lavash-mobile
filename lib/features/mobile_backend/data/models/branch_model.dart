import 'json_helpers.dart';

class BranchModel {
  const BranchModel({
    required this.id,
    required this.name,
    required this.isActive,
    this.address,
    this.latitude,
    this.longitude,
    this.phoneNumber,
    this.openingTime,
    this.closingTime,
    this.raw = const <String, dynamic>{},
  });

  final String id;
  final String name;
  final bool isActive;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? phoneNumber;
  final String? openingTime;
  final String? closingTime;
  final Map<String, dynamic> raw;

  factory BranchModel.fromJson(
    Map<String, dynamic> json, {
    String language = 'ru',
  }) {
    return BranchModel(
      id: readString(json, const ['id']),
      name: localizedText(
        json['name'] ?? json['title'],
        language,
        fallback: readString(json, const ['name', 'title']),
      ),
      isActive: readBool(json, const ['isActive', 'is_active'], fallback: true),
      address: localizedText(
        json['address'],
        language,
        fallback: readString(json, const ['address']),
      ),
      latitude: _optionalDouble(json, const ['latitude', 'lat']),
      longitude: _optionalDouble(json, const ['longitude', 'lng', 'lon']),
      phoneNumber:
          stringOrNull(json['phoneNumber']) ??
          stringOrNull(json['phone_number']),
      openingTime:
          stringOrNull(json['openingTime']) ??
          stringOrNull(json['opening_time']),
      closingTime:
          stringOrNull(json['closingTime']) ??
          stringOrNull(json['closing_time']),
      raw: Map<String, dynamic>.unmodifiable(json),
    );
  }
}

double? _optionalDouble(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
  }
  return null;
}
