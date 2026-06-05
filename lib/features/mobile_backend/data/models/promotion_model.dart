import 'json_helpers.dart';

class PromotionModel {
  const PromotionModel({
    required this.id,
    required this.title,
    required this.isActive,
    this.code,
    this.description,
    this.discountType,
    this.discountValue,
    this.startsAt,
    this.endsAt,
    this.raw = const <String, dynamic>{},
  });

  final String id;
  final String title;
  final bool isActive;
  final String? code;
  final String? description;
  final String? discountType;
  final int? discountValue;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final Map<String, dynamic> raw;

  factory PromotionModel.fromJson(
    Map<String, dynamic> json, {
    String language = 'ru',
  }) {
    return PromotionModel(
      id: readString(json, const ['id']),
      title: localizedText(
        json['title'] ?? json['name'],
        language,
        fallback: readString(json, const ['title', 'name']),
      ),
      isActive: readBool(json, const ['isActive', 'is_active'], fallback: true),
      code: stringOrNull(json['code']) ?? stringOrNull(json['promoCode']),
      description: localizedText(
        json['description'],
        language,
        fallback: readString(json, const ['description']),
      ),
      discountType:
          stringOrNull(json['discountType']) ??
          stringOrNull(json['discount_type']),
      discountValue: _optionalInt(json, const [
        'discountValue',
        'discount_value',
      ]),
      startsAt: readDateTime(json, const ['startsAt', 'starts_at']),
      endsAt: readDateTime(json, const ['endsAt', 'ends_at']),
      raw: Map<String, dynamic>.unmodifiable(json),
    );
  }
}

int? _optionalInt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
  }
  return null;
}
