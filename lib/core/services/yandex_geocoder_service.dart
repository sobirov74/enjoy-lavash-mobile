import 'dart:async';

import 'package:dio/dio.dart';

class GeocoderResult {
  final String name;
  final String district;
  final List<double> coords;

  const GeocoderResult({
    required this.name,
    required this.district,
    required this.coords,
  });
}

class SuggestionResult {
  final String title;
  final String subtitle;
  final String? uri;

  const SuggestionResult({
    required this.title,
    required this.subtitle,
    this.uri,
  });
}

class YandexGeocoderService {
  YandexGeocoderService() : _dio = Dio();

  final Dio _dio;

  static const _geocoderApiKey = 'b95528c3-8d5d-481c-a549-e5b760c57e74';
  static const _suggestApiKey = '0eb8dc58-f9d3-4df8-8cee-1af2c1c083f7';
  static const _reverseMinGap = Duration(milliseconds: 650);
  static const _maxReverseCacheEntries = 80;
  static const _maxSuggestCacheEntries = 80;
  static const _minSuggestQueryLength = 3;

  static final Map<String, GeocoderResult> _reverseCache =
      <String, GeocoderResult>{};
  static final Map<String, Future<GeocoderResult?>> _reverseInFlight =
      <String, Future<GeocoderResult?>>{};
  static final Map<String, List<SuggestionResult>> _suggestCache =
      <String, List<SuggestionResult>>{};
  static final Map<String, Future<List<SuggestionResult>>> _suggestInFlight =
      <String, Future<List<SuggestionResult>>>{};
  static Future<void> _reverseQueue = Future<void>.value();
  static DateTime? _lastReverseRequestAt;

  Future<GeocoderResult?> reverseGeocode({
    required double latitude,
    required double longitude,
    String? uri,
  }) async {
    final cacheKey = _reverseCacheKey(
      latitude: latitude,
      longitude: longitude,
      uri: uri,
    );
    final cached = _reverseCache[cacheKey];
    if (cached != null) return cached;

    final inFlight = _reverseInFlight[cacheKey];
    if (inFlight != null) return inFlight;

    late final Future<GeocoderResult?> request;
    request =
        _withReverseRateLimit(
              () => _performReverseGeocode(
                latitude: latitude,
                longitude: longitude,
                uri: uri,
              ),
            )
            .then((result) {
              if (result != null) {
                _rememberReverseResult(cacheKey, result);
              }
              return result;
            })
            .whenComplete(() {
              if (identical(_reverseInFlight[cacheKey], request)) {
                _reverseInFlight.remove(cacheKey);
              }
            });
    _reverseInFlight[cacheKey] = request;
    return request;
  }

  Future<GeocoderResult?> _performReverseGeocode({
    required double latitude,
    required double longitude,
    String? uri,
  }) async {
    try {
      final geocode = '$longitude,$latitude';
      const url = 'https://geocode-maps.yandex.ru/1.x/';

      final response = await _dio.get(
        url,
        queryParameters: <String, Object?>{
          'apikey': _geocoderApiKey,
          'geocode': geocode,
          'format': 'json',
          'lang': 'uz',
          if (uri?.trim().isNotEmpty == true) 'uri': uri!.trim(),
        },
      );

      final data = response.data;
      final featureMembers =
          data?['response']?['GeoObjectCollection']?['featureMember'] as List?;

      if (featureMembers == null || featureMembers.isEmpty) return null;

      final geoObject = featureMembers[0]['GeoObject'];
      final name = geoObject?['name'] as String? ?? '';

      final pos = geoObject?['Point']?['pos'] as String?;
      final coords = uri != null && pos != null
          ? pos.split(' ').map(double.parse).toList()
          : [longitude, latitude];

      // Find district
      String district = '';
      for (final member in featureMembers) {
        final memberName = member['GeoObject']?['name'] as String? ?? '';
        if (memberName.contains('tuman')) {
          district = memberName;
          break;
        }
      }

      return GeocoderResult(name: name, district: district, coords: coords);
    } catch (_) {
      return null;
    }
  }

  Future<List<SuggestionResult>> suggest(String query) async {
    final normalizedQuery = _normalizeSuggestQuery(query);
    if (normalizedQuery.length < _minSuggestQueryLength) return [];

    final cacheKey = normalizedQuery.toLowerCase();
    final cached = _suggestCache[cacheKey];
    if (cached != null) return cached;

    final inFlight = _suggestInFlight[cacheKey];
    if (inFlight != null) return inFlight;

    try {
      late final Future<List<SuggestionResult>> request;
      request = _performSuggest(normalizedQuery)
          .then((results) {
            _rememberSuggestResults(cacheKey, results);
            return results;
          })
          .whenComplete(() {
            if (identical(_suggestInFlight[cacheKey], request)) {
              _suggestInFlight.remove(cacheKey);
            }
          });
      _suggestInFlight[cacheKey] = request;
      return request;
    } catch (_) {
      return [];
    }
  }

  Future<List<SuggestionResult>> _performSuggest(String query) async {
    try {
      const url = 'https://suggest-maps.yandex.ru/v1/suggest';

      final response = await _dio.get(
        url,
        queryParameters: <String, Object?>{
          'apikey': _suggestApiKey,
          'text': query,
          'print_address': 1,
          'attrs': 'uri',
          'lang': 'ru',
        },
      );
      final results = response.data?['results'] as List? ?? [];

      return results.map((item) {
        return SuggestionResult(
          title: item['title']?['text'] as String? ?? '',
          subtitle: item['subtitle']?['text'] as String? ?? '',
          uri: item['uri'] as String?,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static String _reverseCacheKey({
    required double latitude,
    required double longitude,
    String? uri,
  }) {
    final cleanUri = uri?.trim();
    if (cleanUri?.isNotEmpty == true) return 'uri:$cleanUri';

    return 'coord:${latitude.toStringAsFixed(5)},'
        '${longitude.toStringAsFixed(5)}';
  }

  static String _normalizeSuggestQuery(String query) {
    return query.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static Future<T> _withReverseRateLimit<T>(Future<T> Function() request) {
    final previous = _reverseQueue;
    final gate = Completer<void>();
    _reverseQueue = gate.future;

    return previous.catchError((_) {}).then((_) async {
      try {
        final lastRequestAt = _lastReverseRequestAt;
        if (lastRequestAt != null) {
          final elapsed = DateTime.now().difference(lastRequestAt);
          final waitMs = _reverseMinGap.inMilliseconds - elapsed.inMilliseconds;
          if (waitMs > 0) {
            await Future<void>.delayed(Duration(milliseconds: waitMs));
          }
        }

        _lastReverseRequestAt = DateTime.now();
        return request();
      } finally {
        gate.complete();
      }
    });
  }

  static void _rememberReverseResult(String key, GeocoderResult result) {
    if (_reverseCache.length >= _maxReverseCacheEntries) {
      _reverseCache.remove(_reverseCache.keys.first);
    }
    _reverseCache[key] = result;
  }

  static void _rememberSuggestResults(
    String key,
    List<SuggestionResult> results,
  ) {
    if (_suggestCache.length >= _maxSuggestCacheEntries) {
      _suggestCache.remove(_suggestCache.keys.first);
    }
    _suggestCache[key] = List<SuggestionResult>.unmodifiable(results);
  }
}
