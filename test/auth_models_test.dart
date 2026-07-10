import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/auth_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses client_created from verify otp response', () {
    const refreshExpiresAt = '2026-10-06T12:00:00.000Z';
    final response = VerifyOtpResponse.fromJson({
      'access_token': 'token',
      'refresh_token': 'refresh-token',
      'refresh_token_expires_at': refreshExpiresAt,
      'token_type': 'Bearer',
      'client_created': true,
      'client': {
        'id': 'client-id',
        'fullName': 'Ali Valiyev',
        'phoneNumber': '+998901234567',
        'language': 'uz',
        'bonusBalance': 0,
        'marketingConsent': false,
        'isBlocked': false,
      },
    });

    expect(response.isNewClient, isTrue);
    expect(response.refreshToken, 'refresh-token');
    expect(response.refreshTokenExpiresAt, DateTime.parse(refreshExpiresAt));
  });
}
