import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();

  // Keep mobile-client credentials isolated from any admin credentials that may
  // coexist in secure storage on development or managed devices.
  static const _accessTokenKey = 'mobile_client_access_token';
  static const _refreshTokenKey = 'mobile_client_refresh_token';
  static const _refreshTokenExpiresAtKey =
      'mobile_client_refresh_token_expires_at';

  static Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  static Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  static Future<void> saveRefreshTokenExpiresAt(DateTime? expiresAt) async {
    if (expiresAt == null) {
      await _storage.delete(key: _refreshTokenExpiresAtKey);
      return;
    }

    await _storage.write(
      key: _refreshTokenExpiresAtKey,
      value: expiresAt.toUtc().toIso8601String(),
    );
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  static Future<DateTime?> getRefreshTokenExpiresAt() async {
    final value = await _storage.read(key: _refreshTokenExpiresAtKey);
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  static Future<void> clear() async {
    await Future.wait(<Future<void>>[
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _refreshTokenExpiresAtKey),
    ]);
  }
}
