# Mobile Working Hours and Ordering

## Overview

Use the branch ordering-status endpoint to present pickup and delivery
availability before checkout. Treat it as display guidance: cart preview and
order creation remain authoritative because the branch, schedule, and cart can
change between requests.

The API evaluates schedules in the branch organisation's timezone (falling
back to `Asia/Tashkent` when none is configured). Pickup and delivery have
independent time windows and therefore must be rendered as separate states.

## Endpoint

```http
GET /branches/:id/ordering-status?at=2026-08-10T18%3A15%3A00.000Z
```

`at` is an optional ISO date-time. Omit it to evaluate availability now. The
endpoint is public and does not require a bearer token. A missing branch
returns `404`; an invalid `at` returns `400`.

## Response types

```ts
type WorkingHourSource = 'BRANCH' | 'ORGANISATION' | 'DEFAULT_24_HOURS';
type ClosureSource =
  | 'BRANCH_DAY_OFF'
  | 'ORGANISATION_DAY_OFF'
  | 'WEEKLY_CLOSED'
  | 'OUTSIDE_HOURS';

interface EffectiveWorkingHour {
  weekday: number;
  opensAt: string;
  closesAt: string;
  isClosed: boolean;
  deliveryOpensAt: string;
  deliveryClosesAt: string;
  source: WorkingHourSource;
}

interface OrderingAvailability {
  isOpen: boolean;
  evaluatedAt: string;
  timezone: string;
  localDate: string;
  weekday: number;
  weeklySource: WorkingHourSource;
  closureSource: ClosureSource | null;
  nextOpeningAt: string | null;
}

interface OrderingStatusResponse {
  branchId: string;
  timezone: string;
  evaluatedAt: string;
  weeklyHours: EffectiveWorkingHour[];
  pickup: OrderingAvailability;
  delivery: OrderingAvailability;
}
```

`weekday` uses `1` for Monday through `7` for Sunday. `source` identifies the
rule selected for a weekly row; `weeklySource` identifies the rule used for the
evaluated local day. `closureSource` is `null` when that order type is open.

The public response never contains a private day-off reason. Use only the
returned closure source to choose generic customer-facing copy.

## Example response

This complete response shows separate pickup and delivery availability. At the
evaluated time, pickup remains open while delivery has already closed.

```json
{
  "branchId": "branch-chilanzar",
  "timezone": "Asia/Tashkent",
  "evaluatedAt": "2026-08-10T18:15:00.000Z",
  "weeklyHours": [
    {
      "weekday": 1,
      "opensAt": "09:00",
      "closesAt": "24:00",
      "isClosed": false,
      "deliveryOpensAt": "10:00",
      "deliveryClosesAt": "23:00",
      "source": "BRANCH"
    },
    {
      "weekday": 2,
      "opensAt": "09:00",
      "closesAt": "24:00",
      "isClosed": false,
      "deliveryOpensAt": "10:00",
      "deliveryClosesAt": "23:00",
      "source": "BRANCH"
    },
    {
      "weekday": 3,
      "opensAt": "09:00",
      "closesAt": "24:00",
      "isClosed": false,
      "deliveryOpensAt": "10:00",
      "deliveryClosesAt": "23:00",
      "source": "BRANCH"
    },
    {
      "weekday": 4,
      "opensAt": "09:00",
      "closesAt": "22:00",
      "isClosed": false,
      "deliveryOpensAt": "10:00",
      "deliveryClosesAt": "21:30",
      "source": "ORGANISATION"
    },
    {
      "weekday": 5,
      "opensAt": "09:00",
      "closesAt": "22:00",
      "isClosed": false,
      "deliveryOpensAt": "10:00",
      "deliveryClosesAt": "21:30",
      "source": "ORGANISATION"
    },
    {
      "weekday": 6,
      "opensAt": "00:00",
      "closesAt": "24:00",
      "isClosed": false,
      "deliveryOpensAt": "00:00",
      "deliveryClosesAt": "24:00",
      "source": "DEFAULT_24_HOURS"
    },
    {
      "weekday": 7,
      "opensAt": "00:00",
      "closesAt": "00:00",
      "isClosed": true,
      "deliveryOpensAt": "00:00",
      "deliveryClosesAt": "00:00",
      "source": "ORGANISATION"
    }
  ],
  "pickup": {
    "isOpen": true,
    "evaluatedAt": "2026-08-10T18:15:00.000Z",
    "timezone": "Asia/Tashkent",
    "localDate": "2026-08-10",
    "weekday": 1,
    "weeklySource": "BRANCH",
    "closureSource": null,
    "nextOpeningAt": null
  },
  "delivery": {
    "isOpen": false,
    "evaluatedAt": "2026-08-10T18:15:00.000Z",
    "timezone": "Asia/Tashkent",
    "localDate": "2026-08-10",
    "weekday": 1,
    "weeklySource": "BRANCH",
    "closureSource": "OUTSIDE_HOURS",
    "nextOpeningAt": "2026-08-11T05:00:00.000Z"
  }
}
```

