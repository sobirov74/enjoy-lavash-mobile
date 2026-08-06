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

| Method | Endpoint                        | Description                              |
| ------ | ------------------------------- | ---------------------------------------- |
| GET    | `/branches`                     | List active branches                     |
| GET    | `/branches/:id`                 | Get single branch                        |
| GET    | `/branches/:id/working-hours`   | Configured branch working-hour overrides |
| GET    | `/branches/:id/ordering-status` | Effective schedule and availability      |

`ordering-status` accepts an optional ISO `at` query. It returns the effective
seven-day schedule (branch override, organisation default, or 24-hour fallback),
the organisation timezone, independent pickup/delivery availability, closure
source, and the next opening as a UTC ISO timestamp. Admin-only day-off reasons
are never exposed by this public endpoint.

For customer-app usage, see the
[Mobile working hours and ordering guide](docs/MOBILE_WORKING_HOURS_AND_ORDERING.md).

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
  "deliveryDistanceSource": "ROAD",
  "deliveryAmount": 10000
}
```

`deliveryDistanceMeters` is the length of the recommended drivable route from
the branch to the client. `deliveryDistanceSource` is `ROAD` when the private
OSRM service supplied the road matrix, either for this request or from the
backend's short-lived in-memory cache (five minutes by default). Only successful
road matrices are cached, including valid no-route results. Straight-line
fallbacks, timeouts, and malformed OSRM responses are not cached, so a later
request retries OSRM. If OSRM is temporarily unavailable, the backend keeps
checkout working with a straight-line estimate and returns
`STRAIGHT_LINE_FALLBACK`. A branch that has no drivable route is not considered
deliverable.

The cache avoids a duplicate OSRM request when preview and order creation use
the same destination and the same ordered set of eligible branch coordinates,
normalized to five decimal places. This changes no HTTP request or response
fields. It does not cache delivery pricing: branch eligibility, delivery
tariffs, promotions, and order totals are recalculated for every preview and
order-creation request.

Optional server configuration:

```env
# Successful road matrices remain cached for 5 minutes; 0 disables this cache.
OSRM_CACHE_TTL_MS=300000
# Maximum completed road matrices held by each API process.
OSRM_CACHE_MAX_ENTRIES=2000
```

Concurrent identical lookups are still combined into one OSRM request when the
completed-result cache is disabled. Each backend process owns its own bounded
cache; it is not shared with OSRM itself or with another project that calls OSRM
directly. Backend-to-backend access, TypeScript examples, courier duration
matrices, and route geometry are documented in
[`ops/osrm/CLIENT_INTEGRATION.md`](ops/osrm/CLIENT_INTEGRATION.md).

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
  "paymentMethod": "CASH",
  "scheduledFor": "2026-08-10T12:30:00.000Z"
}
```

**Response 200:**

