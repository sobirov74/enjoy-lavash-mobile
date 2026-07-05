# Mobile Push Notifications

Backend-driven push notifications support two flows:

- scheduled marketing campaigns created by the admin panel
- transactional order-status notifications sent by the backend

Android uses Firebase Cloud Messaging. iOS uses direct APNs with native APNs
device tokens from the Flutter app.

## Environment

```env
APNS_TEAM_ID=ABCDE12345
APNS_KEY_ID=ABC123DEFG
APNS_BUNDLE_ID=com.aurumdev.enjoy_lavash_mobile
APNS_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"
APNS_PRODUCTION=false

FIREBASE_SERVICE_ACCOUNT_JSON={"type":"service_account","project_id":"..."}

NOTIFICATION_CRON="0 * * * * *"
NOTIFICATION_TIMEZONE=Asia/Tashkent
```

`FIREBASE_SERVICE_ACCOUNT_JSON` can be the raw service account JSON or a path
to a JSON file on the server.

## Mobile Token API

All mobile token endpoints require a client bearer token.

### Register or Refresh Token

```http
POST /clients/me/push-tokens
Authorization: Bearer <client_access_token>
Content-Type: application/json
```

```json
{
  "platform": "android",
  "token": "device-token",
  "deviceId": "optional-device-id",
  "appVersion": "1.0.4+5",
  "locale": "ru"
}
```

`platform` must be `android` or `ios`. Re-sending the same token updates client
ownership, locale, app version, and `lastSeenAt`.

### Disable Token

```http
DELETE /clients/me/push-tokens/:token
Authorization: Bearer <client_access_token>
```

The app should call this on logout or when notification permission is revoked.
URI-encode the token before placing it in the path.

## Client Notification Inbox API

All client notification inbox endpoints require a client bearer token.

### List Sent Notifications

```http
GET /clients/me/notifications?limit=50&offset=0&unreadOnly=false
Authorization: Bearer <client_access_token>
```

Response:

```json
{
  "items": [
    {
      "id": "notification-uuid",
      "notificationId": "notification-uuid",
      "deliveryId": "delivery-uuid",
      "title": "Lunch promo",
      "body": "Order your favorite lavash before 15:00.",
      "deepLink": "enjoylavash://promotions/lunch",
      "sentAt": "2026-07-05T06:53:18.000Z",
      "readAt": null,
      "isRead": false
    }
  ],
  "unreadCount": 1,
  "total": 1,
  "limit": 50,
  "offset": 0
}
```

The list includes successfully sent campaign notifications and groups duplicate
deliveries from multiple device tokens into one inbox item.

### Unread Count

```http
GET /clients/me/notifications/unread-count
Authorization: Bearer <client_access_token>
```

```json
{ "unreadCount": 1 }
```

### Mark Read

```http
POST /clients/me/notifications/:notificationId/read
Authorization: Bearer <client_access_token>
```

```json
{ "updated": 1, "unreadCount": 0 }
```

### Mark All Read

```http
POST /clients/me/notifications/read-all
Authorization: Bearer <client_access_token>
```

```json
{ "updated": 3, "unreadCount": 0 }
```

## Flutter Setup Notes

The Flutter app includes token registration code for both platforms:

- iOS gets the native APNs token through the `enjoy_lavash_mobile/apns`
  MethodChannel in `AppDelegate.swift`.
- Android gets an FCM token through `firebase_messaging`.

For iOS, enable the Push Notifications capability for the app identifier and
make sure the provisioning profile includes it.

Before Android can return FCM tokens, add Firebase project config to the Flutter
app, for example with FlutterFire-generated options or Android
`google-services.json`. Until Firebase is configured, the app logs the setup
error and skips Android token registration instead of crashing.

The app registers a token after OTP login and authenticated startup, and deletes
the registered token during logout.

## Admin Campaign API

All admin endpoints require an admin bearer token and notification permissions.

### List

```http
GET /admin/notifications?organisationId=<uuid>&status=APPROVED
```

### Create

```http
POST /admin/notifications
Content-Type: application/json
```

```json
{
  "organisationId": "00000000-0000-4000-8000-000000000001",
  "title": "Lunch promo",
  "body": "Order your favorite lavash before 15:00.",
  "deepLink": "enjoylavash://promotions/lunch",
  "scheduleType": "once",
  "sendDate": "2026-07-01",
  "sendTime": "14:30",
  "isActive": true,
  "targeting": {
    "locales": ["ru", "uz"],
    "platforms": ["ios", "android"]
  }
}
```

Created notifications start as `PENDING`.

### Update

```http
PATCH /admin/notifications/:id
Content-Type: application/json
```

Use the same fields as create. `SENT` notifications cannot be edited.

### Approve

```http
POST /admin/notifications/:id/approve
```

Only `APPROVED` and active notifications are considered by the scheduler.

### Send Now

```http
POST /admin/notifications/:id/send-now
```

Response:

```json
{
  "sent": 42,
  "failed": 1,
  "total": 43
}
```

### Cancel

```http
POST /admin/notifications/:id/cancel
```

Cancelling sets `status=CANCELLED` and `isActive=false`.

## Schedule Rules

Times are local to `Asia/Tashkent` and use `HH:mm`.

One-time:

```json
{
  "scheduleType": "once",
  "sendDate": "2026-07-01",
  "sendTime": "14:30"
}
```

Daily:

```json
{
  "scheduleType": "daily",
  "sendTime": "10:00"
}
```

Weekly:

```json
{
  "scheduleType": "weekly",
  "sendTime": "12:00",
  "weekDay": 1
}
```

`weekDay` uses `0=Sunday` through `6=Saturday`.

Monthly:

```json
{
  "scheduleType": "monthly",
  "sendTime": "09:00",
  "monthDay": 15
}
```

## Status Lifecycle

```text
PENDING -> APPROVED -> SENT       one-time success
PENDING -> APPROVED -> APPROVED   recurring success
PENDING -> APPROVED -> FAILED     all delivery attempts failed
PENDING -> CANCELLED              admin cancellation
```

Marketing campaigns send only to clients with:

- active push token
- `marketingConsent=true`
- `isBlocked=false`
- matching organisation
- matching optional targeting filters

Order-status pushes send to the order client regardless of marketing consent.

## Push Payloads

Campaign payload:

```json
{
  "type": "campaign",
  "notificationId": "notification-uuid",
  "deepLink": "enjoylavash://promotions/lunch"
}
```

Order-status payload:

```json
{
  "type": "order_status",
  "orderId": "order-uuid",
  "orderNumber": "20260629-00001",
  "status": "CONFIRMED"
}
```

The Flutter app should route notification taps by `type`.
