# Cafe redesign implementation audit

Status: current mobile worktree, September 2026

## Summary

The redesign's core customer journey, reference Profile, and high-risk data
correctness work are implemented. Exact visual and behavior parity still
includes the client P1 work listed below. The two backend-dependent blockers to visible content parity are
fulfilment ETA data and promotion creative/action metadata. Ordering status,
category images, product calories, weight and cooking time, and authoritative
cart-preview priced lines are already implemented and are **not** backend gaps.

Scheduled-order controls are outside the approved immediate-order redesign
scope. Existing live order tracking, branch/address selection, assigned
promotions, and payment retry remain available.

## Completed client work

| Area | Current state |
| --- | --- |
| Visual foundation | Shared cream/ink/gold design tokens, Manrope/Golos Text typography, light/dark themes, surface cards, context pill, cart pill, responsive spacing, and reduced-motion handling are in place. |
| Home and fulfilment context | Home includes greeting, loyalty balance, repeat-order card, promotion hero fallback, image-led category cards, notification badge, and a shared delivery/pickup context sheet for address or branch selection. Guest-only notification and loyalty actions are authentication-gated. |
| Catalog and menu | The menu has an All/category filter, two-column product grid, product detail route, quantity controls, quick-add/customization behavior, modifier validation, and cart animation. Category `image` is parsed/resolved and used on Home with a product-image fallback. |
| Product metadata | Catalog `calories`, `weightGrams`, and `cookingTimeMinutes` are parsed into the client model and rendered on product detail. Localized descriptions and modifier images/defaults/availability are also consumed. |
| Cart integrity | Configured modifier selections and comments are persisted, restored, reconciled against the latest catalog, and serialized into preview/create requests. Invalid historical selections fall back safely to customization. |
| Checkout pricing | Authenticated cart preview drives item, modifier, discount, delivery, service-fee, loyalty, and payable totals. Server-priced lines, localized modifier snapshots, promotion status, and bonus/gift items are parsed and rendered, with local cart lines only as a fallback. A rejected entered promo now blocks confirmation until it is corrected or cleared, so it cannot be silently removed from the submitted order. |
| Ordering availability | Typed models, public repository call, and checkout UI consume `GET /branches/:id/ordering-status`. Pickup and delivery remain independent; delivery follows the preview-resolved branch. Known-closed states gate confirmation and refresh automatically or manually; `ORDERING_CLOSED` preview/create metadata and next opening are preserved without clearing the cart. A status-load failure remains advisory because create-order revalidates availability. |
| Submission safety | Order creation uses one UUID idempotency key across retry attempts for the same submission. Network/server retries, loyalty conflicts, authentication expiry, and online-payment handoff/retry are preserved. |
| Success and tracking | The success screen exposes payment/loyalty state, Track order, and Back to home actions. Order details refresh immediately and poll active orders every eight seconds while rendering the real status journey. |
| Notifications and account | All/Orders/Promotions inbox filters, promotion-code actions, mark-read controls, actionable empty state, order history, loyalty wallet/history, settings, and assigned promotions are implemented. Profile now follows the reference's separate identity/points surfaces and compact Orders, Settings, and Actions groups. Identity editing retains name, birth date, marketing consent, and account deletion; the saved-address route lists, creates, defaults, and deletes addresses through the existing API. Guest account-only rows are gated. |
| Resilient bootstrap | Promotion/payment bootstrap failures no longer hide the catalog. Address/order failures remain optional after profile success, while a required profile failure propagates and preserves an already authenticated controller instead of changing it to guest UI. |
| Localization and coverage | New redesign copy, Profile/address labels, promo failure states, promotion rewards, and UZS amounts are localized for Uzbek, Russian, and English. Focused tests cover the authenticated/guest Profile inventory, exact identity and points geometry at the reference width, compact large-text behavior, theme switching, catalog/modifier behavior, ordering-status parsing/repository behavior, notifications, cart persistence, success/payment behavior, bootstrap preservation, and existing migration contracts. |