```json
{
  "organisationId": "org-enjoy-lavash",
  "branchId": "branch-chilanzar",
  "deliveryDistanceMeters": 2150,
  "deliveryDistanceSource": "ROAD",
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

For pickup carts, `deliveryDistanceSource` is omitted. Delivery orders persist
the source used during final order pricing, so order responses expose the same
optional field.

Frontend routing behavior:

- Use delivery or cart preview to show whether the selected coordinates are
  deliverable, the road distance, and the current delivery fee.
- Send the same coordinates (or the same saved `addressId`) when creating the
  order. Treat the created order's branch, distance source, and totals as
  authoritative because availability, tariffs, and promotions can change after
  preview.
- Do not call OSRM directly from a web or mobile client; it is private backend
  infrastructure. `STRAIGHT_LINE_FALLBACK` may be shown as an estimated
  distance without blocking checkout.
- Keep `© OpenStreetMap contributors` visible wherever OpenStreetMap-derived
  map or routing information is presented, following the
  [OpenStreetMap attribution guidelines](https://osmfoundation.org/wiki/Licence/Attribution_Guidelines).

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

Immediate previews and orders require the selected branch to be open now.
Scheduled previews and orders require it to be open both now and at
`scheduledFor`. Delivery auto-selection excludes branches closed at either
required time. A closed request returns HTTP `409` with
`errorCode: "ORDERING_CLOSED"` and public metadata containing the branch,
order type, `CURRENT` or `SCHEDULED` check, timezone, closure source, and next
opening. Existing-order payment retries, provider callbacks, completion,
cancellation, and refunds do not perform this schedule check.

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
  orderType?: 'DELIVERY' | 'PICKUP';
  weekdays?: number[]; // 1=Monday ... 7=Sunday
  paymentMethods?: PaymentMethod[];
  sources?: ('MOBILE_APP' | 'WEBSITE' | 'ADMIN_PANEL')[];
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
      type: 'PERCENT';
      value: number;
      maxDiscountAmount?: number;
      applyTo: 'ORDER';
    }
  | { type: 'FIXED'; value: number; applyTo: 'ORDER' }
  | { type: 'FREE_DELIVERY'; applyTo: 'DELIVERY' }
  | {
      type: 'FREE_PRODUCT';
      freeProductId: string; // product id, slug, or iiko id
      freeProductQuantity?: number;
      applyTo: 'PRODUCTS';
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

Order creation is the authoritative pricing step. It recalculates branch
eligibility, the current delivery tariff, promotions, and the final total. When
the coordinates match a recent preview, it may reuse only that preview's
successful cached OSRM road matrix; it never reuses the preview's calculated
price or promotion result. A previous `STRAIGHT_LINE_FALLBACK` is not cached,
so order creation attempts OSRM again.

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
iiko. Admin orders may also send `clientPhoneNumber`. The backend normalizes a
valid Uzbekistan phone to `+998XXXXXXXXX`, assigns the order to an existing
client with that phone when one exists, stores the normalized phone on the
order, and sends it to iiko.

See the standalone
[Admin Order Creation API guide](docs/ADMIN_ORDER_CREATION_API.md) for complete
pickup/delivery bodies and request/response TypeScript definitions.

If iiko is enabled, order creation stores the order locally with status `NEW`.
Offline payment orders are pushed to iiko after local creation. Online payment
orders are pushed only after the payment webhook marks the order paid. The
response includes `iikoOrderId` after iiko accepts the order; otherwise it is
`null`. If iiko returns `errorInfo`, the backend logs the iiko error and keeps
`iikoOrderId: null`.

Admin order responses also include `iikoDispatch`, an admin-only diagnostic
object. Client/mobile order endpoints keep the existing public shape and do not
expose IIKO retry errors or correlation data. See
[`FRONTEND_IIKO_PAYMENT_DISPATCH.md`](FRONTEND_IIKO_PAYMENT_DISPATCH.md) for
frontend labels, colors, polling rules, and examples.

For iiko delivery, the backend uses the iiko delivery API
`/api/1/deliveries/create` and sends a `deliveryPoint`. If no saved address or
coordinates are available, the backend does not send the order to iiko because
iiko would receive a delivery without an address. Set
`IIKO_DELIVERY_ORDER_TYPE_ID` only when the organization requires a specific
courier-delivery order type.

Delivery fees must be represented by a dedicated product on the iiko check.
Create that product in iiko and set its UUID as
`IIKO_DELIVERY_FEE_PRODUCT_ID`. For delivery orders with
`deliveryAmount > 0`, the backend adds one item using that product and overrides
its price with the calculated delivery amount. If the setting is absent, the
iiko push fails instead of sending a full payment against a lower check total,
which iiko would print as customer change.

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
being cancelled, queued to iiko as cash, and the client receives a transactional
push. A reminder push is sent before expiry. Defaults:
`PAYMENT_ONLINE_TIMEOUT_MINUTES=15` and `PAYMENT_REMINDER_LEAD_MINUTES=5`.

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
| POST   | `/admin/orders/:id/iiko/check`     | `order_view_list`      | Refresh IIKO state  |
| POST   | `/admin/orders/:id/iiko/retry`     | `order_update_status`  | Retry IIKO push     |
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

| Method | Endpoint                             | Permission           | Description                        |
| ------ | ------------------------------------ | -------------------- | ---------------------------------- |
| GET    | `/admin/branches`                    | `branches.view_list` | List branches                      |
| GET    | `/admin/branches/:id`                | `branches.view_list` | Get branch                         |
| POST   | `/admin/branches`                    | `branches.create`    | Create branch                      |
| PATCH  | `/admin/branches/:id`                | `branches.update`    | Update branch                      |
| DELETE | `/admin/branches/:id`                | `branches.delete`    | Delete branch                      |
| PATCH  | `/admin/branches/:id/availability`   | `branches.update`    | Update product availability        |
| GET    | `/admin/branches/:id/working-hours`  | `branches.view_list` | Read overrides and effective hours |
| PUT    | `/admin/branches/:id/working-hours`  | `branches.update`    | Replace all branch overrides       |
| GET    | `/admin/branches/:id/day-offs`       | `branches.view_list` | List dated overrides               |
| PUT    | `/admin/branches/:id/day-offs/:date` | `branches.update`    | Close or reopen one local date     |
| DELETE | `/admin/branches/:id/day-offs/:date` | `branches.update`    | Delete one dated override          |

Branch create/update accepts optional Payme, Click, and Telegram order
notification config:

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
  },
  "telegram": {
    "groupId": "-1001234567890",
    "topicId": 42,
    "botToken": "123456789:AAExampleTelegramBotToken"
  }
}
```

