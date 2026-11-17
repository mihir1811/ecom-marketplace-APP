import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/pagination/paginated_list_state.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/luxe_scope.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/luxe/luxe_card_reveal.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../../core/widgets/luxe/luxe_listing.dart';
import '../../../../core/widgets/luxe/luxe_toggle_sort_sheet.dart';
import '../../../../core/widgets/navigation/top_bar/top_bar_actions.dart';
import '../../../product_detail/presentation/widgets/luxe/luxe_detail_parts.dart';
import '../../../product_detail/product_detail_navigation.dart';
import '../../application/jewellery_categories_provider.dart';
import '../../application/jewelry_house_providers.dart';
import '../../domain/models/jewelry.dart';
import '../../domain/models/jewelry_filter_state.dart';
import '../../domain/models/jewelry_filter_summary.dart';
import '../../domain/models/marketplace_listing.dart';
import '../widgets/jewelry_filter_labels.dart';
import '../widgets/jewelry_luxe_cards.dart';
import 'jewelry_filter_screen.dart';

/// One collection of one house, apart from the shared results page: the
/// house's styles in this collection as chips, Filters and Sort (pinned
/// under the header once scrolled to) over its pieces, paged from
/// `GET /marketplace/listings`.
///
/// Styles are made by people and change, so they are read live and only
/// those the house has pieces in are offered.
class JewelryHouseCollectionScreen extends ConsumerStatefulWidget {
  const JewelryHouseCollectionScreen({
    required this.shop,
    required this.category,
    super.key,
  });

  /// House (shop) slug.
  final String shop;

  /// Top-level category slug.
  final String category;

  @override
  ConsumerState<JewelryHouseCollectionScreen> createState() =>
      _JewelryHouseCollectionScreenState();
}

