import 'package:dio/dio.dart';
import 'package:enjoy_lavash_mobile/core/api/base_url.dart';
import 'package:enjoy_lavash_mobile/core/storage/token_storage.dart';
import 'package:flutter/foundation.dart';

const _refreshEndpoint = '/api/v1/auth/refresh';
const _logoutTriggerCodes = {401, 403};
const _enableNetworkLogs =
    kDebugMode || bool.fromEnvironment('ENABLE_NETWORK_LOGS');

/// Callback invoked when the session expires and the user must re-authenticate.
/// Set from the app layer (e.g. DI setup) to decouple API client from navigation.
typedef LogoutCallback = Future<void> Function();

class ApiClient {
  ApiClient({LogoutCallback? onLogout}) : _onLogout = onLogout {
    dio = Dio(
      BaseOptions(
        baseUrl: BaseUrl.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _refreshDio = Dio(
      BaseOptions(
        baseUrl: BaseUrl.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

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

  final LogoutCallback? _onLogout;

  // Single-flight: only one refresh at a time.
  Future<String?>? _refreshPromise;

  InterceptorsWrapper _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await TokenStorage.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        final status = error.response?.statusCode ?? 0;
        final requestPath = error.requestOptions.path;

        if (requestPath.contains(_refreshEndpoint)) {
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

          final newAccessToken = await _refreshPromise;

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
            await _logout();
          }
        }

        return handler.next(error);
      },
    );
  }

  Future<String?> _doRefresh() async {
    final refreshToken = await TokenStorage.getRefreshToken();
    if (refreshToken == null) return null;

    try {
      final response = await _refreshDio.post(
        _refreshEndpoint,
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final newAccess = data['access_token'] as String?;
        final newRefresh = (data['refresh_token'] as String?) ?? refreshToken;

        if (newAccess != null) {
          await TokenStorage.saveAccessToken(newAccess);
          await TokenStorage.saveRefreshToken(newRefresh);
          return newAccess;
        }
      }
      return null;
    } on DioException catch (e) {
      final status = e.response?.statusCode ?? 0;
      if (_logoutTriggerCodes.contains(status)) {
        await _logout();
      }
      return null;
    }
  }

  Future<void> _logout() async {
    await TokenStorage.clear();
    await _onLogout?.call();
  }
}

void _debugLog(Object object) {
  debugPrint(object.toString());
}
