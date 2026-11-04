import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/diamond_list_provider.dart';
import '../../application/diamond_search_provider.dart';
import '../../domain/models/diamond_catalog_type.dart';
import '../../domain/models/sorting_criteria.dart';

/// Isolates lab-grown search/list/sort state from the natural diamond catalog.
class LabGrownDiamondScope extends StatelessWidget {
  const LabGrownDiamondScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        diamondCatalogTypeProvider.overrideWithValue(
          DiamondCatalogType.labGrown,
        ),
        diamondSearchProvider.overrideWith(DiamondSearchNotifier.new),
        // Derived providers must be re-scoped alongside what they watch,
        // otherwise Riverpod throws when they resolve across containers.
        matchingCountProvider.overrideWith(computeMatchingCount),
        diamondListProvider.overrideWith(DiamondListNotifier.new),
        diamondViewModeProvider.overrideWith((ref) => ViewMode.grid),
        diamondSortingProvider.overrideWith((ref) => <SortingCriteria>[]),
      ],
      child: child,
    );
  }
}
