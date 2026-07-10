import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:enjoy_lavash_mobile/core/api/api_client.dart';
import 'package:enjoy_lavash_mobile/core/api/api_endpoints.dart';
import 'package:enjoy_lavash_mobile/core/storage/token_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test(
    'refreshes mobile client session once and retries concurrent requests',
    () async {
      const refreshExpiresAt = '2026-10-06T13:00:00.000Z';
      await TokenStorage.saveAccessToken('old-access');
      await TokenStorage.saveRefreshToken('old-refresh');

      final adapter = _RecordingAdapter(
        onFetch: (options) async {
          if (options.uri.path == ApiEndpoints.clientRefresh) {
            await Future<void>.delayed(const Duration(milliseconds: 20));
            return _jsonResponse({
              'access_token': 'new-access',
              'refresh_token': 'new-refresh',
              'refresh_token_expires_at': refreshExpiresAt,
              'token_type': 'Bearer',
              'client_created': false,
              'client': {'id': 'client-id', 'phoneNumber': '+998901234567'},
            });
          }

          if (options.uri.path == ApiEndpoints.clientOrders) {
            if (options.headers['Authorization'] == 'Bearer new-access') {
              return _jsonResponse({'orders': []});
            }
            return _jsonResponse({'message': 'expired'}, statusCode: 401);
          }

          return _jsonResponse({'message': 'not found'}, statusCode: 404);
        },
      );
      final apiClient = ApiClient(
        baseUrl: 'https://example.test',
        httpClientAdapter: adapter,
      );

      final responses = await Future.wait([
        apiClient.dio.get(ApiEndpoints.clientOrders),
        apiClient.dio.get(ApiEndpoints.clientOrders),
        apiClient.dio.get(ApiEndpoints.clientOrders),
      ]);

      expect(
        responses.map((response) => response.statusCode),
        everyElement(200),
      );
      expect(
        adapter.requests
            .where((request) => request.path == ApiEndpoints.clientRefresh),
        hasLength(1),
      );
      expect(
        adapter.requests.where(
          (request) =>
              request.path == ApiEndpoints.clientOrders &&
              request.authorization == 'Bearer new-access',
        ),
        hasLength(3),
      );
      expect(
        adapter.requests
            .singleWhere(
              (request) => request.path == ApiEndpoints.clientRefresh,
            )
            .data,
        {'refresh_token': 'old-refresh'},
      );
      expect(await TokenStorage.getAccessToken(), 'new-access');
      expect(await TokenStorage.getRefreshToken(), 'new-refresh');
      expect(
        await TokenStorage.getRefreshTokenExpiresAt(),
        DateTime.parse(refreshExpiresAt),
      );
    },
  );

  test('keeps tokens when refresh fails for a non-auth error', () async {
    await TokenStorage.saveAccessToken('old-access');
    await TokenStorage.saveRefreshToken('old-refresh');
    var loggedOut = false;

    final adapter = _RecordingAdapter(
      onFetch: (options) async {
        if (options.uri.path == ApiEndpoints.clientRefresh) {
          return _jsonResponse({'message': 'server error'}, statusCode: 500);
        }

        if (options.uri.path == ApiEndpoints.clientOrders) {
          return _jsonResponse({'message': 'expired'}, statusCode: 401);
        }

        return _jsonResponse({'message': 'not found'}, statusCode: 404);
      },
    );
    final apiClient = ApiClient(
      baseUrl: 'https://example.test',
      httpClientAdapter: adapter,
      onLogout: () async {
        loggedOut = true;
      },
    );

    await expectLater(
      apiClient.dio.get(ApiEndpoints.clientOrders),
      throwsA(isA<DioException>()),
    );

    expect(loggedOut, isFalse);
    expect(await TokenStorage.getAccessToken(), 'old-access');
    expect(await TokenStorage.getRefreshToken(), 'old-refresh');
  });

  test(
    'logs out when a protected request returns 401 without refresh token',
    () async {
      await TokenStorage.saveAccessToken('old-access');
      var loggedOut = false;

      final adapter = _RecordingAdapter(
        onFetch: (options) async {
          if (options.uri.path == ApiEndpoints.clientOrders) {
            return _jsonResponse({'message': 'expired'}, statusCode: 401);
          }

          return _jsonResponse({'message': 'not found'}, statusCode: 404);
        },
      );
      final apiClient = ApiClient(
        baseUrl: 'https://example.test',
        httpClientAdapter: adapter,
        onLogout: () async {
          loggedOut = true;
        },
      );

      await expectLater(
        apiClient.dio.get(ApiEndpoints.clientOrders),
        throwsA(isA<DioException>()),
      );

      expect(loggedOut, isTrue);
      expect(await TokenStorage.getAccessToken(), isNull);
      expect(await TokenStorage.getRefreshToken(), isNull);
    },
  );
}

class _RequestRecord {
  const _RequestRecord({
    required this.path,
    required this.authorization,
    required this.data,
  });

  final String path;
  final String? authorization;
  final Object? data;
}

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter({required this.onFetch});

  final Future<ResponseBody> Function(RequestOptions options) onFetch;
  final List<_RequestRecord> requests = <_RequestRecord>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(
      _RequestRecord(
        path: options.uri.path,
        authorization: options.headers['Authorization']?.toString(),
        data: options.data,
      ),
    );
    return onFetch(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(
  Map<String, Object?> data, {
  int statusCode = 200,
}) {
  return ResponseBody.fromString(
    jsonEncode(data),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}
