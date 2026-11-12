# Enjoy Lavash Mobile — Project Structure

Reference map of the codebase **as it is today** (November 2026). Read it
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
| Package | `enjoy_lavash_mobile`, pubspec `version: 1.2.4+22`, Flutter 3.47 stable |
| App root | `lib/main.dart` → `MultiProvider` → `InitialLocationLoader` → `MyApp` → `AppVersionGate` → `MainTabs` |
| State | `provider` + `ChangeNotifier` controllers created once in `main.dart` |
| DI | `get_it`: `sl<T>()` from `lib/app/di.dart`, registered by `setupDi()` |
| HTTP | `dio` behind `ApiClient` (`lib/core/api/api_client.dart`); photos via `flutter_cache_manager` (`DiskCachedNetworkImage`) |
| Errors | `Failure` sealed hierarchy + `Result<T>` in `lib/core/error/` |
| Localization | `flutter gen-l10n`, class `L`, `L.of(context)`, template `lib/l10n/app_uz.arb`, locales uz / ru / en |
| Theme | `lib/theme/` only: `AppTheme`, `AppDesignTokens`, `AppTextStyles`, `AppMotion`, `BaseColors` |
| Fonts | Manrope and GolosText variable fonts in `assets/fonts/` |
| Assets | Only `assets/images/` is declared in `pubspec.yaml`; the unbundled `assets/icons/` folder was deleted (performance pass 2, Phase 1) |
| Lints | `flutter_lints` via `analysis_options.yaml` |
| Tests | `flutter test` (all green, 411 tests, 75 files), `flutter_test` only, no mocking package; on-device performance harness in `integration_test/` |
| Backend | REST API documented in `API_DOCS.md`; banners in `BANNERS_API.md` |
| Config | `--dart-define`: `API_BASE_URL`, `ORGANISATION_ID`, `YANDEX_GEOCODER_KEY`, `YANDEX_SUGGEST_KEY`, `ENABLE_NETWORK_LOGS` (see `README.md`). No secrets in source |
| Audit | `docs/STABILITY_AUDIT.md` (October 2026, done) and `docs/PERFORMANCE_PASS_2.md` (November 2026: findings, phase status, before/after measurements) |

Everyday commands:

```sh
flutter analyze            # clean (no issues)
flutter test               # whole suite, ~20 s
dart format lib test
flutter gen-l10n           # after editing an .arb; generated files are committed
```

Performance harness (offline fixture app, details in `docs/PERFORMANCE_PASS_2.md`):

```sh
flutter build apk --profile -P perfBuild=true --target=integration_test/perf_test.dart
PERF_TAG=<label>-profile flutter drive --profile \
  --use-application-binary=build/app/outputs/flutter-apk/app-profile.apk \
  --driver=test_driver/perf_driver.dart --target=integration_test/perf_test.dart -d <device>
```

## Top level

```
.
├── lib/                       application code (map below)
├── test/                      widget + unit tests, flat, one file per concern; shared fixtures in test/support/
├── integration_test/          perf_test.dart: on-device performance scenarios (see docs/PERFORMANCE_PASS_2.md)
├── test_driver/               perf_driver.dart: host side of the performance harness
├── assets/                    images/, fonts/
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
└── utils/                 price_formatter.dart, format_cache.dart (shared intl formatters), log_redaction.dart (strip PII before debug logging)
```

### Startup (`lib/main.dart`)

`main()` runs inside `runZonedGuarded`, installs local-logging `FlutterError.onError` and
`PlatformDispatcher.onError`, starts `ErrorReporter` (Sentry wraps those handlers when a DSN is set), calls `setupDi()`, creates the four root
controllers, wires `ApiClient.setOnLogout` to the backend controller, loads
theme + locale, kicks off push handlers and the backend bootstrap as
fire-and-forget startup tasks, waits at most 200 ms for the menu saved by the
last launch (`restoreCachedContent`), then `runApp` with:

```
MultiProvider(ThemeController, LocaleController, LocationController, MobileBackendController)
  └── InitialLocationLoader          (lib/app/app.dart: on first frame asks for location, then shows the first notification prompt; resumes backend on app resume)
        └── MyApp                    (MaterialApp: lightTheme/darkTheme, L.delegate, home: AppVersionGate → MainTabs)
```

### `lib/app/`

