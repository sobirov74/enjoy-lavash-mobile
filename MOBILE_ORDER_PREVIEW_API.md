# Mobile Order Preview API

Use the authenticated cart preview endpoint to calculate the selected branch,
delivery price, promotions, loyalty points, and final order total before
creating an order.

The preview does not create an order and does not reserve loyalty points. Order
creation recalculates all prices and remains authoritative.

## Endpoint

```http
POST /clients/me/cart/preview
Authorization: Bearer <client-access-token>
Content-Type: application/json
Accept-Language: uz
```

Supported `Accept-Language` values:

- `uz`
- `ru`
- `en`

For authenticated mobile clients, prefer this endpoint over the public
`POST /cart/preview` endpoint. The authenticated endpoint supports saved
addresses, client-specific promotions, assigned promo codes, new-client rules,
and loyalty points.

## Request examples

### Delivery using a saved address

```json
{
  "type": "DELIVERY",
  "addressId": "address-uuid",
  "items": [
    {
      "productId": "product-uuid",
      "quantity": 2,
      "modifiers": [
        {
          "modifierId": "modifier-uuid",
          "quantity": 1
        }
      ],
      "comment": "Less spicy"
    }
  ],
  "paymentMethod": "PAYME",
  "promoCode": "FIRST20",
  "loyaltyRedemptionAmount": 20000
}
```

### Delivery using inline coordinates

```json
{
  "type": "DELIVERY",
  "address": {
    "latitude": 41.3111,
    "longitude": 69.2797,
    "label": "Home",
    "street": "Bunyodkor Avenue",
    "houseNumber": "18",
    "apartmentNumber": "42",
    "entrance": "2",
    "floor": "7",
    "doorCode": "1234",
    "comment": "Call on arrival"
  },
  "items": [
    {
      "productId": "product-uuid",
      "quantity": 1
    }
  ],
  "paymentMethod": "CASH",
  "loyaltyRedemptionAmount": 0
}
```

### Pickup

```json
{
  "type": "PICKUP",
  "branchId": "branch-uuid",
  "items": [
    {
      "productId": "product-uuid",
      "quantity": 1,
      "modifiers": []
    }
  ],
  "paymentMethod": "CASH",
  "loyaltyRedemptionAmount": 0
}
```

## Request fields

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `type` | `OrderType` | Yes | Delivery or pickup. |
| `items` | `CartItem[]` | Yes | Must contain at least one item. |
| `items[].productId` | `string` | Yes | Product ID or supported product key. |
| `items[].quantity` | `integer` | Yes | Must be greater than zero. |
| `items[].modifiers` | `SelectedModifier[]` | No | Selected product modifiers. |
| `items[].modifiers[].modifierId` | `string` | Yes | Modifier ID. |
| `items[].modifiers[].quantity` | `integer` | No | Must be greater than zero; defaults to `1`. |
| `items[].comment` | `string` | No | Item preparation comment. |
| `branchId` | `string` | Conditional | Required for pickup; optional delivery branch preference. |
| `addressId` | `string` | Conditional | Saved client address for delivery. |
| `address` | `DeliveryAddress` | Conditional | Inline delivery address when `addressId` is absent. |
| `paymentMethod` | `PaymentMethod` | No | Defaults to `CASH` for preview calculation. |
| `promoCode` | `string` | No | Explicit promotion or assigned promotion code. |
| `loyaltyRedemptionAmount` | `integer` | No | Exact points to redeem; must be at least zero. One point equals one UZS. |
| `iikoOrganizationId` | `string` | No | iiko organization ID used as an iiko-backed branch alias. |
| `iikoOrganisationId` | `string` | No | Legacy spelling alias for `iikoOrganizationId`. |
| `organisationId` | `string` | No | Accepted for compatibility, but the mobile endpoint uses the authenticated client's organization. |

When both `addressId` and `address` are present, the saved `addressId` takes
priority.

The backend automatically sets the source to `MOBILE_APP` and supplies the
client ID, phone number, organization, and previous order count. The mobile app
must not attempt to set those internal values.

### Delivery address model

```ts
type DeliveryAddress = {
  latitude: number;       // Valid latitude: -90 through 90
  longitude: number;      // Valid longitude: -180 through 180
  label?: string;         // Maximum 120 characters
  text?: string;          // Maximum 500 characters
  addressText?: string;   // Alias for text; maximum 500 characters
  street?: string;        // Maximum 180 characters
  houseNumber?: string;   // Maximum 40 characters
  apartmentNumber?: string; // Maximum 40 characters
  entrance?: string;      // Maximum 40 characters
  floor?: string;         // Maximum 40 characters
  doorCode?: string;      // Maximum 40 characters
  comment?: string;       // Maximum 500 characters
};
```

