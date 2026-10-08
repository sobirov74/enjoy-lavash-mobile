import 'dart:async';

import 'package:enjoy_lavash_mobile/core/api/api_client.dart';
import 'package:enjoy_lavash_mobile/core/services/mobile_push_notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _apnsChannel = MethodChannel('enjoy_lavash_mobile/apns');

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  Map<String, Object?>? launchNotification;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    launchNotification = null;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(_apnsChannel, (
      call,
    ) async {
      if (call.method == 'takeLaunchNotification') return launchNotification;
      return null;
    });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(_apnsChannel, null);
  });

  Future<void> sendTapFromNative(Map<String, Object?> payload) async {
    final completer = Completer<void>();
    await binding.defaultBinaryMessenger.handlePlatformMessage(
      _apnsChannel.name,
      _apnsChannel.codec.encodeMethodCall(
        MethodCall('notificationOpened', payload),
      ),
      (_) => completer.complete(),
    );
    await completer.future;
  }

  test('a tap that launched the app is delivered once Dart listens', () async {
    launchNotification = <String, Object?>{
      'type': 'promotion_assignment',
      'promotionCode': 'LAVASH10',
    };
    final service = MobilePushNotificationService(ApiClient());
    final messages = <PushNotificationMessage>[];
    final subscription = service.messages.listen(messages.add);
    addTearDown(subscription.cancel);

    await service.configureMessageHandlers();
    await Future<void>.delayed(Duration.zero);

    expect(messages, hasLength(1));
    expect(messages.single.openedByUser, isTrue);
    expect(messages.single.promotionCode, 'LAVASH10');
    expect(messages.single.opensPromotions, isTrue);
  });

  test('a tap while running is forwarded as an opened message', () async {
    final service = MobilePushNotificationService(ApiClient());
    final messages = <PushNotificationMessage>[];
    final subscription = service.messages.listen(messages.add);
    addTearDown(subscription.cancel);
    await service.configureMessageHandlers();

    await sendTapFromNative(<String, Object?>{
      'data': <String, Object?>{
        'type': 'loyalty_expiry_reminder',
        'deepLink': 'enjoylavash://loyalty',
      },
    });
    await Future<void>.delayed(Duration.zero);

    expect(messages, hasLength(1));
    expect(messages.single.openedByUser, isTrue);
    expect(messages.single.opensLoyalty, isTrue);
  });
}
