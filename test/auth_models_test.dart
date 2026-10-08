import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/auth_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses the required OTP expiry', () {
    const expiresAt = '2026-07-11T10:15:00.000Z';
    final response = OtpRequestResponse.fromJson({
      'phoneNumber': '+998901234567',
      'codeExpiresAt': expiresAt,
    });

    expect(response.phoneNumber, '+998901234567');
    expect(response.codeExpiresAt, DateTime.parse(expiresAt));
  });

  group('codeLifetimeFrom', () {
    final serverNow = DateTime.utc(2026, 10, 7, 12);
    final expiresAt = serverNow.add(const Duration(minutes: 2));

    test('uses the server clock when the Date header is present', () {
      final response = OtpRequestResponse(
        phoneNumber: '+998901234567',
        codeExpiresAt: expiresAt,
        serverTime: serverNow,
      );
      // Device clock 4 minutes fast: the code would look expired on arrival.
      final fastDevice = serverNow.add(const Duration(minutes: 4));
      expect(response.codeLifetimeFrom(fastDevice), const Duration(minutes: 2));
    });

    test('falls back instead of expiring on arrival without server time', () {
      final response = OtpRequestResponse(
        phoneNumber: '+998901234567',
        codeExpiresAt: expiresAt,
      );
      final fastDevice = serverNow.add(const Duration(minutes: 4));
      expect(response.codeLifetimeFrom(fastDevice), fallbackOtpLifetime);
    });

    test('caps the lifetime when the device clock is far behind', () {
      final response = OtpRequestResponse(
        phoneNumber: '+998901234567',
        codeExpiresAt: expiresAt,
      );
      final slowDevice = serverNow.subtract(const Duration(hours: 1));
      expect(response.codeLifetimeFrom(slowDevice), maxOtpLifetime);
    });

    test('fromJson carries the server time through', () {
      final response = OtpRequestResponse.fromJson({
        'phoneNumber': '+998901234567',
        'codeExpiresAt': expiresAt.toIso8601String(),
      }, serverTime: serverNow);
      expect(response.serverTime, serverNow);
    });
  });

  test('rejects an OTP success response without a valid expiry', () {
    expect(
      () => OtpRequestResponse.fromJson({'phoneNumber': '+998901234567'}),
      throwsFormatException,
    );
  });

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
