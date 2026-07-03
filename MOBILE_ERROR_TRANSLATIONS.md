# Mobile Error Translations

The API returns localized error messages and a stable error code for mobile apps.

## Request Language

Send the user's language in `Accept-Language`:

```http
Accept-Language: ru
Accept-Language: uz
Accept-Language: en
```

Supported values are `ru`, `uz`, and `en`. If the header is missing or unsupported,
the API falls back to Russian.

## Error Response Format

```json
{
  "statusCode": 400,
  "error": "Bad Request",
  "errorCode": "PHONE_REQUIRED",
  "message": "Telefon raqami talab qilinadi",
  "language": "uz",
  "path": "/auth/request-otp",
  "timestamp": "2026-07-02T11:30:00.000Z"
}
```

For validation errors, the API also returns `details`:

```json
{
  "statusCode": 400,
  "error": "Bad Request",
  "errorCode": "VALIDATION_FAILED",
  "message": "Validation failed",
  "language": "en",
  "path": "/auth/request-otp",
  "timestamp": "2026-07-02T11:30:00.000Z",
  "details": [
    "phoneNumber must be a string",
    "phoneNumber should not be empty"
  ]
}
```

## Recommended Mobile Behavior

Use `errorCode` as the stable key. You have two options:

1. Show `message` directly from the API.
2. Translate in the mobile app by mapping `errorCode` to local strings.

The second option is better when you want full control over wording, offline
messages, or app-store-specific copy.

## Example Mobile Translation Map

```ts
export const errorMessages = {
  en: {
    PHONE_REQUIRED: 'Phone number is required',
    PHONE_INVALID_UZ: 'Phone number must be a valid Uzbekistan phone number',
    INVALID_OTP: 'Invalid or expired OTP code',
    OTP_RATE_LIMITED: 'Too many OTP requests. Please try again later.',
    CLIENT_BLOCKED: 'Client is blocked',
    UNAUTHORIZED: 'Authentication is required',
    VALIDATION_FAILED: 'Validation failed',
    INTERNAL_SERVER_ERROR: 'Internal server error',
  },
  ru: {
    PHONE_REQUIRED: 'Номер телефона обязателен',
    PHONE_INVALID_UZ: 'Номер телефона должен быть действительным номером Узбекистана',
    INVALID_OTP: 'Неверный или просроченный OTP код',
    OTP_RATE_LIMITED: 'Слишком много запросов OTP. Попробуйте позже.',
    CLIENT_BLOCKED: 'Клиент заблокирован',
    UNAUTHORIZED: 'Требуется авторизация',
    VALIDATION_FAILED: 'Ошибка валидации',
    INTERNAL_SERVER_ERROR: 'Внутренняя ошибка сервера',
  },
  uz: {
    PHONE_REQUIRED: 'Telefon raqami talab qilinadi',
    PHONE_INVALID_UZ: "Telefon raqami O'zbekiston raqami bo'lishi kerak",
    INVALID_OTP: "OTP kodi noto'g'ri yoki muddati tugagan",
    OTP_RATE_LIMITED: "OTP so'rovlari juda ko'p. Keyinroq urinib ko'ring.",
    CLIENT_BLOCKED: 'Mijoz bloklangan',
    UNAUTHORIZED: 'Avtorizatsiya talab qilinadi',
    VALIDATION_FAILED: 'Validatsiya xatosi',
    INTERNAL_SERVER_ERROR: 'Server ichki xatosi',
  },
} as const;
```

## Example Client Handler

```ts
type ApiErrorBody = {
  statusCode: number;
  errorCode?: string;
  message?: string;
  details?: string[];
};

function getErrorMessage(
  body: ApiErrorBody | undefined,
  lang: 'ru' | 'uz' | 'en',
): string {
  if (!body) return errorMessages[lang].INTERNAL_SERVER_ERROR;

  const code = body.errorCode as keyof typeof errorMessages.en | undefined;
  if (code && errorMessages[lang][code]) {
    return errorMessages[lang][code];
  }

  return body.message ?? errorMessages[lang].INTERNAL_SERVER_ERROR;
}
```

## Current Common Error Codes

| Code | Meaning |
| ---- | ------- |
| `AUTH_HEADER_REQUIRED` | Missing `Authorization` header |
| `BEARER_TOKEN_REQUIRED` | Authorization header is not `Bearer <token>` |
| `INVALID_ACCESS_TOKEN` | Admin access token is invalid |
| `ACCESS_TOKEN_EXPIRED` | Access token expired |
| `INVALID_REFRESH_TOKEN` | Refresh token is invalid |
| `INVALID_OTP` | OTP is invalid or expired |
| `OTP_RATE_LIMITED` | Too many OTP requests |
| `OTP_SEND_FAILED` | SMS provider could not send OTP |
| `CLIENT_BLOCKED` | Client account is blocked |
| `INVALID_CLIENT_TOKEN` | Client token is invalid |
| `PHONE_REQUIRED` | Phone number is missing |
| `PHONE_MUST_BE_STRING` | Phone number type is invalid |
| `PHONE_INVALID_UZ` | Phone number is not a valid Uzbekistan number |
| `FULL_NAME_REQUIRED` | Full name is missing |
| `CLIENT_PHONE_EXISTS` | Active client with the same phone already exists |
| `CLIENT_NOT_FOUND` | Client was not found |
| `ADDRESS_NOT_FOUND` | Client address was not found |
| `ORDER_NOT_FOUND` | Order was not found |
| `PRODUCT_NOT_FOUND` | Product was not found |
| `BRANCH_NOT_FOUND` | Branch was not found |
| `PAYMENT_METHOD_NOT_FOUND` | Payment method was not found |
| `PERMISSION_DENIED` | User does not have permission |
| `VALIDATION_FAILED` | DTO validation failed |
| `BAD_REQUEST` | Generic bad request fallback |
| `UNAUTHORIZED` | Generic auth fallback |
| `FORBIDDEN` | Generic permission fallback |
| `NOT_FOUND` | Generic not-found fallback |
| `INTERNAL_SERVER_ERROR` | Generic server error fallback |
