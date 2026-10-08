import 'dart:async';

import 'package:dio/dio.dart';
import 'package:enjoy_lavash_mobile/core/api/api_endpoints.dart';
import 'package:enjoy_lavash_mobile/core/api/base_url.dart';
import 'package:enjoy_lavash_mobile/core/storage/token_storage.dart';
import 'package:flutter/foundation.dart';

const _refreshEndpoint = ApiEndpoints.clientRefresh;
const _logoutTriggerCodes = {401};
const _defaultLanguage = 'uz';
const _requestTimeout = Duration(seconds: 15);
const _enableNetworkLogs =
    kDebugMode || bool.fromEnvironment('ENABLE_NETWORK_LOGS');

/// Callback invoked when the session expires and the user must re-authenticate.
/// Set from the app layer (e.g. DI setup) to decouple API client from navigation.
typedef LogoutCallback = Future<void> Function();

class ApiClient {
  ApiClient({
    LogoutCallback? onLogout,
    String? baseUrl,
    HttpClientAdapter? httpClientAdapter,
    HttpClientAdapter? refreshHttpClientAdapter,
  }) : _onLogout = onLogout {
    final resolvedBaseUrl = baseUrl ?? BaseUrl.baseUrl;
    dio = Dio(
      BaseOptions(
        baseUrl: resolvedBaseUrl,
        connectTimeout: _requestTimeout,
        sendTimeout: _requestTimeout,
        receiveTimeout: _requestTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept-Language': _defaultLanguage,
        },
      ),
    );

