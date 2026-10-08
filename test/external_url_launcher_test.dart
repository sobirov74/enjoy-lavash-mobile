import 'package:enjoy_lavash_mobile/core/services/external_url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('enjoy_lavash_mobile/external_url');

  group('allowedUri', () {
    test('accepts https links with a host', () {
      expect(
        ExternalUrlLauncher.allowedUri('https://example.test/sale'),
        isNotNull,
      );
      expect(
        ExternalUrlLauncher.allowedUri('  HTTPS://Example.test/sale  '),
        isNotNull,
      );
    });

    test('rejects every non-https scheme', () {
      for (final url in const [
        'http://example.test/sale',
        'javascript:alert(1)',
        'intent://scan/#Intent;scheme=zxing;end',
        'tel:+998901234567',
        'file:///etc/passwd',
        'enjoylavash://menu',
        'https:missing-host',
        '',
        'not a url',
      ]) {
        expect(ExternalUrlLauncher.allowedUri(url), isNull, reason: url);
      }
    });

    test('enforces the host allowlist including subdomains', () {
      expect(
        ExternalUrlLauncher.allowedUri(
          'https://checkout.paycom.uz/abc',
          allowedHosts: paymentLinkHosts,
        ),
        isNotNull,
      );
      expect(
        ExternalUrlLauncher.allowedUri(
          'https://my.click.uz/services/pay?x=1',
          allowedHosts: paymentLinkHosts,
        ),
        isNotNull,
      );
      expect(
        ExternalUrlLauncher.allowedUri(
          'https://paycom.uz',
          allowedHosts: paymentLinkHosts,
        ),
        isNotNull,
      );
      for (final url in const [
        'https://evil.test/paycom.uz',
        'https://paycom.uz.evil.test/',
        'https://notpaycom.uz/',
        'http://checkout.paycom.uz/abc',
      ]) {
        expect(
          ExternalUrlLauncher.allowedUri(url, allowedHosts: paymentLinkHosts),
          isNull,
          reason: url,
        );
      }
    });

    test('store links are limited to the store hosts', () {
      expect(
        ExternalUrlLauncher.allowedUri(
          'https://apps.apple.com/app/id1',
          allowedHosts: appStoreLinkHosts,
        ),
        isNotNull,
      );
      expect(
        ExternalUrlLauncher.allowedUri(
          'https://example.test/update',
          allowedHosts: appStoreLinkHosts,
        ),
        isNull,
      );
    });
  });

  group('open', () {
    final calls = <MethodCall>[];

    setUp(() {
      calls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return true;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('never reaches the platform for a rejected link', () async {
      expect(await ExternalUrlLauncher.open('http://example.test'), isFalse);
      expect(await ExternalUrlLauncher.open('tel:+998901234567'), isFalse);
      expect(
        await ExternalUrlLauncher.open(
          'https://evil.test/pay',
          allowedHosts: paymentLinkHosts,
        ),
        isFalse,
      );
      expect(calls, isEmpty);
    });

    test('forwards an allowed link and returns the platform result', () async {
      expect(
        await ExternalUrlLauncher.open(
          ' https://checkout.paycom.uz/abc ',
          allowedHosts: paymentLinkHosts,
        ),
        isTrue,
      );
      expect(calls, hasLength(1));
      expect(calls.single.method, 'open');
      expect(calls.single.arguments, 'https://checkout.paycom.uz/abc');
    });
  });
}
