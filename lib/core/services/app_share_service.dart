import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:share_plus/share_plus.dart';

const String androidAppShareUrl =
    'https://play.google.com/store/apps/details?id=com.aurumdev.enjoy_lavash_mobile';
const String iosAppShareUrl =
    'https://apps.apple.com/us/app/enjoy-lavash/id6772233657';

class AppShareService {
  const AppShareService._();

  static String text(L t, {TargetPlatform? platform}) {
    final appUrl = switch (platform ?? defaultTargetPlatform) {
      TargetPlatform.iOS => iosAppShareUrl,
      _ => androidAppShareUrl,
    };

    final localizedText = t.shareAppText;
    if (localizedText.contains(androidAppShareUrl)) {
      return localizedText.replaceAll(androidAppShareUrl, appUrl);
    }
    if (localizedText.contains(iosAppShareUrl)) {
      return localizedText.replaceAll(iosAppShareUrl, appUrl);
    }
    return '${localizedText.trim()} $appUrl';
  }

  static Future<void> share(L t, {TargetPlatform? platform}) async {
    await SharePlus.instance.share(
      ShareParams(text: text(t, platform: platform)),
    );
  }
}
