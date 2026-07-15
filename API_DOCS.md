# Enjoy Lavash API Documentation

**Base URL**: `http://localhost:3000`
**Swagger UI**: `http://localhost:3000/docs`
**Content-Type**: `application/json`

All money values are integers in UZS (e.g., `32000` = 32,000 UZS).
i18n text fields use `{ ru?: string, uz?: string, en?: string }` format.

---

## Authentication

### Client Auth (OTP-based for mobile app)

| Method | Endpoint               | Auth | Description                   |
| ------ | ---------------------- | ---- | ----------------------------- |
| POST   | `/auth/request-otp`    | -    | Request OTP code              |
| POST   | `/auth/verify-otp`     | -    | Verify OTP and get tokens     |
| POST   | `/auth/client/refresh` | -    | Refresh mobile client session |

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
The whitelist accepts comma, semicolon, or newline separated Uzbekistan phone numbers.

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
  "refresh_token": "W0H5...",
  "refresh_token_expires_at": "2026-08-07T12:00:00.000Z",
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

Mobile refresh tokens rotate. After every successful
`POST /auth/client/refresh`, replace the stored `access_token`,
`refresh_token`, and `refresh_token_expires_at`. See
[`MOBILE_CLIENT_AUTH.md`](./MOBILE_CLIENT_AUTH.md) for the mobile refresh
implementation notes and session lifetime settings.

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
{ "username": "owner", "password": "your-12-plus-character-password" }
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
session is active for 90 days by default unless `CLIENT_REFRESH_TTL_SECONDS`
overrides it.

### Verify OTP

```
POST /auth/verify-otp
```

Response 200 includes:

