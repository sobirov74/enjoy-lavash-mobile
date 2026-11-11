# Performance pass 2 — November 2026

Second performance and structure pass after the October audit
(`docs/STABILITY_AUDIT.md`, all ten phases done). Scope: the remaining rebuild
scope, image decode sizing, time to first content, dead code, and the files that
are still over 1,000 lines. The rule for every phase: the app behaves the same for
the customer. The only intended visible changes are the saved menu at launch
(Phase 4) and sharper, undistorted product photos (Phase 3).

Baseline: `main` at 354c012 (v1.2.4+22, Flutter 3.47.4), `flutter analyze` clean,
290 tests green.

## Status

| Phase | Scope | Status |
| --- | --- | --- |
| 0 | Measure; pin checkout and cart behaviour with tests | ✅ done |
| 1 | Dead code, unused packages, repository weight | ✅ done |
| 2 | Rebuild scope (R1–R9) | ✅ done |
| 3 | Images (I1–I3) | not started |
| 4 | Instant cold start (S1) | not started |
| 5 | Smaller hot paths (F1–F8) | not started |
| 6 | Shell decomposition (`main_tabs.dart`) | not started |
| 7 | Remaining large files | not started |
| 8 | Re-measure and close | not started |

## How to measure

The harness (`integration_test/perf_test.dart`, driver `test_driver/perf_driver.dart`)
runs the real `MyApp`, repository and controllers against an in-memory fixture
server: 6 categories × 10 products with generated 720 px photos, guest customer. It
never touches the network, the keychain or the saved cart of an installed app.
Scenarios: tab taps and swipes, menu flings, category taps, five add-to-cart taps,
opening and closing three products.

```sh
# Frame timings, profile mode, Android. `-P perfBuild=true` builds the app as
# com.aurumdev.enjoy_lavash_mobile.perf, so it installs next to the store app.
flutter build apk --profile -P perfBuild=true \
  --target=integration_test/perf_test.dart
PERF_TAG=<label>-profile flutter drive --profile \
  --use-application-binary=build/app/outputs/flutter-apk/app-profile.apk \
  --driver=test_driver/perf_driver.dart \
  --target=integration_test/perf_test.dart -d <device-id>

# Widget rebuild counts per scenario: the same with --debug and app-debug.apk
# (`debugOnRebuildDirtyWidget` only runs in debug builds).
```

Results land in `build/perf/perf_<label>.json`.

- Always pass the prebuilt APK. Without `--use-application-binary`, `flutter drive`
  takes the package id from Gradle without the `.perf` suffix and, when the run
  ends, uninstalls `com.aurumdev.enjoy_lavash_mobile` (the store app and its data).
- `binding.watchPerformance` is not used: on Android its garbage-collection
  count connects to the app's own VM service and fails. The harness collects
  `FrameTiming`s and summarizes them with the same `FrameTimingSummarizer`.
- Keep the phone unlocked during a run; a locked screen ends it.
- The iOS simulator cannot run profile mode, so phone numbers come from Android.
- Baselines are measured from a `git worktree` of 354c012 with only the harness
  and the two build fixes (B1, `perfBuild`) added, so they can be repeated.

Device: Samsung Galaxy S23 (SM-S911B), Android 16, 120 Hz.

## Measurements

### After Phase 2 (2026-11-11)

Profile mode, Galaxy S23. Baseline = 354c012 in a worktree; after = Phases 0–2.
Three runs each, alternated (baseline, after, baseline, after, …).

Frames over this phone's 8.3 ms budget (120 Hz), build or raster, per run:

| Scenario | Baseline | After Phase 2 |
| --- | --- | --- |
| Menu scroll (6 flings) | 35.3 %, 39.4 %, 24.2 % | **0.3 %, 0.4 %, 0.3 %** |
| Tab switch (taps + swipes) | 4.2 %, 4.7 %, 1.8 % | 2.1 %, 3.4 %, 2.5 % |
| Category switch | 5.2 %, 4.5 %, 2.8 % | 3.8 %, 3.0 %, 3.2 % |
| Add to cart (5 taps, flight animation) | 34.0 %, 31.5 %, 3.3 % | 36.1 %, 34.3 %, 29.8 % |
| Open and close a product | 9.0 %, 9.0 %, 4.9 % | 9.0 %, 9.1 %, 9.6 % |

