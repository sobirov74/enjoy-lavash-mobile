# Enjoy Lavash Mobile — Project Structure

Reference map of the codebase **as it is today** (September 2026). Read it
before searching for where something lives. `ROADMAP.md` describes the *target*
architecture and the refactoring phases; this file describes the *current*
layout. The legacy B2B layer and duplicate widget/theme folders were removed in
October 2026 (`docs/STABILITY_AUDIT.md`, Phase 7). Where the two
differ, the code is the truth and this file records it.

**Keep it current.** When you add, move, rename or delete a file under `lib/`,
`test/` or `docs/`, update the matching section here in the same change.

## At a glance

| Topic | Where / what |
| --- | --- |
| Package | `enjoy_lavash_mobile`, pubspec `version: 1.2.3+21`, Flutter 3.47 stable |
| App root | `lib/main.dart` → `MultiProvider` → `InitialLocationLoader` → `MyApp` → `AppVersionGate` → `MainTabs` |
| State | `provider` + `ChangeNotifier` controllers created once in `main.dart` |
| DI | `get_it`: `sl<T>()` from `lib/app/di.dart`, registered by `setupDi()` |
| HTTP | `dio` behind `ApiClient` (`lib/core/api/api_client.dart`); photos via `flutter_cache_manager` (`DiskCachedNetworkImage`) |
| Errors | `Failure` sealed hierarchy + `Result<T>` in `lib/core/error/` |
| Localization | `flutter gen-l10n`, class `L`, `L.of(context)`, template `lib/l10n/app_uz.arb`, locales uz / ru / en |
| Theme | `lib/theme/` only: `AppTheme`, `AppDesignTokens`, `AppTextStyles`, `AppMotion`, `BaseColors` |
| Fonts | Manrope and GolosText variable fonts in `assets/fonts/` |
| Assets | Only `assets/images/` is declared in `pubspec.yaml`. `assets/icons/*.svg` is **not bundled** and no longer referenced by any Dart file |
| Lints | `flutter_lints` via `analysis_options.yaml` |
| Tests | `flutter test` (all green, ~279 tests, 64 files), `flutter_test` only, no mocking package |
| Backend | REST API documented in `API_DOCS.md`; banners in `BANNERS_API.md` |
| Config | `--dart-define`: `API_BASE_URL`, `ORGANISATION_ID`, `YANDEX_GEOCODER_KEY`, `YANDEX_SUGGEST_KEY`, `ENABLE_NETWORK_LOGS` (see `README.md`). No secrets in source |
| Audit | `docs/STABILITY_AUDIT.md`: known issues table and the phased remediation plan with status |

Everyday commands:

```sh
flutter analyze            # clean (no issues)
flutter test               # whole suite, ~20 s
dart format lib test
flutter gen-l10n           # after editing an .arb; generated files are committed
```

## Top level

```
.
├── lib/                       application code (map below)
├── test/                      widget + unit tests, flat, one file per concern
├── assets/                    images/, icons/ (unbundled), fonts/
├── docs/                      design notes and specs (index at the end)
├── android/ ios/ web/ macos/ linux/   platform shells
├── pubspec.yaml               deps, fonts, assets, launcher icon + splash config
├── l10n.yaml                  gen-l10n config (class L, template app_uz.arb)
├── analysis_options.yaml      flutter_lints
├── ROADMAP.md                 target clean architecture + phased refactor plan
├── PROJECT_STRUCTURE.md       this file
├── CLAUDE.md                  loads this file and ROADMAP.md into every session
├── README.md                  banners + deep-link notes
├── API_DOCS.md                full backend API reference (2,200 lines)
├── BANNERS_API.md             home banner endpoint contract
├── scripts/build_release.sh   obfuscated release build with dart-defines from .env.json
├── .github/workflows/ci.yml   format check + analyze + test on PRs and main
└── .claude/settings.local.json   local tool permissions
```

## `lib/` map

```
lib/
├── main.dart              bootstrap (see "Startup")
├── app/                   app shell + root controllers
├── core/                  api, errors, storage, services, deep links
├── features/              backend feature module + shared domain models
├── navigation/            MainTabs shell and the checkout flow (part files)
├── screens/               one file per screen; profile split into part files
├── widgets/               shared widgets (index below)
├── theme/                 the live theme / design tokens / motion policy
├── l10n/                  .arb sources + generated L classes
└── utils/                 price_formatter.dart, date_formatter.dart, format_cache.dart (shared intl formatters), log_redaction.dart (strip PII before debug logging)
```

### Startup (`lib/main.dart`)