```json
{
  "access_token": "eyJhbG...",
  "refresh_token": "W0H5...",
  "refresh_token_expires_at": "2026-09-30T12:00:00.000Z",
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
stored tokens after every successful refresh. See
[`MOBILE_CLIENT_AUTH.md`](./MOBILE_CLIENT_AUTH.md) for mobile implementation
details and instructions for prolonging sessions.

On mobile, do not log the user out on the first `401` from an expired access
token. Call `/auth/client/refresh` once, persist the rotated tokens, and retry
the original request. If the app was rebuilt and secure storage still contains
the refresh token, it can refresh silently. If storage was wiped, request OTP
again for the same phone number.

After login or app startup, register the current push token with
`POST /clients/me/push-tokens` so notifications can be sent to the active
device. Active order checks should use the authenticated order endpoints
(`GET /clients/me/orders` or `GET /clients/me/orders/:id`); the OTP-verified
phone identity is already used by the backend to recover orders for the same
phone number.

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
  "promotionStatus": "APPLIED",
  "promotionDeliveryDiscountAmount": 0,
  "bonusItems": [],
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

`POST /cart/preview` is safe for anonymous website usage. It calculates public
and automatic promotions, but client-limited promo codes return
`promotionStatus: "CLIENT_REQUIRED"` instead of applying a discount. For logged
in mobile users, prefer `POST /clients/me/cart/preview` so the backend can check
per-client limits and "new client" rules.

For pickup preview, `branchId`, `iikoOrganizationId`, and
`iikoOrganisationId` use the same branch-selection semantics as order creation.
An iiko organization UUID may also be supplied in the legacy `organisationId`
field; when it identifies a branch, the backend resolves its local organisation
before pricing.

### Promotions

| Method | Endpoint             | Description            |
| ------ | -------------------- | ---------------------- |
| GET    | `/promotions/active` | List active promotions |

**GET /promotions/active Query params:**

| Param            | Required | Description                                                         |
| ---------------- | -------- | ------------------------------------------------------------------- |
| `organisationId` | no       | Organisation id. If omitted, backend uses the default organisation. |

**Body:** none.

**Response 200:**

```json
[
  {
    "id": "promo-free-delivery",
    "createdAt": "2026-07-09T10:00:00.000Z",
    "updatedAt": "2026-07-09T10:00:00.000Z",
    "deletedAt": null,
    "organisationId": "org-enjoy-lavash",
    "code": "FREEDEL",
    "titleI18n": {
      "ru": "Бесплатная доставка",
      "uz": "Bepul yetkazib berish",
      "en": "Free delivery"
    },
    "isActive": true,
    "startDate": null,
    "endDate": null,
    "usageLimit": null,
    "usageCount": 0,
    "conditions": {
      "autoApply": true,
      "minOrderAmount": 150000,
      "orderType": "DELIVERY"
    },
    "reward": {
      "type": "FREE_DELIVERY",
      "applyTo": "DELIVERY"
    }
  },
  {
    "id": "promo-appgift",
    "createdAt": "2026-07-09T10:00:00.000Z",
    "updatedAt": "2026-07-09T10:00:00.000Z",
    "deletedAt": null,
    "organisationId": "org-enjoy-lavash",
    "code": "APPGIFT",
    "titleI18n": {
      "ru": "Подарок в приложении",
      "uz": "Ilova sovg'asi",
      "en": "App gift"
    },
    "isActive": true,
    "startDate": "2026-07-01T00:00:00.000Z",
    "endDate": "2026-07-31T23:59:59.000Z",
    "usageLimit": 1000,
    "usageCount": 42,
    "conditions": {
      "autoApply": true,
      "sources": ["MOBILE_APP"],
      "minOrderAmount": 100000
    },
    "reward": {
      "type": "FREE_PRODUCT",
      "freeProductId": "prod-cola",
      "freeProductQuantity": 1,
      "applyTo": "PRODUCTS"
    }
  }
]
```

Only currently usable promotions are returned: active, inside date window, and
below global `usageLimit`. Client-specific limits are checked during cart
preview/order creation, not by this listing endpoint.

#### Promotion Result Fields

Every cart preview response includes:

| Field                             | Meaning                                                                                                                                                                                                    |
| --------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `promotionStatus`                 | Current promo result: `NONE`, `APPLIED`, `NOT_FOUND`, `INACTIVE`, `NOT_STARTED`, `EXPIRED`, `GLOBAL_LIMIT_REACHED`, `CLIENT_LIMIT_REACHED`, `CLIENT_REQUIRED`, `CONDITIONS_NOT_MET`, `CONFIGURATION_ERROR` |
| `promotionStatusReason`           | Human-readable reason for non-applied requested promo codes                                                                                                                                                |
| `appliedPromotion`                | Promotion object when `promotionStatus = "APPLIED"`                                                                                                                                                        |
| `discountAmount`                  | Discount subtracted from product/modifier amount                                                                                                                                                           |
| `promotionDeliveryDiscountAmount` | Delivery discount value, e.g. original delivery fee for free delivery                                                                                                                                      |
| `bonusItems`                      | Gift products added by a `FREE_PRODUCT` promotion                                                                                                                                                          |

Bonus products also appear inside `items` as normal order lines with
`isBonus: true`, `unitPrice: 0`, `totalPrice: 0`, `originalUnitPrice`,
`promotionId`, and `promotionCode`. Render them in the cart/order UI as gifts,
not as paid products.

Invalid or ineligible promo codes do not change the preview total. Order
creation rejects an explicitly requested unusable promo code with `400`, so the
app should call preview before creating the order.

#### Promotion Conditions

Admin-created promotions store flexible `conditions` JSON:

```ts
type PromotionConditions = {
  autoApply?: boolean; // true = can apply without promoCode
  minOrderAmount?: number; // product + modifier total, before delivery
  productIds?: string[];
  categoryIds?: string[];
  branchIds?: string[];
  orderType?: "DELIVERY" | "PICKUP";
  weekdays?: number[]; // 1=Monday ... 7=Sunday
  paymentMethods?: PaymentMethod[];
  sources?: ("MOBILE_APP" | "WEBSITE" | "ADMIN_PANEL")[];
  perClientUsageLimit?: number; // e.g. 2 or 3 uses per client/phone
  maxPreviousOrders?: number; // 0 = only clients with no prior valid orders
};
```

`sources: ["MOBILE_APP"]` targets orders created through
`POST /clients/me/orders`. `maxPreviousOrders` counts previous non-cancelled
orders for the same client/phone.

#### Promotion Rewards

```ts
type PromotionReward =
  | {
      type: "PERCENT";
      value: number;
      maxDiscountAmount?: number;
      applyTo: "ORDER";
    }
  | { type: "FIXED"; value: number; applyTo: "ORDER" }
  | { type: "FREE_DELIVERY"; applyTo: "DELIVERY" }
  | {
      type: "FREE_PRODUCT";
      freeProductId: string; // product id, slug, or iiko id
      freeProductQuantity?: number;
      applyTo: "PRODUCTS";
    };
