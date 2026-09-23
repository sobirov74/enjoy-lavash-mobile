# enjoy_lavash_mobile

A new Flutter project.

Home banners use the public, global `GET /banners/active` endpoint on launch
and home refresh. No login token or organisation ID is sent. Only Home displays
the returned banners, in API order, with localized titles and image paths
resolved against the backend origin. Empty responses hide the carousel.

Tapping a linked promotion opens its details without applying a discount.
HTTP(S) links open externally. Supported app links are `enjoylavash://home`,
`menu`, `cart`, `profile`, `promotions`, `orders`, `notifications`, and `loyalty`
(using the same scheme). Banners without targets or with unsupported links
remain non-interactive. Cart eligibility is still evaluated by the backend.

See [BANNERS_API.md](BANNERS_API.md) for the contract. Existing promotions do not
automatically become banners; banner records must be created in the backend.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
