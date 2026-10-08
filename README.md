# enjoy_lavash_mobile

A new Flutter project.

Home banners use the public, global `GET /banners/active` endpoint on launch
and home refresh. No login token or organisation ID is sent. Only Home displays
the returned banners, in API order, with localized titles and image paths
resolved against the backend origin. Empty responses hide the carousel.

Tapping a linked promotion opens its details without applying a discount.
`https` links open externally (plain `http` and other schemes are ignored).
Supported app links are `enjoylavash://home`,
`menu`, `cart`, `profile`, `promotions`, `orders`, `notifications`, and `loyalty`
(using the same scheme). Banners without targets or with unsupported links
remain non-interactive. Cart eligibility is still evaluated by the backend.

See [BANNERS_API.md](BANNERS_API.md) for the contract. Existing promotions do not
automatically become banners; banner records must be created in the backend.

## Build configuration

No secrets live in the source tree. Everything environment-specific is passed
with `--dart-define`, or collected in a gitignored `.env.json` and passed with
`--dart-define-from-file=.env.json`:

| Define | Purpose | Default |
| --- | --- | --- |
| `API_BASE_URL` | Backend origin | `https://api.enjoylavash.uz` |
| `ORGANISATION_ID` | Organisation sent with catalog requests | empty |
| `YANDEX_GEOCODER_KEY` | Yandex Geocoder HTTP API key (reverse geocoding) | empty → lookup disabled |
| `YANDEX_SUGGEST_KEY` | Yandex Suggest API key (address autocomplete) | empty → suggestions disabled |
| `ENABLE_NETWORK_LOGS` | Dio request/error logging in non-debug builds | `false` |
| `SENTRY_DSN` | Sentry project DSN for crash and error reporting | empty → reporting off, nothing sent |
| `APP_ENV` | Sentry environment tag (`production`, `staging`) | `production` |
| `MAP_TILE_URL` | Map picker tile URL template | public OpenStreetMap server |

```sh
flutter run \
  --dart-define=YANDEX_GEOCODER_KEY=… \
  --dart-define=YANDEX_SUGGEST_KEY=…
```

Without the Yandex keys the app still runs; the address sheet simply offers no
suggestions and the map picker shows coordinates without a street name.

Release builds go through `scripts/build_release.sh <apk|appbundle|ipa>
[env-file]`, which obfuscates Dart code and writes debug symbols to
`build/symbols/<target>`. Keep those symbols for every release (and upload them
to Sentry), or crash stack traces cannot be read.

Release builds on Android require `android/key.properties` (gitignored) with
`storeFile`, `storePassword`, `keyAlias` and `keyPassword`. The build fails
instead of falling back to the debug key.

CI (`.github/workflows/ci.yml`) runs `dart format` check, `flutter analyze`
and `flutter test` on every pull request and push to `main`.

Force/soft updates: on launch the app asks `GET /app-version` for its
platform and version and, when the backend says so, shows an update prompt
over the running app (a forced update cannot be dismissed). A failed request
shows nothing, so startup never waits on it.

External links (`paymentUrl`, store links, banner links) are opened only when
they are `https`; payment and store links are additionally restricted to the
hosts listed in `lib/core/services/external_url_launcher.dart`.

Known issues and the remediation phases are tracked in
[docs/STABILITY_AUDIT.md](docs/STABILITY_AUDIT.md).

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
