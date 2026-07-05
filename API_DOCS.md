# Enjoy Lavash API Documentation

**Base URL**: `http://localhost:3000`
**Swagger UI**: `http://localhost:3000/docs`
**Content-Type**: `application/json`

All money values are integers in UZS (e.g., `32000` = 32,000 UZS).
i18n text fields use `{ ru?: string, uz?: string, en?: string }` format.

---

## Authentication

### Client Auth (OTP-based for mobile app)

| Method | Endpoint            | Auth | Description              |
| ------ | ------------------- | ---- | ------------------------ |
| POST   | `/auth/request-otp` | -    | Request OTP code         |
| POST   | `/auth/verify-otp`  | -    | Verify OTP and get token |

### Admin Auth (username/password)

| Method | Endpoint        | Auth   | Description            |
| ------ | --------------- | ------ | ---------------------- |
| POST   | `/auth/login`   | -      | Admin login            |
| POST   | `/auth/refresh` | -      | Refresh access token   |
| GET    | `/auth/me`      | Bearer | Get current admin user |

---

## Client Auth Flow

### 1. Request OTP

```
POST /auth/request-otp
```

**Body:**

```json
{ "phoneNumber": "+998901234567" }
```

**Response 200:**

```json
{
  "phoneNumber": "+998901234567",
  "codeExpiresAt": "2026-06-01T12:05:00.000Z"
}
```

When `ESKIZ_EMAIL` and `ESKIZ_PASSWORD` are configured, the OTP is sent by SMS through Eskiz.
Without Eskiz credentials, the dev fallback response also includes `demoCode`.

For demo/test accounts in an SMS-enabled environment, configure:

```env
OTP_DEMO_PHONE_WHITELIST=+998901234567,+998901111111
OTP_DEMO_CODE=1111
```

Phones in `OTP_DEMO_PHONE_WHITELIST` do not receive an SMS. They can verify using `OTP_DEMO_CODE`.
The whitelist accepts copdeplmma, semicolon, or newline separated Uzbekistan phone numbers.

### 2. Verify OTP

```
POST /auth/verify-otp
```

**Body:**

```json
{
  "phoneNumber": "+998901234567",
  "code": "1111",
  "fullName": "Ali Valiyev",
  "language": "ru"
}
```

`fullName` and `language` are optional. On first login, a new client is created.

**Response 200:**

```json
{
  "access_token": "eyJhbG...",
  "token_type": "Bearer",
  "client_created": true,
  "client": {
    "id": "uuid",
    "organisationId": "org-enjoy-lavash",
    "fullName": "Ali Valiyev",
    "phoneNumber": "+998901234567",
    "birthDate": null,
    "language": "ru",
    "bonusBalance": 0,
    "lastOrderAt": null,
    "isBlocked": false,
    "marketingConsent": false,
    "createdAt": "...",
    "updatedAt": "..."
  }
}
```

`client_created` is `true` only when this OTP verification created a new
client account. It is `false` when the phone number already belongs to an
existing active client.

### Using the token

```
Authorization: Bearer <access_token>
```

---

## Admin Auth Flow

### Login

```
POST /auth/login
```

**Body:**

```json
{ "username": "admin", "password": "admin" }
```

**Response 200:**

```json
{
  "access_token": "eyJhbG...",
  "refresh_token": "eyJhbG...",
  "token_type": "Bearer",
  "user": { "id": "...", "fullName": "Admin", "role": { ... } }
}
```

### Refresh

```
POST /auth/refresh
```

**Body:**

```json
{ "refresh_token": "eyJhbG..." }
```

---

## Mobile Client Auth Flow

Client OTP verification now returns a rotating refresh token. The client refresh
session is active for 3 days by default.

### Verify OTP

```
POST /auth/verify-otp
```

Response 200 includes:

```json
{
  "access_token": "eyJhbG...",
  "refresh_token": "W0H5...",
  "refresh_token_expires_at": "2026-07-05T12:00:00.000Z",
  "token_type": "Bearer",
  "client_created": false,
  "client": { "id": "...", "phoneNumber": "+998901234567" }
}
```

### Refresh Client Session

```
POST /auth/client/refresh
```

**Body:**

```json
{ "refresh_token": "W0H5..." }
```

The response returns a new access token and a new refresh token. Replace both
stored tokens after every successful refresh. See `MOBILE_CLIENT_AUTH.md` for
mobile implementation details.

