import 'package:dio/dio.dart';
import 'package:enjoy_lavash_mobile/core/api/base_url.dart';
import 'package:enjoy_lavash_mobile/core/storage/token_storage.dart';
import 'package:enjoy_lavash_mobile/navigation/app_navigator.dart';

const _refreshEndpoint = '/api/v1/auth/refresh';
const _logoutTriggerCodes = {401, 403};

class ApiClient {
  late final Dio dio;

  // Separate Dio instance for refresh calls to avoid interceptor loops
  late final Dio _refreshDio;

  // Single-flight: only one refresh at a time
  Future<String?>? _refreshPromise;

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: BaseUrl.baseUrl,
        connectTimeout: const Duration(seconds: 40),
        receiveTimeout: const Duration(seconds: 40),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _refreshDio = Dio(
      BaseOptions(
        baseUrl: BaseUrl.baseUrl,
        connectTimeout: const Duration(seconds: 40),
        receiveTimeout: const Duration(seconds: 40),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
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

          // If this is the refresh call itself failing, just reject
          if (requestPath.contains(_refreshEndpoint)) {
            return handler.next(error);
          }

          if (_logoutTriggerCodes.contains(status)) {
            // Check if already retried — avoid infinite loops
            if (error.requestOptions.extra['_retry'] == true) {
              await _logout();
              return handler.next(error);
            }

            // Mark as retry
            error.requestOptions.extra['_retry'] = true;

            // Single-flight refresh: reuse existing promise if already refreshing
            _refreshPromise ??= _doRefresh().whenComplete(() {
              _refreshPromise = null;
            });

            final newAccessToken = await _refreshPromise;

            if (newAccessToken != null) {
              // Retry original request with new token
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
              // Refresh returned no token — logout
              await _logout();
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  /// Perform token refresh using a clean Dio instance (no interceptors).
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
    final navigator = AppNavigator.navigatorKey.currentState;
    navigator?.pushNamedAndRemoveUntil('/login', (route) => false);
  }
}