## Backend blockers and contracts still needed

| Priority | Gap | Contract needed |
| --- | --- | --- |
| P0 | Fulfilment ETA | Add an expiring delivery/preparation quote for the selected address or pickup branch, plus the confirmed ETA/range on the created order. Working hours indicate availability but cannot supply duration. This blocks an honest ETA in the Home/Menu context pill and success screen. |
| P0 | Promotion creative and destination | Add localized hero image metadata, badge, and a typed action (`CATEGORY`, `PRODUCT`, `PROMOTION`, or `EXTERNAL_URL`) with target ID/URL and label. The client currently uses text/gradient fallback and routes the hero generically to Menu. |
| P1 | Reliable reorder | Add `POST /clients/me/orders/{orderId}/reorder-preview` returning current product IDs, modifier selections, availability, changed/removed items, and review state. Current repeat-order is best-effort because order history does not preserve modifiers reliably. |
| P1 | Required-modifier invariant | For every available required group, expose enough available `isDefault` options to satisfy `minSelect`, or explicitly require customization. Array order must not imply a default. |
| P1 | Notification filtering at scale | Add server-side order/promotion grouping with filtered `total` and `unreadCount`. Current filtering is correct only for the locally loaded inbox page. |
| P1 | Field-level validation envelope | Stabilize `details.fieldErrors` for customer-correctable 422 fields while retaining `errorCode`, localized `message`, safe `metadata`, and rate-limit data. This enables precise inline checkout errors without parsing prose. |
| Conditional | Product favorites | Only add authenticated favorite list/toggle contracts and `isFavorite` if the reference heart is approved as a real feature. Otherwise keeping the control absent is the correct production behavior. |
| Optional | Richer catalog metadata | Category width/height/alt/accent and nutrition macros/volume are additive enhancements, not redesign blockers. Flat category image plus calories/weight/cooking time already work. |

Detailed proposed payloads and compatibility rules remain in
`docs/CAFE_REDESIGN_BACKEND_REQUIREMENTS.md`.

## Non-blocking P1 client follow-ups

| Follow-up | Scope |
| --- | --- |
| Cart preview placement | Load the authoritative preview on Cart so promo entry, delivery/pickup fee, total, gifts, and estimated points match the reference before checkout. Checkout already consumes the same data correctly. |
| Auth onboarding layout | Move first-time name and birth-date collection from sequential sheets into the reference's third inline authorization state. Phone correction from OTP is already implemented. |
| Loyalty hierarchy | Align the wallet's top balance, spendable/reserved metrics, expiry warning, and grouped transaction surface with the supplied hierarchy after confirming backend balance semantics. |
| Reusable application errors | Add the reference full-screen offline, 401, 404, 429, and 5xx variants with context-specific primary/escape actions and cart/session preservation copy. Existing inline failures remain functional. |
| Product search | Add the menu search field and title/description/category filtering. Localized search strings already exist, but the production menu does not yet consume them. |
| Branch-timezone formatting | Replace `DateTime.toLocal()` for `nextOpeningAt` with conversion using the response's IANA `timezone`; the current label includes the branch timezone but formats in the device timezone. |
| Inline checkout validation | Map stable backend `details.fieldErrors` to address, branch, payment, promo, and loyalty controls while preserving the cart and editable checkout. |
| Backend-dependent integrations | Consume ETA/confirmed ETA, promotion creative/action, reorder-preview, and server notification filters when those contracts ship. |
| Visual regression coverage | Add golden/screenshot coverage for the reference viewport plus compact, dark-theme, and large-text variants of Home, Menu, product detail, cart, checkout, success, and notifications. Profile now has structural, exact-card-geometry, guest, compact large-text, and theme-action widget coverage; image golden baselines remain optional. |
| Favorites decision | Either implement the approved favorite flow after backend support or keep the reference heart intentionally omitted; do not simulate persisted state locally. |