    _refreshDio = Dio(
      BaseOptions(
        baseUrl: resolvedBaseUrl,
        connectTimeout: _requestTimeout,
        sendTimeout: _requestTimeout,
        receiveTimeout: _requestTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept-Language': _defaultLanguage,
        },
      ),
    );

    if (httpClientAdapter != null) {
      dio.httpClientAdapter = httpClientAdapter;
    }
    final refreshAdapter = refreshHttpClientAdapter ?? httpClientAdapter;
    if (refreshAdapter != null) {
      _refreshDio.httpClientAdapter = refreshAdapter;
    }

    if (_enableNetworkLogs) {
      dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: false,
          requestBody: false,
          responseBody: false,
          responseHeader: false,
          error: true,
          logPrint: _debugLog,
        ),
      );
    }

    dio.interceptors.add(_authInterceptor());
  }

  late final Dio dio;
  late final Dio _refreshDio;

  String _languageCode = _defaultLanguage;
  LogoutCallback? _onLogout;

  // Single-flight: only one refresh at a time.
  Future<_RefreshResult>? _refreshPromise;
  Future<void>? _logoutPromise;
  Future<void> _sessionMutationTail = Future<void>.value();
  int _sessionGeneration = 0;

  void setOnLogout(LogoutCallback? callback) {
    _onLogout = callback;
  }

  void setLanguage(String languageCode) {
    _languageCode = _normalizeLanguage(languageCode);
    dio.options.headers['Accept-Language'] = _languageCode;
    _refreshDio.options.headers['Accept-Language'] = _languageCode;
  }

  Future<void> replaceClientSession({
    required String accessToken,
    required String refreshToken,
    DateTime? refreshTokenExpiresAt,
  }) {
    _sessionGeneration++;
    return _serializeSessionMutation(() async {
      await TokenStorage.clear();
      await TokenStorage.saveAccessToken(accessToken);
      await TokenStorage.saveRefreshToken(refreshToken);
      await TokenStorage.saveRefreshTokenExpiresAt(refreshTokenExpiresAt);
    });
  }

  Future<void> clearClientSession() {
    _sessionGeneration++;
    return _serializeSessionMutation(TokenStorage.clear);
  }

  InterceptorsWrapper _authInterceptor() {
    // Dio does not await async interceptor callbacks: if one throws, its
    // handler is never completed and the request hangs forever. Every path
    // below therefore completes the handler exactly once.
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          options.headers['Accept-Language'] ??= _languageCode;
          if (_isClientProtectedEndpoint(options.path)) {
            final token = await TokenStorage.getAccessToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
        } catch (error, stackTrace) {
          return handler.reject(
            DioException(
              requestOptions: options,
              error: error,
              stackTrace: stackTrace,
            ),
          );
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        Object outcome;
        try {
          outcome = await _recoverFromAuthError(error);
        } catch (recoveryError) {
          debugPrint('Auth recovery failed: ${recoveryError.runtimeType}');
          outcome = error;
        }
        if (outcome is Response<Object?>) return handler.resolve(outcome);
        return handler.next(outcome is DioException ? outcome : error);
      },
    );
  }

  /// Refreshes the session after a 401 and replays the request once.
  /// Returns the replayed [Response] or the [DioException] to propagate.
  Future<Object> _recoverFromAuthError(DioException error) async {
    final status = error.response?.statusCode ?? 0;
    final requestPath = error.requestOptions.path;

    if (!_isClientProtectedEndpoint(requestPath) ||
        !_logoutTriggerCodes.contains(status)) {
      return error;
    }

    if (error.requestOptions.extra['_retry'] == true) {
      // The replay itself was rejected: the refreshed session is not valid.
      await _logout();
      return error;
    }
    error.requestOptions.extra['_retry'] = true;

    _refreshPromise ??= _doRefresh().whenComplete(() {
      _refreshPromise = null;
    });
    final refreshResult = await _refreshPromise!;
    final newAccessToken = refreshResult.accessToken;

    if (newAccessToken == null) {
      if (refreshResult.shouldLogout) await _logout();
      return error;
    }

    error.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
    try {
      // A 401 on the replay is handled (logout) by the `_retry` branch above
      // when it passes back through this interceptor.
      return await dio.fetch<Object?>(error.requestOptions);
    } on DioException catch (retryError) {
      return retryError;
    }
  }

  Future<_RefreshResult> _doRefresh() async {
    final sessionGeneration = _sessionGeneration;
    final refreshToken = await TokenStorage.getRefreshToken();
    if (refreshToken == null) {
      return sessionGeneration == _sessionGeneration
          ? const _RefreshResult.sessionExpired()
          : const _RefreshResult.failed();
    }

    try {
      final response = await _refreshDio.post(
        _refreshEndpoint,
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final newAccess = _stringValue(data, const [
          'access_token',
          'accessToken',
          'token',
        ]);
        final newRefresh = _stringValue(data, const [
          'refresh_token',
          'refreshToken',
        ]);
        final refreshExpiresAt = _dateTimeValue(data, const [
          'refresh_token_expires_at',
          'refreshTokenExpiresAt',
        ]);

        if (newAccess != null &&
            newRefresh != null &&
            refreshExpiresAt != null) {
          final stored = await _serializeSessionMutation(() async {
            if (sessionGeneration != _sessionGeneration) return false;
            await TokenStorage.saveAccessToken(newAccess);
            await TokenStorage.saveRefreshToken(newRefresh);
            await TokenStorage.saveRefreshTokenExpiresAt(refreshExpiresAt);
            return sessionGeneration == _sessionGeneration;
          });
          if (!stored) return const _RefreshResult.failed();
          return _RefreshResult.success(newAccess);
        }
      }
      // A successful refresh rotates the server token. If the response is
      // malformed, the previous refresh token is no longer safe to reuse.
      return const _RefreshResult.sessionExpired();
    } on DioException catch (e) {
      final status = e.response?.statusCode ?? 0;
      // A refresh that started before a new login must not sign that new
      // session out when its (old) token is rejected.
      if (_logoutTriggerCodes.contains(status) &&
          sessionGeneration == _sessionGeneration) {
        return const _RefreshResult.sessionExpired();
      }
      return const _RefreshResult.failed();
    }
  }

  Future<void> _logout() async {
    _logoutPromise ??= _performLogout().whenComplete(() {
      _logoutPromise = null;
    });
    await _logoutPromise;
  }

  Future<void> _performLogout() async {
    await clearClientSession();
    await _onLogout?.call();
  }

  Future<T> _serializeSessionMutation<T>(Future<T> Function() mutation) {
    final completer = Completer<T>();
    _sessionMutationTail = _sessionMutationTail.then((_) async {
      try {
        completer.complete(await mutation());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }
}

class _RefreshResult {
  const _RefreshResult._({this.accessToken, required this.shouldLogout});

  const _RefreshResult.success(String accessToken)
    : this._(accessToken: accessToken, shouldLogout: false);

  const _RefreshResult.sessionExpired()
    : this._(accessToken: null, shouldLogout: true);

  const _RefreshResult.failed()
    : this._(accessToken: null, shouldLogout: false);

  final String? accessToken;
  final bool shouldLogout;
}

void _debugLog(Object object) {
  debugPrint(object.toString());
}

String? _stringValue(Object? data, List<String> keys) {
  if (data is! Map) return null;
  for (final key in keys) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return null;
}

DateTime? _dateTimeValue(Object? data, List<String> keys) {
  final value = _firstValue(data, keys);
  if (value is DateTime) return value;
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value.trim());
  }
  return null;
}

Object? _firstValue(Object? data, List<String> keys) {
  if (data is! Map) return null;
  for (final key in keys) {
    final value = data[key];
    if (value != null) return value;
  }
  return null;
}

bool _isClientProtectedEndpoint(String path) {
  final parsedPath = Uri.tryParse(path)?.path ?? path;
  return parsedPath == ApiEndpoints.clientMe ||
      parsedPath.startsWith('${ApiEndpoints.clientMe}/') ||
      parsedPath == ApiEndpoints.filesUpload ||
      parsedPath == ApiEndpoints.filesDelete;
}

String _normalizeLanguage(String languageCode) {
  final normalized = languageCode.toLowerCase().split(RegExp('[-_]')).first;
  return switch (normalized) {
    'ru' || 'en' || 'uz' => normalized,
    _ => _defaultLanguage,
  };
}