```

Examples:

Automatic mobile gift:

```json
{
  "code": "APPGIFT",
  "titleI18n": {
    "ru": "Подарок в приложении",
    "uz": "Ilova sovg'asi",
    "en": "App gift"
  },
  "conditions": {
    "autoApply": true,
    "sources": ["MOBILE_APP"],
    "minOrderAmount": 100000
  },
  "reward": {
    "type": "FREE_PRODUCT",
    "freeProductId": "prod-cola",
    "freeProductQuantity": 1,
    "applyTo": "PRODUCTS"
  }
}
```

New-client promo code usable 3 times:

```json
{
  "code": "NEW3",
  "titleI18n": {
    "ru": "Для новых клиентов",
    "uz": "Yangi mijozlarga",
    "en": "New clients"
  },
  "conditions": {
    "perClientUsageLimit": 3,
    "maxPreviousOrders": 0
  },
  "reward": {
    "type": "PERCENT",
    "value": 20,
    "maxDiscountAmount": 30000,
    "applyTo": "ORDER"
  }
}
```

Threshold automatic discount:

```json
{
  "code": "BIGORDER",
  "titleI18n": {
    "ru": "Скидка за большой заказ",
    "uz": "Katta buyurtma chegirmasi",
    "en": "Big order discount"
  },
  "conditions": { "autoApply": true, "minOrderAmount": 200000 },
  "reward": { "type": "FIXED", "value": 25000, "applyTo": "ORDER" }
}
```

### Payment Methods

| Method | Endpoint           | Description                         |
| ------ | ------------------ | ----------------------------------- |
| GET    | `/payment-methods` | Enabled payment methods (localized) |

Use this to render the payment selector in the app. Only enabled methods are
returned, sorted by `sortOrder`. Pass `branchId` after branch selection;
`PAYME` and `CLICK` are returned only when the method is globally enabled and
that branch has enabled credentials for the provider.

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
  },
  {
    "id": "pm-click",
    "code": "CLICK",
    "name": "Click",
    "isOnline": true,
    "sortOrder": 3,
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

### Mobile Cart Preview

| Method | Endpoint                   | Description                                              |
| ------ | -------------------------- | -------------------------------------------------------- |
| POST   | `/clients/me/cart/preview` | Authenticated cart total with client-specific promotions |

Use the same body as `POST /cart/preview`. For delivery, this authenticated
endpoint also accepts `addressId` from `GET /clients/me/addresses` and resolves
its coordinates; when both `addressId` and inline `address` are present, the
saved address is used. The public `POST /cart/preview` endpoint still requires
inline address coordinates. The backend automatically uses the bearer token to
set `source: "MOBILE_APP"`, `clientId`, client phone, and previous non-cancelled
order count. Use this endpoint before order creation for:

- promo codes with `perClientUsageLimit`
- "new client" rules using `maxPreviousOrders`
- app-only promotions using `sources: ["MOBILE_APP"]`

Response shape is the same as public cart preview. If the user has already used
a code too many times:

```json
{
  "promotionStatus": "CLIENT_LIMIT_REACHED",
  "promotionStatusReason": "Client promotion usage limit was reached",
  "discountAmount": 0,
  "bonusItems": []
}
```

If a promo adds a gift product:

```json
{
  "promotionStatus": "APPLIED",
  "appliedPromotion": { "code": "APPGIFT", "...": "..." },
  "bonusItems": [
    {
      "productId": "prod-cola",
      "quantity": 1,
      "unitPrice": 0,
      "originalUnitPrice": 12000,
      "totalPrice": 0,
      "isBonus": true,
      "promotionCode": "APPGIFT"
    }
  ],
  "items": [
    { "productId": "prod-classic-lavash", "quantity": 2, "...": "..." },
    {
      "productId": "prod-cola",
      "quantity": 1,
      "unitPrice": 0,
      "isBonus": true,
      "...": "..."
    }
  ]
}
```

### Orders

| Method | Endpoint                               | Description          |
| ------ | -------------------------------------- | -------------------- |
| GET    | `/clients/me/orders`                   | List my orders       |
| GET    | `/clients/me/orders/:id`               | Get order detail     |
| POST   | `/clients/me/orders`                   | Create order         |
| POST   | `/clients/me/orders/:id/retry-payment` | Retry online payment |
| POST   | `/clients/me/orders/:id/cancel`        | Cancel order         |

**POST /clients/me/orders Body:**

Delivery using a saved client address:

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

Delivery using only map coordinates:

```json
{
  "type": "DELIVERY",
  "branchId": "branch-chilanzar",
  "items": [{ "productId": "prod-classic-lavash", "quantity": 1 }],
  "address": {
    "latitude": 41.3111,
    "longitude": 69.2797
  },
  "paymentMethod": "CASH"
}
```

Pickup:

```json
{
  "type": "PICKUP",
  "branchId": "branch-chilanzar",
  "items": [{ "productId": "prod-classic-lavash", "quantity": 1 }],
  "paymentMethod": "CASH"
}
```

Promo handling:

- Call cart preview first and display `promotionStatus`.
- If `promoCode` is sent to order creation and is not still applicable, the
  backend returns `400` and does not create the order.
- Automatic promotions are recalculated during order creation; if conditions no
  longer match, the order is created without that automatic promotion.
- Gift products from `FREE_PRODUCT` promotions are saved in `items` with
  `isBonus: true`, `unitPrice: 0`, and `totalPrice: 0`.

For `DELIVERY`, prefer `addressId` from `GET /clients/me/addresses`. The
backend resolves the saved address coordinates before pricing and stores an order
snapshot of `deliveryAddressLabel`, `deliveryAddressText`, `deliveryLatitude`,
and `deliveryLongitude`. That saved street/house/apartment data is also sent to
iiko. If the request sends only `address: { latitude, longitude }`, the backend
can price and create the delivery, but it can send only coordinates to iiko
because no street/house fields exist in the request.

For `PICKUP`, send `branchId`. For iiko-backed branches, the app may send
`iikoOrganizationId` or `iikoOrganisationId` instead; the backend treats that as
the selected branch id. Do not send `addressId` or `address` for pickup.

Admin/POS order creation uses the same shape at `POST /admin/orders`. If an
admin creates delivery for a known client, send both `clientId` and `addressId`
so the backend can validate ownership and send the saved delivery address to
iiko.

If iiko is enabled, order creation stores the order locally with status `NEW`.
Offline payment orders are pushed to iiko after local creation. Online payment
orders are pushed only after the payment webhook marks the order paid. The
response includes `iikoOrderId` after iiko accepts the order; otherwise it is
`null`. If iiko returns `errorInfo`, the backend logs the iiko error and keeps
`iikoOrderId: null`.

For iiko delivery, the backend uses the iiko delivery API
`/api/1/deliveries/create` and sends a `deliveryPoint`. If no saved address or
coordinates are available, the backend does not send the order to iiko because
iiko would receive a delivery without an address. Set
`IIKO_DELIVERY_ORDER_TYPE_ID` only when the organization requires a specific
courier-delivery order type.

For iiko pickup, the backend uses the delivery API
`/api/1/deliveries/create` without a `deliveryPoint` and sends
`orderServiceType: DeliveryByClient` and `createOrderSettings.servicePrint:
true`. Because the current public delivery-create schema does not document
`servicePrint`, the backend also requests the pickup bill through the supported
`/api/1/deliveries/print_delivery_bill` command after iiko accepts the order.
`IIKO_TRANSPORT_TO_FRONT_TIMEOUT_SECONDS` and `IIKO_CHECK_STOP_LIST` can
override the default `30` seconds / `true` values used for transporting the
order to the terminal.

When a promotion produces `discountAmount > 0`, the backend sends the same
amount to iiko in `discountsInfo` as an RMS flexible-sum discount. Set
`IIKO_DISCOUNT_TYPE_ID` to pin the iiko discount type. If it is not configured,
the backend loads `/api/1/discounts` and selects the first non-deleted manual
`FlexibleSum` discount that is not a surcharge. If no suitable type exists, the
iiko push fails instead of creating an order whose full-price items disagree
with its discounted payment total.

**Online payment (Payme / Click):** when `paymentMethod` is an online method, the
created-order response includes a `paymentUrl`. Open it (in-app browser /
redirect) to let the user pay. The order is created with
`paymentStatus: PENDING` and is sent to iiko only after the provider confirms payment.
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

If Payme or Click fails, or the user abandons checkout, call
`POST /clients/me/orders/:id/retry-payment` while the order is active. The
backend allows at most two online attempts. If the online payment window expires
without payment, the order is converted to `paymentMethod: CASH` instead of
being cancelled.

`PAYME` and `CLICK` are hidden from `/payment-methods?branchId=...` when the
branch has no enabled config for that provider. Creating an online order for an
unconfigured branch returns an error.

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

### PromotionRewardType

```
PERCENT | FIXED | FREE_DELIVERY | FREE_PRODUCT
```

### PromotionSource

```
MOBILE_APP | WEBSITE | ADMIN_PANEL
```

### PromotionApplicationStatus

```
NONE | APPLIED | NOT_FOUND | INACTIVE | NOT_STARTED | EXPIRED |
GLOBAL_LIMIT_REACHED | CLIENT_LIMIT_REACHED | CLIENT_REQUIRED |
CONDITIONS_NOT_MET | CONFIGURATION_ERROR
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