The first baseline run rendered about twice as many frames as all the other runs
(the panel's refresh rate differed), so its percentages are lower; the other five
runs per side are directly comparable.

Median of the three runs, frame build time (UI thread) in ms:

| Scenario | Average | 90th percentile | 99th percentile |
| --- | --- | --- | --- |
| Menu scroll | 7.5 → **1.1** | 9.9 → **1.7** | 14.8 → **6.2** |
| Tab switch | 1.7 → 1.6 | 2.8 → 3.0 | 18.9 → **5.9** |
| Category switch | 3.3 → **1.9** | 6.3 → **3.1** | 29.1 → **18.9** |
| Add to cart | 1.4 → 1.5 | 2.0 → 2.0 | 7.7 → 7.4 |
| Open and close a product | 1.6 → 1.6 | 2.1 → 2.3 | 16.6 → 17.7 |

Raster (GPU thread) times did not change, except menu scroll: average 3.6 → 4.5 ms
in every after run. It stays far under budget (90th percentile 5.3 ms) and costs
no frames. Phase 2 changed no painting; the cause was not identified.

Widget rebuilds per scenario (debug run, one each, deterministic):

| Scenario | All widgets | `ProductListItem` | `MenuScreen` | `HomeScreen` | `CartScreen` |
| --- | --- | --- | --- | --- | --- |
| Menu scroll | 991,406 → 6,146 | 15,780 → 68 | 0 → 0 | 0 → 0 | 0 → 0 |
| Tab switch | 20,108 → 4,279 | 144 → 12 | 12 → 1 | 11 → 0 | 10 → 1 |
| Category switch | 28,503 → 5,302 | 382 → 56 | 8 → 4 | 4 → 0 | 4 → 0 |
| Add to cart | 24,886 → 10,629 | 108 → 4 | 4 → 0 | 0 → 0 | 4 → 4 |
| Open and close a product | 9,842 → 9,689 | 72 → 72 | 6 → 6 | 0 → 0 | 0 → 0 |

Release APK (arm64): 12,890,138 → 12,785,744 bytes (−102 KB): bundled assets
471 → 358 KB (the unused Cupertino icon font is gone). Dart AOT code is unchanged
(9 MB; app code 992 → 1,004 KB): the deleted code was never compiled in.

Not measured: cold-start time. `--trace-startup` only times the first frame, and
the real start-up waits on the network; Phase 4 measures it with the saved-menu
change.

## Findings

### Rebuild scope

| ID | Finding | Where | Phase |
| --- | --- | --- | --- |
| R1 | A tab switch and every swipe call `setState` on the shell: Home, Menu (every built card), Cart and the bottom bar rebuild | `main_tabs.dart:552-556, 631-645` | 2 |
| R2 | The selected category is shell state: a category tap rebuilds the whole shell | `main_tabs.dart:545-549` | 2 |
| R3 | A cart `+`/`−` rebuilds `MenuScreen` and every built card, because quantities arrive as a map prop | `main_tabs.dart:1639-1699`, `menu_screen.dart:1131-1146` | 2 |
| R4 | The shell selects a 12-field record; a new orders list, wallet or unread count rebuilds all tabs | `main_tabs.dart:81-94, 1536-1551` | 2 |
| R5 | Four screens `watch` the whole backend controller; the kept-alive Promotions tab rebuilds off screen on every notification | `assigned_promotions_screen.dart:86`, `loyalty_wallet_screen.dart:77`, `notifications_screen.dart:161`, `all_orders_screen.dart:137-138` | 2 |
| R6 | Profile selects whole lists but renders only counts; it watches the whole `LocaleController` | `profile_redesign.dart:37-63` | 2 |
| R7 | The address sheet watches all of `LocationController` and `MediaQuery.of`, so it rebuilds on every keyboard animation frame | `address_bottom_sheet.dart:167-179` | 2 |
| R8 | Menu re-filters products on every build; a category tap rebuilds the grid twice; Home scans all products per category tile | `menu_screen.dart:330, 605-609`, `home_screen.dart:196, 212` | 2 |
| R9 | Found by the Phase 0 rebuild counts: the grid's `SliverLayoutBuilder` re-runs on every layout, and scrolling changes its constraints each frame. It returned a new `SliverList` each time, so every visible card rebuilt every scroll frame (15,780 card builds in the scroll scenario) and during the add-to-cart flight | `menu_screen.dart` `_buildProductGrid` | 2 |

### Images

| ID | Finding | Where | Phase |
| --- | --- | --- | --- |
| I1 | `ResizeImage` in `exact` policy: the 52×52 cart photo is squashed; the menu card and detail photos are decoded too narrow and stretched by `BoxFit.cover` | `product_image.dart:25-58`, `cached_image_provider.dart:19-29` | 3 |
| I2 | The detail Hero lands on the placeholder: different decode size, grid bitmap not reused | `menu_screen.dart:1337` | 3 |
| I3 | Two 512 px logos decoded at full size | `app_version_gate.dart:569`, `authorization_screen.dart:458` | 3 |

### Startup

| ID | Finding | Where | Phase |
| --- | --- | --- | --- |
| S1 | Nothing public is stored; every cold start shows skeletons until the public and the customer requests have all answered | `mobile_backend_repository_impl.dart:137-161` | 4 |

### Smaller hot paths

| ID | Finding | Where | Phase |
| --- | --- | --- | --- |
| F1 | Cart rows replay their entrance after scrolling back into view | `cart_screen.dart:209` | 5 |
| F2 | The order sheet calls `setState` after every 8 s poll, also when nothing changed | `order_details_sheet.dart:99` | 5 |
| F3 | Birth-date pickers rebuild the whole sheet per item crossed | `authorization_screen.dart:1211` | 5 |
| F4 | The OTP countdown rebuilds the whole screen every second | `authorization_screen.dart:195` | 5 |
| F5 | The address-label field rebuilds its sheet per keystroke | `saved_addresses_screen.dart:461` | 5 |
| F6 | Bottom-bar icons rebuild their SVG strings | `main_tabs_bottom_navigation.dart:265` | 5 |
| F7 | Eleven sites build a `DateFormat`/`NumberFormat` per call | e.g. `order_details_sheet.dart:470` | 5 |
| F8 | Measured in Phase 0: about a third of the frames during the add-to-cart flight miss the 120 Hz budget on the raster thread (blurred ground shadows and opacity layers repainted every frame) | `cart_animation_controller.dart` `_GroundShadowPainter`, `preset_packaging_visual.dart` `_PackagingPainter` | 5 |

### Dead code and packaging

| ID | Finding | Phase |
| --- | --- | --- |
| D1 | Unreachable old profile UI behind `ignore_for_file: unused_element`: `profile_sections.dart`, `settings_widgets.dart`, `profile_cards.dart` | 1 |
| D2 | `PromoSlider` is never built; only `showPromotionDetails` is used | 1 |
| D3 | Unused `MainButton`, `MyIconButton`, `WhiteContainer`, `FadeIndexedStack`, `extractErrorMessage`, `date_formatter.dart`, `theme_extensions.dart` | 1 |
| D4 | Unreferenced localization keys (52 after D1–D3) | 1 |
| D5 | Uncalled repository methods `getCatalogProduct`, `cancelOrder`, `uploadFile`, `deleteFile`, `getBranches`, `getBanner`; legacy `CartStorage.save` | 1 |
| D6 | `cupertino_icons` unused; `flutter_native_splash` listed as a runtime dependency | 1 |
| D7 | `assets/icons/` (3.6 MB, not bundled, not referenced) tracked in git; `lib/features/data/menu_catalog.dart` used only by tests | 1 |
| D8 | `flutter_svg` parses SVG at runtime only to draw the five bottom-bar icons from strings; its parser stack (`vector_graphics_compiler`, `petitparser`, `xml`, `source_span`) is about 300 KB of the 9 MB of Dart AOT code. Precompiled vector graphics or `CustomPainter` paths would remove it | decision (icons must look identical) |

### Build

| ID | Finding | Status |
| --- | --- | --- |
| B1 | Every Android profile build failed: `src/profile/AndroidManifest.xml` hard-coded `usesCleartextTraffic="true"` while the main manifest takes it from the build-type placeholder (`false` outside debug) | ✅ fixed in Phase 0: the profile manifest no longer declares it |

## Decisions recorded, not changed

- GPS coordinates can win over a saved address in the order while the label shows
  the saved one (`main_tabs.dart:1091`). Needs a product decision.
- Home and Menu format the delivery label differently (`main_tabs.dart:808` vs
  `menu_screen.dart:252`).
- A category picked from Home keeps the old grid scroll offset.
- Re-confirming the same order type re-requests payment methods.
