import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../domain/models/diamond.dart';
import '../domain/models/diamond_catalog_type.dart';
import '../domain/models/diamond_filter_state.dart';
import 'diamond_list_provider.dart';
import 'diamond_search_provider.dart';

/// One-shot hand-off of a first results page fetched outside the finder
/// (e.g. by Gem Agent), so the results screen shows it without refetching.
///
/// Filters and the page are each claimed once; the page is only served for
/// the exact filter snapshot it was fetched with.
class DiamondResultsHandoff {
  DiamondResultsHandoff({
    required this.catalog,
    required this.filters,
    required DiamondListResponse this._firstPage,
  });

  final DiamondCatalogType catalog;
  final DiamondFilterState filters;
  DiamondListResponse? _firstPage;
  bool _filtersClaimed = false;

  /// Filters for a search notifier of [forCatalog], once.
  DiamondFilterState? claimFilters(DiamondCatalogType forCatalog) {
    if (_filtersClaimed || forCatalog != catalog) return null;
    _filtersClaimed = true;
    return filters;
  }

  /// The prefetched page when [current] is still the hand-off snapshot, once.
  DiamondListResponse? takeFirstPage(
    DiamondCatalogType forCatalog,
    DiamondFilterState current,
  ) {
    if (forCatalog != catalog || !identical(current, filters)) return null;
    final page = _firstPage;
    _firstPage = null;
    return page;
  }
}

/// Latest published hand-off. Never overridden by catalog scopes.
final diamondResultsHandoffProvider = StateProvider<DiamondResultsHandoff?>(
  (ref) => null,
);

/// Publishes [handoff] and primes the app-wide natural catalog state.
///
/// Lab-grown state lives in a route-scoped container, so it claims the
/// filters itself when the scope (or its results screen) mounts.
void publishDiamondResultsHandoff(Ref ref, DiamondResultsHandoff handoff) {
  ref.read(diamondResultsHandoffProvider.notifier).state = handoff;
  if (handoff.catalog != DiamondCatalogType.natural) return;
  final filters = handoff.claimFilters(DiamondCatalogType.natural);
  if (filters == null) return;
  ref.read(diamondSearchProvider.notifier).replaceFilters(filters);
  ref.read(diamondSortingProvider.notifier).state = const [];
  ref.invalidate(diamondListProvider);
}