| Method | Endpoint                           | Permission           | Description                 |
| ------ | ---------------------------------- | -------------------- | --------------------------- |
| GET    | `/admin/branches`                  | `branches.view_list` | List branches               |
| GET    | `/admin/branches/:id`              | `branches.view_list` | Get branch                  |
| POST   | `/admin/branches`                  | `branches.create`    | Create branch               |
| PATCH  | `/admin/branches/:id`              | `branches.update`    | Update branch               |
| DELETE | `/admin/branches/:id`              | `branches.delete`    | Delete branch               |
| PATCH  | `/admin/branches/:id/availability` | `branches.update`    | Update product availability |

Branch create/update accepts optional Payme and Click config:

```json
{
  "payme": {
    "merchantId": "payme-cashbox-id-branch-1",
    "key": "cashbox-secret",
    "isEnabled": true
  },
  "click": {
    "merchantId": "click-merchant-id",
    "serviceId": "click-service-id",
    "merchantUserId": "click-merchant-user-id",
    "secretKey": "click-secret",
    "isEnabled": true
  }
}
```

The raw Payme `key` and Click `secretKey` are encrypted before storage and are never returned. Responses
include safe metadata only: `configured`, `isEnabled`, `merchantId`, and
`keyPreview`; Click responses also include `serviceId` and `merchantUserId`.
For Payme, `merchantId` is the cashbox/web-cash id used in checkout links. For
Click, `merchantId` and `serviceId` are used in checkout links and callbacks,
and `merchantUserId` is stored for future Merchant API status/reversal calls.

