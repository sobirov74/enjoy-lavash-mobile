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
| 3 | Images (I1–I3) | ✅ done |
| 4 | Instant cold start (S1) | ✅ done (device check below) |
| 5 | Smaller hot paths (F1–F8) | ✅ done (F8 left as a decision) |
| 6 | Shell decomposition (`main_tabs.dart`) | ✅ done: 1,801 → 452 lines |
| 7 | Remaining large files | ✅ done: no hand-written file over 900 lines (largest was 2,042) |
| 8 | Re-measure and close | ✅ done 2026-11-12: baseline vs final on a budget phone (REDMI 15C), see "Final" below |
| Review | Independent check of everything above | ✅ done 2026-11-12: defects fixed, see "Review after the pass" |

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
- Xiaomi phones (HyperOS) ask on the phone for every USB install and cancel
  after a few seconds, and `flutter drive` reinstalls on every run. To install
  each APK once: build the variants under different ids (`-P perfSuffix=.perfb`
  and so on, default `.perf`), `adb install` them all, then per run launch the
  app (`adb shell monkey -p <id> -c android.intent.category.LAUNCHER 1`), wait
  for `All tests passed!` in `adb logcat -s flutter`, forward the VM service
  port printed there (`adb forward tcp:0 tcp:<port>`), and collect with
  `flutter drive --use-existing-app=http://127.0.0.1:<local port>/<token>/`.
  The driver then attaches only after the scenarios ran, so it never affects
  the timings. Uninstall the test apps afterwards.

Devices: Samsung Galaxy S23 (SM-S911B), Android 16, 120 Hz (Phase 2); REDMI 15C
(25078RA3EA), Android 15 / HyperOS 2, 60–120 Hz variable (final, Phase 8).

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

### Final: baseline vs Phases 0–7 (2026-11-12)

Profile mode on a budget phone: REDMI 15C (25078RA3EA), Android 15 / HyperOS
2, 720 × 1600 at 2.0 device pixel ratio, variable refresh rate (60/90/120 Hz,
mostly 90 Hz while measuring). Baseline = 354c012 with the harness added; final
= f5dcc1a (Phases 0–7 and the notification reminder). Three runs each,
alternated, plus one debug run each for rebuild counts. The S23 numbers above
stay valid for Phase 2; this phone shows how the pass does on the slow end.

Frames over the 90 Hz budget (11.1 ms), build or raster, per run:

| Scenario | Baseline | Final |
| --- | --- | --- |
| Menu scroll (6 flings) | 27.8 %, 20.5 %, 19.8 % | **2.6 %, 1.7 %, 2.5 %** |
| Tab switch (taps + swipes) | 6.8 %, 6.5 %, 6.1 % | **4.0 %, 4.2 %, 4.0 %** |
| Category switch | 39.6 %, 7.3 %, 8.8 % | 5.7 %, 7.0 %, 7.6 % |
| Add to cart (5 taps, flight animation) | 48.9 %, 49.9 %, 51.0 % | 49.1 %, 43.5 %, 49.4 % |
| Open and close a product | 18.2 %, 20.1 %, 23.0 % | 17.3 %, 18.1 %, 30.8 % |

At the phone's 120 Hz budget (8.3 ms) menu scroll goes from 81–83 % to
19–23 % of frames over budget; the other scenarios stay where they were.

Median of the three runs, frame build time (UI thread) in ms:

| Scenario | Average | 90th percentile | 99th percentile |
| --- | --- | --- | --- |
| Menu scroll | 9.5 → **1.3** | 12.9 → **1.7** | 18.7 → **7.6** |
| Tab switch | 2.3 → 1.9 | 3.4 → 3.5 | 21.6 → **8.3** |
| Category switch | 4.8 → **3.3** | 8.4 → **3.5** | 36.3 → 28.6 |
| Add to cart | 3.2 → 3.0 | 5.3 → 4.9 | 14.0 → 12.4 |
| Open and close a product | 2.7 → 2.7 | 4.3 → 4.3 | 22.9 → 24.9 |

Median of the three runs, frame raster time (GPU thread) in ms:

| Scenario | Average | 90th percentile | 99th percentile |
| --- | --- | --- | --- |
| Menu scroll | 6.5 → 7.7 | 8.0 → 8.9 | 11.4 → 12.6 |
| Tab switch | 7.3 → 7.3 | 9.2 → 9.2 | 15.5 → 15.4 |
| Category switch | 8.3 → 8.4 | 10.1 → 9.8 | 14.4 → 12.5 |
| Add to cart | 11.1 → 10.9 | 14.2 → 13.8 | 18.0 → 16.2 |
| Open and close a product | 9.6 → 9.8 | 11.8 → 12.3 | 16.0 → 15.5 |

Widget rebuilds per scenario (debug run, one each):

| Scenario | All widgets | `ProductListItem` | `MenuScreen` | `HomeScreen` | `CartScreen` |
| --- | --- | --- | --- | --- | --- |
| Menu scroll | 206,677 → 5,576 | 3,288 → 68 | 0 → 0 | 0 → 0 | 0 → 0 |
| Tab switch | 19,219 → 3,854 | 144 → 12 | 12 → 1 | 11 → 0 | 10 → 1 |
| Category switch | 11,095 → 5,202 | 106 → 56 | 8 → 4 | 4 → 0 | 4 → 0 |
| Add to cart | 13,775 → 9,561 | 60 → 4 | 4 → 0 | 0 → 0 | 4 → 4 |
| Open and close a product | 8,703 → 8,688 | 72 → 72 | 6 → 6 | 0 → 0 | 0 → 0 |

What the numbers say:

- **Menu scroll**, the most used screen, is the large win: the UI thread
  needs 1.3 ms a frame instead of 9.5 ms, and frames over the 90 Hz budget
  fall from about a quarter to about 2 %. The final build also draws about
  16 % more frames in the same flings (1,166 against 1,002), because fewer
  are dropped.
- **Tab and category switches** no longer rebuild hidden tabs; their worst
  frames are shorter (tab switch 99th percentile 21.6 → 8.3 ms).
- **Raster time** is now what limits this phone. Menu scroll raster rose by
  about 1.2 ms, the same rise the S23 showed after Phase 2; it stays under
  the 90 Hz budget on average. The cause is not proven. The likely one is
  that the app now produces every frame: the raster thread waits for a free
  buffer at full frame rate, and the CPU clocks down once the UI thread is
  idle, so the same drawing takes longer by the clock. No painting changed
  in Phase 2, and the rise costs no frames. Add to cart (the
  flight animation, F8) and opening a product are raster-bound here: about
  half of the flight's frames miss the 90 Hz budget, before and after. This
  makes the F8 decision below worth taking on budget phones.
- **Photo memory** after the menu scroll: 11.1 → 23.0 MB for the same 58
  images. That is the sharper photos (I1) at work: a menu card box on this
  phone is 316 × 212 px, and the old decode was about 212 px wide (stretched,
  soft); a square photo is now decoded at 320 × 320 to cover the box. It
  stays well under Flutter's 100 MB image cache limit.

Release APK (arm64): 12,890,138 → 12,789,828 bytes (−100 KB). App code
(`package:enjoy_lavash_mobile` in the Dart AOT snapshot) 992 → 1,027 KB: the
saved-content cache, cover-sized decoding and the new pure modules. Bundled
assets 471 → 358 KB.

Not measured: cold-start time to content. The saved menu (Phase 4) shows
without waiting for the network, which a fixture server cannot show; the
manual check below covers it.

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

### Structure (Phases 6 and 7)

Large files were split into `part` files next to their owner. Code moved
unchanged: State behaviour went into extensions on the same State class, and
widgets went into their own part files. No public name or test key changed.

| File | Before | After | Parts |
| --- | --- | --- | --- |
| `navigation/main_tabs.dart` | 1,801 | 459 | `shell_cart`, `shell_navigation`, `order_context`, `checkout_flow`, `home_tab`, `menu_tab`, `keep_alive_tab_page` |
| `screens/menu_screen.dart` | 2,042 | 428 | `menu/`: `product_detail_page`, `menu_sections`, `menu_categories`, `menu_add_to_cart`, `menu_order_context`, `menu_widgets` |
| `main_tabs/order_confirmation_sheet.dart` | 1,611 | 502 | `checkout_sheet_preview`, `checkout_sheet_actions`, `checkout_sheet_parts`, `checkout_ordering_status`, `checkout_loyalty_control` |
| `screens/authorization_screen.dart` | 1,579 | 782 | `auth/`: `otp_countdown_card`, `name_prompt_sheet`, `birth_date_prompt_sheet` |
| `profile/profile_redesign.dart` | 1,033 | 524 | `profile_rows`, `profile_language_sheet` |
| `main_tabs/checkout_preview_summary.dart` | 915 | 453 | `checkout_preview_details_sheet` |