---

## Public Endpoints (No auth required)

### Catalog

| Method | Endpoint                      | Description                                      |
| ------ | ----------------------------- | ------------------------------------------------ |
| GET    | `/catalog`                    | Full catalog (categories + products + modifiers) |
| GET    | `/catalog/categories`         | List categories                                  |
| GET    | `/catalog/products`           | List all products                                |
| GET    | `/catalog/products/featured`  | Featured products only                           |
| GET    | `/catalog/products/:idOrSlug` | Single product by ID or slug                     |

#### GET /catalog

Returns the full nested catalog with localized names. Products with
`mobileVisible=false` are hidden from public catalog responses and app cart
pricing.

**Query params:**

- `lang` — `ru`, `uz`, or `en` (overrides header)
- `branchId` — filter by branch availability
- `Accept-Language` header — fallback language detection

**Response 200:**

```json
{
  "organisationId": "org-enjoy-lavash",
  "language": "ru",
  "categories": [
    {
      "id": "cat-lavash",
      "slug": "lavash",
      "name": "Лаваш",
      "description": "Фирменные лаваши",
      "image": "/uploads/categories/lavash.jpg",
      "sortOrder": 1,
      "isActive": true,
      "products": [
        {
          "id": "prod-classic-lavash",
          "slug": "classic-lavash",
          "name": "Классический лаваш",
          "description": "Говядина, овощи, соус",
          "image": "/uploads/products/classic-lavash.jpg",
          "gallery": [],
          "basePrice": 32000,
          "oldPrice": null,
          "calories": 620,
          "weightGrams": 360,
          "cookingTimeMinutes": 12,
          "mobileVisible": true,
          "isFeatured": true,
          "tags": ["popular"],
          "modifierGroups": [
            {
              "id": "group-lavash-size",
              "name": "Размер",
              "minSelect": 1,
              "maxSelect": 1,
              "isRequired": true,
              "modifiers": [
                {
                  "id": "mod-lavash-standard",
                  "name": "Стандарт",
                  "price": 0,
                  "isDefault": true
                },
                {
                  "id": "mod-lavash-big",
                  "name": "Большой",
                  "price": 7000,
                  "isDefault": false
                }
              ]
            }
          ]
        }
      ]
    }
  ]
}
```

### Branches

| Method | Endpoint                      | Description          |
| ------ | ----------------------------- | -------------------- |
| GET    | `/branches`                   | List active branches |
| GET    | `/branches/:id`               | Get single branch    |
| GET    | `/branches/:id/working-hours` | Branch working hours |

### Delivery

| Method | Endpoint            | Description             |
| ------ | ------------------- | ----------------------- |
| POST   | `/delivery/preview` | Calculate delivery cost |

**Body:**

```json
{
  "address": { "latitude": 41.3111, "longitude": 69.2797 },
  "branchId": "branch-chilanzar",
  "productIds": ["prod-classic-lavash"],
  "itemsAmount": 32000
}
```

**Response 200:**

```json
{
  "branch": { "id": "branch-chilanzar", "name": "...", ... },
  "deliveryDistanceMeters": 2150,
  "deliveryAmount": 10000
}
```

### Cart Preview

| Method | Endpoint        | Description                          |
| ------ | --------------- | ------------------------------------ |
| POST   | `/cart/preview` | Calculate cart total with promotions |

**Body:**

```json
{
  "type": "DELIVERY",
  "items": [
    {
      "productId": "prod-classic-lavash",
      "quantity": 2,
      "modifiers": [
        { "modifierId": "mod-lavash-standard", "quantity": 1 },
        { "modifierId": "mod-cheese", "quantity": 1 }
      ]
    }
  ],
  "address": { "latitude": 41.3111, "longitude": 69.2797 },
  "promoCode": "FIRST20",
  "paymentMethod": "CASH"
}
```

**Response 200:**

```json
{
  "organisationId": "org-enjoy-lavash",
  "branchId": "branch-chilanzar",
  "deliveryDistanceMeters": 2150,
  "itemsAmount": 64000,
  "modifiersAmount": 10000,
  "discountAmount": 14800,
  "deliveryAmount": 10000,
  "serviceFeeAmount": 0,
  "totalAmount": 69200,
  "appliedPromotion": { "id": "...", "code": "FIRST20", ... },
  "items": [
    {
      "productId": "prod-classic-lavash",
      "productNameSnapshotI18n": { "ru": "Классический лаваш", ... },
      "quantity": 2,
      "unitPrice": 32000,
      "modifiersAmount": 10000,
      "totalPrice": 74000,
      "modifiers": [...]
    }
  ]
}
```