## Availability rules

- A branch day off closes that branch. An organisation day off closes all
  branches unless that branch has an explicit open override for the date.
- `WEEKLY_CLOSED` means the effective weekly row is closed; `OUTSIDE_HOURS`
  means the evaluated time is outside the relevant pickup or delivery window.
- An opening boundary is inclusive and a closing boundary is exclusive. For
  example, a `09:00`–`22:00` window is open at `09:00` and closed at `22:00`.
- Windows may continue past midnight. The status endpoint handles the previous
  day's overnight window and date overrides for it.
- `nextOpeningAt` is `null` while open and can also be `null` when the server
  cannot find a future opening. Do not infer an opening time from weekly hours
  alone.

## Immediate flow

1. Fetch ordering status for the selected pickup branch, or for a delivery
   branch the user is viewing. Show pickup from `pickup` and delivery from
   `delivery`.
2. For an immediate checkout, allow continuation only when the relevant state
   is open. Refresh status after a meaningful delay or before enabling the
   final submit action.
3. Preview the cart, then create the order. Both operations validate ordering
   availability again; the server result wins if the state changed.

Use authenticated preview requests:

```http
POST /clients/me/cart/preview
Authorization: Bearer <client-access-token>
Content-Type: application/json
Accept-Language: en

{
  "type": "PICKUP",
  "branchId": "branch-chilanzar",
  "scheduledFor": "2026-08-10T13:00:00.000Z",
  "items": [{ "productId": "prod-classic-lavash", "quantity": 1 }],
  "paymentMethod": "CASH"
}
```

For pickup, `branchId` is required and the selected branch is validated. For
delivery, provide an address or saved `addressId`; the backend selects an
eligible delivery branch automatically. When supplied, a delivery `branchId`
must identify an eligible delivery candidate; otherwise the preview or order is
rejected.

## Scheduled flow

1. Convert the customer's chosen local date and time to an ISO instant, then
   request `GET /branches/:id/ordering-status?at=<ISO>` for the selected
   pickup branch. Use the matching pickup or delivery state to guide the slot.
2. Send the ISO instant as `scheduledFor` in both preview and order creation.
   It must be in the future.
3. A scheduled order must be open **now** and at `scheduledFor`. Delivery
   auto-selection applies both checks to candidate branches, so a preview can
   return a different eligible branch or reject the request if none qualifies.

Create the order through the authenticated endpoint. Use a stable UUID
`Idempotency-Key` for retries; it is required when redeeming loyalty points and
recommended for every creation request.

```http
POST /clients/me/orders
Authorization: Bearer <client-access-token>
Content-Type: application/json
Accept-Language: en
Idempotency-Key: 931488c1-512b-4f15-b71a-1aeb10158336

{
  "type": "PICKUP",
  "branchId": "branch-chilanzar",
  "scheduledFor": "2026-08-10T13:00:00.000Z",
  "items": [{ "productId": "prod-classic-lavash", "quantity": 1 }],
  "paymentMethod": "CASH"
}
```

