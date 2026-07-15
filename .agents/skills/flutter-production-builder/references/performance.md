# Performance — Fast Rendering Under Real-World Data Volumes

The frontend doesn't need to "handle high traffic" the way a backend does — it needs to handle **large and frequently-changing datasets without janking**, and never hold the whole dataset's worth of widgets in memory or rebuild more than necessary. Every rule here serves that, regardless of what the data actually is (products, posts, messages, bookings, transactions, notifications).

## Lists — always virtualized, always paginated

**Never** render a list with `Column(children: items.map(...).toList())` or inside a `SingleChildScrollView` once the list can grow past a screenful (products, orders, reviews, chat messages, posts, bookings, notifications). That builds every single item's widget tree immediately, even off-screen ones — it's the single biggest performance mistake in a data-heavy Flutter app.

**Always** use one of:
- `ListView.builder` — builds items lazily as they scroll into view.
- `SliverList.builder`/`SliverGrid` inside a `CustomScrollView` — when you need the list to coexist with other scrolling content (a header, filter bar, banner) in one smooth scroll.
- `GridView.builder` — for product grids.

### Pagination pattern (infinite scroll)

Wrap this once as `core/widgets/paginated_list_view.dart` and reuse it for every paginated feature instead of reimplementing scroll-position listening per screen:

```dart
class PaginatedListView<T> extends ConsumerStatefulWidget {
  const PaginatedListView({
    required this.items,
    required this.itemBuilder,
    required this.onLoadMore,
    required this.hasMore,
    required this.isLoadingMore,
    super.key,
  });
  final List<T> items;
  final Widget Function(BuildContext, T) itemBuilder;
  final VoidCallback onLoadMore;
  final bool hasMore;
  final bool isLoadingMore;

  @override
  ConsumerState<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends ConsumerState<PaginatedListView<T>> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final nearBottom = _controller.position.pixels >
          _controller.position.maxScrollExtent - 300;
      if (nearBottom && widget.hasMore && !widget.isLoadingMore) {
        widget.onLoadMore();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _controller,
      itemCount: widget.items.length + (widget.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= widget.items.length) return const LoadingShimmer(compact: true);
        return widget.itemBuilder(context, widget.items[index]);
      },
    );
  }
}
```

The `hasMore`/`isLoadingMore` flags and `onLoadMore()` callback come from the feature's `AsyncNotifier` (see `state-management.md`), which appends the next page to its held list rather than replacing it — and guards against firing a second request while one is already in flight.

### List item performance checklist

- `const` constructors on item widgets wherever possible.
- Stable `Key` per item (`ValueKey(item.id)`) so Flutter's diffing doesn't rebuild-and-discard everything on a list update.
- `itemExtent`/`prototypeItem` on `ListView.builder` when items are a fixed height — lets Flutter skip measuring every item and jump-scroll accurately.
- Images inside list items always go through `cached_network_image` (see below) — never `Image.network` directly in a list.

## Images

- Always `cached_network_image`, never bare `Image.network`, in anything that scrolls — it caches to disk, avoids re-downloading on every rebuild/scroll-back, and gives a built-in placeholder/error widget slot (use the shared `CachedNetworkImageWithPlaceholder` from `ui-components.md`). This covers remote PNG/JPG/WebP.
- **SVG** (icons, illustrations from `assets/icons/` or `assets/illustrations/`): use `flutter_svg`'s `SvgPicture` rather than rasterizing at design time — it stays crisp across densities and is usually much smaller than an equivalent PNG.
- **Lottie** (onboarding/empty-state/success micro-animations from `assets/animations/`): use the `lottie` package's `Lottie.asset`/`Lottie.network`. Keep these to the moments called out in `design-system.md`'s motion section — a Lottie animation is expensive relative to a static illustration, so don't default to one where a static image communicates the same thing.
- Request appropriately-sized images from the backend/CDN where possible (thumbnail vs full-size) rather than downloading full-resolution images for a small product-card thumbnail.
- Set explicit `width`/`height`/`memCacheWidth` so Flutter doesn't decode a huge image at full resolution just to display it small.
- Always constrain images with `AspectRatio`/`BoxFit` rather than letting them dictate layout size — an image that loads after its container has already rendered at the wrong size causes a visible layout shift; reserve the space up front.

## Avoiding unnecessary work

- **Search/filter inputs**: debounce (300–400ms) before triggering a provider refresh or API call — see `api-layer.md`.
- **Heavy computation** (client-side sorting/filtering of a large already-fetched list, JSON parsing of a large payload): move off the main isolate with `compute()` if it's large enough to cause a visible frame drop; profile before assuming it's needed.
- **Avoid `Opacity`** for simple show/hide of static content — prefer conditionally not building the widget, or `Visibility`, since `Opacity` forces a full repaint of its subtree every frame it's used in an animation.
- **Don't recompute derived data in `build()`** (e.g. sorting/filtering a list inline in a widget's `build()` method) — do it in a `Provider` that only recomputes when its inputs actually change, so an unrelated rebuild doesn't re-run an O(n log n) sort every frame.

## How to sanity-check a feature performs well

Before marking a feature done (see `definition-of-done.md`): run it with a realistically large dataset (100+ items, not the 3 items in a happy-path mock), scroll fast, and confirm no visible jank. In debug mode, Flutter's performance overlay (or DevTools' "Rebuild counts") should show list items building lazily as they scroll into view, not all at once.
