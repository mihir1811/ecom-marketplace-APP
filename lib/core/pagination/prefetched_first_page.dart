import 'paginated_async_notifier.dart';

/// One-shot first page fetched outside its list screen (e.g. by Gem Agent),
/// so the screen can show it without refetching.
///
/// Served once, and only while the screen's filters are still the exact
/// snapshot ([identical]) the page was fetched with.
class PrefetchedFirstPage<F, T> {
  PrefetchedFirstPage({
    required this.filters,
    required PaginatedPage<T> this._page,
  });

  final F filters;
  PaginatedPage<T>? _page;

  PaginatedPage<T>? take(F current) {
    if (!identical(current, filters)) return null;
    final page = _page;
    _page = null;
    return page;
  }
}
