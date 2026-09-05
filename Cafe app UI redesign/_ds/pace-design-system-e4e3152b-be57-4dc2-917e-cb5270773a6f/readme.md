# Pace Design System

The design system for **Pace** — the mobile coffee-ordering app operated by
**Safia** (bundle id `uz.safia.pace`, production host `coffee.safiacorp.uz`).
Pace's promise is a fast pre-order ritual: *"Ready when you arrive."* You pay
ahead, and — if you opt in — the barista starts your drink when you enter the
shop's pickup zone. No queue, no lukewarm wait.

This system captures the app's visual language: a warm cream ground, near-black
ink, a single confident indigo action color, expressive **Clash Display**
headlines over calm **Instrument Sans** UI text, fully-rounded pill buttons with
a colored glow, and soft low-opacity shadows.

> **Brand naming note.** The design export (the visual source of truth) is
> branded **PACE / Pace**. The shipped mobile app renders the operator wordmark
> **"Safia."** (with a citrus dot) in its hero and welcome screens. Both names
> are legitimate and were provided in the sources. Foundation specimens use the
> **Pace** name; the mobile UI-kit recreations preserve the **"Safia."**
> wordmark exactly as the app ships it. Neither name was invented.

---

## Sources (store even if the reader can't open them)

- **Codebase:** `DrinktIT/` monorepo (attached, read-only). Key trees:
  - `apps/mobile` — Expo SDK 57 / React Native 0.86 customer app. Screens under
    `src/app/**`, reusable UI primitives under `src/components/ui/**`.
  - `packages/design-tokens/src/{colors,typography,layout}.ts` — the canonical
    token set, itself extracted verbatim from the design export. **This system's
    token CSS is a faithful port of those files.**
  - `apps/mobile/assets/fonts` — the shipped Clash Display `.otf` files (copied
    into `assets/fonts/`).
  - `apps/mobile/assets/products` — 13 product photographs (copied into
    `assets/products/`).
  - `apps/mobile/src/i18n/en.json` — all product copy (voice source of truth).
- **Design export / prototype:** `DrinktIT/Pace coffee app design/PACE
  Prototype.dc.html` + `pace-data.js` — the interactive prototype the tokens
  were lifted from. Product names, prices, shops and modifiers live in
  `pace-data.js`.
- **Figma screen exports (uploads):** `uploads/Главная*.svg` (Home),
  `uploads/Меню*.svg` (Menu), `uploads/Карточка*.svg` (Product card),
  `uploads/Карта*.svg` (Map / branch picker). Reference only — the code is the
  authoritative source, so these were not traced.

No dedicated logo file exists in any source. Per the brand pattern the wordmark
is set in Clash Display Semibold with a trailing **citrus dot** — see the Brand
specimen cards. Do not fabricate a mark.

---

## CONTENT FUNDAMENTALS

How Pace writes. The voice is **warm, calm, plainspoken and quietly confident** —
a good barista who respects your time, never a hype machine.

- **Person & address.** Second person, "you"/"your". The app speaks as "we"
  (the shop/team): *"we'll start making your drink when you get close,"* *"we'll
  pass it to the team."* First person singular appears only as the user's own
  voice on a control: *"I'll bring my own cup,"* *"I've got it,"* *"I'll wait."*
- **Casing.** Sentence case everywhere — headings, buttons, chips, toasts. No
  Title Case, no ALL CAPS. Buttons read like actions: "Start preparing now,"
  "Back to home," "Pick a time instead."
