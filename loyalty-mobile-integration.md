# Mobile App Loyalty Integration

This document is the implementation contract for
`../enjoy_lavash_mobile`. The backend is authoritative for balances,
campaign selection, expiry, redemption limits, and final earning. The mobile
app must never reproduce those calculations.

All loyalty endpoints require a client bearer token. Send
`Accept-Language: uz|ru|en`; backend error messages and loyalty notifications
are localized from that header or the client's saved language.

## Contract rules

- One point equals one UZS. Every money and point value in this API is an
  integer.
- `totalBeforePointsAmount` is the priced order total after promotion and
  before loyalty redemption.
- `totalAmount` is the residual amount payable after loyalty redemption.
- Promotion is applied before loyalty points.
- The preview earning value is an estimate. The backend selects the final
  campaign when the order first reaches `DELIVERED` in `Asia/Tashkent`.
- Only authenticated mobile orders can earn or redeem.
- A positive debt blocks redemption. Future earnings repay debt before they
  become spendable.
- The client must submit the exact requested redemption. The backend never
  silently clamps it.
- All timestamps are ISO-8601 UTC strings. Format them in the device locale;
  campaign scheduling itself remains a backend concern.

## API models

### Wallet

```json
{
  "availableBalance": 42000,
  "reservedBalance": 10000,
  "debtBalance": 0,
  "spendableBalance": 42000,
  "nextExpiryAt": "2027-01-20T07:15:00.000Z",
  "expiringWithinSevenDays": 6000,
  "validityDays": 180,
  "reminderDays": 7,
  "programEnabled": true,
  "redemptionEnabled": true,
  "spendOnDelivery": false,
  "spendOnServiceFee": false
}
```

Interpretation:

- `availableBalance` can be used by a future order when `debtBalance == 0`.
- `reservedBalance` is attached to orders that have not been settled yet.
- `debtBalance` is a positive debt amount, not a signed balance.
- `spendableBalance` is authoritative and is always non-negative.
- `nextExpiryAt` is `null` when no remaining credit expires.
- `expiringWithinSevenDays` is recalculated by the server; do not derive it
  from transaction history.
- Existing `ClientProfile.bonusBalance` remains a compatibility summary only.
  Use the wallet response on loyalty screens and checkout.

### Loyalty transaction

Ledger types are:

```text
OPENING_BALANCE
EARN
SPEND_RESERVE
SPEND_COMMIT
SPEND_RELEASE
SPEND_REFUND
EARN_REVERSAL
EXPIRE
DEBT_REPAYMENT
ACCOUNT_CLOSURE
```

The history endpoint returns newest first:

```json
{
  "items": [
    {
      "id": "ledger-entry-id",
      "type": "EARN",
      "availableDelta": 7000,
      "reservedDelta": 0,
      "debtDelta": 0,
      "availableBalanceAfter": 49000,
      "reservedBalanceAfter": 0,
      "debtBalanceAfter": 0,
      "orderId": "order-id",
      "redemptionId": null,
      "accrualId": "accrual-id",
      "creditLotId": "credit-lot-id",
      "expiresAt": "2027-01-20T07:15:00.000Z",
      "metadata": {
        "grossEarned": 7000,
        "expiresAt": "2027-01-20T07:15:00.000Z"
      },
      "createdAt": "2026-07-24T07:15:00.000Z"
    }
  ],
  "nextCursor": "opaque-or-null"
}
```

Treat `type` as forward compatible. Unknown values render as a generic
“Balance update” row using the signed deltas. Never calculate the current
wallet by summing loaded pages.

### Cart loyalty preview

```json
{
  "balance": 42000,
  "spendableBalance": 42000,
  "debtAmount": 0,
  "requestedPoints": 20000,
  "appliedPoints": 20000,
  "eligibleAmount": 90000,
  "maxPointsToSpend": 42000,
  "estimatedEarnPoints": 7000,
  "estimateOnly": true
}
```

`appliedPoints` equals `requestedPoints` on a successful response. A changed
maximum is a conflict response, not a successful response with a smaller
value.

### Order loyalty summary

```json
{
  "eligible": true,
  "redemption": {
    "amount": 20000,
    "status": "RESERVED"
  },
  "accrual": {
    "id": null,
    "status": "PENDING",
    "grossAmount": 0,
    "debtRepaidAmount": 0,
    "creditedAmount": 0,
    "campaignId": null,
    "campaignName": null,
    "earnedAt": null,
    "expiresAt": null,
    "reversedAt": null
  }
}
```

Redemption statuses:

```text
RESERVED | COMMITTED | RELEASED | REFUNDED
```

`redemption` is `null` when the order did not use points.

Accrual statuses:

```text
PENDING | NOT_ELIGIBLE | EARNED | NO_REWARD | REVERSED
```