`main()` runs inside `runZonedGuarded`, installs local-logging `FlutterError.onError` and
`PlatformDispatcher.onError`, starts `ErrorReporter` (Sentry wraps those handlers when a DSN is set), calls `setupDi()`, creates the four root
controllers, wires `ApiClient.setOnLogout` to the backend controller, loads
theme + locale, kicks off push handlers and the backend bootstrap as
fire-and-forget startup tasks, then `runApp` with:

```
MultiProvider(ThemeController, LocaleController, LocationController, MobileBackendController)
  └── InitialLocationLoader          (lib/app/app.dart: asks for location on first frame, resumes backend on app resume)
        └── MyApp                    (MaterialApp: lightTheme/darkTheme, L.delegate, home: AppVersionGate → MainTabs)
```

### `lib/app/`

| File | Contents |
| --- | --- |
| `app.dart` | `MyApp` (MaterialApp) and `InitialLocationLoader` |
| `di.dart` | `sl` (GetIt 9) and `setupDi()`: `ApiClient`, `MobilePushNotificationService`, `MobileBackendRepository` → `MobileBackendRepositoryImpl` (all lazy singletons) |
| `theme_controller.dart` | `ThemeController` (ThemeMode, persisted via `ThemeStorage`) |
| `locale_controller.dart` | `LocaleController` (`supportedLocales`, persisted) |
| `location_controller.dart` | `LocationController`, `LocationStatus` (permission + geocoding via the app-wide `YandexGeocoderService`; `suggestAddresses()` for the address sheet) |

### `lib/core/`

| Folder | Contents |
| --- | --- |
| `api/` | `ApiClient` (Dio, token refresh, language header, logout callback), `ApiEndpoints`, `BaseUrl`, `backend_image_url.dart` (resolve relative image paths) |
| `error/` | `failures.dart` (`Failure` sealed: Network, Server, Conflict, PayloadTooLarge, RateLimit, ServiceUnavailable, `ApiFailurePayload`), `result.dart` (`Result<T>` = `Success` / `Error`, `ResultX` helpers), `dio_error_mapper.dart`, `mobile_error_messages.dart` (failure → localized copy) |
| `storage/` | `TokenStorage` (secure; unreadable keystore → session cleared, never throws on read/clear), `ThemeStorage`, `CartStorage` (persists `CartSelection`s) |
| `services/` | `ErrorReporter` (Sentry, only when `SENTRY_DSN` is defined; `report()` for zone and startup errors), `MobilePushNotificationService` (Firebase Messaging on Android; raw APNs channel on iOS, where `AppDelegate` forwards notification taps as `notificationOpened` and keeps a cold-start tap for `takeLaunchNotification`), `YandexGeocoderService` (keys from `--dart-define`, lookups disabled when empty, 10 s timeouts), `AppShareService`, `ExternalUrlLauncher` (`https` only; `paymentLinkHosts` / `appStoreLinkHosts` allowlists for backend-supplied links; native channels re-check the scheme) |
| `navigation/` | `AppDeepLink` enum (`enjoylavash://home`, `menu`, `cart`, `profile`, `promotions`, `orders`, `notifications`, `loyalty`) |

### `lib/features/`

| Path | Contents |
| --- | --- |
| `mobile_backend/domain/repositories/mobile_backend_repository.dart` | `MobileBackendRepository` abstract contract (auth, bootstrap, catalog, cart preview, orders, addresses, loyalty, notifications, profile, files) |
| `mobile_backend/domain/entities/mobile_bootstrap.dart` | `MobileBootstrap` |
| `mobile_backend/data/repositories/mobile_backend_repository_impl.dart` | `MobileBackendRepositoryImpl` over `ApiClient` |
| `mobile_backend/data/models/` | JSON models: `catalog_model`, `cart_model` (order type, payment method, cart preview request/response), `order_model`, `loyalty_model`, `assigned_promotion_model`, `promotion_model`, `banner_model`, `branch_model`, `address_model`, `auth_models`, `client_profile_model`, `client_notification_model`, `ordering_status_model` (working hours), `app_version_policy_model`, `file_upload_model`, `json_helpers` |
| `mobile_backend/presentation/mobile_backend_controller.dart` | `MobileBackendController` (ChangeNotifier, `MobileBackendStatus`, `SessionEndReason` + `sessionEnded` stream; a session generation drops late responses from a previous session), the app's main state holder. Split with `part` files in `mobile_backend_controller/`: auth, address, bootstrap, catalog adapter (backend catalog → `MenuProduct`), notifications, order, loyalty, state |
| `models/` | UI-facing domain models: `MenuProduct` / `MenuModifierGroup` / `MenuModifierOption`, `MenuCategory`, `CartSelection` / `CartModifierSelection` / `CartLine`, `maxCartLineQuantity`, `CartLineLimitReached` (`cart_line.dart`) |
| `data/menu_catalog.dart` | Static fallback catalog (`menuProducts`); used by tests, not by app code |
| `app_version/presentation/app_version_gate.dart` | `AppVersionGate` (force/soft update prompt laid over the running app; wired as `MaterialApp.home` around `MainTabs` in `app.dart`, policy loaded via `MobileBackendController.getAppVersionPolicy`) |
| `cart/presentation/cart_controller.dart` | `CartController` (ChangeNotifier: cart lines, persistence through `CartStorage`, cached `CartSnapshot` per catalog) |
| `checkout/order_submission_keys.dart` | `OrderSubmissionKeys` (one `Idempotency-Key` per order payload until the server answers definitively) and `newIdempotencyKey()` |

