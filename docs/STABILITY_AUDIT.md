# Stability, security and performance audit — October 2026

Scope: leaks (memory, data, secrets), app-breaking behaviour, crashes and
runtime performance of `enjoy_lavash_mobile` 1.2.3+21 on Flutter 3.47.4.
Method: three parallel code sweeps (all 45 `State` classes for lifecycle; every
secret / log / storage / platform-config site for security; JSON parsing,
startup, token refresh, cart, checkout, auth and controller races for crashes),
one performance sweep, and direct reads of bootstrap, API client, storage, push,
repository and checkout code. Every finding was verified against the source.

Baseline before remediation: `flutter test` green (217 tests), `flutter analyze`
2 warnings + 1 info, `dart format` would touch 4 files.

What is already solid and was **not** flagged: single-flight token refresh with
session generations, idempotent order creation with retry, request-version
guards in the controller, cart reconciliation against the live catalog,
`Result`/`Failure` everywhere, every `setState` after `await` is
`mounted`-guarded, the cart-flight overlay is removed on every path, HTTPS
everywhere with ATS on and cleartext off in release, no WebViews, push payloads
cannot launch arbitrary URLs, Android `MainActivity` guards `startActivity`.

Severity: **P0** wrong money or secret exposure · **P1** silent production
breakage or data exposure · **P2** hygiene / debt.

## Status

| Phase | Scope | Status |
| --- | --- | --- |
| 1 | Secrets and data exposure | ✅ done |
| 2 | Ordering correctness | ✅ done |
| 3 | Infra resilience: storage, interceptors, startup | ✅ done |
| 4 | Observability, force update, iOS push tap | ✅ done |
| 5 | Session hygiene and state races | ✅ done |
| 6 | Lifecycle and memory | ✅ done (lazy location permission left as a product decision) |
| 7 | Dependencies, platform and build hygiene | ✅ done (keychain change and tile provider left as decisions) |
| 8 | UX safety nets | ✅ done |
| 9 | Performance: rendering, images, allocation | ✅ done |
| 10 | Performance: state scope and network | ✅ done |

## Open after remediation

All ten phases are implemented. What remains needs a person, an account or a
product decision:

| Item | Owner | Why it is open |
| --- | --- | --- |
| Rotate both Yandex API keys and restrict them in the Yandex console; put the new keys in `.env.json` and CI secrets | Mobile lead | The old keys are in git history (P0-2). Until keys are supplied, address suggestions are off |
| Create the Sentry project; pass `SENTRY_DSN` in release builds; upload the symbols from `build/symbols/` | Mobile lead | Crash reporting is a no-op without a DSN (Phase 4) |
| Tap a real push on an iPhone, cold start and running | QA | The iOS tap path is unit-tested but not device-verified (Phase 4) |
| Location permission: on first launch (today) or on first address/branch pick | Product | Friendlier for App Review, but Home shows no delivery address until then (Phase 6) |
| iOS keychain `first_unlock_this_device` and keychain cleanup after reinstall | Mobile lead | A reinstalled app stays signed in today; needs a device test (Phase 7) |
| Map tile provider (licensed provider or OSM permission), then set `MAP_TILE_URL` | Product | The public OSM server may throttle or block the app (P2-13) |
| `pinput` stays on 6.x | Mobile lead | 7.0 breaks the OTP screen (pulls `material_ui`); revisit when it supports the app's `Material` |
| Backend asks below | Backend team | Logout revocation, OTP lifetime, order paging, demo OTP config |

## Findings

### P0

| ID | Area | Issue | Where | Fix (phase) |
| --- | --- | --- | --- | --- |
| P0-1 | Money | `_normalizePrice` divides any price ≥ 100 000 UZS divisible by 100 by 100. `API_DOCS.md:7,2211`: prices are whole UZS, "do not divide by 100 in the app". Server preview is not rescaled, so cart ≠ checkout by 100× for such items. | `catalog_model.dart:210,340,451-454` | ✅ heuristic deleted (2). Confirmed live on 2026-10-07: "4 сезон 40см" (110 000), "Enjoy Pizza 45см" and "Комбинированная 45см" (105 000) were shown as 1 100 / 1 050 |
| P0-2 | Secrets | Two Yandex API keys hardcoded and in git history. | `yandex_geocoder_service.dart` | ✅ moved to `--dart-define`; **keys must still be rotated in the Yandex console** (1) |
| P0-3 | Session | Expired refresh token at cold start: profile 401 fails the whole `bootstrap()`, auth is cleared and status becomes `loaded` with no catalog. Empty menu, no error, only pull-to-refresh recovers. | `mobile_backend_repository_impl.dart:620-636`, `mobile_backend_bootstrap_controller.dart:123-127`, `mobile_backend_state_controller.dart:33-36` | ✅ profile 401 loads as guest with the catalog (2) |

### P1