The complete loyalty block is returned from order create, order list, order
detail, cancellation, payment retry, and every later order refresh. Missing
blocks on old orders must parse as ineligible/zero rather than fail.
Before delivery, an eligible order returns the synthetic `PENDING` view shown
above. A loyalty-ineligible order without a stored accrual returns the same
zero-valued view with `status: "NOT_ELIGIBLE"`. Render `PENDING` as
“Calculated after delivery”; do not treat its zero values as a final decision.

## Endpoints

### Read the wallet

```http
GET /clients/me/loyalty/wallet
Authorization: Bearer <client-token>
```

Load this after authentication, on application resume, after creating an
order that reserved points, after observing a terminal order state, and when
opening the wallet or checkout.

### Read wallet history

```http
GET /clients/me/loyalty/transactions?limit=50
GET /clients/me/loyalty/transactions?limit=50&cursor=<opaque-cursor>
Authorization: Bearer <client-token>
```

- Default `limit` is 50; maximum is 100.
- `cursor` is opaque. Store and resend it unchanged.
- Stop pagination when `nextCursor` is `null`.
- Refresh starts again without a cursor. Do not append a refresh response to
  the old list.

### Preview checkout

Use the existing authenticated endpoint and add
`loyaltyRedemptionAmount`. Always send zero when the user is not redeeming.

```http
POST /clients/me/cart/preview
Authorization: Bearer <client-token>
Content-Type: application/json

{
  "type": "DELIVERY",
  "addressId": "address-id",
  "items": [
    {
      "productId": "product-id",
      "quantity": 2,
      "modifiers": [
        { "modifierId": "modifier-id", "quantity": 1 }
      ]
    }
  ],
  "paymentMethod": "PAYME",
  "promoCode": "FIRST20",
  "loyaltyRedemptionAmount": 20000
}
```

The existing preview response gains:

```json
{
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
  }
}
```

Preview does not reserve points. A later create call can therefore return a
conflict when another order or device changed the wallet.

Re-preview whenever any of these changes:

- products, quantities, or modifiers;
- order type, branch, or delivery address;
- payment method;
- promotion code;
- requested loyalty points.

Use the existing request-version pattern in the checkout sheet so an older
response cannot overwrite a newer selection.

### Create an order

Add the same body field and send a UUID in `Idempotency-Key`.

```http
POST /clients/me/orders
Authorization: Bearer <client-token>
Idempotency-Key: 2f5506fa-48fe-4c0f-9a39-c1a15a111ee1
Content-Type: application/json

{
  "type": "DELIVERY",
  "addressId": "address-id",
  "items": [
    { "productId": "product-id", "quantity": 2, "modifiers": [] }
  ],
  "paymentMethod": "PAYME",
  "promoCode": "FIRST20",
  "comment": "Call on arrival",
  "loyaltyRedemptionAmount": 20000
}
```

The order response keeps the existing pricing/payment fields and adds:

```json
{
  "id": "order-id",
  "status": "NEW",
  "paymentStatus": "PENDING",
  "totalBeforePointsAmount": 90000,
  "loyaltyRedeemedAmount": 20000,
  "totalAmount": 70000,
  "paymentUrl": "https://provider.example/checkout",
  "paymentRetryAvailable": false,
  "loyalty": {
    "eligible": true,
    "redemption": {
      "amount": 20000,
      "status": "RESERVED"
    },
    "accrual": {
      "id": null,
      "status": "PENDING",
      "grossAmount": 0,
      "debtRepaidAmount": 0,
      "creditedAmount": 0,
      "campaignId": null,
      "campaignName": null,
      "earnedAt": null,
      "expiresAt": null,
      "reversedAt": null
    }
  }
}
```

Idempotency handling:

1. Generate one UUID when the user confirms the final checkout payload.
2. Retain the same key and identical body through timeout, connection, and
   5xx retries.
3. Do not generate the key in an interceptor: the automatic retry must reuse
   it.
4. Generate a new key when the user changes the checkout payload or abandons
   that create attempt.
5. A repeated key and identical payload returns the original order.
6. A repeated key with a different payload returns
   `409 IDEMPOTENCY_KEY_REUSED`.

For a fully points-paid order:

```json
{
  "paymentStatus": "PAID",
  "totalBeforePointsAmount": 90000,
  "loyaltyRedeemedAmount": 90000,
  "totalAmount": 0,
  "paymentUrl": null,
  "paymentExpiresAt": null,
  "paymentRetryAvailable": false
}
```

Do not open a payment browser or render payment retry when
`totalAmount == 0`. Keep a valid selected/fallback `paymentMethod` in the
request for DTO compatibility; the backend does not create an external
payment attempt for zero residual.

## Error contract

All failures use the existing localized envelope:

```json
{
  "statusCode": 409,
  "error": "Conflict",
  "errorCode": "LOYALTY_AMOUNT_CHANGED",
  "message": "The available points changed. Recalculate the order.",
  "language": "en",
  "path": "/clients/me/orders",
  "timestamp": "2026-07-24T08:00:00.000Z",
  "metadata": {
    "maxPointsToSpend": 15000,
    "spendableBalance": 15000
  }
}
```

Handle these loyalty codes:

| HTTP | `errorCode`                       | Mobile behavior                                                                         |
| ---- | --------------------------------- | --------------------------------------------------------------------------------------- |
| 409  | `LOYALTY_AMOUNT_CHANGED`          | Keep the cart, clear the selected points, refresh wallet, and re-preview.               |
| 409  | `IDEMPOTENCY_KEY_REUSED`          | Stop automatic retry and create a new key only after rebuilding/confirming the payload. |
| 409  | `LOYALTY_DEBT_OUTSTANDING`        | Show debt state, clear points, refresh wallet, and re-preview with zero.                |
| 409  | `LOYALTY_REDEMPTION_DISABLED`     | Clear points and re-preview; checkout may continue without points.                      |
| 409  | `LOYALTY_PROGRAM_DISABLED`        | Clear points and re-preview; checkout may continue without points.                      |
| 503  | `LOYALTY_UNAVAILABLE`             | Do not place a loyalty-bearing order. Let the user retry or explicitly remove points.   |
| 503  | `IIKO_LOYALTY_TENDER_UNAVAILABLE` | Do not place a loyalty-bearing order. Let the user retry or remove points.              |
| 400  | `VALIDATION_FAILED`               | Associate `details` with the points input when it mentions `loyaltyRedemptionAmount`.   |

The current mobile `Failure` classes discard `errorCode` and `metadata`.
Extend the Dio error mapper with a structured API failure payload before
implementing loyalty recovery. Do not select behavior by comparing localized
`message` text.

For every unrecognized code, show the localized `message`, retain the cart,
and offer retry. Never retry a `409` automatically. A `401` continues through
the existing token-refresh/session-expiry flow.

## Expiry notification

Expiry reminders are account/service messages and may appear in the inbox
even when marketing consent is disabled. Push still requires an enabled
device token.

Inbox item:

```json
{
  "kind": "LOYALTY_EXPIRY_REMINDER",
  "title": "Points expiring soon",
  "body": "6,000 points expire on 31 July.",
  "deepLink": "enjoylavash://loyalty",
  "sentAt": "2026-07-24T04:00:00.000Z"
}
```

Push data:

```json
{
  "type": "loyalty_expiry_reminder",
  "notificationId": "notification-id",
  "deepLink": "enjoylavash://loyalty",
  "expiringPoints": "6000",
  "expiryDate": "2026-07-31",
  "language": "en"
}
```

Unknown notification types still open the inbox. A recognized loyalty deep
link opens the wallet and refreshes it before displaying the balance.

## Flutter implementation map

Follow the project's current repository + `ChangeNotifier` architecture.

### Data and repository

1. Add `lib/features/mobile_backend/data/models/loyalty_model.dart` containing
   immutable wallet, transaction page/item, cart preview, redemption, and
   accrual models. Parse both camelCase and snake_case as existing models do.
2. Extend `CartPreviewRequest`, `CartPreviewModel`, `CreateOrderRequest`, and
   `CustomerOrderModel` in:
   - `lib/features/mobile_backend/data/models/cart_model.dart`
   - `lib/features/mobile_backend/data/models/order_model.dart`
3. Add wallet/history constants to
   `lib/core/api/api_endpoints.dart`.
4. Add repository methods and implementations in:
   - `lib/features/mobile_backend/domain/repositories/mobile_backend_repository.dart`
   - `lib/features/mobile_backend/data/repositories/mobile_backend_repository_impl.dart`
5. Change `createOrder` to accept the stable idempotency key and pass it as:

   ```dart
   options: Options(headers: {'Idempotency-Key': idempotencyKey})
   ```

6. Preserve `errorCode`, `details`, and `metadata` in
   `lib/core/error/failures.dart` and
   `lib/core/error/dio_error_mapper.dart`.

### Controller state

Add a `mobile_backend_loyalty_controller.dart` part with:

- wallet value/loading/failure/request-version state;
- cursor history items, next cursor, loading-more, refresh and failure state;
- `refreshLoyaltyWallet()`;
- `refreshLoyaltyTransactions()`;
- `loadMoreLoyaltyTransactions()`.

Integrate it with the existing controller:

- authenticated bootstrap loads wallet alongside client/addresses/orders;
- resume refreshes wallet;
- successful order creation refreshes wallet because points became reserved;
- observing `DELIVERED`, `CANCELLED`, or `REFUNDED` refreshes wallet and the
  first history page;
- logout/session expiry clears wallet, history, cursor, failures and request
  versions;