### Promotions

| Method | Endpoint                | Permission             | Description         |
| ------ | ----------------------- | ---------------------- | ------------------- |
| GET    | `/admin/promotions`     | `promotions.view_list` | List all promotions |
| POST   | `/admin/promotions`     | `promotions.create`    | Create promotion    |
| PATCH  | `/admin/promotions/:id` | `promotions.update`    | Update promotion    |
| DELETE | `/admin/promotions/:id` | `promotions.delete`    | Delete promotion    |

#### GET /admin/promotions

List all non-deleted promotions. This endpoint is for the admin panel table.

**Query params:**

| Param            | Required | Description                                                                              |
| ---------------- | -------- | ---------------------------------------------------------------------------------------- |
| `organisationId` | no       | Filter by organisation id. If omitted, returns all organisations visible to the backend. |

**Body:** none.

**Response 200:**

```json
[
  {
    "id": "promo-new3",
    "createdAt": "2026-07-09T10:00:00.000Z",
    "updatedAt": "2026-07-09T10:00:00.000Z",
    "deletedAt": null,
    "organisationId": "org-enjoy-lavash",
    "code": "NEW3",
    "titleI18n": {
      "ru": "Для новых клиентов",
      "uz": "Yangi mijozlarga",
      "en": "New clients"
    },
    "isActive": true,
    "startDate": null,
    "endDate": null,
    "usageLimit": 500,
    "usageCount": 18,
    "conditions": {
      "perClientUsageLimit": 3,
      "maxPreviousOrders": 0
    },
    "reward": {
      "type": "PERCENT",
      "value": 20,
      "maxDiscountAmount": 30000,
      "applyTo": "ORDER"
    }
  }
]
```

#### POST /admin/promotions

Create a promotion. `code` is normalized to uppercase.

**Body:**

```json
{
  "organisationId": "org-enjoy-lavash",
  "code": "NEW3",
  "titleI18n": {
    "ru": "Для новых клиентов",
    "uz": "Yangi mijozlarga",
    "en": "New clients"
  },
  "isActive": true,
  "startDate": null,
  "endDate": "2026-08-31T23:59:59.000Z",
  "usageLimit": 500,
  "conditions": {
    "perClientUsageLimit": 3,
    "maxPreviousOrders": 0,
    "minOrderAmount": 50000,
    "sources": ["MOBILE_APP", "WEBSITE"]
  },
  "reward": {
    "type": "PERCENT",
    "value": 20,
    "maxDiscountAmount": 30000,
    "applyTo": "ORDER"
  }
}
```

