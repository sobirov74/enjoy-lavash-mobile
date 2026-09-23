import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:enjoy_lavash_mobile/core/api/api_client.dart';
import 'package:enjoy_lavash_mobile/core/error/result.dart';
import 'package:enjoy_lavash_mobile/core/storage/token_storage.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/promotion_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/repositories/mobile_backend_repository_impl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('banner images resolve against the backend origin', () {
    for (final entry in <String?, String?>{
      null: null,
      '': null,
      '  ': null,
      '/uploads/banner.jpg': 'https://backend.test:8443/uploads/banner.jpg',
      'uploads/banner.jpg': 'https://backend.test:8443/uploads/banner.jpg',
      ' https://cdn.test/banner.jpg ': 'https://cdn.test/banner.jpg',
      'file:///banner.jpg': null,
    }.entries) {
      final promotion = PromotionModel.fromJson({
        'id': 'offer',
        'imageUrl': entry.key,
      }, backendBaseUrl: 'https://backend.test:8443/api/v1/');
      expect(promotion.imageUrl, entry.value, reason: '${entry.key}');
    }
    expect(PromotionModel.fromJson({'id': 'no-image'}).imageUrl, isNull);
  });

  test(
    'public promotions include organisation without authentication',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      await TokenStorage.saveAccessToken('stored-client-token');
      late RequestOptions request;
      final client = ApiClient(
        baseUrl: 'https://backend.test',
        httpClientAdapter: _Adapter((options) {
          request = options;
          return ResponseBody.fromString(
            jsonEncode([
              {
                'id': 'offer-42',
                'code': 'SAVE20',
                'titleI18n': {'en': 'Special offer', 'uz': 'Maxsus taklif'},
                'imageUrl': '/uploads/offer.jpg',
              },
            ]),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }),
      );
      final repository = MobileBackendRepositoryImpl(
        client,
        organisationId: ' org-enjoy ',
      );
      final result = await repository.getActivePromotions(language: 'uz');
      expect(request.method, 'GET');
      expect(request.path, '/promotions/active');
      expect(request.uri.queryParameters, {'organisationId': 'org-enjoy'});
      expect(request.headers['Authorization'], isNull);
      final promotion = result.dataOrNull!.single;
      expect(promotion.id, 'offer-42');
      expect(promotion.code, 'SAVE20');
      expect(promotion.title, 'Maxsus taklif');
      expect(promotion.imageUrl, 'https://backend.test/uploads/offer.jpg');

      await MobileBackendRepositoryImpl(client).getActivePromotions();
      expect(request.uri.queryParameters, isEmpty);
    },
  );
}

class _Adapter implements HttpClientAdapter {
  const _Adapter(this.respond);
  final ResponseBody Function(RequestOptions) respond;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => respond(options);

  @override
  void close({bool force = false}) {}
}