- **Tone by moment.** Reassuring under uncertainty (*"Your order is safe and
  paid."*), gently celebratory at the finish (*"Enjoy, Ana."*, *"Paid. You're
  set."*, *"That's the pace."*), factual and non-alarming for errors (*"You
  haven't been charged. Try again, or use a different method."*).
- **Punctuation & rhythm.** Short sentences. Em dashes and mid-sentence pauses
  for a conversational beat: *"Pay ahead, and if you like — we'll start making
  your drink when you get close."* Middots (·) separate metadata:
  *"260 cal · 130 mg"*, *"Order 24 · Canal Street."*
- **Numbers & units.** Compact and lowercase: "6–9 min", "130 mg", "±40 m",
  "$5.25", "0.3 mi". Ranges use an en dash. Time as "ready ~7:42".
- **Honesty about tech.** Pace is candid about GPS and payments rather than
  papering over them: *"GPS isn't perfect,"* *"Nothing is made — and no location
  is used — until payment succeeds."* Privacy is stated plainly: *"one zone …
  not your route or history."*
- **Empty & error states have a point of view.** *"No orders yet — your orders
  will land here, receipts included."* Never a bare "No data."
- **Emoji.** Effectively none in UI copy. The single expressive flourish is a
  **check "✓"** ("Recipe saved ✓") and a guest placeholder "☺" avatar glyph.
  Do not add emoji.
- **Signature lines.** "Ready when you arrive" (tagline), "Skip the line, not
  the ritual," "Counter to cup: 3 min. That's the pace."

---

## VISUAL FOUNDATIONS

- **Color.** One warm neutral ground (`--pace-ground #F6F3EC`), near-black ink
  (`--pace-ink #1D1B2C`), and a **single** action color — ultramarine indigo
  (`--pace-action #3D3FE0`). Everything interactive is that indigo or ink;
  there is no second "brand" hue competing with it. A curated set of **muted
  product fields** (citrus, matcha, cream, coffee, lavender/espresso, berry) art-
  directs the catalog — each pairs a soft field with a deep same-hue ink for
  text. Status colors (success green, warning ochre, danger terracotta) are
  desaturated to sit on cream. Max one or two background colors per screen.
- **Type.** Two families. **Clash Display** (Medium/Semibold) for anything
  expressive — greetings, product names, prices in totals, the giant pickup-shelf
  letter. **Instrument Sans** (400–600) for all UI text. Display sizes run large
  (34–64px); UI text is calm (11–17px). Display is never bold-shouty; it leans on
  size and the warm letterforms.
- **Backgrounds.** Mostly flat cream. Full-bleed **photography** appears only in
  two places: the home hero and the welcome screen (a warm, moody coffee image
  under a dark top-and-bottom protection gradient). Product imagery sits on its
  art-directed color field. No repeating patterns, no textures, no decorative
  gradients — gradients are functional only (image protection + a cream "fade to
  footer" behind sticky CTAs).
- **Shape & radii.** Generous, soft corners. Sheets 28px, large cards 22–24px,
  tiles/menu cards 16–20px, inputs 14px. Buttons, chips and status pills are
  **fully rounded** (999px). Nothing has a sharp corner.
- **Cards.** White (`--pace-white`) on cream, radius 20–22px, a single soft
  shadow (`--shadow-card`, `0 1px 2px rgba(29,27,44,.06)`) — no border. Dividers
  inside a card are `--pace-ink-06` hairlines. Selected/emphasis cards use a 2px
  indigo border instead of a shadow bump.
- **Shadows.** Soft, low-opacity, tight radius. Resting cards barely lift
  (6% ink). The two **signature shadows are colored glows**: the primary CTA
  carries an indigo halo (`--shadow-cta`), and the dark active-order pill / toast
  carry an ink halo (`--shadow-pill-dark`). Sheets cast a soft shadow *upward*.
- **Borders.** Hairlines are ink at 6–12% alpha, 1–1.5px. Filter chips use a
  1.5px **dashed** ink-20 border when unselected — the one dashed treatment in
  the system. Steppers' minus button and inputs use 1.5px ink-12/15.
- **Buttons & press states.** Pill buttons scale down on press
  (`--scale-press-cta 0.95`) and release with a slight overshoot
  (`--ease-cta`). Variants: primary (indigo), dark (ink), soft (lavender
  `--pace-action-soft` bg + indigo text), outline (white + hairline), ghost
  (ink-08), text (borderless indigo), danger (terracotta). The primary CTA can
  carry a `glow`.
- **Hover (web).** Native app has no hover; for web recreations use a subtle
  darken (primary → `--pace-action-pressed`) or a slight lift on cards. Keep it
  restrained.
- **Motion.** Content fades up 8px over 300ms. Bottom sheets slide in over 450ms
  on a springy `cubic-bezier(.3,1.18,.35,1)`. Toasts fade-in-up / fade-out-down.
  Selected segment pill slides 180ms. Nothing bounces gratuitously; the only
  overshoot is the CTA press-release and the dialog zoom-in spring.
- **Transparency & blur.** The tab bar is cream at 92% alpha (a soft frost over
  content). Chips over imagery use white-55/75. Scrims behind sheets/dialogs are
  ink at 40–45%.
- **Imagery vibe.** Warm, natural light, shallow depth of field, real coffee on
  ceramic/glass. Product shots are centered on their color field. Nothing is
  black-and-white, cold, or heavily filtered.
- **Layout.** 20px screen gutters. A recurring **sheet-over-hero** motif: a
  cream sheet with 28px top corners pulled up ~28px over a photographic hero.
  Sticky bottom CTAs sit under a cream fade gradient. Two-column menu grid,
  horizontally-snapping hero carousel.
- **Iconography.** See below.

---

## ICONOGRAPHY

- **Approach.** A small, **bespoke line-icon set**, hand-traced from the design
  and shipped as inline SVG in `apps/mobile/src/components/ui/icons.tsx`. There
  is **no icon font and no third-party icon library** in the product.
- **Style.** Rounded-cap, rounded-join strokes; nav/action icons are
  **1.9–2px** stroke on a 24px grid; small chevrons/close/plus are 1.6–2px on
  tighter viewboxes. Mostly outline; the heart fills on the favorite state; the
  Menu glyph is a 2×2 dot cluster (filled circles). The tab set is Home, Menu
  (dots), Orders, Profile.
- **In this system.** The exact SVG paths are reproduced in the **`Icon`**
  component (`components/core/Icon.jsx`) so recreations use the real glyphs, not
  substitutes. Sizes/colors are props. **Do not** substitute Lucide/Heroicons —
  the shapes are specific to Pace.
- **Non-icon glyphs.** Unicode is used sparingly for a few marks: the minus/plus
  in steppers (− / +), a check "✓" on save confirmations, middots "·" as
  metadata separators, and a "☺" guest-avatar placeholder. No emoji.

---

## Index / manifest

Root files:

- `styles.css` — global entry point (import this one file). `@import`s all of
  `tokens/`.
- `tokens/` — `fonts.css`, `colors.css`, `typography.css`, `spacing.css`,
  `radii.css`, `shadows.css`, `motion.css`.
- `assets/fonts/` — Clash Display `.otf` (Medium / Semibold / Bold) + license.
- `assets/products/` — 13 product photographs (`maple.jpg`, `matchacloud.jpg`,
  … `hero.jpg`).
- `thumbnail.html` — homepage tile.
- `SKILL.md` — Agent-Skills-compatible entry point.

Components (`components/`, `window.PaceDesignSystem_e4e315.*`):

- `core/` — `Button`, `Text`, `Chip`, `SegmentedControl`, `Stepper`, `Icon`,
  `Input`.
- `feedback/` — `Banner`, `Toast`, `Dialog`, `Skeleton`.
- `surfaces/` — `Card`, `Sheet`.

UI kits (`ui_kits/`):

- `pace-app/` — the Pace mobile app: Home, Menu, Product detail, Cart, Order
  tracking, with an interactive click-through `index.html`.

Guidelines specimen cards live beside the tokens and components and populate the
**Design System** tab (groups: Brand, Colors, Type, Spacing, Components,
Pace App).

### Intentional additions

- **`Input`** — the app uses raw React Native `TextInput` with one consistent
  treatment (1.5px `--border-control` border, 14px radius, Instrument Sans
  Medium, `--pace-ink-45` placeholder). Promoted to a small component so
  recreations share it; behavior/markup mirror the app's inline styling exactly.
- **`Card`** — the white-card-on-cream pattern is used verbatim across every
  screen but is authored inline in the app. Extracted as a thin primitive
  (radius + `--shadow-card`, optional `selected` indigo border) for reuse.
- **`Icon`** — a wrapper exposing the app's real inline-SVG glyph set by name.

### Font substitution

**Instrument Sans** is loaded from Google Fonts (the app bundles it via
`@expo-google-fonts`; no `.otf` was in the asset tree to copy). **Clash Display**
`.otf` files are the real shipped binaries. If you have the licensed Instrument
Sans web files, drop them in `assets/fonts/` and swap the `@import` in
`tokens/fonts.css` for `@font-face` rules.
