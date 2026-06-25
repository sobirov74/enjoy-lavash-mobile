import 'client_profile_model.dart';
import 'json_helpers.dart';

class OtpRequestResponse {
  const OtpRequestResponse({
    required this.phoneNumber,
    this.codeExpiresAt,
    this.demoCode,
  });

  final String phoneNumber;
  final DateTime? codeExpiresAt;
  final String? demoCode;

  factory OtpRequestResponse.fromJson(Map<String, dynamic> json) {
    return OtpRequestResponse(
      phoneNumber: readString(json, const ['phoneNumber', 'phone_number']),
      codeExpiresAt: readDateTime(json, const [
        'codeExpiresAt',
        'code_expires_at',
      ]),
      demoCode:
          stringOrNull(json['demoCode']) ?? stringOrNull(json['demo_code']),
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
    required this.tokenType,
    required this.client,
    this.refreshToken,
  });

  final String accessToken;
  final String? refreshToken;
  final String tokenType;
  final ClientProfile client;

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResponse(
      accessToken: readString(json, const ['access_token', 'accessToken']),
      refreshToken:
          stringOrNull(json['refresh_token']) ??
          stringOrNull(json['refreshToken']),
      tokenType: readString(json, const ['token_type', 'tokenType']),
      client: ClientProfile.fromJson(asJsonMap(json['client'])),
    );
  }
}
