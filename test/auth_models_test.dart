import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/auth_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses client_created from verify otp response', () {
    final response = VerifyOtpResponse.fromJson({
      'access_token': 'token',
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
  });
}