## Possible enum values

```ts
type OrderType =
  | 'DELIVERY'
  | 'PICKUP';

type PaymentMethod =
  | 'CASH'
  | 'PAYME'
  | 'CLICK'
  | 'CARD_TERMINAL';

type DeliveryDistanceSource =
  | 'ROAD'
  | 'STRAIGHT_LINE_FALLBACK';

type PromotionStatus =
  | 'NONE'
  | 'APPLIED'
  | 'NOT_FOUND'
  | 'INACTIVE'
  | 'NOT_STARTED'
  | 'EXPIRED'
  | 'GLOBAL_LIMIT_REACHED'
  | 'CLIENT_LIMIT_REACHED'
  | 'CLIENT_REQUIRED'
  | 'CONDITIONS_NOT_MET'
  | 'CONFIGURATION_ERROR';

type PromotionAudience =
  | 'PUBLIC'
  | 'ASSIGNED_ONLY';

type PromotionRewardType =
  | 'PERCENT'
  | 'FIXED'
  | 'FREE_DELIVERY'
  | 'FREE_PRODUCT';

type PromotionApplyTo =
  | 'ORDER'
  | 'PRODUCTS'
  | 'DELIVERY';

type PromotionSource =
  | 'MOBILE_APP'
  | 'WEBSITE'
  | 'ADMIN_PANEL';

type Language =
  | 'uz'
  | 'ru'
  | 'en';
```

### Promotion status meanings

| Status | Meaning | Suggested mobile behavior |
| --- | --- | --- |
| `NONE` | No promotion was applied. | Do not show a promotion discount. |
| `APPLIED` | A promotion was successfully applied. | Show the promotion title and benefit. |
| `NOT_FOUND` | The code is invalid or belongs to another client. | Show an invalid-code state. |
| `INACTIVE` | The promotion is disabled. | Explain that the code is unavailable. |
| `NOT_STARTED` | The promotion start date is in the future. | Explain that it is not active yet. |
| `EXPIRED` | The promotion end date has passed. | Explain that the code expired. |
| `GLOBAL_LIMIT_REACHED` | The promotion's total usage limit was reached. | Explain that the offer is no longer available. |
| `CLIENT_LIMIT_REACHED` | This client has reached the usage limit. | Explain that the code was already used. |
| `CLIENT_REQUIRED` | Client authentication is required. | Relevant mainly to the public preview endpoint. |
| `CONDITIONS_NOT_MET` | Cart, branch, payment, source, weekday, or minimum-total conditions failed. | Show the appropriate condition message. |
| `CONFIGURATION_ERROR` | The promotion is incorrectly configured. | Do not apply it; show a generic unavailable message. |

A rejected promotion normally still returns HTTP `200`. Always inspect
`promotionStatus`.

## Successful response

```ts
type CartPreviewResponse = {
  organisationId: string;
  branchId?: string;

  deliveryDistanceMeters?: number;
  deliveryDistanceSource?: DeliveryDistanceSource;

  itemsAmount: number;
  modifiersAmount: number;
  discountAmount: number;
  deliveryAmount: number;
  serviceFeeAmount: number;

  totalBeforePointsAmount: number;
  totalAmount: number;

  loyalty?: LoyaltyPreview;

  appliedPromotion?: Promotion;
  promotionAssignmentId?: string;
  appliedPromoCode?: string;
  promotionStatus: PromotionStatus;
  promotionStatusReason?: string;
  promotionDeliveryDiscountAmount: number;

  bonusItems: PricedCartItem[];
  items: PricedCartItem[];
};
```

### Example response