| ID | Area | Issue | Where | Fix (phase) |
| --- | --- | --- | --- | --- |
| P1-1 | Privacy | Order-create request/response and cart preview `debugPrint`ed unconditionally (address, door code, coordinates, comment, `paymentUrl`); `debugPrint` writes to the device log in release. | `main_tabs.dart` `_logCheckoutPayload` | ✅ debug-only + `redactSensitiveLogFields` (1) |
| P1-2 | Auth | OTP expiry compares server `codeExpiresAt` with the device clock; a fast device clock makes every code "expired" and blocks login. | `authorization_screen.dart:164-171,237-249,274-280` | ✅ countdown anchored to the server-measured lifetime (HTTP `Date` header) (2) |
| P1-3 | Storage | `TokenStorage` never catches `PlatformException` (Android keystore invalidated after backup restore / OS update); reads sit in `bootstrap()` and the Dio interceptors. | `token_storage.dart`, `api_client.dart:122,179,237` | ✅ try/catch + self-heal (3) |
| P1-4 | Network | Dio 5.9 does not await async interceptor callbacks; a throw inside `onRequest`/`onError` never completes `handler.future`, the request hangs forever. | `api_client.dart:119-172` | ✅ handler always completed (3) |
| P1-5 | Startup | A throw before `runApp` (`setupDi`, `loadTheme`, `loadLocale`) only `debugPrint`s; the app stays on the native splash. | `main.dart:36-57` | ✅ defaults on failure (3) |
| P1-6 | Observability | No crash/error reporter. | `main.dart:96-108` | ✅ `ErrorReporter` / `sentry_flutter`, DSN from dart-define (4) |
| P1-7 | Ops | `AppVersionGate` and `getAppVersionPolicy` exist but nothing wires them; no force-update path. | `app_version_gate.dart`, `app.dart` | ✅ wired, non-blocking (4) |
| P1-8 | Orders | After timeout/5xx on create, "Close" keeps the cart and the next checkout mints a new idempotency key → possible duplicate order. | `main_tabs.dart:1276-1313` | ✅ `OrderSubmissionKeys`: one key per payload until a definite answer; history refreshed after an unknown outcome (2) |
| P1-9 | Security | `ExternalUrlLauncher` and both native channels opened any scheme. Inputs: `paymentUrl`, banner links, store URL. | `external_url_launcher.dart`, `MainActivity.kt`, `AppDelegate.swift` | ✅ `https` only; payment/store host allowlists; native re-check (1) |
| P1-10 | Build | Release build silently fell back to the debug signing key without `key.properties`. | `android/app/build.gradle.kts` | ✅ release packaging tasks fail loudly (1) |
| P1-11 | Backup | `allowBackup` defaults to true, no backup rules: secure-storage files are backed up, keystore keys are not → P1-3 on restore. | `AndroidManifest.xml` | ✅ backup off + extraction rules (3) |
| P1-12 | Push (iOS) | No `GoogleService-Info.plist`; Firebase init fails (caught) so `onMessageOpenedApp` never fires; AppDelegate lacks `userNotificationCenter(_:didReceive:)`. Push tap does not deep-link on iOS. | `mobile_push_notification_service.dart:132-160,519-535`, `AppDelegate.swift` | ✅ native tap → APNs channel → `PushNotificationMessage` (4); verify on a device |
| P1-13 | UX | `_guard` wraps non-Dio exceptions as `UnknownFailure(error.toString())`; 12 screens render `failure.message` raw, so Dart error text reaches users in English. | `mobile_backend_repository_impl.dart:673-681` and the `failure.message` sites | ✅ `failureMessage` / `failureDetail` (3) |
| P1-14 | Cart | `CartSelection.fromJson` uses `as` casts; `CartStorage` catches only `FormatException`. A wrong-typed persisted field throws every launch and is never removed. | `cart_line.dart:30-34,66-67`, `cart_storage.dart:28` | ✅ json helpers + catch-all (2) |

### P2

