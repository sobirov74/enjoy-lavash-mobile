import 'package:enjoy_lavash_mobile/core/services/app_share_service.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations_en.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses the App Store URL on iOS', () {
    expect(
      AppShareService.text(LEn(), platform: TargetPlatform.iOS),
      'Try EnjoyLavash: $iosAppShareUrl',
    );
  });

  test('keeps the Play Store URL on Android', () {
    expect(
      AppShareService.text(LEn(), platform: TargetPlatform.android),
      'Try EnjoyLavash: $androidAppShareUrl',
    );
  });
}
