import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ExternalUrlLauncher {
  ExternalUrlLauncher._();

  static const MethodChannel _channel = MethodChannel(
    'enjoy_lavash_mobile/external_url',
  );

  static Future<bool> open(String url) async {
    final trimmedUrl = url.trim();
    final uri = Uri.tryParse(trimmedUrl);
    if (kIsWeb || uri == null || !uri.hasScheme) return false;

    try {
      return await _channel.invokeMethod<bool>('open', trimmedUrl) ?? false;
    } on PlatformException catch (error) {
      debugPrint('External URL open failed: ${error.message}');
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
