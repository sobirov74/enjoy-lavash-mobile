repo: sobirov74/enjoy-lavash-mobile
branch: main

## Last sync

date: 2026-09-01T14:05:00Z

### Updated in this project

- Added nine empty and error states on a second board (`Enjoy Lavash Holatlar.dc.html`): 500, offline, 404, 401, 429, empty cart, empty inbox, empty category, and 422 field validation.
- Error copy uses the exact strings from `lib/core/error/mobile_error_messages.dart`, demoted to a diagnostic line under a plain-language sentence.
- Flagged `_prefersServerMessage()` returning true for VALIDATION_FAILED / BAD_REQUEST — raw backend text reaches the customer (asserted by `test/mobile_error_messages_test.dart`).
- Swapped the type system to Manrope + Golos Text (both carry Cyrillic, both free for commercial use); three alternative pairings are compared on the board as turn 3, switchable via the `fontPair` prop.
- Added a full dark theme to all nine screens, using `AppThemeColors.dark` (ground #151312, surface #1D1A18, border #35302C) plus the snackbar inversion pattern from `app_theme.dart`.
- Theme switch wired to Profil → Ko'rinish; five dark frames added to the review board as turn 2.
- Confirmed from `pubspec.yaml` that no custom font ships today — documented Clash Display + Instrument Sans as the type upgrade.
- Fixed accent aliases so every interactive element resolves to the brand red instead of the design-system default.

## Screen map

| Project screen | Built from |
| --- | --- |
| 1a Kirish (auth) | `lib/screens/authorization_screen.dart`, uz l10n auth strings |
| 1b Bosh sahifa | new screen; `lib/widgets/promo_slider.dart`, `lib/widgets/delivery_chip.dart` |
| 1c Menyu | `lib/screens/menu_screen.dart`, `lib/widgets/product_list_item.dart` |
| 1d Mahsulot | `lib/screens/menu_screen.dart` (product sheet), `lib/widgets/quantity_button.dart` |
| 1e Savat | `lib/screens/cart_screen.dart`, `lib/widgets/cart_item_card.dart` |
| 1f Buyurtma berish | `MOBILE_ORDER_PREVIEW_API.md`, `lib/enums/payment.dart`, `lib/screens/address_bottom_sheet.dart` |
| 1g Mening ballarim | `lib/screens/loyalty_wallet_screen.dart` |
| 1h Xabarlar | `lib/screens/notifications_screen.dart`, `lib/screens/assigned_promotions_screen.dart` |
| 1i Profil | `lib/screens/profile.dart`, `lib/screens/profile/**` |
| Order type sheet | `lib/screens/branch_bottom_sheet.dart` |
| 4a–4e error screens | `lib/core/error/mobile_error_messages.dart`, `test/mobile_error_messages_test.dart` |
| 4f–4h empty states | `lib/l10n/app_localizations_uz.dart` (`cartEmpty*`, `noNotifications`, `noProducts`) |
| 4i 422 validation | `lib/core/error/mobile_error_messages.dart` (`VALIDATION_FAILED`), `MOBILE_ORDER_PREVIEW_API.md` |

## Sync history

- 2026-09-01T12:10:52Z — first build: 9-screen light-mode flow, copy from `app_localizations_uz.dart`, accent from `AppThemeColors.light.primary`, inbox per `MOBILE_APP_NOTIFICATIONS_AND_PROMOS.md`, logo + icon assets copied.

## Notes

- Design system: Pace (bound to this project). Pace structure/type/spacing/shadows, with `--pace-action` re-pointed to the Enjoy brand red and the logo yellow mapped onto Pace's citrus tokens for anything ball-related.
- Product photography is not in the repo (API-served), so menu tiles use drop-in image placeholders.
