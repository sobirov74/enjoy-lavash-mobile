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

  Future<GeocoderResult?> reverseGeocode({
    required double latitude,
    required double longitude,
    String? uri,
  }) async {
    try {
      final geocode = '$longitude,$latitude';
      final url =
          'https://geocode-maps.yandex.ru/1.x/?apikey=$_geocoderApiKey'
          '&geocode=$geocode&format=json&lang=uz';

      final response = await _dio.get(url, queryParameters: {
        'uri': ?uri,
      });

      final data = response.data;
      final featureMembers = data?['response']?['GeoObjectCollection']
          ?['featureMember'] as List?;

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
        final memberName =
            member['GeoObject']?['name'] as String? ?? '';
        if (memberName.contains('tuman')) {
          district = memberName;
          break;
        }
      }

      return GeocoderResult(
        name: name,
        district: district,
        coords: coords,
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<SuggestionResult>> suggest(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final url =
          'https://suggest-maps.yandex.ru/v1/suggest?apikey=$_suggestApiKey'
          '&text=$query&print_address=1&attrs=uri&lang=ru';

      final response = await _dio.get(url);
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
}