| File | Contents |
| --- | --- |
| `app.dart` | `MyApp` (MaterialApp) and `InitialLocationLoader` (startup permissions in order: location, then notifications via `MobileBackendController.requestPushNotificationPermission`, so the two OS dialogs never overlap; only the location question is awaited, not the GPS and address lookup; the OS notification prompt shows only if this install never saw it, later asks are the shell's reminder) |
| `di.dart` | `sl` (GetIt 9) and `setupDi()`: `ApiClient`, `MobilePushNotificationService`, `MobileBackendRepository` → `MobileBackendRepositoryImpl` (all lazy singletons) |
| `theme_controller.dart` | `ThemeController` (ThemeMode, persisted via `ThemeStorage`) |
| `locale_controller.dart` | `LocaleController` (`supportedLocales`, persisted) |
| `location_controller.dart` | `LocationController`, `LocationStatus` (permission + geocoding via the app-wide `YandexGeocoderService`; `suggestAddresses()` for the address sheet); `deliveryPoint` for checkout: its coordinates and address always describe the same place (`locateAndApply()` takes both or neither, and a point the customer picked while the phone was being located stays); `requestPermissionAndLocate(onPermissionAnswered:)`) |

### `lib/core/`

| Folder | Contents |
| --- | --- |
| `api/` | `ApiClient` (Dio, token refresh, language header, logout callback), `ApiEndpoints`, `BaseUrl`, `backend_image_url.dart` (resolve relative image paths) |
| `error/` | `failures.dart` (`Failure` sealed: Network, Server, Conflict, PayloadTooLarge, RateLimit, ServiceUnavailable, `ApiFailurePayload`), `result.dart` (`Result<T>` = `Success` / `Error`, `ResultX` helpers), `dio_error_mapper.dart`, `mobile_error_messages.dart` (failure → localized copy) |
| `storage/` | `TokenStorage` (secure; unreadable keystore → session cleared, never throws on read/clear), `ThemeStorage`, `CartStorage` (persists `CartSelection`s), `PublicContentCache` (raw catalog/branches/banners of the last default bootstrap whose menu had something to order in the app cache directory; keyed by server, organisation, language and schema; 14-day, 2 MB limits; never throws; no customer data by type) |
| `services/` | `ErrorReporter` (Sentry, only when `SENTRY_DSN` is defined; `report()` for zone and startup errors), `MobilePushNotificationService` (Firebase Messaging on Android; raw APNs channel on iOS, where `AppDelegate` forwards notification taps as `notificationOpened` and keeps a cold-start tap for `takeLaunchNotification`; `requestPermission()` shows the OS prompt while it is still undecided and respects the in-app opt-out, `syncTokenIfPermissionGranted()` never prompts; `requestPermission()` returns a `PushPermissionRequest` (settings + whether the OS really showed its prompt: an answer faster than `promptAnswerThreshold` means it did not, which is how Android 12 and lower and "refused twice" are told apart from a refusal the customer tapped; the result is remembered and reported as `permissionPermanentlyDenied`); for the reminder: `canShowFirstPermissionPrompt()`, `permissionAsks()` / `recordPermissionAsk()` / `clearPermissionAsks()`, `stopPermissionReminders()` / `permissionRemindersStopped()`, `openNotificationSettings()`), `YandexGeocoderService` (keys from `--dart-define`, lookups disabled when empty, 10 s timeouts), `AppShareService`, `ExternalUrlLauncher` (`https` only; `paymentLinkHosts` / `appStoreLinkHosts` allowlists for backend-supplied links; native channels re-check the scheme) |
| `navigation/` | `AppDeepLink` enum (`enjoylavash://home`, `menu`, `cart`, `profile`, `promotions`, `orders`, `notifications`, `loyalty`) |

### `lib/features/`

