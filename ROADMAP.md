# EnjoyLavash Mobile - Refactoring Roadmap

> Each phase is designed as a single conversation session.
> Every step follows **Clean Architecture**, is **performance-optimized**, and keeps code **readable for any developer**.

---

## Target Architecture

```
lib/
├── main.dart
├── app/
│   ├── app.dart                    # MaterialApp, theme, locale, router
│   ├── di.dart                     # GetIt service locator setup
│   ├── router.dart                 # GoRouter configuration
│   ├── theme_controller.dart
│   └── locale_controller.dart
│
├── core/
│   ├── api/
│   │   ├── api_client.dart         # Dio instance (no UI logic)
│   │   ├── api_endpoints.dart
│   │   └── base_url.dart
│   ├── error/
│   │   ├── failures.dart           # Failure types (Network, Server, Cache)
│   │   └── result.dart             # Result<T> = (T?, Failure?) typedef
│   ├── storage/
│   │   ├── token_storage.dart
│   │   └── theme_storage.dart
│   └── utils/
│       ├── price_formatter.dart
│       └── date_formatter.dart
│
├── features/
│   ├── menu/
│   │   ├── data/
│   │   │   ├── menu_remote_source.dart
│   │   │   ├── menu_repository_impl.dart
│   │   │   └── models/menu_product_dto.dart
│   │   ├── domain/
│   │   │   ├── entities/menu_product.dart
│   │   │   ├── repositories/menu_repository.dart   # abstract
│   │   │   └── usecases/get_menu.dart
│   │   └── presentation/
│   │       ├── menu_provider.dart
│   │       ├── menu_screen.dart
│   │       └── widgets/
│   │           ├── category_tabs.dart
│   │           ├── product_card.dart
│   │           └── promo_banner.dart
│   │
│   ├── cart/
│   │   ├── data/
│   │   │   └── cart_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/cart_line.dart
│   │   │   ├── repositories/cart_repository.dart    # abstract
│   │   │   └── usecases/
│   │   │       ├── add_to_cart.dart
│   │   │       ├── update_quantity.dart
│   │   │       └── get_cart_total.dart
│   │   └── presentation/
│   │       ├── cart_provider.dart
│   │       ├── cart_screen.dart
│   │       └── widgets/cart_item_card.dart
│   │
│   ├── checkout/
│   │   ├── data/
│   │   │   ├── order_remote_source.dart
│   │   │   └── order_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/order.dart
│   │   │   ├── repositories/order_repository.dart   # abstract
│   │   │   └── usecases/create_order.dart
│   │   └── presentation/
│   │       ├── checkout_provider.dart
│   │       └── checkout_screen.dart
│   │
│   └── profile/
│       └── presentation/
│           ├── profile_screen.dart
│           └── widgets/
│               ├── loyalty_card.dart
│               ├── order_history_list.dart
│               └── lang_selector.dart
│
├── shared/
│   ├── widgets/
│   │   ├── typography.dart
│   │   ├── button.dart
│   │   ├── action_icon_button.dart
│   │   ├── delivery_chip.dart
│   │   └── quantity_button.dart
│   └── theme/
│       ├── app_colors.dart         # Single source of truth for colors
│       ├── app_theme_colors.dart
│       ├── light_theme.dart
│       ├── dark_theme.dart
│       └── theme_extensions.dart
│
└── l10n/
    ├── app_uz.arb
    ├── app_ru.arb
    └── app_en.arb
```

---

## Phase 1 — Foundation (Core + DI + Error Handling)

**Goal:** Set up the skeleton that every feature will depend on.

### Tasks

1. **Create `core/error/failures.dart`**
   - `Failure` sealed class with `message` field
   - Subclasses: `NetworkFailure`, `ServerFailure`, `CacheFailure`, `UnknownFailure`

2. **Create `core/error/result.dart`**
   - Lightweight `Result<T>` type using sealed class (`Success<T>`, `Error`)
   - No external dependency (no dartz/fpdart needed)

3. **Set up GetIt in `app/di.dart`**
   - Add `get_it` + `injectable` to pubspec
   - Register: `ApiClient`, storage instances, repositories, providers
   - Call `setupDi()` in `main.dart` before `runApp`

4. **Clean up `api_client.dart`**
   - Remove toast/vibration imports (no UI in data layer)
   - Return `Result<T>` from requests instead of throwing
   - Keep token refresh logic, add request timeout (15s)

5. **Consolidate theme files**
   - Delete duplicate `lib/widgets/theme/` folder
   - Keep single `lib/shared/theme/` as source of truth
   - Update all imports

6. **Move shared widgets to `lib/shared/widgets/`**
   - `typography.dart`, `button.dart`, `action_icon_button.dart`, etc.
   - Update all imports

### Performance notes
- `ApiClient` registered as **lazy singleton** (created on first use)
- Storage instances registered as **async singleton** (initialized at startup)

---

## Phase 2 — Menu Feature (Clean Architecture)

**Goal:** Replace hardcoded menu with a proper feature module.

### Tasks