| ID | Area | Issue | Where | Fix (phase) |
| --- | --- | --- | --- | --- |
| P2-1 | Memory | `MapController` never disposed (flutter_map only disposes its own). | `map_picker_screen.dart:20,45-48` | ✅ 6 |
| P2-2 | Memory | `CurvedAnimation`s never disposed. | `map_picker_screen.dart:344`, `address_bottom_sheet.dart:63`, `app_version_gate.dart:221,226`, `menu_screen.dart:434`, `main_tabs.dart:1354` | ✅ 6 |
| P2-3 | Memory | New `YandexGeocoderService` (new `Dio`) per address sheet open and one in `LocationController`; was without timeouts. | `address_bottom_sheet.dart:48`, `main.dart:40` | ✅ timeouts (1); one shared instance (6) |
| P2-4 | Memory | Banner images decoded at full resolution (no `cacheWidth`). | `home_screen.dart:632`, `banner_image_card.dart:27` | ✅ 6 |
| P2-5 | Battery | Order-status poll (8 s) keeps running in background and after session expiry (logout cascade per tick). | `order_details_sheet.dart:58-79` | ✅ 5 |
| P2-6 | Privacy | Cart, promo code, typed address, pending push message survive logout / session expiry / user switch; push registration not removed on session expiry. | `main_tabs.dart`, `mobile_backend_state_controller.dart`, `mobile_backend_auth_controller.dart:100-102` | 5 |
| P2-7 | Races | Controller writes to `_client`/lists lack a session guard; bootstrap after login nulls `_client`; `_refreshCustomerData` can restore a logged-out user; stale refresh failure can `_logout()` a fresh login; `_refreshCatalog` has no request version; `_clearAuthenticatedState` flips `loading`→`loaded`; double `_performLogout` on retry-401. | `mobile_backend_bootstrap_controller.dart`, `api_client.dart:139,160-162,223-224`, `mobile_backend_state_controller.dart:33-36` | 5 |
| P2-8 | UX | Cart lines silently deleted on catalog refresh / branch change; repeat-order silently drops products with required modifiers; no upper quantity limit. | `main_tabs.dart:166-227,495-529,383-407` | ✅ 8 |
| P2-9 | UX | Location permission requested on first frame; `handleAppResumed` fires push sync + 3 requests on every resume. | `app.dart:30-45`, `mobile_backend_notifications_controller.dart:216-229` | 6 |
| P2-10 | Deps | Unused `mobile_scanner` (adds CAMERA permission + ML Kit) and `accordion_widget`; legacy-only `vibration`, `table_calendar`, `path_provider`; `NSCameraUsageDescription` for an unused camera. | `pubspec.yaml`, `Info.plist:29-30` | ✅ 7 |
| P2-11 | Deps | Behind latest: dio, firebase_*, flutter_secure_storage 10→11, permission_handler 11→13, get_it 8→9, share_plus 12→13, pinput 6→7, package_info_plus 9→10; exact pins on `flutter_svg`, `shared_preferences`. | `pubspec.yaml` | ✅ 7 (pinput held at 6.x) |
| P2-12 | Platform | Android launcher label is `enjoy_lavash_mobile`; iOS keychain accessibility `unlocked`; no `--obfuscate` release script; no CI. `.gitignore` gaps. | `AndroidManifest.xml:7`, `token_storage.dart:4` | ✅ gitignore (1); rest 3 / 7 |
| P2-13 | External | Map picker uses the public OSM tile server (policy forbids app distribution without permission). | `map_picker_screen.dart:111` | 7 |
| P2-14 | Lint | `unawaited_return_in_try_block` ×2, deprecated `cacheExtent`, `getRefreshTokenExpiresAt` unused. | `yandex_geocoder_service.dart`, `menu_screen.dart:556` | 6 / 7 |
| P2-15 | Checkout | Working-hours gate fails closed if backend sends `is_open`; no `sendTimeout`. | `ordering_status_model.dart:101`, `api_client.dart:30-31` | 7 / 3 |

### Performance

Ranked by expected user-visible impact. Already fine and not listed: tabs are built lazily on
first visit (`PageView` + keep-alive), no `BackdropFilter`/`ShaderMask`/`saveLayer`, no
`CustomPainter` with `shouldRepaint => true`, `RepaintBoundary` around menu and cart items,
leaf widgets are `const` almost everywhere, fonts are ~350 KB, no raster asset over 300 KB,
the catalog adapter groups/sorts once per load, geocoder suggest is debounced and cached.