**Alternative legacy body:**

```json
{
  "code": "SAVE15000",
  "titleI18n": {
    "ru": "Скидка 15 000",
    "uz": "15 000 chegirma",
    "en": "15,000 off"
  },
  "conditions": { "minOrderAmount": 100000 },
  "rewardType": "FIXED",
  "value": 15000
}
```

**Response 201:**

```json
{
  "id": "promo-new3",
  "createdAt": "2026-07-09T10:00:00.000Z",
  "updatedAt": "2026-07-09T10:00:00.000Z",
  "deletedAt": null,
  "organisationId": "org-enjoy-lavash",
  "code": "NEW3",
  "titleI18n": {
    "ru": "Для новых клиентов",
    "uz": "Yangi mijozlarga",
    "en": "New clients"
  },
  "isActive": true,
  "startDate": null,
  "endDate": "2026-08-31T23:59:59.000Z",
  "usageLimit": 500,
  "usageCount": 0,
  "conditions": {
    "perClientUsageLimit": 3,
    "maxPreviousOrders": 0,
    "minOrderAmount": 50000,
    "sources": ["MOBILE_APP", "WEBSITE"]
  },
  "reward": {
    "type": "PERCENT",
    "value": 20,
    "maxDiscountAmount": 30000,
    "applyTo": "ORDER"
  }
}
```

**Common 400 errors:**

```json
{ "message": "code is required", "statusCode": 400 }
```

```json
{ "message": "rewardType is required", "statusCode": 400 }
```

#### PATCH /admin/promotions/:id

Update a promotion. Body is partial; send only changed fields. When changing the
reward, send the full new `reward` object or the legacy flattened reward fields.

**Body:**

```json
{
  "isActive": false,
  "endDate": "2026-07-31T23:59:59.000Z"
}
```

**Body changing reward and conditions:**

```json
{
  "conditions": {
    "autoApply": true,
    "sources": ["MOBILE_APP"],
    "minOrderAmount": 120000
  },
  "reward": {
    "type": "FREE_PRODUCT",
    "freeProductId": "prod-cola",
    "freeProductQuantity": 1,
    "applyTo": "PRODUCTS"
  }
}
```

**Response 200:**

```json
{
  "id": "promo-appgift",
  "createdAt": "2026-07-09T10:00:00.000Z",
  "updatedAt": "2026-07-09T12:30:00.000Z",
  "deletedAt": null,
  "organisationId": "org-enjoy-lavash",
  "code": "APPGIFT",
  "titleI18n": {
    "ru": "Подарок в приложении",
    "uz": "Ilova sovg'asi",
    "en": "App gift"
  },
  "isActive": true,
  "startDate": null,
  "endDate": null,
  "usageLimit": null,
  "usageCount": 42,
  "conditions": {
    "autoApply": true,
    "sources": ["MOBILE_APP"],
    "minOrderAmount": 120000
  },
  "reward": {
    "type": "FREE_PRODUCT",
    "freeProductId": "prod-cola",
    "freeProductQuantity": 1,
    "applyTo": "PRODUCTS"
  }
}
```

**404 response:**

```json
{ "message": "Promotion not found", "statusCode": 404 }
```

#### DELETE /admin/promotions/:id

Soft-delete a promotion. Deleted promotions no longer appear in lists and cannot
be applied to carts.

**Body:** none.

**Response 200:**

```json
{
  "id": "promo-appgift",
  "createdAt": "2026-07-09T10:00:00.000Z",
  "updatedAt": "2026-07-09T12:45:00.000Z",
  "deletedAt": "2026-07-09T12:45:00.000Z",
  "organisationId": "org-enjoy-lavash",
  "code": "APPGIFT",
  "titleI18n": {
    "ru": "Подарок в приложении",
    "uz": "Ilova sovg'asi",
    "en": "App gift"
  },
  "isActive": true,
  "startDate": null,
  "endDate": null,
  "usageLimit": null,
  "usageCount": 42,
  "conditions": {
    "autoApply": true,
    "sources": ["MOBILE_APP"],
    "minOrderAmount": 120000
  },
  "reward": {
    "type": "FREE_PRODUCT",
    "freeProductId": "prod-cola",
    "freeProductQuantity": 1,
    "applyTo": "PRODUCTS"
  }
}
```

