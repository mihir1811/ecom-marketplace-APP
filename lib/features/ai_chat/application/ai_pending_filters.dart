import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../diamonds/domain/models/diamond_filter_state.dart';

/// Holds filters to apply once a diamond listings screen mounts
/// (needed for lab-grown scope which creates a fresh search notifier).
final aiPendingDiamondFiltersProvider = StateProvider<AiPendingDiamondFilters?>(
  (ref) => null,
);

/// When set, listing back from this route returns home and reopens Gem AI.
final aiResumeChatFromRouteProvider = StateProvider<String?>((ref) => null);

class AiPendingDiamondFilters {
  const AiPendingDiamondFilters({
    required this.filters,
    required this.isLabGrown,
  });

  final DiamondFilterState filters;
  final bool isLabGrown;
}