| ID | Area | Issue | Where | Fix (phase) |
| --- | --- | --- | --- | --- |
| PERF-1 | Render | Product grid is a `Wrap` inside `SliverToBoxAdapter`: every card of the selected category (all products for "All") is built, laid out and its image requested at once; `RenderWrap` paints all N on every scroll frame; `cacheExtent: 1200` has no effect on a box sliver. | `menu_screen.dart:617-621,1036-1068,556` | ✅ lazy row sliver (9) |
| PERF-2 | Rebuilds | `_MainTabsState.build` does `context.watch<MobileBackendController>()` and every cart `+`/`−` calls `setState` on it. One tap, or any of the **45** `_notifyListeners()` sites (8 s order poll included), rebuilds Home, the whole Menu grid, Cart and the nav. `_buildCartLines`, totals, `promotions.where(isActive)` (never read by `MenuScreen`) recomputed per build; `takePendingPushMessage()` mutates the provider inside build; `_persistCart` writes prefs on every tap. | `main_tabs.dart:1448-1484,386-462,1517-1625` | ✅ `CartController` + selected shell fields (10) |
| PERF-3 | Allocation | `formatSum` constructs `NumberFormat.decimalPattern(language)` on every call (34 sites, once per card per rebuild); 15 `DateFormat` sites likewise. | `utils/price_formatter.dart:6`, `product_list_item.dart:220`, `order_helpers.dart:8,13` | ✅ `format_cache.dart` (9) |
| PERF-4 | Startup | Bootstrap: two sequential secure-storage reads, then `/clients/me` → addresses → orders **in series** while public calls run in parallel; the catalog is applied only after both. Every protected request re-reads the token from secure storage (8–10 platform reads at startup). `runApp` waits on SharedPreferences. | `mobile_backend_repository_impl.dart:85-86,127-136,620-636`, `api_client.dart:117-127`, `main.dart:54-57` | ✅ parallel customer calls + in-memory token (10) |
| PERF-5 | Images | No disk cache (no `cached_network_image`): every product/banner/category image re-downloads on each cold start. Banners and category tiles decode at full source size; the grid and the detail hero use different resize keys so opening a product downloads the URL again and the Hero lands on the placeholder. Drawer logo decoded at 512 px for a 28 px slot. | `pubspec.yaml`, `banner_image_card.dart:27`, `home_screen.dart:632`, `product_image.dart:24-30`, `main_tabs_drawer.dart:114` | ✅ disk cache + `cacheWidth` (9); the detail hero now re-decodes from disk instead of re-downloading |
| PERF-6 | Polling | 8 s order poll → `refreshOrder` notifies unconditionally even when nothing changed → whole-app rebuild; not paused in background; in-flight request finishes after dispose. | `order_details_sheet.dart:58-78`, `mobile_backend_order_controller.dart:81-96` | ✅ change-only notify (10), lifecycle pause (5) |
| PERF-7 | Network | Checkout preview: `TextEditingController` listeners do not compare text, so cursor moves, focus and IME composing clear `_previewDetails` (Confirm flickers to loading) and send a new preview POST; `_useMaximumPoints`/`_clearPoints` invalidate twice; payment-method change previews with no debounce. | `order_confirmation_sheet.dart:73-74,156-179,511-530` | ✅ `textChangeListener` (10) |
| PERF-8 | Frames | `AnimatedErrorMessage` repeats forever and its `AnimatedBuilder` rebuilds the whole card (blur shadow, texts, button) every frame; no `TickerMode` anywhere, so an error card on a kept-alive off-screen tab keeps forcing frames; Profile shows it for any background `failure`. Repeating `Opacity` pulses in the address sheet and map picker. | `animated_error_message.dart:34-37,88-117`, `profile_redesign.dart:99-107`, `address_bottom_sheet.dart:442-479` | ✅ icon-only animation, 6 cycles, `TickerMode` per tab (9) |
| PERF-9 | Rebuilds | `MenuScreen` watches `LocationController` and backend addresses from its own State context (for one subtitle string), so the whole grid rebuilds on every address-sheet keystroke; each notify re-runs `didChangeDependencies` → `_cartAnimation.preload` + a post-frame `setState`. | `menu_screen.dart:146-152,237-246,657` | ✅ address slices selected (10) |
| PERF-10 | Network | Fan-out: every resume does push-token POST (no "token unchanged" shortcut) + 3 GETs with no throttle (also when returning from the payment page); loyalty wallet is awaited **before** navigating, then fetched again by the screen; `refreshCustomerData` runs 5 calls in series; a push message fetches unread count and the list (which already carries the count); first Promotions visit refetches; pull-to-refresh is ~13 requests. No `CancelToken` anywhere. | `mobile_backend_notifications_controller.dart:216-250`, `main_tabs.dart:293-300,366-371,630-639`, `mobile_backend_bootstrap_controller.dart:4-79`, `mobile_push_notification_service.dart:209-345` | ✅ all but `CancelToken` (10) |
| PERF-11 | Allocation | `AppTextStyles.ui/display` return a new `TextStyle` per call (96 sites, 4 per card); `cardShadow(context)` returns a new list per call (11 sites); 196 non-const `BorderRadius.circular`; `TypographyText` merges styles per build; `FadeSlideIn` creates `Tween().animate()` per build; nav SVG strings interpolated per build. | `theme/app_design_tokens.dart:99-145`, `widgets/typography.dart:26-43`, `fade_slide_in.dart:86-95`, `main_tabs_bottom_navigation.dart:267-277` | ✅ const shadows and hot radii (9); text styles left as is, see Phase 9 |
| PERF-12 | Lists | `assigned_promotions_screen.dart:97-130` builds every promo card in `ListView(children:)` on a kept-alive tab rebuilt per notify; `all_orders_screen.dart:24-57,95-104,175` re-sorts and re-filters (with `formatSum` per order) on every notify and every search keystroke, no debounce; `cart_screen.dart:194-200` `findChildIndexCallback` is O(n²) because `CartLine.key` builds and sorts strings per call; `notifications_screen.dart:160-169` re-filters per build. | as listed | ✅ (9); the 50-item notification filter was left as is |
| PERF-13 | Memory | `_loyaltyTransactions` grows by 50 per page, each page copies the list and rebuilds an id set (O(n²)), never trimmed after the wallet closes; `_orders` holds the full unpaged history and is copied on every poll; ~3 idle tickers per product card (5–6 when in cart) × all products because the grid is eager; `ImageCache` unconfigured. | `mobile_backend_loyalty_controller.dart:113-120`, `mobile_backend_order_controller.dart:113-123`, `product_list_item.dart`, `quantity_button.dart:15` | ✅ trim on close, lazy grid (9); paged orders remain a backend ask |
| PERF-14 | Rebuilds | Address sheet watches `LocationController` and its own `onChanged` handlers write into it, so the whole sheet rebuilds per keystroke. Smaller single-slice watchers that should use `context.select`: `branch_bottom_sheet.dart:39-43`, `profile_edit_screen.dart:91`, `delete_account_sheet.dart:44`, `saved_addresses_screen.dart:136`, `profile_redesign.dart:34-46`, `order_confirmation_sheet.dart:630`. | `address_bottom_sheet.dart:138,266-368` | ✅ (10) |
| PERF-15 | Correctness | Home's address label is built with `context.read<LocationController>()` inside build, so Home never subscribes to location changes and the label only updates when the backend happens to notify. | `main_tabs.dart:710-721,1662-1668` | ✅ (10) |

