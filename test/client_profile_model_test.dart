import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/client_profile_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('serializes a birth date without a time or timezone', () {
    final update = ClientProfileUpdate(birthDate: DateTime(1995, 4, 7));

    expect(update.toJson(), {'birthDate': '1995-04-07'});
  });

  test('parses a birth date from a client profile', () {
    final profile = ClientProfile.fromJson({
      'id': 'client-id',
      'fullName': 'Ali Valiyev',
      'phoneNumber': '+998901234567',
      'language': 'uz',
      'bonusBalance': 0,
      'birthDate': '1995-04-07',
      'marketingConsent': false,
      'isBlocked': false,
    });

    expect(profile.birthDate, DateTime(1995, 4, 7));
  });
}
