# Mobile Client Authorization and Refresh Tokens

This project has two authorization flows:

- Mobile clients use OTP login: `POST /auth/request-otp`, `POST /auth/verify-otp`, then `POST /auth/client/refresh`.
- Admin users use username/password: `POST /auth/login`, then `POST /auth/refresh`.

This document focuses on the mobile app flow because that is the flow that
usually causes unexpected logout when refresh tokens are not stored or rotated
correctly.

## Token Types

### Access token

Use the access token in protected client API requests:

```http
Authorization: Bearer <access_token>
```

The access token is a JWT. Its lifetime is controlled by:

```env
JWT_ACCESS_TTL_SECONDS=3600
```

Default: 3600 seconds, which is 1 hour.

### Refresh token

Use the refresh token only to get a new access token:

```http
POST /auth/client/refresh
Content-Type: application/json

{ "refresh_token": "<refresh_token>" }
```

The mobile client refresh token lifetime is controlled by:

```env
CLIENT_REFRESH_TTL_SECONDS=7776000
```

`7776000` seconds is 90 days. If this env var is not set, the code default is
also 90 days.

## Login Flow

### 1. Request OTP

```http
POST /auth/request-otp
Content-Type: application/json

{ "phoneNumber": "+998901234567" }
```

Response:

```json
{
  "phoneNumber": "+998901234567",
  "codeExpiresAt": "2026-07-08T12:05:00.000Z"
}
```

### 2. Verify OTP

```http
POST /auth/verify-otp
Content-Type: application/json

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
  "access_token": "eyJhbG...",
  "refresh_token": "W0H5...",
  "refresh_token_expires_at": "2026-10-06T12:00:00.000Z",
  "token_type": "Bearer",
  "client_created": false,
  "client": {
    "id": "uuid",
    "phoneNumber": "+998901234567"
  }
}
```

Store both `access_token` and `refresh_token`. Also store
`refresh_token_expires_at` if the app wants to show a session expiry state.

## Refresh Flow

When an API request returns `401` because the access token expired, call:

```http
POST /auth/client/refresh
Content-Type: application/json

{ "refresh_token": "W0H5..." }
```

Response:

```json
{
  "access_token": "eyJhbG-new...",
  "refresh_token": "new-refresh-token...",
  "refresh_token_expires_at": "2026-10-06T13:00:00.000Z",
  "token_type": "Bearer",
  "client_created": false,
  "client": {
    "id": "uuid",
    "phoneNumber": "+998901234567"
  }
}
```

Important: refresh tokens rotate. After every successful refresh, the old
refresh token is deleted and becomes invalid. The app must replace both stored
tokens immediately:

- Save the new `access_token`.
- Save the new `refresh_token`.
- Save the new `refresh_token_expires_at`.
- Retry the original failed request with the new access token.

## Why Users Get Logged Out

Common causes:

- The app keeps using the old refresh token after refresh. Because refresh tokens rotate, the second use of the old token returns `401 Invalid refresh token`.
- Multiple API requests fail with `401` at the same time and each one calls `/auth/client/refresh`. The first refresh succeeds; the others reuse the old refresh token and fail.
- `CLIENT_REFRESH_TTL_SECONDS` is set too low in the backend environment.
- The client is blocked in admin. Blocked clients cannot authenticate or refresh.
- The database is not enabled or not initialized. In that case refresh sessions may be in memory and can disappear after server restart.

## Recommended App Behavior

Use a single refresh operation at a time. If five requests receive `401`, only
the first request should call `/auth/client/refresh`; the other requests should
wait for that refresh result and then retry with the new access token.

Recommended logic:

1. Send protected requests with `Authorization: Bearer <access_token>`.
2. If the response is not `401`, handle it normally.
3. If the response is `401`, start one shared refresh request.
4. While refresh is running, queue or wait for other failed requests.
5. On refresh success, persist the new access and refresh tokens.
6. Retry queued requests with the new access token.
7. On refresh failure because the refresh token is invalid or expired, clear
   tokens and show OTP login.

Pseudo-code:

```ts
let refreshPromise: Promise<AuthResponse> | null = null;

async function refreshSession() {
  if (!refreshPromise) {
    refreshPromise = api
      .post('/auth/client/refresh', {
        refresh_token: await storage.getRefreshToken(),
      })
      .then(async (response) => {
        await storage.setAccessToken(response.access_token);
        await storage.setRefreshToken(response.refresh_token);
        await storage.setRefreshTokenExpiresAt(
          response.refresh_token_expires_at,
        );
        return response;
      })
      .finally(() => {
        refreshPromise = null;
      });
  }

  return refreshPromise;
}
```

## App Rebuilds, Push Tokens, and Orders

If a rebuild or app update preserves secure storage, keep the user logged in by
calling `/auth/client/refresh` with the stored refresh token when the access
token expires. Do not clear tokens just because an access token is expired.

If a rebuild wipes secure storage, the backend cannot restore the session
without verification. Request OTP again for the same phone number. The existing
client account is reused and `client_created` returns `false`.

Register the current push token after login, app startup, and rebuild:

```http
POST /clients/me/push-tokens
Authorization: Bearer <access_token>
Content-Type: application/json
```

Use the authenticated order endpoints for active order polling:

```http
GET /clients/me/orders
GET /clients/me/orders/:id
```

The backend lists orders by the current client id and by the OTP-verified phone
number stored on orders. Do not add or use a public phone-number order lookup;
OTP login is the phone verification step.

## How To Prolong Mobile Login

Set a longer mobile refresh token lifetime in the backend environment:

```env
# 90 days
CLIENT_REFRESH_TTL_SECONDS=7776000

# optional: keep access token short
JWT_ACCESS_TTL_SECONDS=3600
```

Then restart the backend process.

Examples:

```env
# 7 days
CLIENT_REFRESH_TTL_SECONDS=604800

# 30 days
CLIENT_REFRESH_TTL_SECONDS=2592000

# 90 days
CLIENT_REFRESH_TTL_SECONDS=7776000

# 365 days
CLIENT_REFRESH_TTL_SECONDS=31536000
```

Longer refresh tokens improve user convenience, but if a device is lost the
session can remain usable until the refresh token expires or the client is
blocked.

## Admin Token Notes

Admin access tokens also use `JWT_ACCESS_TTL_SECONDS`.

Admin refresh tokens use:

```env
JWT_REFRESH_TTL_SECONDS=2592000
```

Default: 30 days.

In the current code, admin refresh sessions are kept in memory by
`AuthRepository`. That means admin refresh tokens can be invalid after backend
restart. Mobile client refresh sessions are stored in `client_refresh_tokens`
when the database is initialized.
