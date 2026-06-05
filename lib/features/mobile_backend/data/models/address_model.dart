import 'json_helpers.dart';

class ClientAddress {
  const ClientAddress({
    required this.id,
    required this.label,
    required this.street,
    required this.latitude,
    required this.longitude,
    required this.isDefault,
    this.houseNumber,
    this.apartmentNumber,
    this.entrance,
    this.floor,
    this.doorCode,
    this.comment,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String label;
  final String street;
  final String? houseNumber;
  final String? apartmentNumber;
  final String? entrance;
  final String? floor;
  final String? doorCode;
  final double latitude;
  final double longitude;
  final String? comment;
  final bool isDefault;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ClientAddress.fromJson(Map<String, dynamic> json) {
    return ClientAddress(
      id: readString(json, const ['id']),
      label: readString(json, const ['label']),
      street: readString(json, const ['street']),
      houseNumber:
          stringOrNull(json['houseNumber']) ??
          stringOrNull(json['house_number']),
      apartmentNumber:
          stringOrNull(json['apartmentNumber']) ??
          stringOrNull(json['apartment_number']),
      entrance: stringOrNull(json['entrance']),
      floor: stringOrNull(json['floor']),
      doorCode:
          stringOrNull(json['doorCode']) ?? stringOrNull(json['door_code']),
      latitude: readDouble(json, const ['latitude', 'lat']),
      longitude: readDouble(json, const ['longitude', 'lng', 'lon']),
      comment: stringOrNull(json['comment']),
      isDefault: readBool(json, const ['isDefault', 'is_default']),
      createdAt: readDateTime(json, const ['createdAt', 'created_at']),
      updatedAt: readDateTime(json, const ['updatedAt', 'updated_at']),
    );
  }
}

class ClientAddressInput {
  const ClientAddressInput({
    required this.label,
    required this.street,
    required this.latitude,
    required this.longitude,
    this.houseNumber,
    this.apartmentNumber,
    this.entrance,
    this.floor,
    this.doorCode,
    this.comment,
    this.isDefault,
  });

  final String label;
  final String street;
  final String? houseNumber;
  final String? apartmentNumber;
  final String? entrance;
  final String? floor;
  final String? doorCode;
  final double latitude;
  final double longitude;
  final String? comment;
  final bool? isDefault;

  Map<String, Object?> toJson() {
    return withoutNulls({
      'label': label,
      'street': street,
      'houseNumber': houseNumber,
      'apartmentNumber': apartmentNumber,
      'entrance': entrance,
      'floor': floor,
      'doorCode': doorCode,
      'latitude': latitude,
      'longitude': longitude,
      'comment': comment,
      'isDefault': isDefault,
    });
  }
}