### Promotions

| Method | Endpoint             | Description            |
| ------ | -------------------- | ---------------------- |
| GET    | `/promotions/active` | List active promotions |

### Payment Methods

| Method | Endpoint           | Description                         |
| ------ | ------------------ | ----------------------------------- |
| GET    | `/payment-methods` | Enabled payment methods (localized) |

Use this to render the payment selector in the app. Only enabled methods are
returned, sorted by `sortOrder`. Pass `branchId` after branch selection; `PAYME`
is returned only when that branch has enabled Payme credentials.

**Query params:** `lang` (`ru`/`uz`/`en`), `branchId`, or
`Accept-Language` header.

**Response 200:**

```json
[
  {
    "id": "pm-cash",
    "code": "CASH",
    "name": "Наличные",
    "isOnline": false,
    "sortOrder": 1,
    "icon": null
  },
  {
    "id": "pm-payme",
    "code": "PAYME",
    "name": "Payme",
    "isOnline": true,
    "sortOrder": 2,
    "icon": null
  }
]
```

- `isOnline: true` → on order creation the response includes a `paymentUrl`
  the app must open to complete payment. The order stays
  `paymentStatus: PENDING`; iiko receives it only after payment is confirmed.
- `isOnline: false` (cash, card on delivery) → settled on delivery/pickup; iiko
  receives the order after admin confirmation (`NEW` → `CONFIRMED`).

### Mobile App Version

| Method | Endpoint       | Description                             |
| ------ | -------------- | --------------------------------------- |
| GET    | `/app-version` | Current app version policy for platform |

The mobile app should call this endpoint on startup and before showing the main
flow. The backend stores separate version settings for `ios` and `android`.

**Query params:**

| Query            | Required | Description                         |
| ---------------- | -------- | ----------------------------------- |
| `platform`       | Yes      | `ios` or `android`                  |
| `currentVersion` | No       | Installed app version, e.g. `1.2.3` |
| `lang`           | No       | `ru`, `uz`, or `en`                 |

You can also send `Accept-Language` instead of `lang`.

**Response 200:**

```json
{
  "id": "app-version-ios",
  "createdAt": "2026-01-01T00:00:00.000Z",
  "updatedAt": "2026-01-01T00:00:00.000Z",
  "deletedAt": null,
  "platform": "ios",
  "latestVersion": "1.2.0",
  "minSupportedVersion": "1.1.0",
  "description": "A new version is available.",
  "appUrl": "https://apps.apple.com/app/enjoy-lavash",
  "updateAvailable": true,
  "forceUpdate": false
}
```

- `forceUpdate: true` means block normal app usage and send the user to
  `appUrl`.
- `updateAvailable: true` and `forceUpdate: false` means show an optional update
  prompt.
- If `currentVersion` is omitted, the response still returns configured text and
  URL, but both update flags are `false`.

---

## Client Endpoints (Requires client Bearer token)

All endpoints below require `Authorization: Bearer <client_token>`.

### Profile

| Method | Endpoint      | Description        |
| ------ | ------------- | ------------------ |
| GET    | `/clients/me` | Get current client |
| PATCH  | `/clients/me` | Update profile     |

**PATCH /clients/me Body:**

```json
{
  "fullName": "Ali Valiyev",
  "birthDate": "1995-05-12",
  "language": "uz",
  "marketingConsent": true
}
```

All fields are optional.

### Addresses

| Method | Endpoint                    | Description    |
| ------ | --------------------------- | -------------- |
| GET    | `/clients/me/addresses`     | List addresses |
| POST   | `/clients/me/addresses`     | Create address |
| PATCH  | `/clients/me/addresses/:id` | Update address |
| DELETE | `/clients/me/addresses/:id` | Delete address |

**POST /clients/me/addresses Body:**

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

Required: `label`, `street`, `houseNumber`, `latitude`, `longitude`.
First address is auto-set as default.

### Orders

