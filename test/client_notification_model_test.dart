import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/client_notification_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses client notification inbox response', () {
    final inbox = ClientNotificationInboxModel.fromJson({
      'items': [
        {
          'id': 'notification-uuid',
          'notificationId': 'notification-uuid',
          'deliveryId': 'delivery-uuid',
          'recipientId': 'recipient-uuid',
          'kind': 'PROMOTION_ASSIGNMENT',
          'title': 'Lunch promo',
          'body': 'Order your favorite lavash before 15:00.',
          'deepLink': 'enjoylavash://promotions/lunch',
          'sentAt': '2026-07-05T06:53:18.000Z',
          'readAt': null,
          'isRead': false,
          'promotionAssignmentId': 'assignment-uuid',
          'promotionCode': 'PRIVATE20-ABC',
        },
      ],
      'unreadCount': 1,
      'total': 1,
      'limit': 50,
      'offset': 0,
    });

    expect(inbox.items, hasLength(1));
    expect(inbox.unreadCount, 1);
    expect(inbox.total, 1);
    expect(inbox.limit, 50);
    expect(inbox.offset, 0);

    final item = inbox.items.single;
    expect(item.id, 'notification-uuid');
    expect(item.notificationId, 'notification-uuid');
    expect(item.deliveryId, 'delivery-uuid');
    expect(item.recipientId, 'recipient-uuid');
    expect(item.kind, 'PROMOTION_ASSIGNMENT');
    expect(item.title, 'Lunch promo');
    expect(item.body, 'Order your favorite lavash before 15:00.');
    expect(item.deepLink, 'enjoylavash://promotions/lunch');
    expect(item.sentAt, DateTime.parse('2026-07-05T06:53:18.000Z'));
    expect(item.readAt, isNull);
    expect(item.isRead, isFalse);
    expect(item.promotionAssignmentId, 'assignment-uuid');
    expect(item.promotionCode, 'PRIVATE20-ABC');
    expect(item.opensPromotions, isTrue);

    final unread = item
        .copyWith(readAt: DateTime.now(), isRead: true)
        .copyWith(clearReadAt: true, isRead: false);
    expect(unread.readAt, isNull);
    expect(unread.isRead, isFalse);
  });

  test('parses snake case read result response', () {
    final result = ClientNotificationReadResultModel.fromJson({
      'updated': 3,
      'unread_count': 0,
    });

    expect(result.updated, 3);
    expect(result.unreadCount, 0);
  });
}
