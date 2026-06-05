# Mobile App Implementation Guide

This guide describes the customer mobile app integration for the demo backend.

## Demo Setup

- API docs: `GET /docs`
- Demo OTP code: `1111`
- Demo client phone numbers:
  - `+998901234567` - Ali Valiyev, has two saved addresses and active/past orders.
  - `+998909876543` - Malika Karimova, has one saved address and a delivered order.
- Admin demo login:
  - username: `admin`
  - password: `admin`

The backend returns raw objects and arrays. Do not expect `{ data, message }` wrappers.

## Auth Flow

### Request OTP

`POST /auth/request-otp`

```json
{
  "phoneNumber": "+998901234567"
}
```

Response:

```json
{
  "phoneNumber": "+998901234567",
  "codeExpiresAt": "2026-05-12T10:05:00.000Z",
  "demoCode": "1111"
}
```

### Verify OTP

`POST /auth/verify-otp`

```json
{
  "phoneNumber": "+998901234567",
  "code": "1111",
  "fullName": "Ali Valiyev",
  "language": "ru"
}
```

Response:

```json
{
  "access_token": "eyJhb...",
  "token_type": "Bearer",
  "client": {
    "id": "...",
    "fullName": "Ali Valiyev",
    "phoneNumber": "+998901234567",
    "language": "ru",
    "bonusBalance": 1250000,
    "birthDate": null,
    "marketingConsent": false,
    "isBlocked": false,
    "lastOrderAt": null,
    "organisationId": "...",
    "createdAt": "...",
    "updatedAt": "..."
  }
}
```

Store `access_token` and send it as:

```http
Authorization: Bearer <access_token>
```

The `client` object in the response can be used to populate the profile immediately without a separate `GET /clients/me` call.

Use this token only for client endpoints. Admin auth has separate RBAC behavior.

## Main Screens

### Splash/bootstrap

Load in parallel:

- `GET /branches`
- `GET /catalog?lang=<language>`
- `GET /promotions/active`

If the user has a client token, also load:

- `GET /clients/me`
- `GET /clients/me/addresses`
- `GET /clients/me/orders`

### Home/catalog

Use `GET /catalog`.

Recommended query:

```http
GET /catalog?lang=ru&branchId=branch-chilanzar
```

Render:

- categories
- product cards
- localized `name` and `description`
- prices as integer UZS minor units
- modifiers from `modifierGroups`
- product images from `image`

### Product details

Use `GET /catalog/products/:id` for direct product pages. Also accepts product `slug` instead of `id`.

For products with required modifier groups, force a valid selection before adding to cart.

Example cart item:

```json
{
  "productId": "prod-classic-lavash",
  "quantity": 2,
  "modifiers": [
    { "modifierId": "mod-lavash-standard", "quantity": 1 },
    { "modifierId": "mod-cheese", "quantity": 1 }
  ],
  "comment": "No onion"
}
```

### Cart preview

Call `POST /cart/preview` after cart, address, branch, order type, payment method, or promo code changes.

Delivery example:

```json
{
  "type": "DELIVERY",
  "branchId": "branch-chilanzar",
  "address": {
    "latitude": 41.2884,
    "longitude": 69.2048
  },
  "items": [
    {
      "productId": "prod-classic-lavash",
      "quantity": 2,
      "modifiers": [{ "modifierId": "mod-lavash-standard" }]
    }
  ],
  "paymentMethod": "CASH",
  "promoCode": "FIRST20"
}
```

Show:

- `itemsAmount`
- `modifiersAmount`
- `discountAmount`
- `deliveryAmount`
- `serviceFeeAmount`
- `totalAmount`
- `appliedPromotion`
- selected `branchId`
- `deliveryDistanceMeters`

### Addresses

List:

`GET /clients/me/addresses`

Create:

`POST /clients/me/addresses`

