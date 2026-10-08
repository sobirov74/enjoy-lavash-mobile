import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;

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

/// Reverse geocoding and address suggestions through Yandex.
///
/// API keys are injected at build time:
/// `--dart-define=YANDEX_GEOCODER_KEY=… --dart-define=YANDEX_SUGGEST_KEY=…`.
/// Without a key the matching lookup is disabled and returns an empty result,
/// so the app keeps working with manual address entry.
class YandexGeocoderService {
  YandexGeocoderService({
    Dio? dio,
    String? geocoderApiKey,
    String? suggestApiKey,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: _requestTimeout,
               receiveTimeout: _requestTimeout,
             ),
           ),
       _geocoderApiKey = (geocoderApiKey ?? _configuredGeocoderApiKey).trim(),
       _suggestApiKey = (suggestApiKey ?? _configuredSuggestApiKey).trim() {
    _warnIfUnconfigured();
  }

  final Dio _dio;
  final String _geocoderApiKey;
  final String _suggestApiKey;

  static const _configuredGeocoderApiKey = String.fromEnvironment(
    'YANDEX_GEOCODER_KEY',
  );
  static const _configuredSuggestApiKey = String.fromEnvironment(
    'YANDEX_SUGGEST_KEY',
  );
  static const _requestTimeout = Duration(seconds: 10);
  static const _reverseMinGap = Duration(milliseconds: 650);
  static bool _warnedUnconfigured = false;

  bool get isGeocoderConfigured => _geocoderApiKey.isNotEmpty;
  bool get isSuggestConfigured => _suggestApiKey.isNotEmpty;

  void _warnIfUnconfigured() {
    if (_warnedUnconfigured || (isGeocoderConfigured && isSuggestConfigured)) {
      return;
    }
    _warnedUnconfigured = true;
    debugPrint(
      'Yandex API keys are not configured; address lookup is disabled. '
      'Pass --dart-define=YANDEX_GEOCODER_KEY and YANDEX_SUGGEST_KEY.',
    );
  }

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
    if (!isGeocoderConfigured) return null;

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
    if (!isSuggestConfigured) return const <SuggestionResult>[];

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
      return await request;
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

    // Spaces request *starts* by [_reverseMinGap]; the next caller may start
    // while this request is still in flight.
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
      } finally {
        gate.complete();
      }
      return request();
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