| Path | Contents |
| --- | --- |
| `mobile_backend/domain/repositories/mobile_backend_repository.dart` | `MobileBackendRepository` abstract contract (auth, bootstrap, saved public content, catalog, cart preview, orders, addresses, loyalty, notifications, profile) |
| `mobile_backend/domain/entities/mobile_bootstrap.dart` | `MobileBootstrap` |
| `mobile_backend/domain/entities/mobile_public_content.dart` | `MobilePublicContent` (saved menu, branches, banners) |
| `mobile_backend/data/repositories/mobile_backend_repository_impl.dart` | `MobileBackendRepositoryImpl` over `ApiClient` |
| `mobile_backend/data/models/` | JSON models: `catalog_model`, `cart_model` (order type, payment method, cart preview request/response), `order_model`, `loyalty_model`, `assigned_promotion_model`, `promotion_model`, `banner_model`, `branch_model`, `address_model`, `auth_models`, `client_profile_model`, `client_notification_model`, `ordering_status_model` (working hours), `app_version_policy_model`, `json_helpers` (`readString`, `readInt`, `readOptionalInt`, …) |
| `mobile_backend/presentation/mobile_backend_controller.dart` | `MobileBackendController` (ChangeNotifier, `MobileBackendStatus`, `SessionEndReason` + `sessionEnded` stream; a session generation drops late responses from a previous session; notifications: `requestPushNotificationPermission()` (app entry) and `requestFirstPushNotificationPrompt()` (sign-in) show the OS prompt only the first time, `pushPermissionReminderDue` stream, `pushPermissionReminderDue` also fires on return to the app, `takePushPermissionReminder({atSignIn})` (signed-in, notifications off, not switched off in the app, not stopped; on the schedule, or at sign-in after a 30-minute gap), `acceptPushPermissionReminder()` (opens the settings when the OS shows no prompt), `stopPushPermissionReminders()`, `openNotificationSettings()` (the next resume re-checks even inside the throttle); none of these waits for the token request, bootstrap/resume syncs only when already granted; `restoreCachedContent()` shows the saved public content while the bootstrap loads, `isShowingCachedContent`, `isSessionUnknown` (saved menu on screen and the start-up request still running or failed), `whenSessionSettled()`; a start-up that failed over the saved menu is retried when the app comes back), the app's main state holder. Split with `part` files in `mobile_backend_controller/`: auth, address, bootstrap, catalog adapter (backend catalog → `MenuProduct`), notifications, order, loyalty, state |
| `models/` | UI-facing domain models: `MenuProduct` / `MenuModifierGroup` / `MenuModifierOption`, `MenuCategory`, `CartSelection` / `CartModifierSelection` / `CartLine`, `maxCartLineQuantity`, `CartLineLimitReached` (`cart_line.dart`) |
| `app_version/presentation/app_version_gate.dart` | `AppVersionGate` (`AppVersionGate.isPromptVisible(context)` lets self-opening sheets wait for the prompt; force/soft update prompt laid over the running app; wired as `MaterialApp.home` around `MainTabs` in `app.dart`, policy loaded via `MobileBackendController.getAppVersionPolicy`) |
| `cart/presentation/cart_controller.dart` | `CartController` (ChangeNotifier: cart lines, persistence through `CartStorage`, cached `CartSnapshot` per catalog) |
| `cart/domain/cart_rules.dart` | `capCartQuantity`, `reconcileCartSelections`, `unavailableCartSelections`, `planRepeatOrder` (pure cart rules used by the shell) |
| `checkout/checkout_requests.dart` | `checkoutItems`, `checkoutProductId`, `DeliveryPoint`, `DeliveryTarget` + `resolveDeliveryTarget()` (a point with an address, else the default saved address, else bare coordinates: what the screens show is what is sent), `inlineOrderAddress`, `previewDeliveryAddress`; named error codes `loyaltyResetErrorCodes`, `pointsUnavailableErrorCodes`, `orderingClosedErrorCode` |
| `checkout/payment_method_label.dart` | `paymentMethodLabel()` (one copy for the checkout selector and order details) |
| `push_permission/push_reminder_schedule.dart` | `PushReminderAction` (OS prompt or phone settings), `pushReminderIntervals` (1 day, then every 3 days), `pushReminderSignInGap` (30 minutes), `isPushReminderDue()` |
| `push_permission/presentation/push_permission_sheet.dart` | `PushPermissionSheet` (scrolls on small screens; pops a `PushPermissionChoice`: accept, later, never), `showPushPermissionReminder()`, `askForPushNotificationsAfterSignIn()` (sign-in screen: the first OS prompt, else the reminder) |
| `address/delivery_address_text.dart` | `trimmedOrNull`, `defaultClientAddress`, `clientAddressText`, `deliveryAddressText` (one copy instead of three) |
| `cart/presentation/product_quantities.dart` | `ProductQuantities` (one `ValueListenable<int>` per product, so a menu card rebuilds only when its own quantity changes) |
| `checkout/order_submission_keys.dart` | `OrderSubmissionKeys` (one `Idempotency-Key` per order payload until the server answers definitively) and `newIdempotencyKey()` |