- request versions prevent an old response from repopulating cleared state.

Do not overwrite `ClientProfile.bonusBalance` locally. It remains only a
fallback display until the wallet request succeeds.

### Checkout

The main files are:

- `lib/navigation/main_tabs.dart`
- `lib/navigation/main_tabs/checkout_models.dart`
- `lib/navigation/main_tabs/order_confirmation_sheet.dart`
- `lib/navigation/main_tabs/checkout_preview_summary.dart`
- `lib/navigation/main_tabs/payment_method_selector.dart`
- `lib/navigation/main_tabs/order_success_screen.dart`

Required behavior:

1. Start with zero requested points.
2. Render available/spendable points, numeric whole-point input, “Use
   maximum”, and “Clear”.
3. “Use maximum” uses the latest `maxPointsToSpend` from preview, not the
   profile balance.
4. A points change invalidates the current preview and triggers a debounced
   preview. Disable submit while preview is stale/loading/failed.
5. Preview summary order is: order before points, promotion discount, points
   used, amount to pay, estimated points.
6. Label `estimatedEarnPoints` as an estimate finalized at delivery.
7. If the preview has debt, show the debt amount and disable points controls.
8. If residual total is zero, hide the payment selector and show “Fully paid
   with points”. The request still carries a valid fallback method.
9. Preserve the cart and sheet state on create errors. Clear only loyalty
   selection for recoverable loyalty conflicts.
10. Clear the cart only after a successful create response.

### Wallet and order UI

1. Add `lib/screens/loyalty_wallet_screen.dart`.
2. Make the points chip in `profile_sections.dart` open the wallet.
3. Replace `_CashbackSection` hardcoded percentage/spending text with generic
   dynamic information from the wallet:
   - one point equals one UZS;
   - earning depends on the campaign active at delivery;
   - expiry duration;
   - whether delivery/service fees can be paid with points.
4. Wallet header shows spendable balance, reserved points, debt (only when
   positive), next expiry, and amount expiring within seven days.
5. History uses cursor pagination and distinct icons/colors for earn, spend,
   release/refund, expiry, reversal, debt repayment, and opening balance.
6. Extend `order_row.dart`, `all_orders_screen.dart`,
   `order_details_sheet.dart`, and the success screen to show:
   - order value before points;
   - points spent;
   - residual payment;
   - estimated/pending, credited, restored, reversed, and expired states.
7. Payment retry is hidden whenever `totalAmount == 0`, regardless of older
   response flags.

### Navigation and localization

- Recognize `enjoylavash://loyalty` in
  `mobile_push_notification_service.dart` and route it from
  `main_tabs.dart`.
- Add every new visible string to `app_en.arb`, `app_ru.arb`, and
  `app_uz.arb`.
- Run `flutter gen-l10n`; never manually edit generated
  `app_localizations*.dart` files.
- Format points using the existing UZS/number formatter; do not append a
  fractional currency.

## Test checklist

### Models and repository

- Parse a complete wallet, a debt wallet, nullable expiry, and unknown ledger
  type.
- Parse old orders with no loyalty fields and new orders in every loyalty
  status.
- Serialize zero, partial, and full `loyaltyRedemptionAmount`.
- Verify `Idempotency-Key` is present and is reused on an identical retry.
- Preserve `errorCode` and `metadata.maxPointsToSpend`.
- Verify cursor refresh replaces and load-more appends without duplicates.

### Controller

- Bootstrap/resume/terminal order refresh the wallet.
- Logout and authentication failure clear all loyalty state.
- A late response cannot restore state after logout.
- Concurrent history loads do not duplicate entries.

### Checkout widgets

- No points, partial points, maximum points, clear, and debt-disabled states.
- Product/promo/address/payment changes invalidate the preview.
- Full-points checkout works with no active online gateway and opens no URL.
- `LOYALTY_AMOUNT_CHANGED` preserves the cart, clears points, refreshes, and
  re-previews.
- A timeout retry reuses the same idempotency key.

### Wallet and orders

- Empty history, paginated history, debt warning, and expiring summary.
- Pending, earned, no-reward, refunded, reversed, and legacy order rendering.
- Loyalty push and inbox deep links open/refetch the wallet.
- Dark theme, narrow device, and large text do not overflow.

Run:

```bash
flutter gen-l10n
dart format lib test
flutter analyze
flutter test
```

## Phased delivery checklist

1. Models, structured errors, endpoints, repository methods, and contract
   tests.
2. Wallet/controller lifecycle and cursor history.
3. Checkout preview, exact redemption, idempotent create, and full-points
   behavior.
4. Wallet screen, profile entry point, order presentation, and deep links.
5. EN/RU/UZ localization, accessibility/widget tests, analyze, and full test
   suite.

Do not enable loyalty for the production organisation until a mobile version
containing all five phases is the minimum supported version.
