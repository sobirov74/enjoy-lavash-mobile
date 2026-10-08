import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Hosts a server-provided payment link may point to. Subdomains match, so
/// `checkout.paycom.uz` and `my.click.uz` are accepted.
const Set<String> paymentLinkHosts = <String>{
  'paycom.uz',
  'payme.uz',
  'click.uz',
  'enjoylavash.uz',
};

/// Hosts an app-store link (update prompt, share) may point to.
const Set<String> appStoreLinkHosts = <String>{
  'play.google.com',
  'apps.apple.com',
};

/// Hands a link to the operating system through the platform channel.
///
/// Only `https` links with a host are ever opened. Callers that receive the
/// link from the backend (payment pages, store links) also pass the hosts they
/// expect, so a compromised payload cannot open an arbitrary scheme or site.
class ExternalUrlLauncher {
  ExternalUrlLauncher._();

  static const MethodChannel _channel = MethodChannel(
    'enjoy_lavash_mobile/external_url',
  );
  static const String _allowedScheme = 'https';

  /// Returns the parsed link when it is safe to open, otherwise `null`.
  ///
  /// With [allowedHosts] the link host must equal one of them or be a
  /// subdomain of one; without it any host is accepted.
  static Uri? allowedUri(String url, {Set<String>? allowedHosts}) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return null;
    if (uri.scheme.toLowerCase() != _allowedScheme) return null;

    final host = uri.host.toLowerCase();
    if (host.isEmpty) return null;
    if (allowedHosts != null && !_hostMatches(host, allowedHosts)) return null;
    return uri;
  }

  static Future<bool> open(String url, {Set<String>? allowedHosts}) async {
    final uri = allowedUri(url, allowedHosts: allowedHosts);
    if (kIsWeb || uri == null) return false;

    try {
      return await _channel.invokeMethod<bool>('open', url.trim()) ?? false;
    } on PlatformException catch (error) {
      debugPrint('External URL open failed: ${error.message}');
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  static bool _hostMatches(String host, Set<String> allowedHosts) {
    for (final allowed in allowedHosts) {
      final normalized = allowed.toLowerCase();
      if (host == normalized || host.endsWith('.$normalized')) return true;
    }
    return false;
  }
}
