# Mobile App: Notifications and Assigned Promo Codes

All endpoints in this guide require the client bearer token unless stated
otherwise.

## Push registration

Register or refresh the device token after login, app launch, token rotation,
or language change:

```http
POST /clients/me/push-tokens
Authorization: Bearer <client-token>
Content-Type: application/json

{
  "platform": "android",
  "token": "<provider-token>",
  "deviceId": "<stable-device-id>",
  "appVersion": "1.4.0",
  "locale": "uz"
}
```

Push is an alert channel only. The inbox is server-backed, so an assignment
notification remains visible when push permission is disabled, no token is
registered, or the provider fails. Promotional push respects the client's
`marketingConsent`.

## Inbox and unread badge

```http
GET /clients/me/notifications?limit=50&offset=0&unreadOnly=false
GET /clients/me/notifications/unread-count
POST /clients/me/notifications/:notificationId/read
POST /clients/me/notifications/:notificationId/unread
POST /clients/me/notifications/read-all
```

The list response includes `items`, `unreadCount`, `total`, `limit`, and
`offset`. Each item contains:

```json
{
  "id": "notification-id",
  "notificationId": "notification-id",
  "recipientId": "recipient-id",
  "kind": "PROMOTION_ASSIGNMENT",
  "title": "Your promo code",
  "body": "Use PRIVATE20-ABC",
  "deepLink": "enjoylavash://promotions",
  "sentAt": "2026-07-23T12:00:00.000Z",
  "readAt": null,
  "isRead": false,
  "promotionAssignmentId": "assignment-id",
  "promotionCode": "PRIVATE20-ABC"
}
```

Recommended UI behavior:

1. Load `unread-count` at startup, after login, and after returning to the
   foreground.
2. Refresh the list when a push is opened or the inbox screen becomes active.
3. Mark the notification read when its detail/deep link is opened.
4. Use the unread count returned by every read/unread mutation immediately.

## Push payload

Assignment and expiry pushes include:

```json
{
  "type": "promotion_assignment",
  "notificationId": "notification-id",
  "promotionAssignmentId": "assignment-id",
  "promotionCode": "PRIVATE20-ABC",
  "deepLink": "enjoylavash://promotions",
  "language": "uz"
}
```

Expiry reminders use `type: "promotion_expiry_reminder"`. Treat unknown types
as a request to open the inbox instead of dropping the notification.

## Assigned promos

```http
GET /clients/me/promotions
GET /clients/me/promotions?status=ALL
```

The default response contains only `ACTIVE` assignments. `ALL` also returns
`NOT_STARTED`, `USED`, `EXPIRED`, `REVOKED`, `INACTIVE`, and
`GLOBAL_LIMIT_REACHED`.

Display the assignment's `code`, `status`, promotion title, end date,
conditions, reward, and remaining uses. Copy the assigned `code` into
`promoCode` for authenticated cart preview and order creation:

```http
POST /clients/me/cart/preview

{
  "type": "PICKUP",
  "items": [{ "productId": "product-id", "quantity": 1 }],
  "promoCode": "PRIVATE20-ABC"
}
```

An assigned-only code used anonymously or by another client returns
`promotionStatus: "NOT_FOUND"`. A consumed unique code returns
`CLIENT_LIMIT_REACHED`. Always treat the order response as authoritative
because an assignment can expire, be revoked, or be consumed after preview.
