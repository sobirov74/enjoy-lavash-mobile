# Enjoy Lavash Mobile UX Audit

This audit focuses on the shortest path from opening the app to placing an
order, while keeping the current warm Enjoy Lavash identity.

## Implemented in this pass

| Problem | User impact | Solution |
| --- | --- | --- |
| Checkout moved below every cart item | Users with long orders had to hunt for the primary action | The cart now keeps its total and Checkout action fixed at the bottom while only the item list scrolls |
| Weak feedback after adding food | Users could miss that an item was added or forget the current total | A floating cart summary now shows item count and total and opens the cart in one tap |
| Accidental removal was irreversible | One extra tap could silently remove a product | Removing the final quantity now shows an Undo action |
| Cart disappeared after restart | Interrupted orders had to be rebuilt | Valid cart quantities are persisted locally and restored safely |
| Back from Cart/Profile could exit the app | Navigation did not match common Android expectations | Back returns to Menu first; it exits only from the Menu tab |
| Loading spinner gave no layout context | The menu felt slower and visually jumped when content arrived | Loading now uses a clear status plus product-shaped skeleton cards |
| Empty search was a dead end | Users had to manually edit the query | The empty result includes a prominent Clear search action |
| Inconsistent controls and surfaces | Buttons, inputs, sheets, and dark-mode surfaces felt unrelated | A shared Material 3 theme now defines type hierarchy, touch sizes, fields, buttons, dialogs, sheets, borders, and feedback |
| Some icon and quantity actions were unclear to assistive tech | Screen-reader and long-press users lacked action names | Tooltips and semantic labels were added to navigation and quantity controls |
| Analyzer output contained 100 existing warnings | Real regressions were easy to miss | Controller notifications now preserve `ChangeNotifier` boundaries; analysis is clean |

## Design direction

- Keep orange as the action color and use warm neutral surfaces so food imagery
  remains the visual focus.
- Use one strong action per stage: View cart on Menu, Checkout in Cart, Create
  order in confirmation.
- Keep controls at least 48 logical pixels where possible.
- Show state changes next to the action that caused them, with recovery for
  destructive changes.
- Prefer progressive disclosure: menu first, order details during checkout,
  account settings in Profile.

## Motion system plan: Enjoy Smile

Motion should explain state and location before it decorates the interface. The
shared language is a warm fold, a short smile-shaped path, and a soft settle;
the app should not use unrelated bounce, parallax, confetti, or looping motion.

| Phase | Motion | Product purpose | Acceptance criteria | Status |
| --- | --- | --- | --- | --- |
| Foundation | Shared timing and reduced-motion policy | Keep motion consistent and accessible | Decorative travel and stagger are skipped when either platform animation suppression or accessible navigation is enabled | Implemented |
| Add to cart | Product token follows an Enjoy-smile curve into the floating cart summary | Show exactly where the first item went | Cart state updates immediately; one flight at a time; rapid taps collapse to a count update; overlay cannot receive taps or semantics | Implemented |
| Product continuity | Product image expands into an unrolling detail surface | Preserve context while progressively revealing product information | Reversible transition, immediate close action, no layout shift, works in light/dark mode | Implemented |
| Selection | One orange surface moves between categories and Delivery/Pickup | Make related controls feel predictable | Labels and hit targets remain fixed; selection state is never communicated by motion alone | Implemented |
| Order confidence | Success ticket and real-status journey | Confirm submission and make status changes understandable | Success content and Track order are visible immediately; progress moves only after a real backend status update; no fake looping progress | Implemented |

### Motion tokens

- Micro feedback: 140 ms.
- Local state change: 220 ms.
- Spatial transition: 380 ms.
- One-time success moment: up to 650 ms.
- Use transform, opacity, and isolated painting for animated elements. Never
  delay cart, checkout, payment, or navigation state until animation completes.

### Motion QA checklist

- Verify 320 px width, large accessibility text, landscape, and light/dark
  themes.
- Verify Uzbek, Russian, and English strings do not move or clip controls.
- Verify animation suppression and accessible navigation produce an immediate,
  stable interface.
- Verify rapid product adds do not queue overlay flights.
- Profile on a lower-end Android device and keep motion at 60 fps without
  full-screen blur or shader effects.
- Confirm order progress animates only when polling returns a newer real status.

### Verification completed in this pass

- `flutter analyze` completes with no issues.
- Twenty focused motion and ordering widget tests pass, including the real menu
  Add → cart flight → product-detail open/close path.
- Compact 320 px, large text, dark theme, and reduced-motion cases pass without
  overflow or unreachable primary actions.
- The Flutter web debug build compiles and serves successfully.
- The complete repository suite retains three pre-existing failures in
  `authorization_screen_migration_test.dart`; the same failures were present in
  the baseline before motion work and are outside this motion change.

## Recommended next iterations

### High priority

1. Extend the new product-detail sheet with backend-provided ingredients,
   allergens, and modifiers. This reduces ordering mistakes and enables
   customization.
2. Add delivery estimates and minimum-order information beside the address,
   before checkout begins.
3. Cache the last successful catalog and show an offline banner. Users should
   still be able to browse during a temporary connection loss.
4. Add a backend-provided ETA to the new order-success screen when the order
   response exposes one; do not invent a time estimate on the client.

### Medium priority

1. Support favorites and quick reorder for repeat customers.
2. Add dietary/allergen filters and recent searches.
3. Validate layouts at 320 px width, large accessibility text, landscape, and
   both light/dark modes with screenshot tests.
4. Measure the funnel: menu view → add item → cart → checkout preview → order
   success. Use this data to prioritize future changes.

## Product risks to monitor

- Backend price or availability changes while an item is stored locally. The
  server preview should remain the source of truth and explain changes clearly.
- Address permission denial or inaccurate GPS. Manual address entry must always
  remain available.
- Slow image delivery. Keep placeholders, cache resized images, and monitor
  image payload sizes.
- Duplicate order submission on unstable networks. The server should use an
  idempotency key and the UI should preserve a visible submitting state.
