import 'package:flutter/foundation.dart';

class BaseUrl {
  static const _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const _localHostBaseUrl = 'https://api.enjoylavash.uz';
  // static const _localHostBaseUrl = 'http://10.0.1.211:5173';

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl;
    }

    if (kIsWeb) {
      return _localHostBaseUrl;
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => _localHostBaseUrl,
      TargetPlatform.iOS => _localHostBaseUrl,
      _ => _localHostBaseUrl,
    };
  }

  // Production can be selected with:
  // flutter run --dart-define=API_BASE_URL=https://api.enjoylavash.uz
}