| Method | Endpoint                               | Description          |
| ------ | -------------------------------------- | -------------------- |
| GET    | `/clients/me/orders`                   | List my orders       |
| GET    | `/clients/me/orders/:id`               | Get order detail     |
| POST   | `/clients/me/orders`                   | Create order         |
| POST   | `/clients/me/orders/:id/retry-payment` | Retry online payment |
| POST   | `/clients/me/orders/:id/cancel`        | Cancel order         |

**POST /clients/me/orders Body:**

```json
{
  "type": "DELIVERY",
  "items": [
    {
      "productId": "prod-classic-lavash",
      "quantity": 2,
      "modifiers": [
        { "modifierId": "mod-lavash-standard" },
        { "modifierId": "mod-cheese" }
      ]
    }
  ],
  "addressId": "addr-ali-home",
  "promoCode": "FIRST20",
  "paymentMethod": "CASH",
  "comment": "Less spicy please",
  "scheduledFor": null
}
```

For `DELIVERY` orders, provide `addressId` (from saved addresses) or `address: { latitude, longitude }`.
For `PICKUP` orders, provide `branchId`.

If iiko is enabled, order creation stores the order locally with status `NEW`.
It is sent to iiko after admin confirmation (`NEW` → `CONFIRMED`). The response
includes `iikoOrderId` after iiko accepts the order; otherwise it is `null`.

**Online payment (Payme):** when `paymentMethod` is an online method, the
created-order response includes a `paymentUrl`. Open it (in-app browser /
redirect) to let the user pay. The order is created with
`paymentStatus: PENDING` and is sent to iiko only after Payme confirms payment
Poll `GET /clients/me/orders/:id` (or use a deep link) to detect
`paymentStatus: PAID`.

```json
{
  "id": "...",
  "paymentMethod": "PAYME",
  "paymentStatus": "PENDING",
  "totalAmount": 40000,
  "paymentUrl": "https://checkout.paycom.uz/<base64>",
  "paymentExpiresAt": "2026-07-03T12:15:00.000Z",
  "paymentRetryAvailable": true,
  "paymentAttemptCount": 1,
  "iikoOrderId": null
}
```

If Payme fails or the user abandons checkout, call
`POST /clients/me/orders/:id/retry-payment` while the order is active. The
backend allows at most two online attempts. If the online payment window expires
without payment, the order is converted to `paymentMethod: CASH` instead of
being cancelled.

`PAYME` is hidden from `/payment-methods?branchId=...` when the branch has no
enabled Payme config. Creating a Payme order for such a branch returns an error.

**POST /clients/me/orders/:id/cancel Body:**

```json
{ "reason": "Changed my mind" }
```

---

## Enums

### OrderType

```
DELIVERY | PICKUP
```

### PaymentMethod

```
CASH | PAYME | CLICK | CARD_TERMINAL
```

### RestaurantOrderStatus

```
NEW → CONFIRMED → COOKING → READY → COURIER_ASSIGNED → ON_THE_WAY → DELIVERED
                                   → DELIVERED (for pickup)
Any non-terminal status → CANCELLED
```

### PaymentStatus

```
PENDING | PAID | FAILED | REFUNDED
```

### Language

```
ru | uz | en
```

---

## Admin Endpoints (Requires admin Bearer token)

All admin endpoints require `Authorization: Bearer <admin_token>`.

### Orders

| Method | Endpoint                           | Permission             | Description         |
| ------ | ---------------------------------- | ---------------------- | ------------------- |
| GET    | `/admin/orders`                    | `order_view_list`      | List all orders     |
| GET    | `/admin/orders/:id`                | `order_view_list`      | Get order           |
| POST   | `/admin/orders`                    | `order_update_status`  | Create order (POS)  |
| PATCH  | `/admin/orders/:id/status`         | `order_update_status`  | Update order status |
| POST   | `/admin/orders/:id/cancel`         | `order_update_status`  | Cancel order        |
| PATCH  | `/admin/orders/:id/assign-courier` | `order_assign_courier` | Assign courier      |

### Kitchen

| Method | Endpoint                          | Permission                  | Description                                             |
| ------ | --------------------------------- | --------------------------- | ------------------------------------------------------- |
| GET    | `/admin/kitchen/orders?branchId=` | `kitchen.orders.view_list`  | Kitchen display orders (NEW, CONFIRMED, COOKING, READY) |
| PATCH  | `/admin/kitchen/orders/:id/ready` | `kitchen.orders.mark_ready` | Mark order as ready                                     |

### Courier

