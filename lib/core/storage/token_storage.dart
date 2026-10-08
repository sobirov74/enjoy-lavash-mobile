import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Client session tokens in the platform keystore / keychain.
///
/// The keystore can become unreadable (Android backup restored onto a new
/// device, OS update, keystore reset). Reads then throw [PlatformException].
/// Instead of failing every request and bootstrap until the app is
/// reinstalled, an unreadable session is deleted and treated as signed out.
class TokenStorage {
  static FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// The access token is attached to every protected request; reading it
  /// from the platform keystore each time costs a channel round trip, so the
  /// last known value is kept here. `null` means "not loaded yet".
  static String? _accessTokenCache;
  static bool _accessTokenLoaded = false;

  /// Replaces the backing store; tests use it to simulate keystore failures.
  @visibleForTesting
  static set storage(FlutterSecureStorage storage) => _storage = storage;

  @visibleForTesting
  static void resetStorage() {
    _storage = const FlutterSecureStorage();
    _forgetAccessToken();
  }

  static void _forgetAccessToken() {
    _accessTokenCache = null;
    _accessTokenLoaded = false;
  }

  // Keep mobile-client credentials isolated from any admin credentials that may
  // coexist in secure storage on development or managed devices.
  static const _accessTokenKey = 'mobile_client_access_token';
  static const _refreshTokenKey = 'mobile_client_refresh_token';
  static const _refreshTokenExpiresAtKey =
      'mobile_client_refresh_token_expires_at';
  static const _sessionKeys = <String>[
    _accessTokenKey,
    _refreshTokenKey,
    _refreshTokenExpiresAtKey,
  ];

  static Future<void> saveAccessToken(String token) async {
    await _write(_accessTokenKey, token);
    _accessTokenCache = token;
    _accessTokenLoaded = true;
  }

  static Future<void> saveRefreshToken(String token) {
    return _write(_refreshTokenKey, token);
  }

  static Future<void> saveRefreshTokenExpiresAt(DateTime? expiresAt) async {
    if (expiresAt == null) {
      await _deleteQuietly(_refreshTokenExpiresAtKey);
      return;
    }
    await _write(
      _refreshTokenExpiresAtKey,
      expiresAt.toUtc().toIso8601String(),
    );
  }

  static Future<String?> getRefreshToken() => _read(_refreshTokenKey);

  static Future<DateTime?> getRefreshTokenExpiresAt() async {
    final value = await _read(_refreshTokenExpiresAtKey);
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  static Future<String?> getAccessToken() async {
    if (_accessTokenLoaded) return _accessTokenCache;
    final token = await _read(_accessTokenKey);
    _accessTokenCache = token;
    _accessTokenLoaded = true;
    return token;
  }

  /// Removes the session. Never throws: signing out must always succeed.
  static Future<void> clear() async {
    _accessTokenCache = null;
    _accessTokenLoaded = true;
    await Future.wait(<Future<void>>[
      for (final key in _sessionKeys) _deleteQuietly(key),
    ]);
  }

  static Future<String?> _read(String key) async {
    try {
      return await _storage.read(key: key);
    } on PlatformException catch (error) {
      debugPrint('Secure storage unreadable (${error.code}); signing out.');
      _forgetAccessToken();
      await clear();
      return null;
    }
  }

  /// Writes [value]; after a keystore error the stale entry is deleted and
  /// the write retried once. A second failure propagates so the caller (login)
  /// can report it instead of pretending the session was saved.
  static Future<void> _write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } on PlatformException catch (error) {
      debugPrint('Secure storage write failed (${error.code}); retrying.');
      await _deleteQuietly(key);
      await _storage.write(key: key, value: value);
    }
  }

  static Future<void> _deleteQuietly(String key) async {
    try {
      await _storage.delete(key: key);
    } on PlatformException catch (error) {
      debugPrint('Secure storage delete failed (${error.code}).');
    }
  }
}