The raw Payme `key` and Click `secretKey` are encrypted before storage and are never returned. Responses
include safe metadata only: `configured`, `isEnabled`, `merchantId`, and
`keyPreview`; Click responses also include `serviceId` and `merchantUserId`.
For Payme, `merchantId` is the cashbox/web-cash id used in checkout links. For
Click, `merchantId` and `serviceId` are used in checkout links and callbacks,
and `merchantUserId` is stored for future Merchant API status/reversal calls.
The raw Telegram `botToken` is also encrypted before storage and is never
returned. Admin branch responses include only `telegram.configured`,
`telegram.groupId`, `telegram.topicId`, and `telegram.botTokenPreview`; public
`GET /branches` and `GET /branches/:id` responses do not expose Telegram config.

When a branch has both `telegram.groupId` and `telegram.botToken` configured,
new orders for that branch are sent to the Telegram group. If `topicId` is set,
the backend sends it as Telegram `message_thread_id`. Delivery orders send the
order text first and then a Telegram location message when delivery coordinates
exist. Configure `TELEGRAM_SECRET_ENCRYPTION_KEY` for production token
encryption; if omitted, the backend falls back to `PAYMENT_SECRET_ENCRYPTION_KEY`.
See `FRONTEND_ORDER_TELEGRAM_NOTIFICATIONS.md` for frontend/admin examples and
the notification text format.

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

Frontend integration details and TypeScript contracts are in
[`FRONTEND_REPORTS.md`](./FRONTEND_REPORTS.md).

| Method | Endpoint                  | Permission              | Description                         |
| ------ | ------------------------- | ----------------------- | ----------------------------------- |
| GET    | `/admin/reports/sales`    | `reports.sales.view`    | Filtered sales summary              |
| GET    | `/admin/reports/products` | `reports.products.view` | Filtered product sales              |
| GET    | `/admin/reports/branches` | `reports.sales.view`    | Filtered branch sales               |
| GET    | `/admin/reports/clients`  | `reports.clients.view`  | Client accounts and purchaser stats |

All four endpoints require an admin bearer token. The backend takes the
organisation from the authenticated user; do not send `organisationId` from the
frontend.

#### Shared date and branch query

| Query       | Required | Format       | Meaning                                    |
| ----------- | -------- | ------------ | ------------------------------------------ |
| `startDate` | Yes      | `YYYY-MM-DD` | First included calendar date               |
| `endDate`   | Yes      | `YYYY-MM-DD` | Last included calendar date                |
| `branchId`  | No       | Branch ID    | One branch; omit to report on all branches |

Dates are interpreted as calendar dates in `Asia/Tashkent`. Both dates are
inclusive: the backend applies a half-open interval from the start of
`startDate` through the start of the day after `endDate`. Send date-only values
without a time or UTC offset. Using the same value for both dates requests one
calendar day.

```http
GET /admin/reports/sales?startDate=2026-07-01&endDate=2026-07-31
GET /admin/reports/clients?startDate=2026-07-01&endDate=2026-07-31&branchId=0ed21b6c-bdb2-40df-8c41-31444cc41b8a
Authorization: Bearer <access_token>
```

Missing dates, malformed dates, impossible calendar dates, and an `endDate`
before `startDate` return `400`. An unknown branch or a branch owned by another
organisation returns `404`. The usual `401` and `403` responses apply for
authentication and permission failures.

#### Sales, product, and branch metrics

These three reports include only non-deleted `DELIVERED` orders whose
`createdAt` falls in the selected Tashkent date range. When `branchId` is
present, only orders from that branch are included. Their existing response
shapes are unchanged.

**GET /admin/reports/sales Response:**