| Method | Endpoint                              | Permission             | Description      |
| ------ | ------------------------------------- | ---------------------- | ---------------- |
| GET    | `/admin/courier/orders?courierId=`    | `order_assign_courier` | Courier's orders |
| PATCH  | `/admin/courier/orders/:id/picked-up` | `order_update_status`  | Mark picked up   |
| PATCH  | `/admin/courier/orders/:id/delivered` | `order_update_status`  | Mark delivered   |

### Catalog Management

| Method | Endpoint                               | Permission             | Description           |
| ------ | -------------------------------------- | ---------------------- | --------------------- |
| GET    | `/admin/categories`                    | `categories.view_list` | List categories       |
| POST   | `/admin/categories`                    | `categories.create`    | Create category       |
| PATCH  | `/admin/categories/:id`                | `categories.update`    | Update category       |
| DELETE | `/admin/categories/:id`                | `categories.delete`    | Delete category       |
| GET    | `/admin/products`                      | `products.view_list`   | List products         |
| GET    | `/admin/products/:slug`                | `products.view_list`   | Get product           |
| POST   | `/admin/products`                      | `products.create`      | Create product        |
| PATCH  | `/admin/products/:id`                  | `products.update`      | Update product        |
| DELETE | `/admin/products/:id`                  | `products.delete`      | Delete product        |
| GET    | `/admin/products/:id/modifier-groups`  | `products.update`      | List modifier groups  |
| POST   | `/admin/products/:id/modifier-groups`  | `products.update`      | Create modifier group |
| PATCH  | `/admin/modifier-groups/:id`           | `products.update`      | Update modifier group |
| DELETE | `/admin/modifier-groups/:id`           | `products.delete`      | Delete modifier group |
| GET    | `/admin/modifier-groups/:id/modifiers` | `products.update`      | List modifiers        |
| POST   | `/admin/modifier-groups/:id/modifiers` | `products.update`      | Create modifier       |
| PATCH  | `/admin/modifiers/:id`                 | `products.update`      | Update modifier       |
| DELETE | `/admin/modifiers/:id`                 | `products.delete`      | Delete modifier       |

Product image and mobile visibility fields:

```json
{
  "mobileVisible": false,
  "imageOverride": "/uploads/products/custom-lavash.jpg"
}
```

- `mobileVisible=false` hides the product from the mobile/public catalog and
  prevents app cart pricing for that product.
- `imageOverride` is the admin-controlled app image. Public catalog resolves
  product image as `imageOverride`, then `iikoImage`, then legacy `image`.
- Sending `image` to product create/update remains supported and is treated as
  a local image override for backward compatibility.

### Branches

| Method | Endpoint                           | Permission        | Description                 |
| ------ | ---------------------------------- | ----------------- | --------------------------- |
| POST   | `/admin/branches`                  | `branches.create` | Create branch               |
| PATCH  | `/admin/branches/:id`              | `branches.update` | Update branch               |
| DELETE | `/admin/branches/:id`              | `branches.delete` | Delete branch               |
| PATCH  | `/admin/branches/:id/availability` | `branches.update` | Update product availability |

Branch create/update accepts optional Payme config:

```json
{
  "payme": {
    "merchantId": "payme-merchant-branch-1",
    "key": "cashbox-secret",
    "isEnabled": true
  }
}
```

The raw `key` is encrypted before storage and is never returned. Responses
include safe metadata only: `configured`, `isEnabled`, `merchantId`, and
`keyPreview`.

### Promotions

| Method | Endpoint                | Permission          | Description         |
| ------ | ----------------------- | ------------------- | ------------------- |
| GET    | `/admin/promotions`     | `promotions.update` | List all promotions |
| POST   | `/admin/promotions`     | `promotions.create` | Create promotion    |
| PATCH  | `/admin/promotions/:id` | `promotions.update` | Update promotion    |
| DELETE | `/admin/promotions/:id` | `promotions.delete` | Delete promotion    |

### Reports

| Method | Endpoint                    | Permission              | Description     |
| ------ | --------------------------- | ----------------------- | --------------- |
| GET    | `/admin/reports/sales`      | `reports.sales.view`    | Sales summary   |
| GET    | `/admin/reports/products`   | `reports.products.view` | Product stats   |
| GET    | `/admin/reports/promotions` | `reports.sales.view`    | Promotion usage |
| GET    | `/admin/reports/branches`   | `reports.sales.view`    | Branch stats    |

#### SMS Provider Reports (Eskiz)

