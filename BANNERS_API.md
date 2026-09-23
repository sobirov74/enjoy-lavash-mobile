# Home-screen banners

Banners are global app content. The client does not need a login token or an
organisation ID. Banners have their own image, order, visibility and schedule,
and can optionally link to a promotion or another destination.

## Mobile integration

Call `GET /banners/active` on app launch and when refreshing the home screen.
Render the returned array in its existing order (lowest `sortOrder` first).
An empty array means there are currently no visible banners.

Example response (timestamps omitted here):

```json
[
  {
    "id": "3c388e2a-c809-4e15-8bab-b257418b209b",
    "titleI18n": { "uz": "20% chegirma", "en": "20% off" },
    "imageUrl": "/uploads/sale-banner.jpg",
    "promotionId": null,
    "linkUrl": "enjoylavash://menu",
    "sortOrder": 0,
    "isActive": true,
    "startDate": null,
    "endDate": null,
    "promotion": null
  }
]
```

- Resolve `/uploads/...` image paths against the backend origin. Absolute
  HTTP(S) image URLs can be used as returned.
- Select `titleI18n` using the app's current language.
- If `promotionId` is set, `promotion` contains the public promotion object
  (including its `id`, `code`, `titleI18n`, `organisationId`, `conditions` and
  `reward`). Use it to open the promotion screen. The banner API requires no
  organisation query, including for promotions from different organisations.
- Otherwise, open `linkUrl` if present. HTTP(S) and `enjoylavash://` are supported.
  Handle recognized app deep links with the mobile router.
- With neither target, display the banner without a tap action.
- `GET /banners/:id` retrieves one currently visible banner with the same shape;
  unavailable or deleted banners return 404.

Only active, non-deleted banners inside their date range are shown. Boundaries
are inclusive. Linked banners are also hidden when their promotion is missing,
deleted, inactive, not yet started, expired, at its global usage limit, or has
an `ASSIGNED_ONLY` audience. This is re-evaluated on each request.

Showing a banner does not make its promotion redeemable in every organisation.
The existing promotion organisation, cart conditions, and client usage rules
still apply during pricing. No promotion is automatically applied on a tap.

## Admin integration

Admin requests require an admin bearer token. Banner permissions manage
**global content across the whole app**, unlike organisation-scoped promotion
permissions. Only system-admin roles receive these new permissions by default;
grant them to other roles deliberately.

| Method | Endpoint | Permission |
| --- | --- | --- |
| GET | `/admin/banners` | `banners.view_list` |
| GET | `/admin/banners/:id` | `banners.view_list` |
| POST | `/admin/banners` | `banners.create` |
| PATCH | `/admin/banners/:id` | `banners.update` |
| DELETE | `/admin/banners/:id` | `banners.delete` |

Upload a JPEG, PNG, or WebP image (up to 5 MB) using `POST /files/upload`,
multipart field `file`, with `media.manage` permission. Use its returned `url`:

```http
POST /admin/banners
Authorization: Bearer <admin-token>
Content-Type: application/json

{
  "imageUrl": "/uploads/sale-banner.jpg",
  "titleI18n": { "uz": "20% chegirma", "en": "20% off" },
  "promotionId": "00000000-0000-4000-8000-000000000101",
  "sortOrder": 0,
  "isActive": true,
  "startDate": null,
  "endDate": null
}
```

Use a real promotion UUID from `GET /admin/promotions`. Only `PUBLIC` promotions
can be linked. To advertise something without a promotion, omit `promotionId`
and optionally provide `linkUrl`. A banner cannot have both targets.

`imageUrl` is required. Defaults: `titleI18n: {}`, `sortOrder: 0`,
`isActive: true`, and null targets/dates. Dates must be ISO 8601; use an explicit
timezone such as `2026-10-01T00:00:00+05:00` for predictable scheduling.

PATCH accepts only changed fields and preserves the rest. Send null to clear
`promotionId`, `linkUrl`, `startDate` or `endDate`. To change target types, clear
the old target in the same request:

```json
{ "promotionId": null, "linkUrl": "enjoylavash://menu" }
```

Set `isActive: false` to hide a banner immediately. DELETE soft-deletes it and
returns 204. Neither operation deletes the uploaded image or promotion.
Admin list/detail endpoints include disabled and out-of-schedule banners.

## Deployment

Apply `1790121700000-CreateBanners` with `pnpm migration:run`, then restart the
updated backend. The existing `deploy.sh` already runs migrations before reload.
The migration creates the banner table and permissions. Existing promotions
are not automatically converted into banners: create a banner and attach the
promotion explicitly. Swagger includes the new endpoints and request schemas.