Admin panel form guidance:

| UI field                | API field                                                    |
| ----------------------- | ------------------------------------------------------------ |
| Code                    | `code`, uppercase is applied by backend                      |
| Name/title              | `titleI18n`                                                  |
| Active toggle           | `isActive`                                                   |
| Start/end date          | `startDate`, `endDate` ISO strings or `null`                 |
| Global usage limit      | `usageLimit`                                                 |
| Auto apply without code | `conditions.autoApply`                                       |
| Minimum cart amount     | `conditions.minOrderAmount`                                  |
| Order source            | `conditions.sources`: `MOBILE_APP`, `WEBSITE`, `ADMIN_PANEL` |
| Per-client uses         | `conditions.perClientUsageLimit`                             |
| New-client rule         | `conditions.maxPreviousOrders`                               |
| Reward type             | `reward.type`                                                |

Create/update can send either a full `reward` object or legacy flattened fields
(`rewardType`, `value`, `maxDiscountAmount`, `freeProductId`,
`freeProductQuantity`). Prefer full `reward` for the admin panel because it is
clearer and supports all reward types.

**Create fixed discount code:**

```json
{
  "organisationId": "org-enjoy-lavash",
  "code": "SAVE15000",
  "titleI18n": {
    "ru": "Скидка 15 000",
    "uz": "15 000 chegirma",
    "en": "15,000 off"
  },
  "isActive": true,
  "usageLimit": 500,
  "conditions": {
    "minOrderAmount": 100000,
    "perClientUsageLimit": 2
  },
  "reward": {
    "type": "FIXED",
    "value": 15000,
    "applyTo": "ORDER"
  }
}
```

**Create automatic mobile app gift:**

```json
{
  "code": "APPGIFT",
  "titleI18n": {
    "ru": "Подарок в приложении",
    "uz": "Ilova sovg'asi",
    "en": "App gift"
  },
  "isActive": true,
  "conditions": {
    "autoApply": true,
    "sources": ["MOBILE_APP"],
    "minOrderAmount": 100000
  },
  "reward": {
    "type": "FREE_PRODUCT",
    "freeProductId": "prod-cola",
    "freeProductQuantity": 1,
    "applyTo": "PRODUCTS"
  }
}
```

**Create new-client promo code usable 3 times:**

```json
{
  "code": "NEW3",
  "titleI18n": {
    "ru": "Для новых клиентов",
    "uz": "Yangi mijozlarga",
    "en": "New clients"
  },
  "conditions": {
    "perClientUsageLimit": 3,
    "maxPreviousOrders": 0
  },
  "reward": {
    "type": "PERCENT",
    "value": 20,
    "maxDiscountAmount": 30000,
    "applyTo": "ORDER"
  }
}
```

Admin panel should show `usageCount` as global uses. Per-client usage is enforced
server-side through promotion usage records and does not require frontend
bookkeeping.

### Reports

| Method | Endpoint                    | Permission              | Description     |
| ------ | --------------------------- | ----------------------- | --------------- |
| GET    | `/admin/reports/sales`      | `reports.sales.view`    | Sales summary   |
| GET    | `/admin/reports/products`   | `reports.products.view` | Product stats   |
| GET    | `/admin/reports/promotions` | `reports.sales.view`    | Promotion usage |
| GET    | `/admin/reports/branches`   | `reports.sales.view`    | Branch stats    |

**GET /admin/reports/promotions Response:**

```json
[
  {
    "promoCode": "APPGIFT",
    "promotionId": "promo-appgift",
    "ordersCount": 42,
    "discountAmount": 0,
    "deliveryDiscountAmount": 0,
    "bonusItemsQuantity": 42,
    "totalBenefitAmount": 504000
  },
  {
    "promoCode": "NEW3",
    "promotionId": "promo-new3",
    "ordersCount": 18,
    "discountAmount": 420000,
    "deliveryDiscountAmount": 0,
    "bonusItemsQuantity": 0,
    "totalBenefitAmount": 420000
  }
]
```

`ordersCount` counts created orders that consumed the promotion. This matches
promo-code limit enforcement. It is not reduced by later cancellation/refund in
the first version.

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

Full Payme architecture, setup, and troubleshooting notes are in
[`PAYME_INTEGRATION.md`](./PAYME_INTEGRATION.md).

