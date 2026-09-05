# Cafe redesign — backend requirements

Status: mobile redesign integration, September 2026

This document lists only data that the supplied redesign needs but the current
mobile API contract does not expose reliably. Existing capabilities are called
out separately so they are not rebuilt on the backend.

## What already exists

No backend work is required for these parts of the redesign:

- Customer name and phone: `GET /clients/me`.
- Profile name, birth date, language, and marketing consent updates:
  `PATCH /clients/me`.
- Saved-address listing, creation, update/default selection, and deletion:
  existing `/clients/me/addresses` endpoints. The reference Profile now uses
  these contracts; no new Profile backend endpoint is required.
- Loyalty balance, reserved balance, expiry, rules, and history: existing
  loyalty wallet and transaction endpoints.
- Recent order content, totals, date, status, branch, and address: existing
  client order endpoints.
- Product images and localized descriptions: existing catalog payload.
- Category image URLs and product `calories`, `weightGrams`, and
  `cookingTimeMinutes`: existing catalog payload, now consumed by mobile.
- Product modifier groups, minimum/maximum selection, default options, option
  prices, availability, and option images: existing catalog payload.
- Selected modifiers in preview/create-order requests: existing
  `items[].modifiers` contract.
- Delivery fee, service fee, promotion result, loyalty estimate, and final
  payable amount: existing cart-preview response.
- Authoritative priced cart lines, modifier snapshots, and promotion gift
  items: existing cart-preview response, now consumed by checkout.
- Branch address, coordinates, phone, and opening/closing time: existing branch
  payload.
- Independent pickup/delivery availability, effective weekly hours, closure
  source, timezone, and next opening: existing public
  `GET /branches/:id/ordering-status`, now wired into checkout.
- Notification kind, unread state, promotion code, and loyalty/promotion deep
  link intent: existing notification inbox payload.

The redesigned product page and cart reconcile persisted modifier IDs against
the latest catalog, refresh localized names/prices, and send valid selections
through preview and order creation. Order-history repeat is still best-effort;
the current mobile order item parser does not receive/preserve modifier
selections reliably.

## P0 — required for full content parity

### 1. Fulfilment context/ETA quote

The Home and Menu context pill is designed to show the selected mode, target,
and a current ETA. The existing ordering-status endpoint now provides honest
open/closed guidance, but branch hours cannot produce a delivery or preparation
duration.

Recommended endpoint:

```http
POST /clients/me/fulfilment/quote
Content-Type: application/json
```

```json
{
  "type": "DELIVERY",
  "addressId": "address-uuid",
  "address": {
    "latitude": 41.3111,
    "longitude": 69.2797
  },
  "branchId": null
}
```

```json
{
  "type": "DELIVERY",
  "available": true,
  "branchId": "branch-uuid",
  "branchName": "Chilonzor",
  "etaMinMinutes": 25,
  "etaMaxMinutes": 35,
  "distanceMeters": 4200,
  "reasonCode": null,
  "message": null,
  "quotedAt": "2026-09-01T17:30:00.000Z",
  "expiresAt": "2026-09-01T17:35:00.000Z"
}
```

For pickup, accept `branchId` and return preparation ETA. When unavailable,
return `available: false` plus a stable `reasonCode` and localized `message`.
Suggested reason codes: `OUTSIDE_DELIVERY_ZONE`, `BRANCH_CLOSED`,
`DELIVERY_PAUSED`, and `ADDRESS_REQUIRED`.

The contract must make one branch-selection rule explicit: either delivery may
send a customer-selected `branchId`, or the quote resolves the eligible branch.
Echo the confirmed ETA/range (or an ETA expiry) on created-order responses so
the success screen does not present a stale quote as confirmed.

### 2. Promotion creative and destination

The current public contract has `titleI18n`, code, `startDate`/`endDate`,
conditions, and a nested reward. Mobile now parses those names. A localized
description is not documented, and the payload still lacks the visual and
action destination required by the full-bleed Home hero.

Add these optional fields to public promotion and assigned-promotion payloads:

```json
{
  "image": {
    "url": "https://cdn.example.uz/promotions/lavash-weekend.webp",
    "width": 1600,
    "height": 900,
    "alt": {
      "uz": "Lavash aksiyasi",
      "ru": "Акция на лаваш",
      "en": "Lavash offer"
    }
  },
  "badge": {
    "uz": "MAXSUS TAKLIF",
    "ru": "СПЕЦИАЛЬНОЕ ПРЕДЛОЖЕНИЕ",
    "en": "SPECIAL OFFER"
  },
  "action": {
    "type": "CATEGORY",
    "targetId": "category-uuid",
    "label": {
      "uz": "Ko'rish",
      "ru": "Смотреть",
      "en": "View"
    }
  }
}
```

Supported `action.type` values should be a closed enum: `CATEGORY`, `PRODUCT`,
`PROMOTION`, and `EXTERNAL_URL`. The mobile app must not infer navigation from
human-readable titles.