### `lib/navigation/`

`main_tabs.dart` is the shell (state, lifecycle, listeners and `build`, about
450 lines). It owns a `CartController` (lines, totals and persistence); its
behaviour lives in part-file extensions on `_MainTabsState` (cart, navigation,
order context, checkout), with the pure rules in `lib/features/`. Extensions
call `_updateState` because `setState` is protected; listener methods stay in
the class because extension tear-offs are not equal and could not be removed. Rebuild scope (guarded by
`shell_rebuild_scope_test`):
- the current tab, the menu category and the checkout flag are `ValueNotifier`s
  (`_currentTab`, `_selectedCategory`, `_isCheckingOut`): a tab switch or swipe
  rebuilds only the bottom bar, the back-button scope and each tab's
  `TickerMode`;
- Home and Menu are hosted by `_HomeTab` / `_MenuTab`, which `select` the fields
  they render; the shell itself selects only `_ShellData` (catalog, sign-in,
  status, birth-date prompt);
- the cart reaches each menu card through `MenuScreen.cart` and
  `ProductQuantities`; the cart tab and bottom bar listen to it directly.

Bottom tabs in order: **0 Home, 1 Menu, 2 Promotions, 3 Cart,
4 Profile**; the cart tab icon carries `cartIconKey` used as the add-to-cart
flight target. Screens are pushed with `MaterialPageRoute` (no router yet).

Part files in `navigation/main_tabs/` (all `part of main_tabs.dart`):

| File | Contents |
| --- | --- |
| `shell_cart.dart` | `_ShellCart`: cart edits, saved-cart restore, reconciliation against the network catalog, removal notices, repeat order |
| `shell_navigation.dart` | `_ShellNavigation`: tabs, pushed screens, banner links and push taps, sign-in gating (`_sessionKnown`: waits for the session and retries a failed start-up; one gated action at a time, dropped if the customer moved on), startup birth-date prompt, notification reminder (opens 2 s after it is due; stays pending while a screen, checkout or the update prompt is on top, and follows the birth-date prompt) |
| `order_context.dart` | `_ShellOrderContext`: delivery/pickup, pickup branch, catalog and payment-method refreshes, current delivery address |
| `checkout_flow.dart` | `_ShellCheckout`: preview and create-order requests, confirmation sheet, order creation with retry/error dialog, success screen, debug-only payload logging |
| `home_tab.dart` | `_HomeTab`: selects Home's backend fields, locale and delivery label inputs; builds `HomeScreen` |
| `menu_tab.dart` | `_MenuTab`: selects the catalog state, listens to the category filter; builds `MenuScreen` |
| `keep_alive_tab_page.dart` | `_KeepAliveTabPage` (keep-alive + `TickerMode` that follows the tab), `_TabActive` |
| `main_tabs_bottom_navigation.dart` | bottom bar, tab icons, cart badge + `CartArrivalFeedback`, `CartPill` |
| `main_tabs_drawer.dart` | drawer |
| `order_confirmation_sheet.dart` | `_OrderConfirmationSheet`: the checkout sheet's state, lifecycle and `build` (about 500 lines); its behaviour is in the next two parts |
| `checkout_sheet_preview.dart` | `_CheckoutSheetPreview`: cart preview requests, debounce, stale-response guard, promo code, preview failure text |
| `checkout_sheet_actions.dart` | `_CheckoutSheetActions`: destination and branch changes, payment method, confirm (hands back the delivery target the confirmed preview was priced for) |
| `checkout_sheet_parts.dart` | `_CheckoutStepLabel`, `_CheckoutDestinationCard`, `_OrderCommentField` |
| `checkout_ordering_status.dart` | `_OrderingStatusCard` and the working-hours rows |
| `checkout_loyalty_control.dart` | `_LoyaltyRedemptionControl`, `_FullyPaidWithPointsCard` |
| `checkout_preview_summary.dart` | priced lines / totals from cart preview (`_CheckoutPreviewSummary`, loading and error states, `_PreviewTotals`) |
| `checkout_preview_details_sheet.dart` | `_showCheckoutPreviewDetails()`: the breakdown sheet behind the totals |
| `order_confirmation_items.dart` | item rows in the sheet |
| `payment_method_selector.dart`, `promo_code_field.dart`, `order_type_toggle.dart` (`OrderTypeSlidingToggle`) | checkout inputs |
| `checkout_models.dart` | private checkout result/failure types |
| `order_success_screen.dart` | `OrderSuccessScreen` |

