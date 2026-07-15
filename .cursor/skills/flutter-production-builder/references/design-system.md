# Design System — Typography, Color, Spacing, Radius, Shadows, Motion, Assets

This is the "single source of truth" layer referenced throughout `ui-components.md`. Read this before creating or touching anything in `core/theme/` or `assets/`, or before hardcoding any visual value in a widget.

## Typography hierarchy

Every text style in the app comes from `core/theme/app_typography.dart`, never an inline `TextStyle(fontSize: 14)`. Use Material 3's standard hierarchy — six tiers, each with clear semantic purpose — and let widgets pick a role, not a raw size:

```dart
class AppTypography {
  const AppTypography._();
  static const display  = TextStyle(fontSize: 32, fontWeight: FontWeight.w700, height: 1.2);
  static const headline = TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.25);
  static const title    = TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.3);
  static const body     = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5);
  static const label    = TextStyle(fontSize: 13, fontWeight: FontWeight.w500, height: 1.4);
  static const caption  = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.4);
}
```

- **Display/Headline**: hero/section titles, empty-state headers, onboarding.
- **Title**: screen titles, card headers, dialog titles.
- **Body**: primary readable content — product descriptions, chat messages.
- **Label**: buttons, form field labels, chips.
- **Caption**: timestamps, helper text, metadata (price-per-unit, review counts).

Wire these into `ThemeData.textTheme` in `app_theme.dart` so `Theme.of(context).textTheme.titleLarge` also resolves correctly for any third-party widget that reads Material's default text theme — don't maintain two disconnected typography systems.

Respect the platform's text scale factor (`MediaQuery.textScalerOf(context)`) rather than disabling it — this is both a typography and an accessibility requirement (see `responsiveness-accessibility.md`).

## Color system

`core/theme/app_colors.dart` defines the raw palette once; both light and dark themes are built from it, never hand-duplicated:

```dart
class AppColors {
  const AppColors._();
  static const primary = Color(0xFF1A73E8);
  static const secondary = Color(0xFF34A853);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceDark = Color(0xFF121212);
  static const error = Color(0xFFD32F2F);
  static const success = Color(0xFF2E7D32);
  static const warning = Color(0xFFF9A825);
  // textPrimary/textSecondary defined per-brightness, not as one flat pair
}
```

`app_theme.dart` exposes `AppTheme.light` and `AppTheme.dark`, both built as proper Material 3 `ThemeData` (via `ColorScheme.fromSeed` or an explicit `ColorScheme`, not a patched-together Material 2 theme). `MaterialApp.router` wires `theme`, `darkTheme`, and `themeMode` — every screen must be checked in both light and dark, not just designed for one and hoped to work in the other. A widget that hardcodes `Colors.white` as a background will visibly break in dark mode; use `Theme.of(context).colorScheme.surface` instead.

Use `ThemeExtension` for any custom semantic color that Material's default `ColorScheme` doesn't cover (e.g. a "discount"/"verified" color for a marketplace, an "online"/"typing" color for a chat app, a "confirmed"/"pending" color for a booking app) rather than bolting extra static constants onto `AppColors` that don't flow through `Theme.of(context)`.

## Spacing, radius, and elevation constants

`core/theme/app_spacing.dart` — one numeric scale, used everywhere, never a raw number typed inline in a widget:

```dart
class AppSpacing {
  const AppSpacing._();
  // Spacing scale
  static const s4 = 4.0, s8 = 8.0, s12 = 12.0, s16 = 16.0, s20 = 20.0;
  static const s24 = 24.0, s32 = 32.0, s40 = 40.0, s48 = 48.0, s64 = 64.0;

  // Radius scale
  static const r8 = 8.0, r12 = 12.0, r16 = 16.0, r20 = 20.0, r24 = 24.0, r32 = 32.0;
}
```