### Payme Merchant API

```
POST /payments/payme
```

JSON-RPC endpoint for the Payme billing system. **Not called by the mobile app**
— configure this URL in your Payme merchant cabinet. Implements the standard
methods: `CheckPerformTransaction`, `CreateTransaction`, `PerformTransaction`,
`CancelTransaction`, `CheckTransaction`, `GetStatement`.

Auth supported by the webhook:

- Merchant API Basic auth only:
  `Authorization: Basic <base64(<login>:<cashbox_key>)>`.
- `login` is the Merchant API login provided by Payme Business. The default is
  `Paycom`; set `PAYME_MERCHANT_LOGIN` if Payme gives another login.
- `cashbox_key` is the branch Payme key/password stored in the encrypted branch
  Payme config.
- `X-Auth` is for Subscribe API calls and is not accepted by this Merchant API
  webhook.

- The order is matched by the `order_num` account field. During rollout, the
  webhook also accepts the old `order_id` field from previously generated
  checkout links.
- The Payme web-cash/cashbox account field in the merchant cabinet must also be
  named `order_num`; checkout URL params and cabinet settings must match.
- Payme may send Merchant API requests with `Content-Type: text/json`; the
  webhook accepts that content type and returns `text/json; charset=utf-8`.
- Branch credentials are resolved from the order/transaction branch; each branch
  has its own Payme merchant id and key.
- Amount is validated against `order.totalAmount * 100` (tiyin).
- On `PerformTransaction` the order becomes `paymentStatus: PAID` and is pushed
  to iiko. On `CancelTransaction` before payment it becomes
  `paymentStatus: FAILED` and can be retried. On `CancelTransaction` of a
  performed payment it becomes `REFUNDED` and the order is cancelled.

**Server env:** `PAYMENT_SECRET_ENCRYPTION_KEY`, `PAYME_MERCHANT_LOGIN`
(default `Paycom`), `PAYME_CHECKOUT_URL` (default
`https://checkout.paycom.uz`), `PAYME_ACCOUNT_FIELD` (default `order_num`),
`PAYME_RETURN_URL` (optional),
`PAYMENT_ONLINE_TIMEOUT_MINUTES` (default `15`). `PAYME_MERCHANT_ID` and
`PAYME_KEY` remain a development fallback for in-memory mode; production branch
credentials are stored encrypted per branch.

### Click Shop API

```
POST /payments/click
```

Form-urlencoded endpoint for Click callbacks. **Not called by the mobile app**
— configure this URL in the Click merchant cabinet. The endpoint returns JSON
and implements:

- `action=0` Prepare
- `action=1` Complete

Important callback fields:

- `merchant_trans_id` must be the local payment attempt id generated in the
  Click checkout URL as `transaction_param`.
- `merchant_prepare_id` on Complete must match the attempt number returned by
  Prepare.
- `service_id`, `amount`, and `sign_string` are validated against the branch
  Click config and order total.
- Amount is validated in UZS with two decimal places; Payme remains in tiyin.

Click callbacks return Click error codes consistently: `0`, `-1`, `-2`, `-3`,
`-4`, `-5`, `-6`, `-8`, `-9`.

On successful Complete the order becomes `paymentStatus: PAID` and is pushed to
iiko. If Click sends a negative Complete error, the attempt is marked failed and
the order can be retried while the retry window allows it. Merchant-initiated
Click reversal/status calls are not sent by this backend yet.

**Server env:** `PAYMENT_SECRET_ENCRYPTION_KEY`, `CLICK_CHECKOUT_URL` (default
`https://my.click.uz/services/pay/`), `CLICK_RETURN_URL` (optional),
`PAYMENT_ONLINE_TIMEOUT_MINUTES` (default `15`). `CLICK_MERCHANT_ID`,
`CLICK_SERVICE_ID`, `CLICK_SECRET_KEY`, and `CLICK_MERCHANT_USER_ID` remain a
development fallback for in-memory mode; production branch credentials are
stored encrypted per branch.

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
5. **Prices**: All API prices are whole UZS integers. Do not divide by 100 in the app; `32000` means 32,000 UZS. Payme converts order totals to tiyin internally; Click sends UZS with two decimal places.
6. **Images**: Prepend base URL to image paths (e.g., `http://localhost:3000/uploads/products/classic-lavash.jpg`).
7. **Swagger**: Full interactive docs at `/docs` with all request/response schemas.