### `lib/screens/`

| Screen / entry | File | Notes |
| --- | --- | --- |
| `HomeScreen` | `home_screen.dart` | banners (`HomeBannerSlider`), promos, ordering status; `sessionPending` shows placeholders for the greeting and balance while the saved menu shows and the customer is not known yet |
| `MenuScreen` | `menu_screen.dart` + `menu/` part files | the screen's state, lifecycle and `build` (about 430 lines): category pills (pill position in a `ValueNotifier`), lazily built product grid (`SliverList` of rows, reused across layouts while the column count is unchanged), listens to its `CartController` itself (per-card `ProductQuantities`), `packagingAssets` override map. Parts: `menu_sections.dart` (`_MenuSections`: header, pills, grid, states), `menu_categories.dart` (`_MenuCategories`: category selection and pill geometry), `menu_add_to_cart.dart` (`_MenuAddToCart`: add-to-cart flight via `CartAnimationController`), `menu_order_context.dart` (`_MenuOrderContext`: delivery/pickup pill), `product_detail_page.dart` (`_ProductDetailPage`), `menu_widgets.dart` (skeleton card, sticky category header) |
| `CartScreen` | `cart_screen.dart` | reads props from `MainTabs` |
| `Profile` | `profile.dart` + `profile/` part files | `profile_redesign.dart` (main body; header carries `NotificationButton` when `onNotificationsTap` is set), `profile_rows.dart` (section, row, badge, switch, theme pill, version rows), `profile_language_sheet.dart`, `profile_edit_screen.dart`, `saved_addresses_screen.dart`, `all_orders_screen.dart`, `order_row.dart`, `order_details_sheet.dart` (`OrderProgressJourney`), `order_detail_widgets.dart`, `order_helpers.dart`, `delete_account_sheet.dart` |
| `AuthorizationScreen`, `OtpCountdownCard` | `authorization_screen.dart` + `auth/` part files | phone + OTP flow; parts: `otp_countdown_card.dart` (`OtpCountdownCard`), `name_prompt_sheet.dart` (`_NamePromptSheet`), `birth_date_prompt_sheet.dart` (`showBirthDatePromptSheet()`) |
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
| `TypographyText`, `TextType`, `FontWeightType` | `typography.dart` |
| `QuantityButton`, `AnimatedQuantityText` | `quantity_button.dart` |
| `ProductImage` | `product_image.dart` (network photo with gradient/emoji fallback; decoded to cover its box; `layoutWidth` for a known box width, `placeholderBox` to show an already-decoded smaller copy first) |
| `ProductListItem` | `product_list_item.dart` (menu grid tile: photo anchor, add / ± controls; `imageWidth` from the grid, `imageHeight` constant) |
| `CartItemCard` | `cart_item_card.dart` |
| `BannerImageCard` | `banner_image_card.dart` |
| `HomeBannerSlider` | `home_banner_slider.dart` |
| `NotificationButton` (round inbox button with unread dot; home and profile headers) | `notification_button.dart` |
| `showPromotionDetails()` (promotion details bottom sheet) | `promotion_details_sheet.dart` |
| `AppSurfaceCard` | `redesign/app_surface_card.dart` |
| `CartPill` | `redesign/cart_pill.dart` |
| `OrderContextPill` | `redesign/order_context_pill.dart` |
| `appSnackBar()` | `app_snack_bar.dart` |
| `showAppModalBottomSheet<T>()`, `AppModalBottomSheetDragScope` | `app_modal_bottom_sheet.dart` |
| `AppBottomSheetDragHandle` | `app_bottom_sheet_drag_handle.dart` |
| `showConfirmDialog()` | `confirm_dialog.dart` |
| `AnimatedErrorMessage` | `animated_error_message.dart` |
| `FadeSlideIn` (`animate: false` shows the child at once, e.g. a list row scrolled back into view) | `fade_slide_in.dart` |
| `CurvedFadeTransition` (use in route `transitionsBuilder`s instead of an inline `CurvedAnimation`) | `curved_fade_transition.dart` |
| `coverNetworkImage()`, `DiskCachedNetworkImage`, `AppImageCacheManager`, `networkImageProvider` (disk-cached photos decoded to cover their box; product photos at 3× at most, banners and Home tiles at the full screen ratio; tests override the factory in `test/flutter_test_config.dart`) | `utils/cached_image_provider.dart` |
| `CoverSizedImage`, `coverTargetSize()`, `coverDecodeExtent()` (decode at the smallest size that covers a box, keeping the aspect ratio; 16 px steps, DPR capped at 3) | `utils/cover_sized_image.dart` |
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