### `lib/navigation/`

`main_tabs.dart` is the shell. It owns a `CartController` (lines, totals and
persistence; only the menu tab, cart tab and bottom bar listen to it), the cart
rules (quantity cap, reconciliation notices, repeat order), checkout and order
creation. It `select`s only the backend fields it renders (`_ShellData`). Bottom tabs in order: **0 Home, 1 Menu, 2 Promotions, 3 Cart,
4 Profile**; the cart tab icon carries `cartIconKey` used as the add-to-cart
flight target. Screens are pushed with `MaterialPageRoute` (no router yet).

Part files in `navigation/main_tabs/` (all `part of main_tabs.dart`):

| File | Contents |
| --- | --- |
| `main_tabs_bottom_navigation.dart` | bottom bar, tab icons, cart badge + `CartArrivalFeedback`, `CartPill` |
| `main_tabs_drawer.dart` | drawer |
| `order_confirmation_sheet.dart` | `_OrderConfirmationSheet` checkout sheet (1,584 lines) |
| `checkout_preview_summary.dart` | priced lines / totals from cart preview |
| `order_confirmation_items.dart` | item rows in the sheet |
| `payment_method_selector.dart`, `promo_code_field.dart`, `order_type_toggle.dart` (`OrderTypeSlidingToggle`) | checkout inputs |
| `checkout_models.dart` | private checkout result/failure types |
| `order_success_screen.dart` | `OrderSuccessScreen` |

### `lib/screens/`

| Screen / entry | File | Notes |
| --- | --- | --- |
| `HomeScreen` | `home_screen.dart` | banners (`HomeBannerSlider`), promos, ordering status |
| `MenuScreen` | `menu_screen.dart` | category pills, lazily built product grid (`SliverList` of rows), private `_ProductDetailPage`, add-to-cart animation wiring (`CartAnimationController`), `packagingAssets` override map |
| `CartScreen` | `cart_screen.dart` | reads props from `MainTabs` |
| `Profile` | `profile.dart` + `profile/` part files | `profile_redesign.dart` (main body), `profile_sections.dart`, `profile_cards.dart`, `settings_widgets.dart`, `profile_edit_screen.dart`, `saved_addresses_screen.dart`, `all_orders_screen.dart`, `order_row.dart`, `order_details_sheet.dart` (`OrderProgressJourney`), `order_detail_widgets.dart`, `order_helpers.dart`, `delete_account_sheet.dart` |
| `AuthorizationScreen`, `OtpCountdownCard` | `authorization_screen.dart` | phone + OTP flow |
| `NotificationsScreen` | `notifications_screen.dart` | inbox with filters |
| `LoyaltyWalletScreen` | `loyalty_wallet_screen.dart` | |
| `AssignedPromotionsScreen` | `assigned_promotions_screen.dart` | |
| `MapPickerScreen` | `map_picker_screen.dart` | `flutter_map` picker |
| `showAddressBottomSheet(context)` | `address_bottom_sheet.dart` | |
| `showBranchBottomSheet(...)` | `branch_bottom_sheet.dart` | returns `BranchModel?` |
| `showOrderContextSheet(...)` | `order_context_sheet.dart` | order type / address / branch context |

### `lib/widgets/` — widget index

Shared, redesign-era widgets (use these):

