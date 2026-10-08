import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:enjoy_lavash_mobile/core/services/yandex_geocoder_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('skips the network entirely when no API key is configured', () async {
    final adapter = _RecordingAdapter();
    final service = YandexGeocoderService(
      dio: Dio()..httpClientAdapter = adapter,
      geocoderApiKey: '',
      suggestApiKey: '',
    );

    expect(service.isGeocoderConfigured, isFalse);
    expect(service.isSuggestConfigured, isFalse);
    expect(
      await service.reverseGeocode(latitude: 41.3111, longitude: 69.2797),
      isNull,
    );
    expect(await service.suggest('Amir Temur'), isEmpty);
    expect(adapter.requests, isEmpty);
  });

  test('sends the injected keys as the apikey query parameter', () async {
    final adapter = _RecordingAdapter();
    final service = YandexGeocoderService(
      dio: Dio()..httpClientAdapter = adapter,
      geocoderApiKey: 'geocoder-key',
      suggestApiKey: 'suggest-key',
    );

    await service.suggest('Amir Temur');
    // Unique coordinates keep the service's static cache out of the way.
    await service.reverseGeocode(latitude: 41.123456, longitude: 69.654321);

    expect(adapter.requests, hasLength(2));
    final suggest = adapter.requests.first;
    expect(suggest.uri.host, 'suggest-maps.yandex.ru');
    expect(suggest.queryParameters['apikey'], 'suggest-key');
    final reverse = adapter.requests.last;
    expect(reverse.uri.host, 'geocode-maps.yandex.ru');
    expect(reverse.queryParameters['apikey'], 'geocoder-key');
  });

  test('default client has request timeouts', () {
    final service = YandexGeocoderService(
      geocoderApiKey: 'k',
      suggestApiKey: 'k',
    );
    expect(service.isGeocoderConfigured, isTrue);
  });
}

class _RecordingAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      '{"results":[],"response":{"GeoObjectCollection":{"featureMember":[]}}}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
