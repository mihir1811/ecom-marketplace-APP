import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../diamonds/data/mappers/diamond_search_request_mapper.dart';
import '../../diamonds/data/mappers/seller_diamond_project_search_mapper.dart';
import '../../diamonds/domain/models/diamond.dart';
import '../../diamonds/domain/models/diamond_catalog_type.dart';
import '../../diamonds/domain/models/diamond_filter_state.dart';
import '../data/mappers/diamond_project_mapper.dart';
import '../domain/diamond_project_stats_calculator.dart';
import '../domain/models/diamond_project.dart';
import '../domain/models/diamond_project_item.dart';
import '../domain/models/diamond_project_stats.dart';

/// In-memory selection for the current diamond project (no network).
class DiamondProjectSelection {
  const DiamondProjectSelection({
    this.projectId,
    this.name = '',
    this.diamondType = 'NATURAL',
    this.filters = const {},
    this.items = const [],
  });

  final String? projectId;
  final String name;
  final String diamondType;
  final Map<String, dynamic> filters;
  final List<DiamondProjectItem> items;

  bool get isEmpty => items.isEmpty;

  DiamondProjectSelection copyWith({
    String? projectId,
    String? name,
    String? diamondType,
    Map<String, dynamic>? filters,
    List<DiamondProjectItem>? items,
    bool clearProjectId = false,
  }) {
    return DiamondProjectSelection(
      projectId: clearProjectId ? null : (projectId ?? this.projectId),
      name: name ?? this.name,
      diamondType: diamondType ?? this.diamondType,
      filters: filters ?? this.filters,
      items: items ?? this.items,
    );
  }
}

class DiamondProjectSelectionNotifier
    extends Notifier<DiamondProjectSelection> {
  @override
  DiamondProjectSelection build() => const DiamondProjectSelection();

  /// Replaces the selection with seller-dashboard inventory results.
  void selectInventory({
    required List<DiamondProjectItem> items,
    required DiamondFilterState filters,
    String? sellerId,
    String? name,
  }) {
    final body =
        SellerDiamondProjectSearchMapper.toBody(
            sellerId: sellerId ?? '',
            filters: filters,
            page: 1,
          )
          ..remove('page')
          ..remove('limit');
    if (sellerId == null || sellerId.isEmpty) {
      body.remove('seller_id');
    }

    state = DiamondProjectSelection(
      name: name ?? _defaultName(),
      diamondType: 'NATURAL',
      filters: body,
      items: List<DiamondProjectItem>.unmodifiable(items),
    );
  }

  /// Replaces the selection with diamonds already loaded in the listing.
  void selectLoadedPage({
    required List<Diamond> diamonds,
    required DiamondFilterState filters,
    required DiamondCatalogType catalog,
  }) {
    final isLab = catalog.isLabGrown;
    final isMelee = isLab
        ? filters.labCategory == 'Lab Melee'
        : filters.labNatural.usesMeleeFilters;
    final kind = isMelee ? 'MELEE' : 'SINGLE';
    final body = DiamondSearchRequestMapper.toBody(
      filters: filters,
      catalog: catalog,
      page: 1,
    );
    body.remove('page');
    body.remove('limit');
    body.remove('sort_by');

    final seen = <String>{};
    final items = <DiamondProjectItem>[];
    for (final diamond in diamonds) {
      if (diamond.id.isEmpty || !seen.add(diamond.id)) continue;
      items.add(DiamondProjectMapper.fromDiamond(diamond, productKind: kind));
    }

    state = DiamondProjectSelection(
      name: _defaultName(),
      diamondType: isLab ? 'LAB' : 'NATURAL',
      filters: body,
      items: items,
    );
  }

  void hydrate(DiamondProject project) {
    state = DiamondProjectSelection(
      projectId: project.id,
      name: project.name,
      diamondType: project.diamondType ?? 'NATURAL',
      filters: project.filters,
      items: project.items,
    );
  }

  void removeItem(String diamondId) {
    state = state.copyWith(
      items: [
        for (final item in state.items)
          if (item.diamondId != diamondId) item,
      ],
    );
  }

  void rename(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    state = state.copyWith(name: trimmed);
  }

  void markSaved(DiamondProject project) {
    state = state.copyWith(projectId: project.id, name: project.name);
  }

  void clear() {
    state = const DiamondProjectSelection();
  }

  static String _defaultName() {
    final stamp = DateTime.now().millisecondsSinceEpoch.toString();
    return 'Diamond_Selection_${stamp.substring(stamp.length - 5)}';
  }
}

final diamondProjectSelectionProvider =
    NotifierProvider<DiamondProjectSelectionNotifier, DiamondProjectSelection>(
      DiamondProjectSelectionNotifier.new,
    );

/// Derived local analytics — never hits the network.
final diamondProjectStatsProvider = Provider<DiamondProjectStats>((ref) {
  final items = ref.watch(
    diamondProjectSelectionProvider.select((s) => s.items),
  );
  return DiamondProjectStatsCalculator.compute(items);
});
