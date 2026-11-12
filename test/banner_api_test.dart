import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:enjoy_lavash_mobile/core/api/api_client.dart';
import 'package:enjoy_lavash_mobile/core/api/api_endpoints.dart';
import 'package:enjoy_lavash_mobile/core/error/result.dart';
import 'package:enjoy_lavash_mobile/core/navigation/app_deep_link.dart';
import 'package:enjoy_lavash_mobile/core/services/mobile_push_notification_service.dart';
import 'package:enjoy_lavash_mobile/core/storage/token_storage.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/banner_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/repositories/mobile_backend_repository_impl.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/presentation/mobile_backend_controller.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test(
    'banner uses its own image/title and retains a cross-organisation promotion',
    () {
      final banner = BannerModel.fromJson(
        _banner('sale', promotion: true),
        language: 'uz',
        backendBaseUrl: 'https://backend.test:8443/api/v1/',
      );
      expect(banner.title, '20% chegirma');
      expect(banner.imageUrl, 'https://backend.test:8443/uploads/sale.jpg');
      expect(banner.promotionId, 'promotion-20');
      expect(banner.promotion!.id, 'promotion-20');
      expect(banner.promotion!.code, 'SAVE20');
      expect(banner.promotion!.raw['organisationId'], 'another-organisation');
      expect(banner.promotion!.isPercentageDiscount, isTrue);
      expect(banner.promotion!.imageUrl, isNull);
      final absolute = BannerModel.fromJson({
        ..._banner('cdn'),
        'imageUrl': 'https://cdn.test/banner.jpg',
      }, language: 'en');
      expect(absolute.imageUrl, 'https://cdn.test/banner.jpg');
      expect(absolute.title, '20% off');
    },
  );

  test(
    'the banner list is a global public GET even with a stored token',
    () async {
      await TokenStorage.saveAccessToken('client-access');
      final requests = <RequestOptions>[];
      final repository = MobileBackendRepositoryImpl(
        ApiClient(
          baseUrl: 'https://backend.test',
          httpClientAdapter: _Adapter((request) {
            requests.add(request);
            return _json([
              _banner('first'),
              _banner('second', promotion: true),
            ]);
          }),
        ),
        organisationId: 'should-not-be-sent',
      );
      final list = await repository.getActiveBanners(language: 'en');
      expect(list.dataOrNull!.map((banner) => banner.id), ['first', 'second']);
      expect(list.dataOrNull!.last.promotion!.code, 'SAVE20');
      expect(requests.single.path, ApiEndpoints.activeBanners);
      expect(requests.single.method, 'GET');
      expect(requests.single.queryParameters, isEmpty);
      expect(requests.single.headers['Authorization'], isNull);
    },
  );

  test(
    'launch and refresh update global banners independently of promotions',
    () async {
      var bannerRequests = 0;
      final client = ApiClient(
        baseUrl: 'https://backend.test',
        httpClientAdapter: _Adapter((request) {
          if (request.path == ApiEndpoints.activeBanners) {
            bannerRequests++;
            return _json(bannerRequests == 1 ? [_banner('sale')] : []);
          }
          if (request.path == ApiEndpoints.catalog) {
            return _json({'categories': [], 'products': []});
          }
          return _json([]);
        }),
      );
      final controller = MobileBackendController(
        MobileBackendRepositoryImpl(client),
        MobilePushNotificationService(client),
      );
      addTearDown(controller.dispose);
      await controller.bootstrap(language: 'en');
      expect(controller.status, MobileBackendStatus.loaded);
      expect(controller.banners.single.title, '20% off');
      await controller.bootstrap(language: 'en');
      expect(bannerRequests, 2);
      expect(controller.banners, isEmpty);
    },
  );

  test('banner outage does not block the rest of bootstrap', () async {
    final repository = MobileBackendRepositoryImpl(
      ApiClient(
        baseUrl: 'https://backend.test',
        httpClientAdapter: _Adapter(
          (request) => request.path == ApiEndpoints.activeBanners
              ? _json({'message': 'Unavailable'}, status: 503)
              : _json([]),
        ),
      ),
    );
    final result = await repository.bootstrap(language: 'en');
    expect(result.dataOrNull, isNotNull);
    expect(result.dataOrNull!.banners, isEmpty);
  });

  test('recognized app destinations stay in the mobile router', () {
    for (final route in AppDeepLink.values) {
      expect(
        AppDeepLink.fromUri(Uri.parse('enjoylavash://${route.name}')),
        route,
      );
      expect(supportedBannerLink('enjoylavash://${route.name}'), isNotNull);
    }
    expect(
      AppDeepLink.fromUri(Uri.parse('enjoylavash:///menu')),
      AppDeepLink.menu,
    );
    expect(supportedBannerLink('https://example.test/sale'), isNotNull);
    for (final unsupported in [
      null,
      '',
      'enjoylavash://unknown',
      'javascript:alert(1)',
      // Plain http never leaves the app; only https is handed to the OS.
      'http://example.test/sale',
      'intent://scan/#Intent;scheme=zxing;end',
      '/menu',
      'https:missing-host',
    ]) {
      expect(supportedBannerLink(unsupported), isNull);
    }
  });
}

Map<String, Object?> _banner(String id, {bool promotion = false}) => {
  'id': id,
  'titleI18n': {'uz': '20% chegirma', 'en': '20% off'},
  'imageUrl': '/uploads/$id.jpg',
  'sortOrder': 0,
  'promotionId': promotion ? 'promotion-20' : null,
  'linkUrl': promotion ? null : 'enjoylavash://menu',
  'promotion': promotion
      ? {
          'id': 'promotion-20',
          'code': 'SAVE20',
          'titleI18n': {'en': 'Discount', 'uz': 'Chegirma'},
          'organisationId': 'another-organisation',
          'reward': {'type': 'PERCENT', 'value': 20},
        }
      : null,
};

ResponseBody _json(Object? data, {int status = 200}) => ResponseBody.fromString(
  jsonEncode(data),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

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