Order creation recalculates the cart, resolves the final branch, and performs
the final current and scheduled availability checks before order persistence or
online payment-attempt creation.

## 409 handling

When an availability check fails during preview or creation, the localized API
returns HTTP `409` with `errorCode: "ORDERING_CLOSED"`. The customer-facing
`message` follows `Accept-Language`; use the metadata for state handling.

```json
{
  "statusCode": 409,
  "error": "Conflict",
  "errorCode": "ORDERING_CLOSED",
  "message": "Ordering is currently closed",
  "language": "en",
  "path": "/clients/me/orders",
  "timestamp": "2026-08-10T18:15:03.000Z",
  "metadata": {
    "branchId": "branch-chilanzar",
    "orderType": "DELIVERY",
    "checkKind": "SCHEDULED",
    "evaluatedAt": "2026-08-11T05:00:00.000Z",
    "timezone": "Asia/Tashkent",
    "closureSource": "OUTSIDE_HOURS",
    "nextOpeningAt": "2026-08-11T06:00:00.000Z"
  }
}
```

For `checkKind: "CURRENT"`, close the immediate checkout action and offer the
next opening time when present. For `checkKind: "SCHEDULED"`, preserve the
cart but require a different scheduled time; the branch may be open now. When
`nextOpeningAt` is `null`, use fallback copy such as “Ordering is currently
unavailable. Please choose another branch or try again later.” Do not disclose
internal closure details.

## Time display

All returned instants—top-level `evaluatedAt`, each availability
`evaluatedAt`, and `nextOpeningAt`—are UTC ISO strings. `at` and
`scheduledFor` are also ISO instants. Convert instants to the returned
`timezone` for schedule UI; use `localDate` and `weekday` as the server's local
evaluation context. The weekly clock strings are local times in that timezone,
not UTC timestamps.

Avoid using the device timezone to interpret a branch's weekly hours. Label
the selected branch timezone when it differs from the device setting.

## Payment behavior

Schedule validation applies to cart preview and new order creation. It does
not block payment retries for an already-created order, provider callbacks,
completion, cancellation, or refunds. If an online payment retry is available,
continue the existing-order payment flow rather than creating a new order.

## Implementation checklist

- Model pickup and delivery as independent availability objects.
- Fetch status without `at` for immediate UI and with `at` for a selected
  scheduled instant.
- Send `scheduledFor` unchanged to authenticated preview and creation calls.
- Require a pickup `branchId`; for delivery, send the customer's address and
  accept the backend-selected branch from the preview.
- Parse the localized API error envelope and handle `ORDERING_CLOSED` from
  both preview and creation.
- Use `nextOpeningAt` when available; otherwise show generic unavailable copy.
- Keep one idempotency UUID for retries of the same create-order submission.

## QA checklist

- Verify a status response returns seven weekly rows and both availability
  objects.
- Verify pickup can be open while delivery is closed for the same branch.
- Verify the opening minute is accepted and the closing minute is rejected.
- Verify a branch day off, an organisation day off, and a weekly closed day
  show their respective public closure source without extra detail.
- Verify an immediate order fails with `checkKind: "CURRENT"` when closed.
- Verify a scheduled order fails when closed now and when closed at its chosen
  future instant.
- Verify delivery succeeds only after backend branch selection and that a
  no-eligible-branch response keeps the cart editable.
- Verify a `409` with a null `nextOpeningAt` uses generic unavailable copy.
- Verify an existing online-payment retry remains available even while new
  ordering is closed.

## Related docs

- [Mobile Order Preview API](./MOBILE_ORDER_PREVIEW_API.md) — authenticated
  preview fields, pricing, promotions, loyalty, and the general error envelope.
- [Admin order creation API](./ADMIN_ORDER_CREATION_API.md) — administrative
  order creation contract; it is not the mobile client endpoint.
