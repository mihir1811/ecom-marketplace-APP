# UI Components — Reusable, Overflow-Safe, Consistently Themed

## Widget defaults and size limits

- **Default to `StatelessWidget`.** Only reach for `StatefulWidget` when the widget genuinely owns local, ephemeral UI state that a provider shouldn't (an `AnimationController`, a `TextEditingController`/`FocusNode`, a `ScrollController`, transient expand/collapse toggle state). Data that other widgets care about, or that survives navigation, belongs in Riverpod (`state-management.md`) — not `setState`.
- **Keep widgets small.** A single widget file should stay around ≈200 lines; a screen file (the top-level `Scaffold` for a route) around ≈300 lines. When a widget/screen grows past that, it's a signal to extract a child widget — this is the same DRY/SRP pressure that drives the reusable-component list below, applied continuously rather than only when something is literally duplicated.
- **Avoid deep nesting.** More than ~4–5 levels of nested `Row`/`Column`/`Padding`/`Container` inside one `build()` is a readability and perf smell — extract inner sections into their own small widgets instead of one long nested tree.

## Pixel-perfect matching

When the user provides a design reference (Stitch, Figma, a screenshot), match it exactly, not approximately — spacing, alignment, typography scale, icon size, padding, margins, corner radius, elevation, color, shadows, opacity, and borders should all trace back to a specific value in the design, resolved through the design tokens in `design-system.md` (pick the closest token, or add a new token if the design consistently uses a value outside the current scale — don't silently round to "close enough"). If a design value doesn't cleanly map to an existing token and doesn't look like a one-off, flag it to the user rather than quietly expanding the token set on your own judgment.

## Design tokens — the single source of truth

Nothing in a feature widget hardcodes a color, font size, spacing value, or radius. Everything comes from `core/theme/`:

```dart
// core/theme/app_colors.dart
class AppColors {
  const AppColors._();
  static const primary = Color(0xFF1A73E8);
  static const surface = Color(0xFFFFFFFF);
  static const error = Color(0xFFD32F2F);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF6B6B6B);
  // ...
}

// core/theme/app_spacing.dart
class AppSpacing {
  const AppSpacing._();
  static const xs = 4.0, sm = 8.0, md = 16.0, lg = 24.0, xl = 32.0;
  static const radiusSm = 8.0, radiusMd = 12.0, radiusLg = 16.0;
}
```

`app_theme.dart` assembles a single `ThemeData` (colors, `textTheme`, `elevatedButtonTheme`, `inputDecorationTheme`, etc.) from these tokens, and `MaterialApp.router` uses only that. A widget reaching for `Colors.blue` or `fontSize: 14` directly instead of `Theme.of(context)`/`AppColors`/`AppTypography` is a bug, not a style preference — it's what makes 40 independently-built modules look like one designed app instead of a patchwork.

If the user has an existing design system (Figma tokens, an existing `AppTheme`), use that instead of inventing a new one — ask if unsure rather than creating a second, competing token set.

## Reusable widget library (`core/widgets/`)

Before writing a new widget, check whether one of these already covers it. Typical set to build once and reuse everywhere, regardless of app domain:

- `AppButton` (primary/secondary/text variants, loading state built in — so every async button shows a spinner the same way instead of each screen inventing its own)
- `AppTextField` (consistent error/label/helper text styling)
- `LoadingShimmer` — skeleton loading, not a bare `CircularProgressIndicator`, for anything list/card-shaped
- `ErrorStateView` — icon + message + retry button, used by every `.when(error: ...)` branch
- `EmptyStateView` — illustration (see `design-system.md` asset organization), a meaningful message (not a generic "No data"), and space for a primary action (e.g. "Browse products") plus an optional secondary action (e.g. "Clear filters") — used for legitimate zero-results states like an empty cart, no search results, or no orders yet
- `PaginatedListView<T>` — wraps the infinite-scroll pattern from `performance.md` so no feature reimplements pagination scrolling logic
- Small domain-specific atoms reused across cards/rows/tiles — e.g. `PriceTag`/`RatingChip` for a marketplace, `MessageBubble`/`OnlineDot` for a chat app, `StatusBadge` for a booking or order-tracking app. Whatever the domain's recurring visual atom is, build it once in `core/widgets/` and reuse it everywhere that data type appears.
- `CachedNetworkImageWithPlaceholder` — thin wrapper around `cached_network_image` with the app's standard placeholder/error asset baked in

A widget only gets promoted here once it's actually needed by a second feature — see `folder-structure.md`. Guessing ahead of time leads to a bloated shared library nobody trusts.

## Overflow safety — non-negotiable rules

Real-world data is unpredictable in length (long titles, names, prices with different currency formats, message text, addresses — whatever the domain's content is). Every layout must assume the worst-case string length, not the string in your test data.

1. **Every `Text` in a `Row`/constrained width gets wrapped**: `Expanded`/`Flexible` around the `Text`, plus `overflow: TextOverflow.ellipsis` and usually `maxLines`. A bare `Text(longString)` directly inside a `Row` is the #1 cause of yellow-and-black overflow bars — never ship one.
2. **Never give a `Row`/`Column` children whose combined intrinsic size can exceed the available space without a `Flexible`/`Expanded` somewhere** — if in doubt, wrap it.
3. **Use `Wrap` instead of `Row`** for things like tag/chip lists whose count varies (categories, filters) — a `Row` of an unbounded number of chips will overflow; `Wrap` degrades gracefully.
4. **Avoid fixed pixel heights on anything containing text** (e.g. a card with `height: 80` and a title inside) — let content determine height, or use `ConstrainedBox`/`minHeight` instead of a hard `height` when a minimum is needed.
5. **Grids of cards**: use `GridView.builder` with `childAspectRatio` tuned generously, or better, a `SliverGrid` with a fixed cross-axis extent and let card height be intrinsic via `mainAxisExtent` — a too-tight `childAspectRatio` is the second most common overflow source in product grids.
6. **Test against real worst cases mentally**: the longest realistic title/name in the app's domain, a name in a language with different average character width, a number with more digits than your sample data (₹1,23,456 vs $9.99, or a large unread-count badge), a small phone width (~320dp) — a layout that only survives your one sample string isn't done.
7. **`SafeArea`** wraps every top-level screen so content never sits under a notch/status bar/gesture nav.

## Performance-conscious widget habits (also see `performance.md`)

- Mark widgets `const` wherever every field is a compile-time constant — this is the single cheapest performance habit and costs nothing to apply consistently.
- Give list items stable `Key`s (e.g. `ValueKey(product.id)`) so Flutter can diff efficiently instead of rebuilding every item on any list change.
- Avoid rebuilding an entire screen for a small state change — this is a `state-management.md` concern as much as a widget one; split widgets so `Consumer`s wrap only the part that actually changes.
- Wrap independently-animating or independently-repainting subtrees (e.g. a shimmer loader next to static content) in `RepaintBoundary` so their repaints don't force siblings to repaint too.
