import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Distinguishes natural vs lab-grown diamond catalogs.
/// Separate from [LabNaturalType], which only toggles melee filters on the natural screen.
enum DiamondCatalogType {
  natural('Natural Diamond'),
  labGrown('Lab Grown Diamond');

  final String label;
  const DiamondCatalogType(this.label);

  bool get isLabGrown => this == DiamondCatalogType.labGrown;
}

/// Active catalog for the current diamond finder scope.
/// Overridden under the lab-grown shell route so search/list share isolated state.
final diamondCatalogTypeProvider = Provider<DiamondCatalogType>(
  (ref) => DiamondCatalogType.natural,
);
