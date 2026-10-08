import 'client_profile_model.dart';
import 'json_helpers.dart';

/// Longest OTP lifetime the client will display. A longer computed lifetime
/// means the device clock is behind; the server still rejects late codes.
const Duration maxOtpLifetime = Duration(minutes: 15);

/// Lifetime shown when it cannot be measured reliably (no server time and a
/// device clock so far ahead that the code would look expired on arrival).
const Duration fallbackOtpLifetime = Duration(minutes: 2);

class OtpRequestResponse {
  const OtpRequestResponse({
    required this.phoneNumber,
    required this.codeExpiresAt,
    this.serverTime,
  });

  final String phoneNumber;
  final DateTime codeExpiresAt;

  /// Server clock when the response was produced (HTTP `Date` header).
  final DateTime? serverTime;

  /// How long the code stays valid, measured on the server's clock when
  /// available. Count this down from the device's "now" instead of comparing
  /// [codeExpiresAt] with the device clock, which may be wrong.
  Duration codeLifetimeFrom(DateTime deviceNow) {
    final reference = serverTime ?? deviceNow;
    final lifetime = codeExpiresAt.toUtc().difference(reference.toUtc());
    if (lifetime <= Duration.zero) return fallbackOtpLifetime;
    if (lifetime > maxOtpLifetime) return maxOtpLifetime;
    return lifetime;
  }

  factory OtpRequestResponse.fromJson(
    Map<String, dynamic> json, {
    DateTime? serverTime,
  }) {
    return OtpRequestResponse(
      phoneNumber: readString(json, const ['phoneNumber', 'phone_number']),
      codeExpiresAt: _requiredDateTime(json, const [
        'codeExpiresAt',
        'code_expires_at',
      ], fieldName: 'codeExpiresAt'),
      serverTime: serverTime,
    );
  }
}

class VerifyOtpRequest {
  const VerifyOtpRequest({
    required this.phoneNumber,
    required this.code,
    this.fullName,
    this.language,
  });

  final String phoneNumber;
  final String code;
  final String? fullName;
  final String? language;

  Map<String, Object?> toJson() {
    return withoutNulls({
      'phoneNumber': phoneNumber,
      'code': code,
      'fullName': fullName,
      'language': language,
    });
  }
}

class VerifyOtpResponse {
  const VerifyOtpResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.refreshTokenExpiresAt,
    required this.tokenType,
    required this.client,
    this.isNewClient = false,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime refreshTokenExpiresAt;
  final String tokenType;
  final ClientProfile client;
  final bool isNewClient;

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResponse(
      accessToken: _requiredString(json, const [
        'access_token',
        'accessToken',
      ], fieldName: 'access_token'),
      refreshToken: _requiredString(json, const [
        'refresh_token',
        'refreshToken',
      ], fieldName: 'refresh_token'),
      refreshTokenExpiresAt: _requiredDateTime(json, const [
        'refresh_token_expires_at',
        'refreshTokenExpiresAt',
      ], fieldName: 'refresh_token_expires_at'),
      tokenType: _requiredString(json, const [
        'token_type',
        'tokenType',
      ], fieldName: 'token_type'),
      client: ClientProfile.fromJson(asJsonMap(json['client'])),
      isNewClient: readBool(json, const [
        'clientCreated',
        'client_created',
        'createdClient',
        'created_client',
        'isNewClient',
        'is_new_client',
        'isNewUser',
        'is_new_user',
        'created',
      ]),
    );
  }
}

String _requiredString(
  Map<String, dynamic> json,
  List<String> keys, {
  required String fieldName,
}) {
  final value = readString(json, keys).trim();
  if (value.isEmpty) {
    throw FormatException('Missing required response field: $fieldName');
  }
  return value;
}

DateTime _requiredDateTime(
  Map<String, dynamic> json,
  List<String> keys, {
  required String fieldName,
}) {
  final value = readDateTime(json, keys);
  if (value == null) {
    throw FormatException('Missing or invalid response field: $fieldName');
  }
  return value;
}
