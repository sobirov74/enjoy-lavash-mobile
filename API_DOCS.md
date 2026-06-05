# Enjoy Lavash API Documentation

**Base URL**: `http://localhost:3000`
**Swagger UI**: `http://localhost:3000/docs`
**Content-Type**: `application/json`

All money values are integers in UZS (e.g., `3200000` = 32,000 UZS).
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
  "codeExpiresAt": "2026-06-01T12:05:00.000Z",
  "demoCode": "1111"
}
```

> `demoCode` is returned only in dev mode. In production, SMS will be sent.

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

Returns the full nested catalog with localized names.

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
          "basePrice": 3200000,
          "oldPrice": null,
          "calories": 620,
          "weightGrams": 360,
          "cookingTimeMinutes": 12,
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
                  "price": 700000,
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
  "itemsAmount": 3200000
}
```

**Response 200:**

```json
{
  "branch": { "id": "branch-chilanzar", "name": "...", ... },
  "deliveryDistanceMeters": 2150,
  "deliveryAmount": 1000000
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
  "itemsAmount": 6400000,
  "modifiersAmount": 1000000,
  "discountAmount": 1480000,
  "deliveryAmount": 1000000,
  "serviceFeeAmount": 0,
  "totalAmount": 6920000,
  "appliedPromotion": { "id": "...", "code": "FIRST20", ... },
  "items": [
    {
      "productId": "prod-classic-lavash",
      "productNameSnapshotI18n": { "ru": "Классический лаваш", ... },
      "quantity": 2,
      "unitPrice": 3200000,
      "modifiersAmount": 1000000,
      "totalPrice": 7400000,
      "modifiers": [...]
    }
  ]
}
```

### Promotions

| Method | Endpoint             | Description            |
| ------ | -------------------- | ---------------------- |
| GET    | `/promotions/active` | List active promotions |

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

| Method | Endpoint                        | Description      |
| ------ | ------------------------------- | ---------------- |
| GET    | `/clients/me/orders`            | List my orders   |
| GET    | `/clients/me/orders/:id`        | Get order detail |
| POST   | `/clients/me/orders`            | Create order     |
| POST   | `/clients/me/orders/:id/cancel` | Cancel order     |

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
    },
    {
      "productId": "prod-cola",
      "quantity": 1
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

If iiko is enabled, order creation pushes the order to iiko after local persistence.
The response includes `iikoOrderId` when iiko accepts the order; otherwise it is `null`.

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

### Branches

| Method | Endpoint                           | Permission        | Description                 |
| ------ | ---------------------------------- | ----------------- | --------------------------- |
| POST   | `/admin/branches`                  | `branches.create` | Create branch               |
| PATCH  | `/admin/branches/:id`              | `branches.update` | Update branch               |
| DELETE | `/admin/branches/:id`              | `branches.delete` | Delete branch               |
| PATCH  | `/admin/branches/:id/availability` | `branches.update` | Update product availability |

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
5. **Prices**: All prices are in UZS. Display as `price / 100` if storing in tiyins, but currently stored as whole UZS (e.g., `3200000` = 3,200,000 UZS = 32,000 sum).
6. **Images**: Prepend base URL to image paths (e.g., `http://localhost:3000/uploads/products/classic-lavash.jpg`).
7. **Swagger**: Full interactive docs at `/docs` with all request/response schemas.