Duplicates merged (Phases 6 and 7). Each was identical, or is now pinned by a
test:
- Delivery address text: three copies became `features/address/delivery_address_text.dart`
  (Home, checkout and, since the review, the menu pill).
- The "opens at" text of a closed branch: three copies became `_nextOpeningText`
  in `main_tabs/checkout_ordering_status.dart`. One of them always added
  " · time zone", also when the zone was empty.
- The payment-method label: two copies became `features/checkout/payment_method_label.dart`.
- `_optionalInt`: two model copies became `readOptionalInt` in `json_helpers.dart`.
  The copy in `assigned_promotion_model.dart` behaves differently (it skips an
  unparseable string and tries the next key), so it stays.
- Inline colours became tokens: 25 inline copies of the surface colour now call
  `AppDesignTokens.surface(context)`, and 13 copies of the inset fill call the new
  `AppDesignTokens.inset(context)`. Every one was decided by the theme's
  brightness and the app has no nested `Theme`, so the colours are identical.
  The menu skeleton keeps its own pair, because it has a highlight shade.
- Six widgets lost an `isDark` parameter they no longer read (several had
  never read it).

### Build

| ID | Finding | Status |
| --- | --- | --- |
| B1 | Every Android profile build failed: `src/profile/AndroidManifest.xml` hard-coded `usesCleartextTraffic="true"` while the main manifest takes it from the build-type placeholder (`false` outside debug) | ✅ fixed in Phase 0: the profile manifest no longer declares it |

## Review after the pass (2026-11-12)

Everything from 354c012 to the end of Phase 8 was checked again: by comparing
every moved method with its original (294 identical, 155 changed on purpose)
and by four independent reads of the changed code, one per area. The refactor
itself held: no request the app sends at checkout changed, no customer data
can reach the saved menu, and nothing deleted was still used. The defects
were in the new behaviour (the saved menu at launch, the notification
reminder). All of them are fixed and pinned by tests (362 → 411 tests).

| Area | Defect | Fix |
| --- | --- | --- |
| Checkout | Checkout tapped twice while the start-up request was still running opened two confirmation pages (a second order could follow); the page used the cart as it was before the network catalog arrived | The button shows progress and takes no second tap while the session is awaited; the cart is read again after it was checked against the network catalog |
| Sign-in gates | Bell, loyalty, promotions and orders had the same double-open, and opened late over whatever the customer had moved on to | One gated action at a time; dropped if the customer left the tab or opened something meanwhile |
| Offline launch | The start-up could fail before the main screen existed, and then no notice or Retry ever showed; the notice lasted 3 s; a signed-in customer was shown as "Guest" with a zero balance and sent to the sign-in screen; nothing tried again | The notice follows the state (shown at mount, kept until dismissed or a retry starts, shown again when that fails); Home keeps its placeholders while the session is unknown; gated actions and Checkout retry the start-up instead of asking to sign in; coming back to the app retries too |
| Sign-in | After the code was accepted, the screen waited for the push-token request (a spinner for as long as the network took) | Sign-in waits for the customer's answer to the permission question only; the token is registered in the background |
| Reminder | Dropped for the whole launch when anything was open (the start-up birth-date prompt usually was); only evaluated after the GPS lookup; never on return to the app; could open over the update prompt; once shown, every route change rebuilt all tabs; could follow a refusal within a minute at sign-in; could not be stopped | A due reminder stays pending and follows the birth-date prompt; it waits for the location question only, not the lookup; it is also checked on return to the app; it never opens over the update prompt; the route check no longer subscribes the shell; sign-in respects a 30-minute gap; "Don't remind me" stops it |
| Reminder, Android | "Open settings" was offered although the OS would still show its prompt (after a dismissed dialog); on Android 12 and lower, or once the OS had stopped asking, "Allow" did nothing | The app remembers from each request whether the OS showed its prompt (a request answered faster than a person could means it showed nothing); when "Allow" turns out to show nothing, it opens the settings |
| Reminder sheet | Its buttons could be cut off on a small screen or with large text | It scrolls and never covers more than 88 % of the screen |
| Saved menu | An empty or unreadable answer replaced a good saved menu; a killed save left temp files; content saved "in the future" never expired; a branch picked during start-up could leave the old saved menu on screen; ended promotion banners still showed | Only a menu with something to order is saved; one fixed temp file; a negative age is a miss; a successful start-up always replaces saved content; saved banners whose promotion ended are dropped |
| Startup | The public promotions list was downloaded and saved at every launch, and nothing showed it | The request is gone (`/promotions/active`); banners and personal promo codes are separate and stay |
| Rebuild scope | The motion helper tied every widget that asked it to all of `MediaQuery`, so each frame of the keyboard sliding in rebuilt the shell and every tab under a sheet (older than this pass, but it undid R1–R4 there) | It reads only the two accessibility settings; the menu asks for the screen size and text scale explicitly, so rotation still lays the category pill out again |
| Images | The 3× decode cap also applied to banners and Home tiles, which decoded below the resolution of denser screens | The cap is for product photos only |
| Cart | A line that was removed and came back (Undo) no longer played its entrance | It does again |