```json
{
  "ordersCount": 87,
  "revenueAmount": 7245000,
  "deliveryRevenueAmount": 540000,
  "byBranch": [
    {
      "key": "0ed21b6c-bdb2-40df-8c41-31444cc41b8a",
      "count": 51,
      "amount": 4280000
    },
    {
      "key": "91cd5dc2-df3a-40be-9266-ee9848be320a",
      "count": 36,
      "amount": 2965000
    }
  ],
  "byDay": [
    { "key": "2026-07-01", "count": 12, "amount": 965000 },
    { "key": "2026-07-02", "count": 15, "amount": 1220000 }
  ]
}
```

`byBranch[].key` is a branch ID and `byDay[].key` is a Tashkent calendar date.
Empty sales results return zero totals and empty `byBranch`/`byDay` arrays.

**GET /admin/reports/products Response:**

```json
[
  {
    "productId": "product-classic-lavash",
    "productName": "Классический лаваш",
    "quantity": 64,
    "revenueAmount": 2048000
  },
  {
    "productId": "product-cola",
    "productName": "Coca-Cola",
    "quantity": 39,
    "revenueAmount": 468000
  }
]
```

**GET /admin/reports/branches Response:**

```json
[
  {
    "key": "0ed21b6c-bdb2-40df-8c41-31444cc41b8a",
    "count": 51,
    "amount": 4280000
  },
  {
    "key": "91cd5dc2-df3a-40be-9266-ee9848be320a",
    "count": 36,
    "amount": 2965000
  }
]
```

Product and branch reports return `[]` when no delivered orders match. Every
amount is a whole UZS integer.

#### Client report

`GET /admin/reports/clients` returns organisation account metrics together with
order-based purchaser metrics.

```json
{
  "period": {
    "startDate": "2026-07-01",
    "endDate": "2026-07-07",
    "timezone": "Asia/Tashkent",
    "branchId": "0ed21b6c-bdb2-40df-8c41-31444cc41b8a"
  },
  "accounts": {
    "registeredInRangeCount": 12,
    "currentUnblockedCount": 1420,
    "byDay": [
      { "date": "2026-07-01", "registeredClientsCount": 3 },
      { "date": "2026-07-03", "registeredClientsCount": 5 }
    ]
  },
  "ageStats": {
    "clientsWithBirthDateCount": 1180,
    "clientsWithoutBirthDateCount": 240,
    "averageAge": 29.4,
    "byRange": [
      { "range": "under18", "minAge": null, "maxAge": 17, "clientsCount": 35 },
      { "range": "18-24", "minAge": 18, "maxAge": 24, "clientsCount": 290 },
      { "range": "25-34", "minAge": 25, "maxAge": 34, "clientsCount": 475 },
      { "range": "35-44", "minAge": 35, "maxAge": 44, "clientsCount": 245 },
      { "range": "45-54", "minAge": 45, "maxAge": 54, "clientsCount": 95 },
      { "range": "55+", "minAge": 55, "maxAge": null, "clientsCount": 40 }
    ]
  },
  "purchasers": {
    "activeClientsCount": 41,
    "newClientsCount": 9,
    "returningClientsCount": 32,
    "orders": {
      "ordersCount": 66,
      "deliveredOrdersCount": 58,
      "deliveredRevenueAmount": 4520000
    },
    "newClientOrders": {
      "ordersCount": 15,
      "deliveredOrdersCount": 13,
      "deliveredRevenueAmount": 980000
    },
    "returningClientOrders": {
      "ordersCount": 51,
      "deliveredOrdersCount": 45,
      "deliveredRevenueAmount": 3540000
    },
    "byDay": [
      {
        "date": "2026-07-01",
        "activeClientsCount": 12,
        "newClientsCount": 3,
        "returningClientsCount": 9,
        "ordersCount": 15,
        "deliveredOrdersCount": 13,
        "deliveredRevenueAmount": 980000
      }
    ]
  }
}
```

`ageStats` covers all non-deleted client accounts in the organisation. Ages are
calculated at the end of the requested reporting period. A missing or future
`birthDate` is included in `clientsWithoutBirthDateCount`; when no age is known,
`averageAge` is `null`. All six `byRange` buckets are always returned, including
zero-count buckets.

Client metric definitions:

- `registeredInRangeCount` counts non-deleted client accounts created during
  the selected range. `accounts.byDay` groups those registrations by Tashkent
  date.