| Widget / function | File |
| --- | --- |
| `MainButton`, `ButtonVariant`, `ButtonSize`, `IconPosition` | `button.dart` |
| `MyIconButton` | `icon_button.dart` |
| `TypographyText`, `TextType`, `FontWeightType` | `typography.dart` |
| `QuantityButton`, `AnimatedQuantityText` | `quantity_button.dart` |
| `ProductImage` | `product_image.dart` (network photo with gradient/emoji fallback) |
| `ProductListItem` | `product_list_item.dart` (menu grid tile: photo anchor, add / ± controls) |
| `CartItemCard` | `cart_item_card.dart` |
| `BannerImageCard` | `banner_image_card.dart` |
| `HomeBannerSlider` | `home_banner_slider.dart` |
| `PromoSlider`, `showPromotionDetails()` | `promo_slider.dart` |
| `AppSurfaceCard` | `redesign/app_surface_card.dart` |
| `CartPill` | `redesign/cart_pill.dart` |
| `OrderContextPill` | `redesign/order_context_pill.dart` |
| `appSnackBar()` | `app_snack_bar.dart` |
| `showAppModalBottomSheet<T>()`, `AppModalBottomSheetDragScope` | `app_modal_bottom_sheet.dart` |
| `AppBottomSheetDragHandle` | `app_bottom_sheet_drag_handle.dart` |
| `showConfirmDialog()` | `confirm_dialog.dart` |
| `AnimatedErrorMessage` | `animated_error_message.dart` |
| `FadeSlideIn`, `FadeIndexedStack` | `fade_slide_in.dart` |
| `CurvedFadeTransition` (use in route `transitionsBuilder`s instead of an inline `CurvedAnimation`) | `curved_fade_transition.dart` |
| `decodeWidthFor()` (decode network images at layout width) | `utils/image_decode_size.dart` |
| `resizedNetworkImage()`, `DiskCachedNetworkImage`, `AppImageCacheManager`, `networkImageProvider` (disk-cached photos; tests override the factory in `test/flutter_test_config.dart`) | `utils/cached_image_provider.dart` |
| `WhiteContainer` | `white_container.dart` |
| `extractErrorMessage()` | `utils/error_extracter.dart` |
| `textChangeListener()` (controller listener that ignores cursor/composing updates) | `utils/text_change_listener.dart` |
| `failureMessage()`, `failureDetail()` (localized, never raw exception text; use these to show any `Failure`) | `utils/failure_message.dart` |

Add-to-cart animation (`widgets/cart_animation/`, design doc
`docs/add_to_cart_assets.md`):

| Class | File | Role |
| --- | --- | --- |
| `CartAnimationController` | `cart_animation_controller.dart` | owns the overlay flight; `add()` runs the cart mutation exactly once, then decorates. Private `_CartFlight`, `_GroundShadowPainter` |
| `CartAnimationSource`, `CartAnimationAnchor`, `CartAddFeedback`, `cartAnimationBounds()` | `cart_animation_source.dart` | capture the displayed photo + bounds; press feedback |
| `CartArrivalFeedback` | `cart_arrival_feedback.dart` | cart icon spring on arrival |
| `CartPackagingKind`, `CartPackagingLayer`, `CartPackagingAssets`, `CartPackagingVisual`, `classifyCartPackaging()` | `packaging_visual.dart` | product → package classification; optional artwork override |
| `PresetPackagingVisual` | `preset_packaging_visual.dart` | built-in vector packaging (lit materials, folds, grain) |

Not referenced by app code today, kept as redesign building blocks:
`MainButton` (`button.dart`), `MyIconButton` (`icon_button.dart`),
`WhiteContainer`, `utils/date_formatter.dart`, `theme/theme_extensions.dart`.

### `lib/theme/`

| File | Contents |
| --- | --- |
| `app_design_tokens.dart` | `AppDesignTokens` (colors, radii, heights, `surface()`, `ground()`, text colors, `cardShadow()`) and `AppTextStyles` (`display()`, `ui()`) |
| `app_motion.dart` | `AppMotion` durations (`micro`, `state`, `spatial`, `celebration`), curves, `reduced(context)`, `duration(context, normal)` |
| `app_theme.dart` | `AppTheme` builder; `light_theme.dart` / `dark_theme.dart` export `lightTheme` / `darkTheme` |
| `app_colors.dart` | `BaseColors` (brand primary etc.) |
| `app_theme_colors.dart`, `theme_extensions.dart` | `AppThemeColors` extension + `ThemeColorsX` |

### `lib/l10n/`

`app_uz.arb` is the template; `app_ru.arb` and `app_en.arb` must carry the same
keys. Generated `app_localizations*.dart` are committed. Access strings with
`L.of(context).key`. Never hardcode user-facing Russian/Uzbek text.

## `test/`

Flat folder, one file per concern, named `<area>_test.dart`. Groups:

- Cart animation: `cart_animation_controller_test`, `cart_packaging_preset_integration_test`, `cart_packaging_visual_test`, `preset_packaging_visual_test`, `cart_add_failure_test`, `cart_flight_preview_test`. The last two visual tests write contact sheets when given `--dart-define=PACKAGING_PREVIEW_PATH=…` / `CART_FLIGHT_PREVIEW_PATH=…`.
- Screens/UX: `home_screen_test`, `menu_lazy_grid_test`, `menu_motion_test`, `cart_screen_ux_test`, `profile_redesign_test`, `notifications_promotions_ui_test`, `loyalty_wallet_screen_test`, `order_success_screen_test`, `authorization_*`, `branch_bottom_sheet_test`, `product_list_item_test`, `product_configuration_test`, `widget_test`.
- Checkout: `order_submission_keys_test` (key reuse after unknown outcomes), `cart_safety_nets_test` (removed-item notice, repeat order, quantity cap).
- Session: `mobile_backend_session_test` (late responses across login/logout, session end reasons, resume throttle, change-only order polling, promotions freshness).
- Performance guards: `shell_rebuild_scope_test`, `menu_lazy_grid_test`, `startup_requests_test`, `cart_controller_test`, `token_storage_test`, `text_change_listener_test`.
- Models/repositories: `*_model_test`, `ordering_status_repository_test`, `promotion_banner_repository_test`, `api_client_test`, `cart_storage_test`, `mobile_backend_migration_contract_test`, `redesign_audit_contract_test`.
- Startup/errors: `startup_preferences_test`, `failure_message_test`.
- Services: `ios_notification_tap_test`, `app_version_gate_test`, `mobile_push_notification_service_test`, `app_share_service_test`, `initial_location_loader_test`, `external_url_launcher_test` (scheme + host allowlist, channel never called for rejected links), `yandex_geocoder_service_test` (no network without keys, key injection), `log_redaction_test`.

Tests build real widgets with `MaterialApp` + `MediaQuery` and fake
repositories by hand; there is no mockito/mocktail. `flutter_test_config.dart`
runs before every file and routes network images through plain `NetworkImage`.

## Conventions observed in the code

- Colors, radii and spacing come from `AppDesignTokens`; motion timing from
  `AppMotion`, and every animation has a reduced-motion path
  (`AppMotion.reduced(context)`).
- User-visible strings go through `L`; errors are mapped with
  `mobile_error_messages.dart`, never shown raw.
- Fire-and-forget futures are wrapped in `unawaited(...)`.
- Large widgets are split into `part` files next to the owner
  (`main_tabs/`, `profile/`, `mobile_backend_controller/`).
- Expensive subtrees get a `RepaintBoundary`; models are immutable with
  `const` constructors.
- Run `dart format` before finishing; commit messages are short lowercase
  summaries (e.g. `product add to cart effect`).

## Where the code stands against `ROADMAP.md`

| Phase | Status today |
| --- | --- |
| 1 Foundation | `core/error/failures.dart`, `result.dart`, `app/di.dart` exist; `widgets/theme/` duplicate and legacy B2B data layer deleted. Shared widgets still in `lib/widgets/`, not `lib/shared/` |
| 2 Menu | Backend catalog flows through `MobileBackendController` + catalog adapter into `MenuProduct`. `MenuScreen` is still a 1,874-line stateful widget with category logic inside |
| 3 Cart | `CartController` in `lib/features/cart/presentation/`, owned by `MainTabs`; screens still receive cart data as props |
| 4 Checkout | Implemented inside `MainTabs` part files (`_OrderConfirmationSheet`, `OrderSuccessScreen`), not as a feature module |
| 5 GoRouter | Not started; `MaterialPageRoute` everywhere |
| 6 Profile | Real data via `MobileBackendController`; UI split into `profile/` parts |
| 7–10 | Error mapping and localization done; Sentry error reporting and dart-define config in place; connectivity and CI not started |

## Other documents

| File | What it covers |
| --- | --- |
| `ROADMAP.md` | target architecture and the ten refactor phases |
| `docs/STABILITY_AUDIT.md` | October 2026 audit: leaks, crash risks, security and performance findings with severity, and the remediation phases with status |
| `docs/add_to_cart_assets.md` | add-to-cart packaging animation: presets, lighting, timing, preview tests |
| `docs/CAFE_REDESIGN_BACKEND_REQUIREMENTS.md` | backend data the redesign still needs |
| `docs/CAFE_REDESIGN_IMPLEMENTATION_AUDIT.md` | redesign parity audit and remaining P1 work |
| `docs/superpowers/specs/2026-08-06-working-hours-ordering-design.md` | working-hours checkout gating design |
| `API_DOCS.md`, `BANNERS_API.md`, `README.md` | backend contracts and deep links |