Older bugs the review exposed, fixed with it:

- **The order could go somewhere else than its preview priced.** The preview
  and the order each worked out the delivery target on their own, so a GPS fix
  landing while the confirmation page was open changed where the order went
  (to the phone, with the fee of the saved address). The confirmed preview's
  target now travels with the order.
- **Coordinates and address could describe different places.** After a
  failed address lookup the phone's coordinates were kept under the name of
  the place picked before; a start-up GPS fix could replace a point the
  customer had just picked. `LocationController.locateAndApply` now takes both
  together or neither.

## Manual checks on a device

- **Offline launch after the review:** in airplane mode the Retry notice must
  appear even on the very first frame and stay until dismissed; Home must
  show placeholders, not "Guest"; tapping the bell or Checkout must not open
  the sign-in screen. Back online, Retry (or leaving and returning to the
  app) brings the greeting back.
- **Notification reminder:** refuse the OS prompt, sign in 30 minutes or more
  later: the sheet appears. On iPhone its button opens Settings; on Android
  13+ it shows the OS dialog once more. "Don't remind me" must stop it.
- **Saved menu at cold start (Phase 4):** open the app once with network so the
  menu is saved. Kill it, switch on airplane mode and open it again: the menu
  should appear at once, Home should show placeholders for the greeting and
  balance, and after the request fails a message with Retry should appear. Switch
  airplane mode off and tap Retry: the content refreshes and the greeting
  appears.

## Decisions recorded, not changed

- No `OrderContextController` (Phase 6 plan): order type and pickup branch
  change only on an explicit choice, and the shell rebuild they cause is the
  one intended. A controller would re-plumb every tab for no measurable gain.

- Add-to-cart flight raster cost (F8): the blurred ground shadows and the
  packaging's lit layers change shape every frame, so every frame repaints
  them. Making them cheaper (pre-rendered shadows, fewer blur passes) changes
  how the animation looks and needs a design sign-off.
- Bottom-bar icons (D8): drawing them without runtime SVG parsing would drop
  about 300 KB of code, but the icons must be redrawn pixel-for-pixel first.

- A category picked from Home keeps the old grid scroll offset.
- Re-confirming the same order type re-requests payment methods.
- A delivery preview that answers after the customer switched to pickup still
  reloads the payment methods for the delivery branch (needs a preview slower
  than the branch pick; `checkout_flow.dart`, `_previewCartForCheckout`).
- The address search in the address sheet is switched off (`_showSearch` is
  never set in `address_bottom_sheet.dart`), with its suggestion code and
  `LocationController.suggestAddresses` unreachable. Left in place: it is a
  dormant feature, not a leftover.
- Saved addresses cannot be picked at checkout: one is used only when the
  phone has no point with an address (see below).

## Decisions taken (2026-11-12)

- **What the screen shows is what is sent.** A point with an address (picked
  on the map, or the phone's position once its address was found) wins;
  otherwise the default saved address is used; the phone's bare coordinates
  are sent only when nothing is saved. One rule, `resolveDeliveryTarget`,
  serves the preview and the order, and `deliveryAddressText` shows the same
  on Home, the menu and checkout (which also ended the Home/Menu difference).
- **The reminder can be stopped.** "Don't remind me" on the sheet ends the
  reminders until notifications are switched on in Profile. It is not the
  in-app opt-out: notifications allowed later in the phone settings work.
- **The unused public promotions download was removed.**