## Phases

Each phase is one working session. Run `flutter analyze`, `flutter test` and
`dart format` on changed files before closing a phase; update
`PROJECT_STRUCTURE.md` when files move. Tick the Status table above.

### Phase 1 — Secrets and data exposure ✅

- Yandex keys read from `YANDEX_GEOCODER_KEY` / `YANDEX_SUGGEST_KEY` dart-defines; lookups are
  disabled (not failing) when empty; 10 s timeouts on the geocoder client.
- Checkout logging is `kDebugMode`-only and passes through `redactSensitiveLogFields`
  (`lib/utils/log_redaction.dart`).
- `ExternalUrlLauncher` opens `https` only; `paymentLinkHosts` for `paymentUrl`,
  `appStoreLinkHosts` for the update prompt; `MainActivity.kt` and `AppDelegate.swift` re-check
  the scheme. `supportedBannerLink` follows the same policy (plain `http` banners are inert).
- Release packaging tasks throw when `key.properties` is missing.
- `.gitignore` covers Firebase iOS config, `.env.*`, keystores and provisioning profiles.
- Tests: `external_url_launcher_test`, `yandex_geocoder_service_test`, `log_redaction_test`.
- **Manual follow-up:** rotate both Yandex keys and restrict them in the Yandex console; add the
  new keys to the local `env.json` / CI secrets; restrict the Firebase Android key in GCP.

### Phase 2 — Ordering correctness ✅ (P0-1, P0-3, P1-2, P1-8, P1-14)

- `catalog_model.dart`: `_normalizePrice` deleted; prices are read as whole UZS. The production
  catalog was checked on 2026-10-07 (91 products, all whole UZS) and three pizzas were affected.
  `catalog_model_test` now covers 100 000, 105 000 and 110 000.