1. **Domain layer**
   - `MenuProduct` entity (immutable, `const` constructor)
   - `MenuRepository` abstract class
   - `GetMenuUseCase` — returns `Result<List<MenuProduct>>`

2. **Data layer**
   - `MenuProductDto` with `fromJson` / `toEntity()`
   - `MenuRemoteSource` — fetches from API
   - `MenuRepositoryImpl` — implements abstract repo, wraps errors into `Failure`
   - Keep static fallback from `menu_catalog.dart` for offline/demo

3. **Presentation layer**
   - `MenuProvider` (ChangeNotifier) with states: `loading`, `loaded`, `error`
   - Move scroll-spy & category logic into provider (out of widget)
   - `MenuScreen` becomes stateless, reads from provider

4. **Extract widgets**
   - `CategoryTabs` — horizontal chip list (own file)
   - `ProductCard` — single product item (own file)
   - `PromoBanner` — promo section (own file)

### Performance notes
- Products grouped by category **once** in provider, not on every build
- `CategoryTabs` uses `RepaintBoundary` to isolate repaints
- `ProductCard` is `const`-constructible where possible
- `ListView` uses `addAutomaticKeepAlives: false` for off-screen disposal

---

## Phase 3 — Cart Feature (Extract from MainTabs)

**Goal:** Cart becomes its own feature with proper state management.

### Tasks

1. **Domain layer**
   - `CartLine` entity
   - `CartRepository` abstract class
   - Use cases: `AddToCart`, `UpdateQuantity`, `RemoveFromCart`, `GetCartTotal`

2. **Data layer**
   - `CartRepositoryImpl` — local-first (Map in memory), persist to SharedPreferences
   - Later: sync to backend

3. **Presentation layer**
   - `CartProvider` (ChangeNotifier) registered in DI
   - Expose: `items`, `totalItems`, `totalAmount`, `addItem()`, `updateItem()`, `removeItem()`
   - `CartScreen` reads from `CartProvider` instead of receiving props

4. **Fix MainTabs**
   - Remove all cart state (`_cart`, `_cartLines`, `_totalItems`, `_totalAmount`)
   - `MainTabs` becomes a thin shell: just tab switching
   - Cart badge reads from `context.watch<CartProvider>().totalItems`

### Performance notes
- `CartProvider` uses `notifyListeners()` only when data actually changes
- `CartItemCard` wrapped in `RepaintBoundary` (already done)
- Cart total computed as cached getter, not re-folded on every access

---

## Phase 4 — Checkout Feature (New)

**Goal:** Make "Checkout" button functional.

### Tasks

1. **Domain layer**
   - `Order` entity
   - `OrderRepository` abstract class
   - `CreateOrderUseCase` — takes cart items, delivery address, payment method

2. **Data layer**
   - `OrderRemoteSource` — POST to order endpoint
   - `OrderRepositoryImpl`

3. **Presentation layer**
   - `CheckoutProvider` with states: `idle`, `processing`, `success`, `error`
   - `CheckoutScreen` — address input, payment method, confirm button
   - On success: clear cart, show confirmation, navigate to order details

4. **Wire up**
   - Cart screen "Checkout" button navigates to `CheckoutScreen`
   - Pass cart items via provider (not constructor args)

---

## Phase 5 — Navigation (GoRouter)

**Goal:** Replace imperative navigation with declarative routing.

### Tasks

1. **Add `go_router` package**

2. **Create `app/router.dart`**
   ```dart
   final router = GoRouter(
     routes: [
       ShellRoute(           // MainTabs shell
         builder: (_, __, child) => MainShell(child: child),
         routes: [
           GoRoute(path: '/menu', builder: ...),
           GoRoute(path: '/cart', builder: ...),
           GoRoute(path: '/profile', builder: ...),
         ],
       ),
       GoRoute(path: '/checkout', builder: ...),
       GoRoute(path: '/order/:id', builder: ...),
     ],
   );
   ```

3. **Remove `app_navigator.dart`** (GlobalKey antipattern)

4. **Update `api_client.dart`** logout redirect to use router

### Performance notes
- `ShellRoute` preserves tab state without `IndexedStack` overhead
- Pages are lazy-loaded on first visit

---

## Phase 6 — Profile Feature Refactor

**Goal:** Replace hardcoded profile data with real user data.

### Tasks

1. **Domain layer**
   - `User` entity, `LoyaltyInfo` entity
   - `UserRepository` abstract class
   - `GetUserProfileUseCase`, `GetLoyaltyInfoUseCase`

2. **Data layer**
   - Wire to existing `auth.dart` repository (getMe)
   - Add loyalty endpoint

3. **Presentation layer**
   - `ProfileProvider` with user state
   - Extract: `LoyaltyCard`, `OrderHistoryList`, `LangSelector` as separate widgets
   - Order history fetched from API with pagination

4. **Performance**
   - Profile data cached in provider, refreshed on pull-to-refresh
   - `LoyaltyCard` is its own `RepaintBoundary`

---

## Phase 7 — Error Handling & UX Polish