```json
{
  "label": "Home",
  "street": "Bunyodkor Avenue",
  "houseNumber": "18",
  "apartmentNumber": "42",
  "entrance": "2",
  "floor": "7",
  "doorCode": "1245",
  "latitude": 41.2884,
  "longitude": 69.2048,
  "comment": "Call when near the entrance",
  "isDefault": true
}
```

Update:

`PATCH /clients/me/addresses/:id`

```json
{
  "label": "Work",
  "street": "Amir Temur Avenue",
  "houseNumber": "5"
}
```

Delete:

`DELETE /clients/me/addresses/:id`

Use saved `addressId` when creating authenticated delivery orders.

### Checkout

For logged-in clients, prefer:

`POST /clients/me/orders`

```json
{
  "type": "DELIVERY",
  "addressId": "addr-ali-home",
  "items": [
    {
      "productId": "prod-classic-lavash",
      "quantity": 1,
      "modifiers": [{ "modifierId": "mod-lavash-standard" }]
    }
  ],
  "paymentMethod": "CASH",
  "promoCode": "FIRST20",
  "comment": "Less spicy"
}
```

For pickup:

```json
{
  "type": "PICKUP",
  "branchId": "branch-mirabad",
  "items": [
    {
      "productId": "prod-cola",
      "quantity": 2
    }
  ],
  "paymentMethod": "CARD_TERMINAL"
}
```

For scheduled orders, add `scheduledFor` (ISO 8601):

```json
{
  "type": "DELIVERY",
  "addressId": "addr-ali-home",
  "items": [...],
  "paymentMethod": "CASH",
  "scheduledFor": "2026-05-22T12:00:00.000Z"
}
```

### Orders

Authenticated client order history:

`GET /clients/me/orders`

Order status values:

- `NEW`
- `CONFIRMED`
- `COOKING`
- `READY`
- `COURIER_ASSIGNED`
- `ON_THE_WAY`
- `DELIVERED`
- `CANCELLED`
- `REFUNDED`

Render `statusLog` as the timeline.

Cancel active order:

`POST /clients/me/orders/:id/cancel`

```json
{
  "reason": "Changed my mind"
}
```

### Profile

Current profile:

`GET /clients/me`

Update:

`PATCH /clients/me`

```json
{
  "fullName": "Ali Valiyev",
  "birthDate": "1995-05-12",
  "language": "ru",
  "marketingConsent": true
}
```

## Demo Data To Show

### Client Ali

- Phone: `+998901234567`
- Bonus balance: `1250000`
- Addresses:
  - Home near Chilanzar
  - Office near Amir Temur Street
- Orders:
  - Active delivery order in `COOKING`
  - Delivered pickup order

### Client Malika

- Phone: `+998909876543`
- Language: `uz`
- Address:
  - Yunusabad home
- Orders:
  - Delivered Payme order

## Error Handling

Common backend errors:

- `400` - invalid request body, invalid cart, invalid modifiers, invalid status transition.
- `401` - missing/invalid bearer token or expired OTP.
- `404` - requested client address/order/product not found.

Show backend error `message` when available.

## Money and Localization

- All money fields are integer minor units.
- Format as UZS in the app.
- Supported languages: `ru`, `uz`, `en`.
- Use `?lang=` for catalog and `language` on client profile.

## File Upload

Upload images (product photos, etc.) via multipart form-data.

`POST /files/upload`

```http
Content-Type: multipart/form-data

file: <binary>
```

Response:

```json
{
  "url": "/uploads/abc123.png"
}
```

Max file size: 10 MB. The returned `url` path is relative — prepend the API base URL to display.

Delete a file:

`DELETE /files/delete?filename=abc123.png`

Returns `204 No Content`.

## Production Gaps

- OTP is demo/static; replace with SMS provider later.
- Client and address data support both in-memory and PostgreSQL (dual mode). TypeORM entities and migrations are in place.
- Payments are modeled as statuses/methods but Payme/Click webhooks are not implemented yet.