- `mobile_backend_repository_impl.dart`: a 401 on `/clients/me` during bootstrap (after the
  interceptor's refresh attempt) returns guest auth data, so the catalog loads. 5xx still
  propagates (session preserved). Test: `bootstrap_auth_preservation_test` "expired session…".
- OTP: `OtpRequestResponse.codeLifetimeFrom` measures the lifetime against the server clock
  from the HTTP `Date` header; the screen counts that duration down from the device's now.
  Without the header a non-positive lifetime falls back to `fallbackOtpLifetime` (2 min) and a
  very long one is capped at `maxOtpLifetime` (15 min). The client-side expiry block is kept
  because it is now consistent with the server. Tests: `auth_models_test`,
  `authorization_screen_migration_test` "a fast device clock…".
- `lib/features/checkout/order_submission_keys.dart`: one `Idempotency-Key` per exact payload,
  kept after network errors, timeouts and 5xx (order may exist), released on success or any
  definitive answer. After an unknown outcome `refreshCustomerData()` reloads history.
  Test: `order_submission_keys_test`.
- `CartSelection.fromJson` / `CartModifierSelection.fromJson` use `readString`/`readInt`;
  `CartStorage` drops unreadable data on any error. Tests in `cart_storage_test`.

### Phase 3 — Infra resilience ✅ (P1-3, P1-4, P1-5, P1-11, P1-13, part of P2-7)

- `token_storage.dart`: reads catch `PlatformException`, delete the session and return null
  (signed out instead of broken); writes retry once after deleting the stale entry; `clear()`
  never throws. `TokenStorage.storage` is injectable for tests.
- `api_client.dart`: `onRequest`/`onError` complete their handler on every path (recovery moved
  to `_recoverFromAuthError`); a rejected replay logs out once (was twice); a refresh that
  started before a new login no longer signs that login out; `sendTimeout` added (15 s).
- `ThemeController.loadTheme` / `LocaleController.loadLocale` fall back to defaults (and the
  locale only accepts supported codes); `main.dart` runs them as a guarded startup task.
- Android: `allowBackup="false"`, `fullBackupContent="false"`, `res/xml/data_extraction_rules.xml`
  excludes everything from cloud backup and device transfer; launcher label `Enjoy Lavash`.
- `lib/widgets/utils/failure_message.dart`: `failureMessage` (standalone text) and
  `failureDetail` (under a heading). Localized server copy passes through; network/timeout use
  app copy; English constructor defaults and Dart/Dio exception text are replaced. All 15 raw
  `failure.message` sites now use it. No new `.arb` keys were needed.
- Tests: `api_client_test` (keystore failure never hangs, single logout, stale refresh),
  `failure_message_test`, `startup_preferences_test`.

### Phase 4 — Observability, force update, iOS push tap ✅ (P1-6, P1-7, P1-12)

- `sentry_flutter` 8.14 behind `lib/core/services/error_reporter.dart`. Initialised only when
  `SENTRY_DSN` is defined; `sendDefaultPii`, print breadcrumbs, screenshots and performance
  tracing are off. Sentry chains onto the app's `FlutterError.onError` /
  `PlatformDispatcher.onError` (which now only log locally), and `ErrorReporter.report` covers
  zone errors and caught startup-task failures, so each error is sent once.
- `AppVersionGate` takes an `AppVersionPolicyLoader` (from
  `MobileBackendController.getAppVersionPolicy`) and is `MaterialApp.home`. It no longer shows a
  splash while loading: the app renders at once and the prompt is stacked over it, so a soft
  dismissal keeps all state and an offline launch is not delayed. `resolveForCurrentVersion`
  prompts only builds older than `latestVersion`. Tests: `app_version_gate_test`,
  `app_version_policy_model_test`.
- iOS: `AppDelegate` implements `userNotificationCenter(_:didReceive:)`, forwards the custom
  payload as `notificationOpened` on `enjoy_lavash_mobile/apns`, and keeps a cold-start tap until
  Dart calls `takeLaunchNotification`. `PushNotificationMessage.fromPayload` parses top-level or
  `data`-nested keys. Test: `ios_notification_tap_test`.
- **Manual follow-up:** create the Sentry project and pass `SENTRY_DSN` in release builds; tap a
  real push on an iPhone (cold start and running) to confirm the deep link.

### Phase 5 — Session hygiene and races ✅ (P2-5, P2-6, P2-7)

- `MobileBackendController._sessionGeneration` is bumped on login (`verifyOtp`) and whenever the
  session is cleared. Bootstrap, `refreshCustomerData` (checked after every await), profile and
  language updates, address CRUD, order create/refresh/retry and notification read/unread
  capture it and drop late results. A bootstrap that finishes after a login or logout still
  applies public data (catalog, branches, banners) but leaves the customer state alone.
- `_refreshCatalog` and `_bootstrap` share `_catalogRequestVersion`; bootstrap also bumps the
  payment-methods version so a branch-specific refresh is not overwritten.
- `_clearAuthenticatedState` no longer flips `loading` → `loaded` (two bootstraps could run).
  A bootstrap auth failure now ends in `error` with the failure kept, so the retry UI shows and
  reloads as a guest.
- `sessionEnded` stream with `SessionEndReason` (`signedOut`, `accountDeleted`, `expired`).
  `MainTabs` clears the cart (memory and `CartStorage`), promo code and
  `LocationController` personal data on sign-out and deletion; an expired session keeps them.
  The pending push message is dropped for every reason, and session expiry also forgets the
  local push registration.
- Order details: polling stops when signed out or on an `AuthFailure`, pauses when the app is
  backgrounded, and refreshes on resume.
- Notifying after `dispose` is a no-op.
- Also fixed: the last raw `failure.message` sites (Profile logout snackbar, notifications).
- Test: `mobile_backend_session_test` (late guest bootstrap after login, late refresh after
  logout, session end reasons, no concurrent bootstrap).

### Phase 6 — Lifecycle and memory ✅ (P2-1 to P2-4, P2-9, P2-14)

- `map_picker_screen.dart` disposes its `MapController` and pulse `CurvedAnimation`; the address
  sheet and the update prompt dispose theirs.
- `lib/widgets/curved_fade_transition.dart`: `CurvedFadeTransition` owns one curved animation
  per route; used by the product detail and order success routes instead of an inline
  `CurvedAnimation` per rebuild.
- The address sheet no longer creates its own `YandexGeocoderService`/`Dio`; it calls
  `LocationController.suggestAddresses`, which reuses the app-wide instance.
- Banners and Home category tiles decode at slot width (`lib/widgets/utils/image_decode_size.dart`,
  `decodeWidthFor`), like product images already did.
- `handleAppResumed` refreshes at most once per `resumeRefreshInterval` (30 s); the controller
  takes an injectable clock for tests.
- Analyzer is fully clean: the geocoder `unawaited_return_in_try_block` warnings are fixed (the
  rate limiter still spaces request starts) and `cacheExtent` became `scrollCacheExtent`.
- **Not changed, needs a product decision:** location permission is still requested on the
  first frame (`InitialLocationLoader`, covered by `initial_location_loader_test`). Asking when
  the customer first opens the address/branch picker is friendlier for App Review, but Home
  would show no delivery address until then.
- Tests: `mobile_backend_session_test` (resume throttle), `home_screen_test` (banner decoded via
  `ResizeImage`).

### Phase 7 — Dependencies, platform and build hygiene ✅ (P2-10 to P2-13, P2-15)

- Deleted, after a reachability check from `lib/main.dart` and all tests: the legacy B2B data
  layer `lib/core/data/` and its four DI registrations and admin endpoints, `lib/enums/`,
  `lib/widgets/theme/`, `lib/widgets/ui/` (including the dead `QuantityField`), the unused
  legacy widgets, `app_navigator.dart`, `EmptyList` and `NotFoundScreen` (which pointed at a
  missing asset). Unused redesign widgets (`MainButton`, `MyIconButton`, `WhiteContainer`)
  were kept.
- Removed packages: `mobile_scanner`, `accordion_widget`, `table_calendar`, `vibration`,
  `path_provider`; removed `NSCameraUsageDescription`. The merged Android manifest now declares
  only location, internet, network state, notifications and wake lock (unused biometric
  permissions from `flutter_secure_storage` are stripped with `tools:node="remove"`).
- Upgraded: `flutter_secure_storage` 11.2 (every install already used v10's format, so no data
  loss), `permission_handler` 13, `get_it` 9, `share_plus` 13, `package_info_plus` 10,
  `sentry_flutter` 9.30 (8.x failed to compile on Android: Kotlin language version 1.6).
  Exact pins on `flutter_svg` / `shared_preferences` relaxed to carets.
  **`pinput` stays on 6.x:** 7.0 pulls in the standalone `material_ui` package and its
  `Pinput` no longer finds the app's `Material`, which broke the OTP screen.
- `scripts/build_release.sh <apk|appbundle|ipa> [env-file]`: obfuscated release with
  `--split-debug-info=build/symbols/<target>` and `--dart-define-from-file` (default
  `.env.json`, gitignored).
- `.github/workflows/ci.yml`: format check, `flutter analyze`, `flutter test` on PRs and `main`
  (Flutter 3.47.4). The whole tree is `dart format`-clean.
- Map picker: tile URL from `MAP_TILE_URL` (default OpenStreetMap); the tile User-Agent now
  uses the real application ID.
- `OrderingAvailabilityModel` also reads `is_open`.
- Verified: `flutter build apk --debug` succeeds.
- **Left as decisions, not changed:**
  - iOS keychain accessibility (`first_unlock_this_device`) and clearing the keychain after a
    reinstall: today a reinstalled app stays signed in. Changing it needs a device test;
    `flutter_secure_storage` 11.2 now finds items across accessibility levels, which makes the
    migration safer to try.
  - Skipping the profile call when the stored refresh-token expiry has passed: it would trust
    the device clock (the same trap as the old OTP bug) to save one request, so it was not done.
  - Map tile provider: choose a licensed provider (or get OSM permission) and set `MAP_TILE_URL`.

### Phase 8 — UX safety nets ✅ (P2-8)

- `maxCartLineQuantity` (99) in `cart_line.dart`. Quantity changes are capped with a
  "You can add up to 99 of one item" message; an add from the menu that cannot change the cart
  throws `CartLineLimitReached`, which the menu's add flow shows instead of a false "added".
- When catalog reconciliation (catalog refresh, branch change, cold-start restore) removes saved
  lines, the customer sees which items went ("No longer available, removed from your cart: …")
  or a generic notice when a removed product's name is unknown.
- Repeat order uses the product's standard configuration (`standardCartSelection`) instead of
  an empty modifier list, caps quantities, and names products it could not add.
- New strings in uz/ru/en: `cartQuantityLimitReached`, `cartItemsUnavailable`,
  `cartSomeItemsUnavailable`, `repeatOrderSkipped`.
- Test: `cart_safety_nets_test` (removal notice, repeat order, quantity cap).

### Phase 9 — Performance: rendering, images, allocation ✅ (PERF-1, 3, 5, 8, 11, 12, 13)

- **Lazy menu grid** (`menu_screen.dart`): the `Wrap` in a box sliver became a
  `SliverList.separated` of rows (2 or 3 columns by width) inside a `SliverLayoutBuilder`, so
  cards are built and their images requested only as they scroll into view, and
  `scrollCacheExtent` now actually applies. Test: `menu_lazy_grid_test` (60 products → only
  the visible rows are built; scrolling to the end builds the last one and releases the first).
- **Formatters** (`lib/utils/format_cache.dart`): `decimalFormat(locale)` and
  `dateFormat(locale, skeleton, create)` keep one `intl` instance per locale/skeleton;
  `formatSum` and every per-row `NumberFormat`/`DateFormat` site use them.
- **Disk image cache** (`lib/widgets/utils/cached_image_provider.dart`): `DiskCachedNetworkImage`
  over `flutter_cache_manager` (`AppImageCacheManager`: 600 objects, 14-day stale period), used
  through `resizedNetworkImage()` by `ProductImage`, `BannerImageCard` and Home category tiles,
  so photos are not downloaded again on every cold start. `cached_network_image` was tried and
  dropped: it pulls in `material_ui`, the package that broke the OTP screen (Phase 7).
  `test/flutter_test_config.dart` swaps `NetworkImage` in for all widget tests. A failed load
  is evicted from the memory cache so the next build retries.
- **Error card** (`animated_error_message.dart`): text and buttons are built once; only the icon
  halo listens to the controller (inside its own `RepaintBoundary`), and the pulse stops after
  six cycles. `_KeepAliveTabPage` wraps each tab in `TickerMode(enabled: active)`, so animations
  on off-screen tabs no longer schedule frames.
- **Allocation**: `AppDesignTokens.cardShadow` returns one of two `static const` lists; the
  product and cart card radii are `const`; the drawer logo decodes at 28 px. `AppTextStyles` and
  `TypographyText` still build a `TextStyle` per call: measured against layout cost that is
  noise, and a memo keyed on four fields would cost about as much as the allocation.
- **Lists**: assigned promotions render through `SliverList.separated`; the order history
  memoises its filtered list on `(orders, branches, addresses, locale, query, filters)` and
  debounces the search field (250 ms); the cart's `findChildIndexCallback` uses a map built once
  per build.
- **Memory**: `MobileBackendController.releaseLoyaltyTransactions()` drops loaded pages when the
  wallet screen closes. `ImageCache` keeps Flutter's default limits (100 MB / 1000 images): with
  decode-at-display-size everywhere the catalog fits comfortably.
- Verified: `flutter analyze` clean, 267 tests green, Android and iOS debug builds (see Status).

### Phase 10 — Performance: state scope and network ✅ (PERF-2, 4, 6, 7, 9, 10, 14, 15)

- **Cart out of the shell's `setState`**: `lib/features/cart/presentation/cart_controller.dart`
  (`CartController`, `CartSnapshot`) holds the lines, persists every change and caches the
  resolved lines/totals per (cart version, catalog). `MainTabs` owns one and only the menu tab,
  the cart tab and the bottom bar listen to it (`ListenableBuilder`); the add-to-cart arrival
  pulse is a `ValueNotifier`. Business rules (cap, reconciliation notices, repeat order) stay in
  `MainTabs`. Test: `cart_controller_test`.
- **Shell rebuild scope**: `MainTabs` selects a `_ShellData` record of the 12 backend fields it
  renders instead of watching the controller; pending push messages are taken from a listener
  instead of inside `build`. Test: `shell_rebuild_scope_test` (a cart tap and an unrelated
  backend notification leave Home's widget instance untouched).
- **Narrow watchers**: checkout sheet, Profile, saved addresses, branch sheet, profile edit and
  delete-account sheet `select` only the fields they render. `MenuScreen` selects the address
  slices for its pill (saved addresses only when nothing was picked), preloads packaging once,
  and Home's delivery label now follows address edits.
- **Address sheet**: the five apartment fields keep their text locally and commit once through
  `LocationController.setAddressDetails` on confirm or close, instead of notifying (and
  rebuilding the menu) on every keystroke.
- **Startup**: profile, addresses and orders are requested in parallel; the access token is kept
  in memory by `TokenStorage` (one keystore read per session instead of one per request).
  Test: `startup_requests_test` pins a signed-in cold start at 11 distinct requests, each once.
  A two-phase bootstrap (render the catalog before the customer data) was not needed once the
  customer calls run in parallel.
- **Polling**: `refreshOrder` notifies only when the order payload changed (test in
  `mobile_backend_session_test`).
- **Checkout preview**: `textChangeListener` (`lib/widgets/utils/text_change_listener.dart`) makes
  the promo and points fields react only to text edits, so cursor, focus and keyboard composing
  no longer clear the total and re-request the preview. Test: `text_change_listener_test`.
- **Fan-out**: `refreshCustomerData` starts its five reads together; a push message refreshes the
  inbox only (it carries the unread count); the wallet opens immediately; an unchanged push
  registration is re-posted at most every 24 h (`registrationRefreshInterval`); the Promotions
  tab skips its first fetch when the same list loaded within a minute
  (`hasFreshAssignedPromotions`). App resume was already throttled in Phase 6.
- **Not done:** `CancelToken`s per screen. Every late response is already dropped by `mounted`
  checks, request versions or the session generation, so cancelling would only save bandwidth.

## Backend asks

- Confirm every endpoint sends whole UZS (P0-1).
- `POST /auth/client/logout` to revoke the refresh token; call it from `logout()`.
- `expiresInSeconds` (or `serverTime`) in the OTP response so expiry is clock-independent.
- Confirm `OTP_DEMO_PHONE_WHITELIST` / `OTP_DEMO_CODE` (`API_DOCS.md:59-62`) are off in prod.
- Optional: proxy Yandex geocoding/suggest so no key ships in the app.
- Paging for `GET /clients/me/orders` (PERF-13); the full history is fetched on every bootstrap.
- `GET /catalog` has no paging either; confirm the expected product count stays in the low hundreds.