**Goal:** Consistent error handling across all features.

### Tasks

1. **Error widget system**
   - `ErrorView` widget (retry button + message)
   - `LoadingView` widget (skeleton shimmer)
   - `EmptyView` widget (replaces current `EmptyList`)

2. **Network-aware UX**
   - Add `connectivity_plus` package
   - Show offline banner when no connection
   - Queue failed requests for retry

3. **Loading states**
   - Every provider exposes `AsyncState<T>` = `loading | loaded(T) | error(Failure)`
   - Screens use pattern matching: `switch (state) { loading => ..., loaded => ..., error => ... }`

4. **Localize all error messages**
   - Add keys to ARB files: `errorNetwork`, `errorServer`, `errorUnknown`, `errorTimeout`
   - Remove all hardcoded Russian strings from repositories

---

## Phase 8 — Performance Optimization Pass

**Goal:** Squeeze maximum rendering performance.

### Tasks

1. **Widget-level**
   - Audit every widget for missing `const` constructors
   - Add `RepaintBoundary` around expensive subtrees (promo banner, loyalty card)
   - Replace `Column` with `ListView.builder` for long lists
   - Use `addAutomaticKeepAlives: false` + `addRepaintBoundaries: false` where custom boundaries exist

2. **Provider-level**
   - Use `context.select<T, R>()` instead of `context.watch<T>()` to minimize rebuilds
   - Split large providers into focused ones (e.g., `CartBadgeProvider` for just the count)

3. **Image/Asset**
   - Cache network images with `cached_network_image`
   - Preload critical assets in `main.dart`
   - Use appropriate image resolution per device DPI

4. **Build-level**
   - Enable tree shaking for icons: `uses-material-design: true` + specific icon fonts
   - Run `flutter build --analyze-size` and address large imports
   - Defer heavy packages with deferred loading if needed

5. **Scroll performance**
   - `cacheExtent: 1200` already set (good)
   - Add `AutomaticKeepAlive` only for tabs that need state preservation
   - Profile with DevTools and fix any jank frames

---

## Phase 9 — Testing

**Goal:** Reliable test coverage for critical paths.

### Tasks

1. **Unit tests**
   - All use cases (mock repository, verify result)
   - All repositories (mock API client, verify mapping)
   - Providers (verify state transitions)

2. **Widget tests**
   - `MenuScreen` — renders categories, tapping chip scrolls
   - `CartScreen` — empty state, add/remove items, total updates
   - `CheckoutScreen` — form validation, submit flow

3. **Integration tests**
   - Full flow: browse menu -> add to cart -> checkout -> confirm
   - Language switch -> verify all visible strings change

4. **Setup**
   - Create `test/` mirror of `lib/features/` structure
   - Add `mockito` + `build_runner` for mock generation
   - CI pipeline: `flutter test --coverage`

---

## Phase 10 — Production Readiness

**Goal:** Ship-ready app.

### Tasks

1. **Environment config**
   - `--dart-define` for `BASE_URL`, `ENV` (dev/staging/prod)
   - Remove hardcoded `base_url.dart`

2. **Logging & analytics**
   - Add `logger` package for structured logging
   - Firebase Analytics (or equivalent) for screen views, events

3. **Security**
   - Certificate pinning for API calls
   - Obfuscate release builds: `flutter build --obfuscate --split-debug-info`
   - Review token storage encryption

4. **CI/CD**
   - GitHub Actions: lint -> test -> build
   - Fastlane for iOS/Android release

5. **App store assets**
   - Screenshots for 3 languages
   - Store descriptions in UZ/RU/EN

---

## Quick Reference: What to Say Each Session

| Session | Prompt |
|---------|--------|
| Phase 1 | "Implement Phase 1 from ROADMAP.md — core foundation, DI, error handling" |
| Phase 2 | "Implement Phase 2 from ROADMAP.md — menu feature clean architecture" |
| Phase 3 | "Implement Phase 3 from ROADMAP.md — extract cart feature" |
| Phase 4 | "Implement Phase 4 from ROADMAP.md — checkout feature" |
| Phase 5 | "Implement Phase 5 from ROADMAP.md — GoRouter navigation" |
| Phase 6 | "Implement Phase 6 from ROADMAP.md — profile refactor" |
| Phase 7 | "Implement Phase 7 from ROADMAP.md — error handling & UX" |
| Phase 8 | "Implement Phase 8 from ROADMAP.md — performance optimization" |
| Phase 9 | "Implement Phase 9 from ROADMAP.md — testing" |
| Phase 10 | "Implement Phase 10 from ROADMAP.md — production readiness" |

---

## Rules for Every Phase

- **No feature flags or backwards-compat shims** — just change the code
- **No over-engineering** — only build what's needed now
- **const everything** — if a constructor can be const, make it const
- **No magic values** — colors in theme, strings in l10n, numbers as named constants
- **One responsibility per file** — if a file has 2 classes, split it
- **Errors never reach the UI raw** — always map to user-friendly localized message
- **Every provider has clear states** — loading / loaded / error, no ambiguity