All endpoints below require `reports.sms.view`. They proxy Eskiz report APIs and keep
Eskiz credentials server-side. Date filters accept camelCase or Eskiz-style snake_case:
`startDate`/`start_date`, `endDate`/`end_date`/`toDate`/`to_date`.

Detailed website implementation guide: [SMS_WEBSITE_API_DOCS.md](SMS_WEBSITE_API_DOCS.md)

| Method | Endpoint                                  | Description                         |
| ------ | ----------------------------------------- | ----------------------------------- |
| GET    | `/admin/reports/sms/messages`             | Sent SMS detail list                |
| GET    | `/admin/reports/sms/messages/by-dispatch` | Sent SMS list for a dispatch        |
| GET    | `/admin/reports/sms/dispatch-status`      | Dispatch status by user/dispatch ID |
| GET    | `/admin/reports/sms/status/:id`           | SMS status by Eskiz ID              |
| GET    | `/admin/reports/sms/totals`               | Sent SMS totals by year/month       |
| GET    | `/admin/reports/sms/balance`              | Eskiz SMS balance/limit             |
| GET    | `/admin/reports/sms/export`               | Export SMS report as CSV            |
| GET    | `/admin/reports/sms/total-by-month`       | Monthly totals for a year           |
| GET    | `/admin/reports/sms/total-by-smsc`        | Monthly totals grouped by SMSC      |
| GET    | `/admin/reports/sms/logs/:id`             | Eskiz SMS system logs               |
| GET    | `/admin/reports/sms/total-by-range`       | Cost totals by date range           |
| GET    | `/admin/reports/sms/total-by-dispatch`    | Cost totals by dispatch ID          |
| GET    | `/admin/reports/sms/prices`               | Eskiz SMS prices                    |

### Payment Methods

| Method | Endpoint                     | Permission                  | Description                |
| ------ | ---------------------------- | --------------------------- | -------------------------- |
| GET    | `/admin/payment-methods`     | `payment_methods.view_list` | List all methods (raw)     |
| PATCH  | `/admin/payment-methods/:id` | `payment_methods.update`    | Enable/disable, edit label |

The 4 known methods (CASH, PAYME, CLICK, CARD_TERMINAL) are seeded; you toggle
and relabel them rather than creating arbitrary ones (each `code` is tied to
backend behavior).

**PATCH /admin/payment-methods/:id Body (all optional):**

```json
{
  "isEnabled": true,
  "nameI18n": { "ru": "Payme", "uz": "Payme", "en": "Payme" },
  "sortOrder": 2,
  "icon": "/uploads/payment/payme.png"
}
```

### Mobile App Versions

| Method | Endpoint                        | Permission               | Description               |
| ------ | ------------------------------- | ------------------------ | ------------------------- |
| GET    | `/admin/app-versions`           | `app_versions.view_list` | List iOS/Android settings |
| GET    | `/admin/app-versions/:platform` | `app_versions.view_list` | Get one platform setting  |
| PATCH  | `/admin/app-versions/:platform` | `app_versions.update`    | Update version policy     |

`:platform` is `ios` or `android`.

**PATCH /admin/app-versions/:platform Body (all optional):**

```json
{
  "latestVersion": "1.2.0",
  "minSupportedVersion": "1.1.0",
  "descriptionI18n": {
    "ru": "Доступна новая версия приложения.",
    "uz": "Ilovaning yangi versiyasi mavjud.",
    "en": "A new app version is available."
  },
  "appUrl": "https://apps.apple.com/app/enjoy-lavash"
}
```

`minSupportedVersion` cannot be greater than `latestVersion`. Use App Store URL
for `ios` and Play Store URL for `android`.

### Organisation Settings

| Method | Endpoint                                | Permission                     | Description                   |
| ------ | --------------------------------------- | ------------------------------ | ----------------------------- |
| GET    | `/admin/organisation/settings`          | `organisation.settings.view`   | Read organisation settings    |
| PATCH  | `/admin/organisation/settings/delivery` | `organisation.settings.update` | Update delivery tariff in UZS |

Delivery tariff amounts are whole UZS integers.

```json
{
  "basePrice": 10000,
  "includedKm": 2,
  "pricePerKm": 3000,
  "maxDistanceKm": 30,
  "freeDeliveryFrom": 150000
}
```

`maxDistanceKm` can be omitted or set to `null` to remove the maximum delivery
distance cap.

