# State Management — Riverpod Patterns

The goal of every pattern here is the same: **a change in one piece of data should rebuild the smallest possible number of widgets.** That's what makes modules "update independently without refreshing the major UI," and it's also most of what makes the app fast — those are the same problem solved the same way.

## Provider shapes, by use case

- **A single async fetch (screen data, a detail page):** `FutureProvider`/`AsyncNotifierProvider` returning `AsyncValue<T>`.
- **Paginated/infinite list:** a dedicated `AsyncNotifier<List<T>>` (or a small custom notifier) that exposes `loadNextPage()`, tracks `hasMore`, and appends rather than replaces — see `performance.md` for the widget side.
- **Form/local UI state (filters, quantity selector, toggle):** `NotifierProvider` holding a small immutable state class, scoped to the widget subtree that needs it, not global.
- **Derived/computed values (e.g. cart total from cart items):** a plain `Provider` that watches the source provider — never recompute derived values inside `build()`.
- **Cross-feature shared state (auth session, cart):** lives in `core/` or a clearly-owned feature, exposed via a `Provider`/`NotifierProvider` other features are allowed to `ref.watch` — this is the one legitimate way features are allowed to depend on each other.

## Scoping rules that prevent cascading rebuilds

1. **Watch the narrowest thing possible.** Prefer `ref.watch(productProvider.select((p) => p.price))` over watching the whole `Product` object in a widget that only renders the price.
2. **Split one big screen notifier into several small ones** rather than one `HomeScreenState` object with 15 fields where changing one field rebuilds everything watching the notifier. If two pieces of state change independently, they belong in independent providers.
3. **Push `Consumer`/`ConsumerWidget` down to the smallest widget that actually needs the data**, not at the top of the screen. A screen's outer `Scaffold`/`AppBar` almost never needs to rebuild when list data changes — wrap only the part that does in a `Consumer`.
4. **Use `family` for per-item state** (e.g. "is this specific product favorited") instead of one provider holding a map/list for every item on screen — that way toggling item #47 doesn't touch the widget for item #1.
5. **Keep providers close to where they're used.** Feature-scoped providers live in that feature's `application/` folder. Only promote to `core/` when a second feature genuinely needs it (see `folder-structure.md`).

## Standard async UI pattern

Every screen backed by a `FutureProvider`/`AsyncNotifierProvider` renders its `AsyncValue` the same way, via a shared helper so the loading/error/empty look and feel is consistent everywhere (put this in `core/widgets/` — see `ui-components.md` for the widget itself):

```dart
final productsAsync = ref.watch(productListProvider);

return productsAsync.when(
  data: (products) => products.isEmpty
      ? const EmptyStateView(message: 'No products yet')
      : ProductGrid(products: products),
  loading: () => const LoadingShimmer(),
  error: (error, stackTrace) => ErrorStateView(
    // map the raw error to a Failure/user-facing message — see error-handling.md
    onRetry: () => ref.invalidate(productListProvider),
  ),
);
```

Note what this buys you: a failed request never leaves the screen half-built or throws past the widget tree — it renders `ErrorStateView` with a retry action, every single time, for every feature, because it's the same pattern everywhere.

## What NOT to do

- Don't call `ref.read` inside `build()` to "get the current value" — that skips rebuilds when it changes. Use `ref.watch` in `build()`; reserve `ref.read` for inside callbacks (button `onPressed`, etc.).
- Don't put `Dio`/repository calls directly inside a `Notifier`'s constructor logic without going through the repository interface — the notifier depends on the domain `Repository` interface, never on `data/` classes directly.
- Don't create a provider inside `build()` (e.g. `Provider((ref) => ...)` defined locally) — providers are always top-level `final` declarations so Riverpod can track and dispose them correctly.
- Don't use `ChangeNotifier`/`setState` for anything that represents shared or async state — reserve local `setState` for truly ephemeral, single-widget UI state (e.g. a `PageView` index) that no other widget needs.