Elevation/shadow presets live alongside it (`AppShadows.card`, `AppShadows.modal`, `AppShadows.none`) as reusable `List<BoxShadow>` constants, so "card elevation" looks identical whether it's a product card, an order card, or a seller card. Don't invent a one-off shadow value per widget.

A number like `16` or `24` typed directly into a widget's `padding:`/`SizedBox(height: ...)`/`BorderRadius.circular(...)` instead of `AppSpacing.s16` is the spacing-system equivalent of a hardcoded color — flag it in review the same way.

## Motion / animation

Animations should feel premium but never gratuitous — motion earns its place only where it clarifies what changed (a state transition, a new item appearing, a value updating), not decoration for its own sake.

`core/theme/app_durations.dart` — centralize timing so every animation in the app feels like it belongs to the same system:

```dart
class AppDurations {
  const AppDurations._();
  static const fast = Duration(milliseconds: 150);   // button press, ripple
  static const medium = Duration(milliseconds: 250);  // card expansion, fade
  static const slow = Duration(milliseconds: 400);    // page transition, bottom sheet
}
```

Where animation is appropriate in a production app:
- **Page transitions** — use `go_router`'s built-in transition support rather than hand-rolled `PageRouteBuilder`s per screen, so navigation feels consistent app-wide.
- **Button press feedback** — Material's built-in ripple/ink response is usually enough; don't fight it with a custom scale animation unless the design explicitly calls for it.
- **List item appearance** — a subtle fade/slide-in as items load is fine; never animate every rebuild (that reads as jank, not polish) — trigger it once on first insert (e.g. keyed by item id) not on every parent rebuild.
- **Bottom sheets/dialogs** — rely on the platform's built-in modal transition rather than replacing it.
- **Loading → content** — `AnimatedSwitcher` between a `LoadingShimmer` and real content reads better than an abrupt swap.

Prefer **implicit** animations (`AnimatedContainer`, `AnimatedOpacity`, `AnimatedSwitcher`, `AnimatedSize`) over explicit `AnimationController` plumbing whenever the effect is simple — controllers are for genuinely custom, multi-stage, or interruptible animations (e.g. a custom Hero-like product image transition). Every custom `AnimationController` **must** be disposed in `dispose()` — an undisposed controller is a memory leak that gets worse as the user browses more screens.

Target 60 FPS: profile with DevTools if an animation feels janky rather than guessing. Avoid animating properties that force layout (`width`/`height` changes on a widget with heavy children) when a `Transform`/`Opacity`-based equivalent achieves the same visual result more cheaply.

## Icons

Pick one icon family for the whole app (Material Symbols, or a custom SVG icon set matching the design) and stick to it — mixing Material icons with a different-style custom set in the same screen is a visual-consistency bug, not a minor detail. If the design (Figma/Stitch) uses a custom icon set, import those as SVGs (see `performance.md` for `flutter_svg` usage) rather than approximating with the closest built-in Material icon.

## Asset organization

```
assets/
├── images/          # raster photos/illustrations (PNG/JPG/WebP)
├── icons/            # SVG icon set
├── animations/       # Lottie JSON files
├── fonts/            # custom font files, registered in pubspec.yaml
└── illustrations/     # empty-state / onboarding illustrations (SVG or PNG)
```

Reference assets through a generated or hand-maintained `AppAssets` class (string path constants) rather than typing raw string paths inline in widgets — a typo'd inline path fails silently at runtime with no compile-time warning, while a typo'd `AppAssets.emptyCartIllustration` fails to compile.

## Naming conventions (visual/design-system layer)

Same conventions as the rest of the codebase (see `folder-structure.md`), applied to design-system files specifically:
- Token classes: `PascalCase` (`AppColors`, `AppSpacing`, `AppTypography`, `AppDurations`, `AppShadows`).
- Constants inside them: `camelCase`, named by role not raw value where the role is stable (`primary`, `s16`, `radiusMd`) — a value-only name (`sixteen`) breaks if the underlying number ever needs to change.
- Files: `snake_case.dart` (`app_colors.dart`, `app_typography.dart`).
