import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_scope.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../../core/widgets/luxe/luxe_layout.dart';
import '../../../../core/widgets/luxe/luxe_listing.dart';
import '../../../../core/widgets/luxe/luxe_toggle_sort_sheet.dart';
import '../../../../core/widgets/navigation/top_bar/top_bar_actions.dart';
import '../../../jewelry_checkout/presentation/jewelry_checkout_format.dart';
import '../../../product_detail/product_detail_navigation.dart';
import '../../application/jewelry_premium_providers.dart';
import '../../domain/models/jewelry_filter_state.dart';
import '../widgets/jewelry_filter_labels.dart';
import '../widgets/jewelry_luxe_cards.dart';

/// Premium: published pieces whose starting price reaches the amount
/// GemWorld sets in ohana-admin (read on every load, never hard-coded).
/// Category tabs appear with two or more categories; three sorts, newest
/// first by default.
class JewelryPremiumScreen extends ConsumerStatefulWidget {
  const JewelryPremiumScreen({super.key});

  @override
  ConsumerState<JewelryPremiumScreen> createState() =>
      _JewelryPremiumScreenState();
}

class _JewelryPremiumScreenState extends ConsumerState<JewelryPremiumScreen> {
  static const _sorts = [
    JewelrySortOption.newest,
    JewelrySortOption.priceDesc,
    JewelrySortOption.priceAsc,
  ];

  final _scroll = ScrollController();
  final _entered = <String>{};
  String? _category;
  JewelrySortOption _sort = JewelrySortOption.newest;
  LuxeViewMode _viewMode = LuxeViewMode.grid;

  /// Last threshold and tabs seen, kept while another tab or sort loads.
  double? _threshold;
  List<({String slug, String name, int count})> _categories = const [];

  JewelryPremiumQuery get _query => (category: _category, sort: _sort);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final pos = _scroll.position;
      if (pos.pixels > pos.maxScrollExtent - 600) {
        ref.read(jewelryPremiumProvider(_query).notifier).loadNextPage();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _openSort() => showLuxeToggleSortSheet<JewelrySortOption>(
    context,
    title: context.tr(JewelryFlowL10n.sortTitle),
    fields: jewelrySortFields(context, _sorts),
    current: _sort,
    onChanged: (o) {
      if (mounted) setState(() => _sort = o);
    },
  );

  void _selectCategory(String? slug) {
    if (slug == _category) return;
    AppHaptics.selection();
    setState(() => _category = slug);
  }

  @override
  Widget build(BuildContext context) {
    return LuxeScope(child: Builder(builder: _build));
  }

  Widget _build(BuildContext context) {
    final p = LuxePalette.of(context);
    final state = ref.watch(jewelryPremiumProvider(_query));
    // Keep the last threshold and tabs while another tab loads.
    if (state.thresholdInr != null) _threshold = state.thresholdInr;
    if (state.categories.isNotEmpty) _categories = state.categories;
    final threshold = _threshold;
    final categories = _categories;
    final pieces = state.pieces;
    final items = pieces.items;

    if (!state.available) {
      return AppScaffold(
        backgroundColor: p.canvas,
        appBar: LuxeTopBar(title: context.tr(JewelryMarketL10n.premium)),
        body: LuxeStateView(
          icon: Icons.workspace_premium_outlined,
          title: context.tr(JewelryMarketL10n.premium),
          message: context.tr(JewelryMarketL10n.premiumUnavailable),
        ),
      );
    }

    return AppScaffold(
      backgroundColor: p.canvas,
      appBar: LuxeTopBar(
        title: context.tr(JewelryMarketL10n.premium),
        actions: const [TopBarActions()],
      ),
      body: RefreshIndicator(
        color: p.ink,
        backgroundColor: p.surface,
        onRefresh: () =>
            ref.read(jewelryPremiumProvider(_query).notifier).refresh(),
        child: CustomScrollView(
          controller: _scroll,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(JewelryMarketL10n.premium).toUpperCase(),
                      style: LuxeType.eyebrow(p.accent),
                    ),
                    const SizedBox(height: 6),
                    if (threshold == null)
                      const LuxeSkeleton(width: 220, height: 30)
                    else
                      Text(
                        context.tr(JewelryMarketL10n.premiumFrom, {
                          'amount': rupees(threshold),
                        }),
                        style: LuxeType.display(30, p.ink),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      pieces.isInitialLoading
                          ? ''
                          : context.tr(JewelryMarketL10n.premiumCount, {
                              'count': pieces.totalCount,
                            }),
                      style: LuxeType.body(p.inkMuted, size: 13),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  children: [
                    if (categories.length >= 2) ...[
                      ChoiceChip(
                        label: Text(context.tr(JewelryMarketL10n.allPieces)),
                        selected: _category == null,
                        onSelected: (_) => _selectCategory(null),
                      ),
                      for (final c in categories) ...[
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Text('${c.name} (${c.count})'),
                          selected: _category == c.slug,
                          onSelected: (_) => _selectCategory(c.slug),
                        ),
                      ],
                      const SizedBox(width: 12),
                    ],
                    ActionChip(
                      avatar: const Icon(Icons.swap_vert_rounded, size: 18),
                      label: Text(context.tr(JewelryFlowL10n.sortTitle)),
                      onPressed: _openSort,
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      avatar: Icon(
                        _viewMode == LuxeViewMode.grid
                            ? Icons.view_agenda_outlined
                            : Icons.grid_view_rounded,
                        size: 18,
                      ),
                      label: const SizedBox.shrink(),
                      labelPadding: EdgeInsets.zero,
                      onPressed: () => setState(
                        () => _viewMode = _viewMode == LuxeViewMode.grid
                            ? LuxeViewMode.list
                            : LuxeViewMode.grid,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ...luxeResultSlivers(
              context: context,
              initialLoading: pieces.isInitialLoading,
              error: pieces.errorMessage,
              items: items,
              isLoadingMore: pieces.isLoadingMore,
              viewMode: _viewMode,
              idOf: (j) => j.id,
              cardOf: (j, mode) => mode == LuxeViewMode.grid
                  ? JewelryLuxeGridCard(
                      jewelry: j,
                      onTap: () => openJewelryDetail(context, j, among: items),
                    )
                  : JewelryLuxeListCard(
                      jewelry: j,
                      onTap: () => openJewelryDetail(context, j, among: items),
                    ),
              entered: _entered,
              loadingMoreLabel: context.tr(DiamondFlowL10n.loadingMore),
              emptyView: LuxeStateView(
                icon: Icons.workspace_premium_outlined,
                title: context.tr(CatalogL10n.noProducts),
                message: context.tr(JewelryMarketL10n.premiumEmpty, {
                  'amount': threshold == null ? '' : rupees(threshold),
                }),
              ),
              errorView: (message) => LuxeStateView(
                icon: Icons.cloud_off_rounded,
                tone: LuxeTone.error,
                title: context.tr(CatalogFlowL10n.errorTitle),
                message: message,
                actionLabel: context.tr(CatalogL10n.retry),
                onAction: () =>
                    ref.read(jewelryPremiumProvider(_query).notifier).refresh(),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.paddingOf(context).bottom + 40,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
