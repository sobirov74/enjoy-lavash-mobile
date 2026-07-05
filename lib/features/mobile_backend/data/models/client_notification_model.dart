import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/json_helpers.dart';

class ClientNotificationInboxModel {
  const ClientNotificationInboxModel({
    required this.items,
    required this.unreadCount,
    required this.total,
    required this.limit,
    required this.offset,
  });

  final List<ClientNotificationItemModel> items;
  final int unreadCount;
  final int total;
  final int limit;
  final int offset;

  factory ClientNotificationInboxModel.fromJson(Map<String, dynamic> json) {
    return ClientNotificationInboxModel(
      items: asJsonMapList(
        json['items'],
      ).map(ClientNotificationItemModel.fromJson).toList(growable: false),
      unreadCount: readInt(json, const ['unreadCount', 'unread_count']),
      total: readInt(json, const ['total']),
      limit: readInt(json, const ['limit']),
      offset: readInt(json, const ['offset']),
    );
  }
}

class ClientNotificationItemModel {
  const ClientNotificationItemModel({
    required this.id,
    required this.notificationId,
    required this.deliveryId,
    required this.title,
    required this.body,
    required this.deepLink,
    required this.sentAt,
    required this.readAt,
    required this.isRead,
  });

  final String id;
  final String notificationId;
  final String deliveryId;
  final String title;
  final String body;
  final String? deepLink;
  final DateTime? sentAt;
  final DateTime? readAt;
  final bool isRead;

  factory ClientNotificationItemModel.fromJson(Map<String, dynamic> json) {
    final notificationId = readString(json, const [
      'notificationId',
      'notification_id',
    ]);
    return ClientNotificationItemModel(
      id: readString(json, const ['id'], fallback: notificationId),
      notificationId: notificationId,
      deliveryId: readString(json, const ['deliveryId', 'delivery_id']),
      title: readString(json, const ['title']),
      body: readString(json, const ['body']),
      deepLink: _nonEmptyString(json, const ['deepLink', 'deep_link']),
      sentAt: readDateTime(json, const ['sentAt', 'sent_at']),
      readAt: readDateTime(json, const ['readAt', 'read_at']),
      isRead: readBool(json, const ['isRead', 'is_read']),
    );
  }

  ClientNotificationItemModel copyWith({DateTime? readAt, bool? isRead}) {
    return ClientNotificationItemModel(
      id: id,
      notificationId: notificationId,
      deliveryId: deliveryId,
      title: title,
      body: body,
      deepLink: deepLink,
      sentAt: sentAt,
      readAt: readAt ?? this.readAt,
      isRead: isRead ?? this.isRead,
    );
  }
}

class ClientNotificationReadResultModel {
  const ClientNotificationReadResultModel({
    required this.updated,
    required this.unreadCount,
  });

  final int updated;
  final int unreadCount;

  factory ClientNotificationReadResultModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClientNotificationReadResultModel(
      updated: readInt(json, const ['updated']),
      unreadCount: readInt(json, const ['unreadCount', 'unread_count']),
    );
  }
}

String? _nonEmptyString(Map<String, dynamic> json, List<String> keys) {
  final value = readString(json, keys).trim();
  return value.isEmpty ? null : value;
}
