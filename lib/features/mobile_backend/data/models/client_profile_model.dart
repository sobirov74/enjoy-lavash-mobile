import 'json_helpers.dart';

class ClientProfile {
  const ClientProfile({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.language,
    required this.bonusBalance,
    required this.marketingConsent,
    required this.isBlocked,
    this.birthDate,
    this.lastOrderAt,
    this.organisationId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String fullName;
  final String phoneNumber;
  final String language;
  final int bonusBalance;
  final DateTime? birthDate;
  final bool marketingConsent;
  final bool isBlocked;
  final DateTime? lastOrderAt;
  final String? organisationId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ClientProfile.fromJson(Map<String, dynamic> json) {
    return ClientProfile(
      id: readString(json, const ['id']),
      fullName: readString(json, const ['fullName', 'full_name', 'name']),
      phoneNumber: readString(json, const ['phoneNumber', 'phone_number']),
      language: readString(json, const ['language'], fallback: 'ru'),
      bonusBalance: readInt(json, const ['bonusBalance', 'bonus_balance']),
      birthDate: readDateTime(json, const ['birthDate', 'birth_date']),
      marketingConsent: readBool(json, const [
        'marketingConsent',
        'marketing_consent',
      ]),
      isBlocked: readBool(json, const ['isBlocked', 'is_blocked']),
      lastOrderAt: readDateTime(json, const ['lastOrderAt', 'last_order_at']),
      organisationId:
          stringOrNull(json['organisationId']) ??
          stringOrNull(json['organisation_id']),
      createdAt: readDateTime(json, const ['createdAt', 'created_at']),
      updatedAt: readDateTime(json, const ['updatedAt', 'updated_at']),
    );
  }
}

class ClientProfileUpdate {
  const ClientProfileUpdate({
    this.fullName,
    this.birthDate,
    this.language,
    this.marketingConsent,
  });

  final String? fullName;
  final DateTime? birthDate;
  final String? language;
  final bool? marketingConsent;

  Map<String, Object?> toJson() {
    return withoutNulls({
      'fullName': fullName,
      'birthDate': birthDate?.toIso8601String().split('T').first,
      'language': language,
      'marketingConsent': marketingConsent,
    });
  }
}