class _JewelryHouseCollectionScreenState
    extends ConsumerState<JewelryHouseCollectionScreen> {
  static const _sorts = [
    JewelrySortOption.newest,
    JewelrySortOption.popular,
    JewelrySortOption.priceAsc,
    JewelrySortOption.priceDesc,
  ];

  final _scroll = ScrollController();
  final _offset = ValueNotifier<double>(0);
  final _barShown = ValueNotifier<bool>(false);
  final _barKey = GlobalKey();

  late JewelryFilterState _filters = JewelryFilterState(
    shop: widget.shop,
    category: widget.category,
  );
  JewelrySortOption _sort = JewelrySortOption.newest;
  LuxeViewMode _viewMode = LuxeViewMode.grid;

  JewelryHouseQuery get _query => (filters: _filters, sort: _sort);

  /// Bottom of the floating header (status bar + its 58 pt bar).
  double get _headerBottom => MediaQuery.paddingOf(context).top + 58;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _offset.dispose();
    _barShown.dispose();
    super.dispose();
  }

  void _onScroll() {
    _offset.value = _scroll.offset;
    _barShown.value = _barPassed();
    final pos = _scroll.position;
    if (pos.pixels > pos.maxScrollExtent - 600) {
      ref.read(jewelryHousePiecesProvider(_query).notifier).loadNextPage();
    }
  }

  /// True once the inline bar has gone up under the header.
  bool _barPassed() {
    final box = _barKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return false;
    return box.localToGlobal(Offset.zero).dy < _headerBottom;
  }

  /// Applies [next] and, when the bar is pinned, brings the first pieces
  /// up under it.
  void _apply({JewelryFilterState? filters, JewelrySortOption? sort}) {
    final pinned = _barShown.value;
    final barTop = pinned
        ? (_barKey.currentContext?.findRenderObject() as RenderBox?)
              ?.localToGlobal(Offset.zero)
              .dy
        : null;
    setState(() {
      _filters = filters ?? _filters;
      _sort = sort ?? _sort;
    });
    if (barTop != null && _scroll.hasClients) {
      _scroll.jumpTo(_scroll.offset + barTop - _headerBottom + 1);
    }
  }

  void _selectStyle(String? slug) => _apply(
    filters: slug == null
        ? _filters.copyWith(clearSubCategory: true)
        : _filters.copyWith(subCategory: slug),
  );

  Future<void> _openFilters(String title) async {
    final result = await context.push<JewelryFilterState>(
      AppRouteNames.jewelryFilters,
      extra: JewelryFilterScope(filters: _filters, title: title),
    );
    if (result == null || !mounted) return;
    // The house and collection are this page; never let them change.
    _apply(
      filters: result.copyWith(shop: widget.shop, category: widget.category),
    );
  }

  Future<void> _openSort() => showLuxeToggleSortSheet<JewelrySortOption>(
    context,
    title: context.tr(JewelryFlowL10n.sortTitle),
    fields: jewelrySortFields(context, _sorts),
    current: _sort,
    onChanged: (o) {
      if (mounted) _apply(sort: o);
    },
  );

  void _clearFilters() => _apply(
    filters: JewelryFilterState(
      shop: widget.shop,
      category: widget.category,
      subCategory: _filters.subCategory,
    ),
  );

  Future<void> _refresh() async {
    ref.invalidate(
      jewelryHouseStylesProvider((
        shop: widget.shop,
        category: widget.category,
      )),
    );
    await ref.read(jewelryHousePiecesProvider(_query).notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    return LuxeScope(child: Builder(builder: _buildScaffold));
  }

  Widget _buildScaffold(BuildContext context) {
    final p = LuxePalette.of(context);
    final categories = ref.watch(jewelleryCategoriesProvider).value;
    final collection = categories == null
        ? null
        : MarketplaceCategory.find(categories, widget.category);
    final name = collection?.name ?? '';
    final ownStyles = ref
        .watch(
          jewelryHouseStylesProvider((
            shop: widget.shop,
            category: widget.category,
          )),
        )
        .value;
    final styles = [
      for (final s in collection?.children ?? const <MarketplaceCategory>[])
        if (ownStyles != null && ownStyles.contains(s.slug)) s,
    ];
    final pieces = ref.watch(jewelryHousePiecesProvider(_query));
    final topInset = _headerBottom;

    Widget bar({required bool floating}) => _CollectionBar(
      styles: styles,
      selectedStyle: _filters.subCategory,
      activeFilters: JewelryFilterSummary.of(_filters).total,
      viewMode: _viewMode,
      floating: floating,
      onStyle: _selectStyle,
      onFilters: () => _openFilters(name),
      onSort: _openSort,
      onViewMode: (m) => setState(() => _viewMode = m),
    );

    return AppScaffold(
      backgroundColor: p.canvas,
      safeTop: false,
      body: Stack(
        children: [
          RefreshIndicator(
            color: p.ink,
            backgroundColor: p.surface,
            edgeOffset: topInset,
            onRefresh: _refresh,
            child: LuxeScrollAssemble(
              controller: _scroll,
              child: CustomScrollView(
                controller: _scroll,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(child: SizedBox(height: topInset)),
                  SliverToBoxAdapter(
                    child: KeyedSubtree(
                      key: _barKey,
                      child: bar(floating: false),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 5)),
                  ..._pieces(context, pieces),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: MediaQuery.paddingOf(context).bottom + 40,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: _headerBottom,
            left: 0,
            right: 0,
            child: ValueListenableBuilder<bool>(
              valueListenable: _barShown,
              builder: (context, shown, child) => IgnorePointer(
                ignoring: !shown,
                child: AnimatedOpacity(
                  opacity: shown ? 1 : 0,
                  duration: LuxeMotion.fast,
                  child: child,
                ),
              ),
              child: bar(floating: true),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LuxeFloatingHeader(
              title: name,
              offset: _offset,
              // Always solid: the page opens on the canvas.
              solidAfter: 0,
              actions: (glass) => [TopBarActions(glass: glass)],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _pieces(
    BuildContext context,
    PaginatedListState<Jewelry> state,
  ) {
    final items = state.items;
    final filtered = JewelryFilterSummary.of(_filters).total > 0;
    return luxeResultSlivers(
      context: context,
      initialLoading: state.isInitialLoading,
      error: state.errorMessage,
      items: items,
      isLoadingMore: state.isLoadingMore,
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
      loadingMoreLabel: context.tr(DiamondFlowL10n.loadingMore),
      emptyView: LuxeStateView(
        icon: Icons.diamond_outlined,
        title: context.tr(CatalogL10n.noProducts),
        message: context.tr(
          filtered
              ? CatalogL10n.adjustOrClear
              : JewelryFlowL10n.housePiecesEmpty,
        ),
        actionLabel: filtered ? context.tr(CatalogL10n.clearAll) : null,
        onAction: filtered ? _clearFilters : null,
      ),
      errorView: (message) => LuxeStateView(
        icon: Icons.cloud_off_rounded,
        tone: LuxeTone.error,
        title: context.tr(CatalogFlowL10n.errorTitle),
        message: message,
        actionLabel: context.tr(CatalogL10n.retry),
        onAction: () =>
            ref.read(jewelryHousePiecesProvider(_query).notifier).refresh(),
      ),
    );
  }
}

/// The house's styles in this collection as chips, then Filters and Sort. Drawn inline and, frosted,
/// pinned under the header.
class _CollectionBar extends StatelessWidget {
  const _CollectionBar({
    required this.styles,
    required this.selectedStyle,
    required this.activeFilters,
    required this.viewMode,
    required this.floating,
    required this.onStyle,
    required this.onFilters,
    required this.onSort,
    required this.onViewMode,
  });

  final List<MarketplaceCategory> styles;
  final String? selectedStyle;
  final int activeFilters;
  final LuxeViewMode viewMode;
  final bool floating;
  final ValueChanged<String?> onStyle;
  final VoidCallback onFilters;
  final VoidCallback onSort;
  final ValueChanged<LuxeViewMode> onViewMode;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final hairline = BorderSide(color: p.hairline, width: 0.6);
    final tabs = <({String? slug, String label})>[
      (slug: null, label: context.tr(JewelryFlowL10n.allStyles)),
      for (final s in styles) (slug: s.slug, label: s.name),
    ];

    Widget content = Container(
      decoration: BoxDecoration(
        color: floating ? p.canvas.withValues(alpha: 0.92) : p.canvas,
        border: Border(bottom: hairline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (styles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 2),
              child: LuxeQuickChips<String?>(
                chips: [
                  for (final t in tabs)
                    LuxeQuickChip(value: t.slug, label: t.label),
                ],
                isSelected: (slug) => slug == selectedStyle,
                onTap: onStyle,
              ),
            ),
          // Same Filters / Sort / grid-list toolbar as the listing screens.
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Center(
              child: LuxeListingToolbar(
                filtersLabel: context.tr(DiamondFlowL10n.filters),
                activeFilters: activeFilters,
                onFilters: onFilters,
                onSort: onSort,
                viewMode: viewMode,
                onViewMode: onViewMode,
                gridLabel: context.tr(DiamondFlowL10n.grid),
                listLabel: context.tr(DiamondFlowL10n.list),
              ),
            ),
          ),
        ],
      ),
    );
    if (floating) {
      content = ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: content,
        ),
      );
    }
    return content;
  }
}