### 3. Category creative enhancements

The existing flat category `image` URL is now used by Home, with the first
product image only as a failure fallback. Only richer media metadata and the
optional accent remain additive requests.

Add to each catalog category:

```json
{
  "imageMetadata": {
    "url": "https://cdn.example.uz/categories/lavash.webp",
    "width": 800,
    "height": 600,
    "alt": {
      "uz": "Lavash",
      "ru": "Лаваш",
      "en": "Lavash"
    }
  },
  "accentColor": "#E9DAC6"
}
```

`accentColor` is optional and must be a validated six-digit hex value. The
mobile app will use its curated neutral fallback when absent.

### 4. Additional product nutrition metadata

The existing flat `calories`, `weightGrams`, and `cookingTimeMinutes` fields are
now parsed and rendered. The current design does not require the backend to
duplicate them in a nested object. The following optional values would support
future drinks and expanded nutrition UI:

Add an optional object to catalog products:

```json
{
  "nutrition": {
    "volumeMl": null,
    "proteinGrams": 24.5,
    "fatGrams": 18.0,
    "carbohydrateGrams": 52.0
  }
}
```

`volumeMl` and macros are future-safe enhancements, not current redesign
blockers. Do not return zero for unknown values; omit or return `null`.

## P1 — recommended for reliable behavior at scale

### 5. Reorder compatibility preview

The Home repeat-order card can be rendered from order history today. Re-adding
items locally is best-effort, and current order history does not reliably
provide modifier selections to mobile. Products, prices, modifier IDs, and
availability may also have changed.

Recommended endpoint:

```http
POST /clients/me/orders/{orderId}/reorder-preview
```

```json
{
  "canReorder": true,
  "items": [
    {
      "originalProductId": "product-uuid",
      "productId": "product-uuid",
      "quantity": 1,
      "modifiers": [{"modifierId": "modifier-uuid", "quantity": 1}],
      "available": true,
      "changed": false,
      "message": null
    }
  ],
  "removedItemCount": 0,
  "requiresReview": false
}
```

The mobile app should always open the cart after this call so the customer can
review updated prices before checkout.

### 6. Required-modifier default invariant

Menu-tile quick-add uses only options explicitly marked `isDefault`. For every
available required modifier group, either expose enough available defaults to
satisfy `minSelect`, or expect mobile to open customization instead of
quick-adding. Never rely on array order as an implicit default.

### 7. Product favorites (only if the reference heart is actionable)

The reference product page includes a favorite control, but the current mobile
contract has no persisted favorite state or mutation. If this is a real
feature, add authenticated list/toggle endpoints and return `isFavorite` on
catalog product detail. Otherwise the control should be removed from the
approved production design rather than simulated locally.

### 8. Notification kind filter

The redesign has All, Orders, and Promotions filters. Client-side filtering is
correct for the currently loaded inbox page, but becomes incomplete once the
inbox is paginated.

Extend the existing endpoint with an optional repeatable or comma-separated
kind group:

```http
GET /clients/me/notifications?group=ORDER&limit=50&offset=0
GET /clients/me/notifications?group=PROMOTION&limit=50&offset=0
```

Return `total` and `unreadCount` after applying the group filter. Preserve the
current response shape.

## Error contract needed by the redesigned states

Continue using the existing localized error envelope, and ensure these values
are stable across the endpoints above:

- `errorCode`: machine-readable stable code (mobile may temporarily accept
  `error_code` as an alias).
- `message`: localized customer-safe text.
- `details.fieldErrors`: optional map for 422 validation, with stable keys such
  as `address`, `branchId`, `paymentMethod`, `promoCode`, and
  `loyaltyRedemptionAmount`; each value is a localized string or string array.
- `metadata`: safe public state for conflicts such as `ORDERING_CLOSED`.
- `retryAfterSeconds`: integer for 429/rate limiting.
- HTTP 401 for expired/invalid session, 404 for removed product/order, 409 for
  stale availability/price conflicts, 422 for customer-correctable input, 429
  for rate limiting, and 5xx for server failures.

The mobile app already keeps the cart itself on 409/422. Checkout-level create
errors are not yet fully field-local, so the stable shape above is required
before that remaining client work can be completed without title/message
parsing. A full-screen state is used only when no usable content loaded.

## Acceptance checklist

- Media URLs are absolute HTTPS URLs or follow the existing relative-media URL
  convention consistently.
- Localized objects support `uz`, `ru`, and `en` with the existing fallback
  rules.
- New fields are additive and optional so older mobile versions continue to
  parse responses.
- ETA responses have an expiry and are not presented as guaranteed delivery
  times.
- Created orders echo a confirmed ETA/range or explicitly indicate that the
  quote expired.
- Action targets use IDs/enums, never title parsing.
- Required modifier defaults satisfy `minSelect`, or quick-add is intentionally
  unavailable for that product.
- Unknown numeric metadata is `null`/absent, not `0`.