### Roles & Permissions

| Method | Endpoint       | Permission              | Description          |
| ------ | -------------- | ----------------------- | -------------------- |
| GET    | `/permissions` | `permissions.view_list` | List all permissions |
| POST   | `/roles`       | `roles.create`          | Create role          |
| PATCH  | `/roles/:id`   | `roles.update`          | Update role          |

### iiko Sync (if enabled)

| Method | Endpoint                        | Permission  | Description           |
| ------ | ------------------------------- | ----------- | --------------------- |
| POST   | `/admin/iiko/sync/nomenclature` | `iiko.sync` | Manual menu sync      |
| POST   | `/admin/iiko/sync/stop-lists`   | `iiko.sync` | Manual stop list sync |
| GET    | `/admin/iiko/sync/status`       | `iiko.sync` | Sync status           |
| GET    | `/admin/iiko/organizations`     | `iiko.sync` | iiko organizations    |

### File Upload

| Method | Endpoint        | Description                                      |
| ------ | --------------- | ------------------------------------------------ |
| POST   | `/files/upload` | Upload file (multipart/form-data, field: `file`) |

Returns `{ url: "/uploads/filename.jpg" }`.

---

## Payment Webhooks (server-to-server, not for the app)

### Payme Merchant API

```
POST /payments/payme
```

JSON-RPC endpoint for the Payme billing system. **Not called by the mobile app**
— configure this URL in your Payme merchant cabinet. Authenticated via Basic
auth using the selected branch cashbox key. Implements the standard methods:
`CheckPerformTransaction`, `CreateTransaction`, `PerformTransaction`,
`CancelTransaction`, `CheckTransaction`, `GetStatement`.

- The order is matched by the `order_id` account field.
- Branch credentials are resolved from the order/transaction branch; each branch
  has its own Payme merchant id and key.
- Amount is validated against `order.totalAmount * 100` (tiyin).
- On `PerformTransaction` the order becomes `paymentStatus: PAID` and is pushed
  to iiko. On `CancelTransaction` before payment it becomes
  `paymentStatus: FAILED` and can be retried. On `CancelTransaction` of a
  performed payment it becomes `REFUNDED` and the order is cancelled.

**Server env:** `PAYMENT_SECRET_ENCRYPTION_KEY`, `PAYME_CHECKOUT_URL`
(default `https://checkout.paycom.uz`), `PAYME_ACCOUNT_FIELD` (default
`order_id`), `PAYME_RETURN_URL` (optional),
`PAYMENT_ONLINE_TIMEOUT_MINUTES` (default `15`). `PAYME_MERCHANT_ID` and
`PAYME_KEY` remain a development fallback for in-memory mode; production branch
credentials are stored encrypted per branch.

---

## Error Responses

All errors follow NestJS format:

```json
{
  "statusCode": 400,
  "message": "Error description",
  "error": "Bad Request"
}
```

| Code | Meaning                       |
| ---- | ----------------------------- |
| 400  | Validation error or bad input |
| 401  | Missing/invalid/expired token |
| 403  | Insufficient permissions      |
| 404  | Resource not found            |

---

## Order Status Flow

```
Client creates order → NEW
Admin confirms       → CONFIRMED
Kitchen starts       → COOKING
Kitchen done         → READY
  ├── Pickup: Admin marks → DELIVERED
  └── Delivery:
      Courier assigned    → COURIER_ASSIGNED
      Courier picks up    → ON_THE_WAY
      Courier delivers    → DELIVERED

Any non-terminal status → CANCELLED (by admin or client)
```

---

## Tips for Frontend

1. **Language**: Pass `?lang=ru` or `Accept-Language: ru` header on catalog requests.
2. **Cart flow**: Call `POST /cart/preview` to show pricing before order creation.
3. **Delivery check**: Use `POST /delivery/preview` to check if address is deliverable and show delivery cost.
4. **Modifiers**: Required modifier groups (`isRequired: true`) must have at least `minSelect` items selected.
5. **Prices**: All API prices are whole UZS integers. Do not divide by 100 in the app; `32000` means 32,000 UZS. Payme is the only integration that converts order totals to tiyin internally.
6. **Images**: Prepend base URL to image paths (e.g., `http://localhost:3000/uploads/products/classic-lavash.jpg`).
7. **Swagger**: Full interactive docs at `/docs` with all request/response schemas.
