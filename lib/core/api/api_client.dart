import 'package:dio/dio.dart';
import 'package:enjoy_lavash_mobile/core/api/api_endpoints.dart';
import 'package:enjoy_lavash_mobile/core/api/base_url.dart';
import 'package:enjoy_lavash_mobile/core/storage/token_storage.dart';
import 'package:flutter/foundation.dart';

const _refreshEndpoint = ApiEndpoints.clientRefresh;
const _authFlowEndpoints = <String>{
  ApiEndpoints.requestOtp,
  ApiEndpoints.verifyOtp,
  ApiEndpoints.clientRefresh,
};
const _logoutTriggerCodes = {401};
const _defaultLanguage = 'uz';
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
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept-Language': _defaultLanguage,
        },
      ),
    );

    _refreshDio = Dio(
      BaseOptions(
        baseUrl: resolvedBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
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
          requestHeader: true,
          requestBody: true,
          responseBody: true,
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

  void setOnLogout(LogoutCallback? callback) {
    _onLogout = callback;
  }

  void setLanguage(String languageCode) {
    _languageCode = _normalizeLanguage(languageCode);
    dio.options.headers['Accept-Language'] = _languageCode;
    _refreshDio.options.headers['Accept-Language'] = _languageCode;
  }

  InterceptorsWrapper _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        options.headers['Accept-Language'] ??= _languageCode;
        if (!_isAuthFlowEndpoint(options.path)) {
          final token = await TokenStorage.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        final status = error.response?.statusCode ?? 0;
        final requestPath = error.requestOptions.path;

        if (_isAuthFlowEndpoint(requestPath)) {
          return handler.next(error);
        }

        if (_logoutTriggerCodes.contains(status)) {
          if (error.requestOptions.extra['_retry'] == true) {
            await _logout();
            return handler.next(error);
          }

          error.requestOptions.extra['_retry'] = true;

          _refreshPromise ??= _doRefresh().whenComplete(() {
            _refreshPromise = null;
          });

          final refreshResult = await _refreshPromise;
          final newAccessToken = refreshResult?.accessToken;

          if (newAccessToken != null) {
            error.requestOptions.headers['Authorization'] =
                'Bearer $newAccessToken';
            try {
              final response = await dio.fetch(error.requestOptions);
              return handler.resolve(response);
            } on DioException catch (retryError) {
              final retryStatus = retryError.response?.statusCode ?? 0;
              if (_logoutTriggerCodes.contains(retryStatus)) {
                await _logout();
              }
              return handler.next(retryError);
            }
          } else {
            if (refreshResult?.shouldLogout == true) {
              await _logout();
            }
          }
        }

        return handler.next(error);
      },
    );
  }

  Future<_RefreshResult> _doRefresh() async {
    final refreshToken = await TokenStorage.getRefreshToken();
    if (refreshToken == null) return const _RefreshResult.sessionExpired();

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
        final newRefresh =
            _stringValue(data, const ['refresh_token', 'refreshToken']) ??
            refreshToken;
        final refreshExpiresAt = _dateTimeValue(data, const [
          'refresh_token_expires_at',
          'refreshTokenExpiresAt',
        ]);

        if (newAccess != null && newRefresh.isNotEmpty) {
          await TokenStorage.saveAccessToken(newAccess);
          await TokenStorage.saveRefreshToken(newRefresh);
          await TokenStorage.saveRefreshTokenExpiresAt(refreshExpiresAt);
          return _RefreshResult.success(newAccess);
        }
      }
      return const _RefreshResult.failed();
    } on DioException catch (e) {
      final status = e.response?.statusCode ?? 0;
      if (_logoutTriggerCodes.contains(status)) {
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
    await TokenStorage.clear();
    await _onLogout?.call();
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

bool _isAuthFlowEndpoint(String path) {
  final parsedPath = Uri.tryParse(path)?.path ?? path;
  return _authFlowEndpoints.contains(parsedPath);
}

String _normalizeLanguage(String languageCode) {
  final normalized = languageCode.toLowerCase().split(RegExp('[-_]')).first;
  return switch (normalized) {
    'ru' || 'en' || 'uz' => normalized,
    _ => _defaultLanguage,
  };
}
