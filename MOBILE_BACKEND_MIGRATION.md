# Mobile App Backend Migration

This document lists mobile-client changes required by the staged backend
security and reliability release. It is a migration guide, not a complete API
reference. Existing API paths remain unchanged unless a replacement is shown.

## Where to Change the Mobile App

Exact filenames depend on the mobile repository, but these frontend areas need
review:

| Mobile area | Required update |
| --- | --- |
| OTP response model and API client | Remove `demoCode`; add `codeExpiresAt`, `429`, and `503` handling. |
| OTP/login screens | Drive expiry and resend state from `codeExpiresAt`; never display a backend-supplied code. |
| Auth store and HTTP interceptor | Keep client tokens separate, rotate refresh tokens, and sign out after failed refresh. |
| Branch model/cache | Remove `payme` and `click` properties. |
| Checkout payment selector | Load methods from `/payment-methods?branchId=...`. |
| Push registration service | Persist the returned registration `id` and delete by ID. |
| Orders repository/cache | Remove phone-based merging and refetch durable server state. |
| Account settings | Confirm deletion and clear all local personal/session data afterward. |
| API error mapper | Add explicit behavior for `409`, `413`, `429`, and `503`. |

## Required Changes

### 1. OTP requests no longer return a code

`POST /auth/request-otp`

Request:

```json
{
  "phoneNumber": "+998901234567"
}
```

Response:

```json
{
  "phoneNumber": "+998901234567",
  "codeExpiresAt": "2026-07-11T10:15:00.000Z"
}
```

- Remove all parsing and display logic for `demoCode`.
- Use `codeExpiresAt` to drive the resend timer and expiry UI.
- Whitelisted test phones still use the shared `OTP_DEMO_CODE`, but the code is
  never sent in the API response. Obtain that code from the test environment
  configuration, not from the backend response.
- A code has five verification attempts and is consumed after successful use.
- Treat `429` as a rate-limit response and disable resend until the retry period.
- Treat `503` as SMS temporarily unavailable. Do not open the verification screen
  as though an SMS was sent for non-whitelisted phones.

`POST /auth/verify-otp` and its successful response fields remain unchanged.

### 2. Handle forced reauthentication and token separation

Admin and client access tokens now have different JWT kinds, issuers, audiences,
subjects, and IDs. A client token cannot call admin endpoints, and an admin token
cannot call `clients/me` endpoints.

- Keep mobile tokens in storage separate from any admin-web credentials.
- On an access-token `401`, call `POST /auth/client/refresh` once.
- Replace both stored tokens with the returned `access_token` and `refresh_token`.
- If refresh returns `401`, clear the session and return to mobile login.
- Expect all users to authenticate again when the deployment rotates `JWT_SECRET`.

The login response still contains:

```json
{
  "access_token": "...",
  "refresh_token": "...",
  "refresh_token_expires_at": "2026-10-09T10:00:00.000Z",
  "token_type": "Bearer",
  "client_created": false,
  "client": {}
}
```

### 3. Do not read gateway configuration from branches

The public endpoints below no longer return `payme` or `click` objects:

- `GET /branches`
- `GET /branches/:id`

Use `GET /payment-methods?branchId=<branch-id>` to decide which payment methods
to show. The mobile app must never need merchant IDs, secret previews, service
IDs, or merchant-user IDs.

The public payment-method response is:

```json
[
  {
    "id": "...",
    "code": "PAYME",
    "name": "Payme",
    "isOnline": true,
    "sortOrder": 2,
    "icon": null
  }
]
```

### 4. Store push registration IDs

`POST /clients/me/push-tokens` returns the push-token registration record. Store
its `id` alongside the device token.

Use the new deletion route when logging out, replacing a token, or disabling
notifications:

```http
DELETE /clients/me/push-token-registrations/:id
Authorization: Bearer <client-access-token>
```

Response:

```json
{ "deleted": true }
```

The old `DELETE /clients/me/push-tokens/:rawToken` route remains for one
compatibility release and must be removed from the mobile client during this
migration. Do not place raw push tokens in URLs or client logs.

### 5. Treat order ownership as account-ID based

`GET /clients/me/orders` now returns only orders whose `clientId` is the
authenticated client's ID. The backend no longer falls back to phone-number
matching.

- Remove any phone-number order-history query or merge logic.
- Do not assume a recycled phone number grants access to older orders.
- Existing order create, detail, cancel, and retry-payment paths are unchanged.
- Online payment and status mutations are durable across backend restarts; keep
  polling/refetch behavior based on the returned order state rather than local
  optimistic state alone.

### 6. Account deletion is final

`DELETE /clients/me` now transactionally revokes sessions, disables push tokens,
removes addresses, and anonymizes profile and order personal data.

- Show a destructive confirmation before calling it.
- On success, clear access tokens, refresh tokens, cached addresses, cached
  profile data, push registration IDs, and locally stored order PII.
- Do not attempt token refresh after successful deletion.

## Error Handling

The backend now validates request DTOs strictly and rejects unknown fields.

| Status | Mobile behavior |
| --- | --- |
| `400` | Show field validation feedback; remove obsolete request properties. |
| `401` | Refresh once, then sign out if refresh fails. |
| `404` | Treat the record as unavailable; do not infer tenant or ownership details. |
| `413` | Reject the oversized request locally where possible. |
| `429` | Apply resend/action cooldown and avoid automatic request loops. |
| `503` | Show temporary service unavailability and allow a manual retry. |

## Unchanged Mobile Routes

These routes keep their existing request and response contracts:

- `GET/PATCH/DELETE /clients/me`
- `GET/POST/PATCH/DELETE /clients/me/addresses...`
- `POST /clients/me/cart/preview`
- `GET/POST /clients/me/orders`
- `GET /clients/me/orders/:id`
- `POST /clients/me/orders/:id/cancel`
- `POST /clients/me/orders/:id/retry-payment`
- `GET /clients/me/notifications`
- `GET /clients/me/notifications/unread-count`
- `POST /clients/me/notifications/:notificationId/read`
- `POST /clients/me/notifications/read-all`
- `GET /catalog`, `GET /catalog/products...`, and `GET /promotions/active`

## Mobile Release Checklist

- Remove `demoCode` from models, fixtures, analytics, and UI.
- Add explicit `429` and `503` OTP states.
- Verify refresh-token replacement and forced logout behavior.
- Remove `payme` and `click` from the branch model.
- Resolve available payment methods through `/payment-methods`.
- Persist and delete push registrations by record ID.
- Remove phone-based order-history behavior.
- Add account-deletion confirmation and complete local-data cleanup.
- Smoke test normal OTP, whitelisted OTP, expired OTP, and five invalid attempts.
- Smoke test cash, Payme, and Click order flows after an app restart.