### `lib/theme/`

| File | Contents |
| --- | --- |
| `app_design_tokens.dart` | `AppDesignTokens` (colors, radii, heights, `surface()` for cards and sheets, `inset()` for fields and boxes set into a surface, `ground()`, text colors, `cardShadow()`) and `AppTextStyles` (`display()`, `ui()`) |
| `app_motion.dart` | `AppMotion` durations (`micro`, `state`, `spatial`, `celebration`), curves, `reduced(context)` (reads only the two accessibility settings, so callers are not rebuilt by other `MediaQuery` changes), `duration(context, normal)` |
| `app_theme.dart` | `AppTheme` builder; `light_theme.dart` / `dark_theme.dart` export `lightTheme` / `darkTheme` |
| `app_colors.dart` | `BaseColors` (brand primary etc.) |
| `app_theme_colors.dart` | `AppThemeColors` theme extension |

### `lib/l10n/`

`app_uz.arb` is the template; `app_ru.arb` and `app_en.arb` must carry the same
keys. Generated `app_localizations*.dart` are committed. Access strings with
`L.of(context).key`. Never hardcode user-facing Russian/Uzbek text.
Uzbek copy uses the reformed Latin alphabet adopted in 2026: `ö ğ ş ç` in
place of `oʻ gʻ sh ch`; the in-word apostrophe (`maʼlumot`) and `ng` are
unchanged. This also applies to the Uzbek literals in
`mobile_error_messages.dart`, `app_version_gate.dart` and `price_formatter.dart`.

## `test/`

Flat folder, one file per concern, named `<area>_test.dart`. Groups:

