import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/app_version_policy_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses documented app version policy response', () {
    final policy = AppVersionPolicyModel.fromJson({
      'id': 'app-version-ios',
      'createdAt': '2026-01-01T00:00:00.000Z',
      'updatedAt': '2026-01-01T00:00:00.000Z',
      'deletedAt': null,
      'platform': 'ios',
      'latestVersion': '1.2.0',
      'minSupportedVersion': '1.1.0',
      'description': 'A new version is available.',
      'appUrl': 'https://apps.apple.com/app/enjoy-lavash',
      'updateAvailable': true,
      'forceUpdate': false,
    });

    expect(policy.id, 'app-version-ios');
    expect(policy.createdAt, DateTime.parse('2026-01-01T00:00:00.000Z'));
    expect(policy.platform, 'ios');
    expect(policy.latestVersion, '1.2.0');
    expect(policy.minSupportedVersion, '1.1.0');
    expect(policy.description, 'A new version is available.');
    expect(policy.appUrl, 'https://apps.apple.com/app/enjoy-lavash');
    expect(policy.updateAvailable, isTrue);
    expect(policy.forceUpdate, isFalse);
    expect(policy.shouldPrompt, isTrue);
  });

  test('parses snake case flags from backend variants', () {
    final policy = AppVersionPolicyModel.fromJson({
      'platform': 'android',
      'latest_version': '2.0.0',
      'min_supported_version': '1.8.0',
      'app_url': 'https://play.google.com/store/apps/details?id=app',
      'update_available': false,
      'force_update': true,
    });

    expect(policy.platform, 'android');
    expect(policy.latestVersion, '2.0.0');
    expect(policy.minSupportedVersion, '1.8.0');
    expect(policy.updateAvailable, isFalse);
    expect(policy.forceUpdate, isTrue);
    expect(policy.shouldPrompt, isTrue);
  });

  test('prompts when current version differs from latest version', () {
    final policy = AppVersionPolicyModel.fromJson({
      'platform': 'android',
      'latestVersion': '1.0.7',
      'minSupportedVersion': '1.0.0',
      'appUrl': 'https://play.google.com/store/apps/details?id=app',
      'updateAvailable': false,
      'forceUpdate': false,
    }).resolveForCurrentVersion('1.0.6');

    expect(policy.updateAvailable, isTrue);
    expect(policy.forceUpdate, isFalse);
    expect(policy.shouldPrompt, isTrue);
  });

  test(
    'forces update when current version is below minimum supported version',
    () {
      final policy = AppVersionPolicyModel.fromJson({
        'platform': 'ios',
        'latestVersion': '1.2.0',
        'minSupportedVersion': '1.1.0',
        'appUrl': 'https://apps.apple.com/app/enjoy-lavash',
        'updateAvailable': false,
        'forceUpdate': false,
      }).resolveForCurrentVersion('1.0.9');

      expect(policy.updateAvailable, isTrue);
      expect(policy.forceUpdate, isTrue);
      expect(policy.shouldPrompt, isTrue);
    },
  );

  test('does not prompt when current version matches latest version', () {
    final policy = AppVersionPolicyModel.fromJson({
      'platform': 'android',
      'latestVersion': '1.0.6',
      'minSupportedVersion': '1.0.0',
      'appUrl': 'https://play.google.com/store/apps/details?id=app',
      'updateAvailable': false,
      'forceUpdate': false,
    }).resolveForCurrentVersion('1.0.6');

    expect(policy.updateAvailable, isFalse);
    expect(policy.forceUpdate, isFalse);
    expect(policy.shouldPrompt, isFalse);
  });
}