```json
{
  "organisationId": "organisation-uuid",
  "branchId": "branch-uuid",
  "deliveryDistanceMeters": 2150,
  "deliveryDistanceSource": "ROAD",
  "itemsAmount": 80000,
  "modifiersAmount": 10000,
  "discountAmount": 10000,
  "deliveryAmount": 10000,
  "serviceFeeAmount": 0,
  "totalBeforePointsAmount": 90000,
  "totalAmount": 70000,
  "loyalty": {
    "balance": 42000,
    "spendableBalance": 42000,
    "debtAmount": 0,
    "requestedPoints": 20000,
    "appliedPoints": 20000,
    "eligibleAmount": 90000,
    "maxPointsToSpend": 42000,
    "estimatedEarnPoints": 7000,
    "estimateOnly": true
  },
  "promotionStatus": "APPLIED",
  "promotionDeliveryDiscountAmount": 0,
  "appliedPromoCode": "FIRST20",
  "appliedPromotion": {
    "id": "promotion-uuid",
    "organisationId": "organisation-uuid",
    "code": "FIRST20",
    "audience": "PUBLIC",
    "titleI18n": {
      "uz": "Birinchi buyurtmaga chegirma",
      "ru": "Скидка на первый заказ",
      "en": "First order discount"
    },
    "isActive": true,
    "startDate": null,
    "endDate": null,
    "usageLimit": null,
    "usageCount": 10,
    "conditions": {
      "minOrderAmount": 50000
    },
    "reward": {
      "type": "FIXED",
      "value": 10000,
      "applyTo": "ORDER"
    }
  },
  "bonusItems": [],
  "items": [
    {
      "productId": "product-uuid",
      "productNameSnapshotI18n": {
        "uz": "Klassik lavash",
        "ru": "Классический лаваш",
        "en": "Classic lavash"
      },
      "categoryId": "category-uuid",
      "quantity": 2,
      "unitPrice": 40000,
      "modifiersAmount": 10000,
      "totalPrice": 90000,
      "modifiers": [
        {
          "modifierId": "modifier-uuid",
          "modifierNameSnapshotI18n": {
            "uz": "Pishloq",
            "ru": "Сыр",
            "en": "Cheese"
          },
          "quantity": 1,
          "unitPrice": 10000,
          "totalPrice": 10000
        }
      ]
    }
  ]
}
```

## Response models

### Priced cart item

```ts
type I18nText = {
  uz?: string;
  ru?: string;
  en?: string;
};

type PricedModifier = {
  modifierId: string;
  modifierNameSnapshotI18n: I18nText;
  quantity: number;
  unitPrice: number;
  totalPrice: number;
};

type PricedCartItem = {
  productId: string;
  productNameSnapshotI18n: I18nText;
  categoryId: string;
  quantity: number;
  unitPrice: number;
  modifiersAmount: number;
  totalPrice: number;
  modifiers: PricedModifier[];
  comment?: string;

  // Present for gift products:
  isBonus?: boolean;
  originalUnitPrice?: number;
  promotionId?: string;
  promotionCode?: string;
};
```

Gift products appear in both `bonusItems` and `items`. Do not add both
collections when calculating or displaying the total. Items with
`isBonus: true` should be rendered as gifts with zero price.

### Loyalty preview

```ts
type LoyaltyPreview = {
  balance: number;
  spendableBalance: number;
  debtAmount: number;
  requestedPoints: number;
  appliedPoints: number;
  eligibleAmount: number;
  maxPointsToSpend: number;
  estimatedEarnPoints: number;
  estimateOnly: true;
};
```

`estimatedEarnPoints` is only an estimate. Loyalty points are not reserved
during preview. Another device or order may change the available balance before
order creation.

When the user selects "use maximum", use the latest
`loyalty.maxPointsToSpend` value from the preview response.

### Applied promotion

```ts
type Promotion = {
  id: string;
  createdAt: string;
  updatedAt: string;
  deletedAt?: string | null;
  organisationId: string;
  code: string;
  audience?: PromotionAudience;
  titleI18n: I18nText;
  isActive: boolean;
  startDate?: string | null;
  endDate?: string | null;
  usageLimit?: number | null;
  usageCount: number;
  conditions: {
    autoApply?: boolean;
    minOrderAmount?: number;
    productIds?: string[];
    categoryIds?: string[];
    branchIds?: string[];
    orderType?: OrderType;
    weekdays?: number[]; // 1 = Monday through 7 = Sunday
    paymentMethods?: PaymentMethod[];
    sources?: PromotionSource[];
    perClientUsageLimit?: number;
    maxPreviousOrders?: number;
  };
  reward: {
    type: PromotionRewardType;
    value?: number;
    maxDiscountAmount?: number;
    freeProductId?: string;
    freeProductQuantity?: number;
    applyTo: PromotionApplyTo;
  };
};
```

`appliedPromotion` is present only when `promotionStatus` is `APPLIED`.

## Amount calculation

All monetary fields and loyalty points are integer UZS values.

```text
totalBeforePointsAmount
  = itemsAmount
  + modifiersAmount
  + deliveryAmount
  + serviceFeeAmount
  - discountAmount

totalAmount
  = totalBeforePointsAmount
  - loyalty.appliedPoints
```

Field meanings:

| Field | Meaning |
| --- | --- |
| `itemsAmount` | Base product prices before modifiers. |
| `modifiersAmount` | Total selected modifier prices. |
| `discountAmount` | Promotion discount subtracted from products and modifiers. |
| `deliveryAmount` | Final delivery fee after any delivery promotion. |
| `promotionDeliveryDiscountAmount` | Delivery discount benefit, such as the original fee removed by free delivery. |
| `serviceFeeAmount` | Service fee; currently always `0`. |
| `totalBeforePointsAmount` | Total after promotions but before loyalty redemption. |
| `totalAmount` | Final preview total after loyalty points. |

For pickup, `deliveryAmount` is `0` and `deliveryDistanceSource` is omitted.

`STRAIGHT_LINE_FALLBACK` is a valid result. It means road routing was
temporarily unavailable and the backend used an estimated straight-line
distance. The app may label it as estimated without blocking checkout.

## Error response

```json
{
  "statusCode": 409,
  "error": "Conflict",
  "errorCode": "LOYALTY_AMOUNT_CHANGED",
  "message": "The available loyalty amount changed. Please review and try again.",
  "language": "en",
  "path": "/clients/me/cart/preview",
  "timestamp": "2026-07-27T10:00:00.000Z",
  "details": {
    "maxPointsToSpend": 15000,
    "availableBalance": 15000,
    "debtAmount": 0
  },
  "metadata": {
    "maxPointsToSpend": 15000,
    "spendableBalance": 15000,
    "debtAmount": 0
  }
}
```

```ts
type ApiError = {
  statusCode: number;
  error: string;
  errorCode: string;
  message: string;
  language: Language;
  path: string;
  timestamp: string;
  details?: unknown;
  metadata?: unknown;
};
```

### Important error codes

| HTTP | `errorCode` | Meaning | Suggested mobile behavior |
| --- | --- | --- | --- |
| `400` | `VALIDATION_FAILED` | DTO or field validation failed. | Associate `details` with the affected field when possible. |
| `400` | `BAD_REQUEST` | Invalid item, modifier, branch, address, or unavailable delivery. | Keep the cart and show the localized message. |
| `401` | `AUTH_HEADER_REQUIRED` | Authorization header is missing. | Start the session-expiry flow. |
| `401` | `BEARER_TOKEN_REQUIRED` | Authorization header is not valid Bearer format. | Start the session-expiry flow. |
| `401` | `INVALID_CLIENT_TOKEN` | Client access token is invalid or the client is blocked. | Refresh or clear the session. |
| `404` | `ADDRESS_NOT_FOUND` | The saved address does not exist for this client. | Refresh saved addresses and ask for another address. |
| `409` | `LOYALTY_AMOUNT_CHANGED` | Requested points exceed the latest maximum. | Clear or clamp selected points using returned `maxPointsToSpend`, then re-preview. |
| `409` | `LOYALTY_PROGRAM_DISABLED` | The loyalty program is disabled. | Clear points and re-preview. |
| `409` | `LOYALTY_REDEMPTION_DISABLED` | Spending points is disabled. | Clear points and re-preview. |
| `409` | `LOYALTY_DEBT_OUTSTANDING` | The client has loyalty debt. | Disable point spending, show the debt, and re-preview with zero. |
| `503` | `LOYALTY_UNAVAILABLE` | Loyalty pricing is temporarily unavailable. | Retry or explicitly continue with zero points. |

Use `errorCode` and `promotionStatus` for application logic. Do not compare
localized `message` or `promotionStatusReason` text.

## Mobile implementation rules

1. Re-preview whenever products, quantities, modifiers, order type, branch,
   address, payment method, promo code, or requested loyalty points change.
2. Debounce rapid changes such as quantity and loyalty-point input.
3. Track a request version so an older response cannot replace a newer
   checkout state.
4. Disable final submission while the preview is stale, loading, or failed.
5. Send the same address or `addressId`, branch, promo code, payment method, and
   loyalty amount to order creation.
6. Treat the created order response as authoritative because branch
   availability, prices, delivery tariffs, promotions, and loyalty balances may
   change after preview.
7. Do not call OSRM or another routing service directly from the mobile app.
8. Never calculate the payable amount exclusively on the client; use the
   backend `totalAmount`.

## Backend source references

- Request DTO: `src/dto/common.dto.ts`
- Response DTO: `src/dto/response.dto.ts`
- Shared response types: `src/entities/restaurant.types.ts`
- Enum definitions: `src/common/enums.ts`
- Mobile preview logic: `src/services/client.service.ts`
- Pricing logic: `src/services/cart-pricing.service.ts`
- Loyalty preview logic: `src/loyalty/loyalty.service.ts`