- Cart animation: `cart_animation_controller_test`, `cart_packaging_preset_integration_test`, `cart_packaging_visual_test`, `preset_packaging_visual_test`, `cart_add_failure_test`, `cart_flight_preview_test`. The last two visual tests write contact sheets when given `--dart-define=PACKAGING_PREVIEW_PATH=…` / `CART_FLIGHT_PREVIEW_PATH=…`.
- Screens/UX: `home_screen_test`, `menu_lazy_grid_test`, `menu_motion_test`, `cart_screen_ux_test` (also: a line that left the cart and came back plays its entrance again), `profile_redesign_test`, `notifications_promotions_ui_test`, `loyalty_wallet_screen_test`, `order_success_screen_test`, `authorization_*`, `branch_bottom_sheet_test`, `product_list_item_test`, `product_configuration_test`, `widget_test`.
- Checkout: `checkout_rules_test` (delivery address text, the delivery target rule and "what is shown is what is sent", cart reconciliation, repeat order, order lines and inline address), `checkout_flow_test` (exact preview and create-order payloads for delivery to a saved address or a map point, pickup, promo code and payment method; success, ordering closed, timeout retry and key reuse), `order_submission_keys_test` (key reuse after unknown outcomes), `cart_safety_nets_test` (removed-item notices at restore and on catalog refresh, Undo after removing a line, sign-out clears and expiry keeps the cart, repeat order, quantity cap).
- Cold start with the saved menu: `public_content_cache_test` (round trip, scope/language/schema/age misses, content saved "in the future", bad and oversized files deleted, leftover temp file replaced, overlapping saves), `public_content_repository_test` (only public payloads saved, same menu read back, no save for branch catalogs, failed requests or an answer with nothing to order, no promotions request, ended-promotion banners dropped), `cached_startup_test` (shown while loading, replaced by the network, kept on failure with a Retry notice that also shows for a failure before the first frame and stays, cart never trimmed against it, sign-in actions and Checkout wait for the session, open once and retry a failed start-up instead of asking to sign in, Home placeholders while the session is unknown, a branch picked during start-up, retry on return to the app).
- Session: `mobile_backend_session_test` (late responses across login/logout, session end reasons, resume throttle, change-only order polling, promotions freshness), `push_permission_prompt_test` (the OS prompt once, at app entry or sign-in, never on background refresh; guests are asked but not registered; later launches signal the reminder instead; the 1-day/3-day schedule; no reminder for guests or after the in-app opt-out; Android rationale picks the OS prompt or settings; allowing in settings registers on return), `push_reminder_shell_test` (the shell shows a due reminder, "Not now", "Don't remind me", it waits behind another screen, the birth-date prompt and the update prompt, the sheet scrolls on a small screen with large text), `authorization_screen_migration_test` (sign-in shows the first OS prompt, or the reminder sheet when it was shown before).
- Performance guards: `shell_rebuild_scope_test` (rebuild counts: a tab tap or swipe builds no tab content, a category tap rebuilds the menu once, a cart tap rebuilds one card, an unread-count change rebuilds Home only, a no-op notification rebuilds no tab, the keyboard sliding in rebuilds no tab, a screen-size change still rebuilds the menu), `menu_lazy_grid_test`, `startup_requests_test`, `cart_controller_test`, `product_quantities_test`, `token_storage_test`, `text_change_listener_test`.
- Images: `cover_sized_image_test` (decode-size rule and real decodes: never squashed, never upscaled), `product_image_test` (cart thumbnail box, known layout width, self-measuring fallback, placeholder decode first).
- Models/repositories: `*_model_test` (`payment_method_model_test` also pins `paymentMethodLabel` and `readOptionalInt`), `ordering_status_repository_test`, `promotion_banner_repository_test`, `api_client_test`, `cart_storage_test`, `mobile_backend_migration_contract_test`, `redesign_audit_contract_test`.
- Startup/errors: `startup_preferences_test`, `failure_message_test`.
- Services: `location_controller_test` (coordinates and address stay about one place; a picked point is not replaced by a lookup that started earlier), `ios_notification_tap_test`, `app_version_gate_test`, `mobile_push_notification_service_test`, `app_share_service_test`, `initial_location_loader_test` (location first, then notification permission), `external_url_launcher_test` (scheme + host allowlist, channel never called for rejected links), `yandex_geocoder_service_test` (no network without keys, key injection), `log_redaction_test`.

Tests build real widgets with `MaterialApp` + `MediaQuery` and fake
repositories by hand; there is no mockito/mocktail. `test/support/menu_catalog.dart`
is a static sample catalog (`menuProducts`) shared by several widget tests. `flutter_test_config.dart`
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
| 2 Menu | Backend catalog flows through `MobileBackendController` + catalog adapter into `MenuProduct`. `MenuScreen` is a stateful widget split into `menu/` part files (detail page, categories, add to cart, sections); category logic still lives in the widget, not a provider |
| 3 Cart | `CartController` in `lib/features/cart/presentation/`, owned by `MainTabs`; `MenuScreen` listens to it directly, `CartScreen` still receives lines as props |
| 4 Checkout | Implemented inside `MainTabs` part files (`_OrderConfirmationSheet`, `OrderSuccessScreen`), not as a feature module |
| 5 GoRouter | Not started; `MaterialPageRoute` everywhere |
| 6 Profile | Real data via `MobileBackendController`; UI split into `profile/` parts |
| 7–10 | Error mapping and localization done; Sentry error reporting and dart-define config in place; connectivity and CI not started |

## Other documents

| File | What it covers |
| --- | --- |
| `ROADMAP.md` | target architecture and the ten refactor phases |
| `docs/STABILITY_AUDIT.md` | October 2026 audit: leaks, crash risks, security and performance findings with severity, and the remediation phases with status |
| `docs/PERFORMANCE_PASS_2.md` | November 2026 performance and structure pass: findings, phase status, how to run the on-device harness, before/after numbers |
| `docs/add_to_cart_assets.md` | add-to-cart packaging animation: presets, lighting, timing, preview tests |
| `docs/CAFE_REDESIGN_BACKEND_REQUIREMENTS.md` | backend data the redesign still needs |
| `docs/CAFE_REDESIGN_IMPLEMENTATION_AUDIT.md` | redesign parity audit and remaining P1 work |
| `docs/superpowers/specs/2026-08-06-working-hours-ordering-design.md` | working-hours checkout gating design |
| `API_DOCS.md`, `BANNERS_API.md`, `README.md` | backend contracts and deep links |