- `currentUnblockedCount` counts non-deleted, unblocked accounts at request
  time. It is a current total, not a historical snapshot for `endDate`.
- Account metrics are always organisation-wide. They do not change when a
  `branchId` filter is applied.
- A valid client order is non-deleted, has a non-null `clientId`, and is neither
  `CANCELLED` nor `REFUNDED`. Guest and anonymized orders are excluded from all
  purchaser metrics.
- `activeClientsCount` is the number of distinct clients with at least one valid
  order in the selected date and branch scope.
- A new purchaser is an active client whose first valid order anywhere in the
  organisation falls inside the selected range. A returning purchaser first
  ordered before the range. First-order classification still uses every branch
  when the report is filtered to one branch.
- `ordersCount` counts all valid client orders in scope. Delivered counts and
  revenue include only the `DELIVERED` subset. `deliveredRevenueAmount` is a
  whole UZS integer.
- `newClientOrders` and `returningClientOrders` partition the scoped order
  metrics by purchaser cohort.
- Daily new/returning counts use the same range-level cohorts. A purchaser whose
  first valid order is inside the selected range remains in that range's new
  cohort on every day they are active; they do not switch to returning on their
  next day in the same report.
- Daily arrays are sorted ascending and sparse. Dates with no registrations or
  purchaser activity are omitted rather than returned as zero rows. A client
  can be active on more than one day, so do not sum daily distinct-client counts
  to calculate the period total.

When no data matches, the client report keeps the same object shape, returns
zero for every total, and returns `[]` for both daily arrays. `period.branchId`
is `null` when `branchId` was omitted.

Distinct clients are not additive across branches. To display an all-branch
client count, request the report without `branchId`; do not sum results from
separate branch requests.

#### Promotion report (unchanged)

| Method | Endpoint                    | Permission           | Description     |
| ------ | --------------------------- | -------------------- | --------------- |
| GET    | `/admin/reports/promotions` | `reports.sales.view` | Promotion usage |

The shared date/branch query above does not apply to this endpoint.

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
| GET    | `/admin/organisation/working-hours`     | `organisation.settings.view`   | Read effective weekly hours   |
| PUT    | `/admin/organisation/working-hours`     | `organisation.settings.update` | Replace organisation hours    |
| GET    | `/admin/organisation/day-offs`          | `organisation.settings.view`   | List local-date closures      |
| PUT    | `/admin/organisation/day-offs/:date`    | `organisation.settings.update` | Close one local date          |
| DELETE | `/admin/organisation/day-offs/:date`    | `organisation.settings.update` | Delete one local-date closure |

Delivery tariff amounts are whole UZS integers. The calculated delivery price
is rounded to the nearest 1,000 UZS; a remainder of 500 UZS or more rounds up.

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

Weekly schedule `PUT` bodies use `{ "hours": [...] }`. Each weekday may appear
at most once and contains `weekday` (1–7), `opensAt`, `closesAt`,
`deliveryOpensAt`, `deliveryClosesAt`, and `isClosed`; times use `HH:mm`, and
opening/closing values must differ. Missing organisation weekdays are open 24
hours. Missing branch weekdays inherit the organisation. Overnight windows are
supported and closing boundaries are exclusive.

Organisation day-off `PUT` accepts an optional admin-only `reason`. Branch
day-off `PUT` accepts `state: "CLOSED" | "OPEN"` and an optional reason. A
branch `OPEN` bypasses an organisation day-off but still follows weekly hours.
Day-off list endpoints accept optional local `YYYY-MM-DD` `from` and `to`
queries. Dates are evaluated in the organisation timezone, defaulting to
`Asia/Tashkent`.

For admin implementation details, see the
[Admin working hours and day-offs guide](docs/ADMIN_WORKING_HOURS_AND_DAY_OFFS.md).

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

## Notifications and assigned promotion guides

- Mobile app: [`docs/MOBILE_APP_NOTIFICATIONS_AND_PROMOS.md`](docs/MOBILE_APP_NOTIFICATIONS_AND_PROMOS.md)
- Admin panel: [`docs/ADMIN_PANEL_NOTIFICATIONS_AND_PROMOS.md`](docs/ADMIN_PANEL_NOTIFICATIONS_AND_PROMOS.md)

These guides document the durable inbox, read/unread state, unread counts,
private shared and unique promo assignments, push payloads, analytics, and
expiry reminders.

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
