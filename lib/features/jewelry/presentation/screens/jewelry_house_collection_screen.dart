import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/pagination/paginated_list_state.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/luxe_scope.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../../core/widgets/luxe/luxe_listing.dart';
import '../../../../core/widgets/navigation/top_bar/top_bar_actions.dart';
import '../../../product_detail/presentation/widgets/luxe/luxe_detail_parts.dart';
import '../../../product_detail/product_detail_navigation.dart';
import '../../application/jewellery_categories_provider.dart';
import '../../application/jewelry_catalogue_providers.dart';
import '../../application/jewelry_house_providers.dart';
import '../../domain/models/jewelry.dart';
import '../../domain/models/jewelry_filter_state.dart';
import '../../domain/models/jewelry_filter_summary.dart';
import '../../domain/models/marketplace_listing.dart';
import '../jewellery_category_images.dart';
import '../widgets/jewelry_filter_labels.dart';
import '../widgets/jewelry_house_parts.dart';
import '../widgets/jewelry_luxe_cards.dart';
import 'jewelry_filter_screen.dart';

/// One collection of one house, apart from the shared results page: a dark
/// hero fronted by the house's newest piece, then the house's styles in
/// this collection, Filters and Sort (pinned under the header once scrolled
/// to) over its pieces, paged from `GET /marketplace/listings`.
///
/// Styles are made by people and change, so they are read live and only
/// those the house has pieces in are offered.
class JewelryHouseCollectionScreen extends ConsumerStatefulWidget {
  const JewelryHouseCollectionScreen({
    required this.shop,
    required this.category,
    this.preview,
    super.key,
  });

  /// House (shop) slug.
  final String shop;

  /// Top-level category slug.
  final String category;

  /// House data from the previous page, shown while it loads.
  final MarketplaceShop? preview;

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
  final _entered = <String>{};

  late JewelryFilterState _filters = JewelryFilterState(
    shop: widget.shop,
    category: widget.category,
  );
  JewelrySortOption _sort = JewelrySortOption.newest;

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

  Future<void> _openSort() async {
    final picked = await showLuxeChoiceSheet<JewelrySortOption>(
      context,
      title: context.tr(JewelryFlowL10n.sortTitle),
      options: _sorts,
      current: _sort,
      labelOf: (o) => jewelrySortLabel(context, o),
    );
    if (picked != null && mounted) _apply(sort: picked);
  }

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
    final house =
        ref.watch(jewelryShopProvider(widget.shop)).valueOrNull ??
        widget.preview;
    final categories = ref.watch(jewelleryCategoriesProvider).valueOrNull;
    final collection = categories == null
        ? null
        : MarketplaceCategory.find(categories, widget.category);
    final name = collection?.name ?? '';
    final cover = _coverOf(
      ref.watch(jewelryHouseCollectionsProvider(widget.shop)).valueOrNull,
    );
    final ownStyles = ref
        .watch(
          jewelryHouseStylesProvider((
            shop: widget.shop,
            category: widget.category,
          )),
        )
        .valueOrNull;
    final styles = [
      for (final s in collection?.children ?? const <MarketplaceCategory>[])
        if (ownStyles != null && ownStyles.contains(s.slug)) s,
    ];
    final pieces = ref.watch(jewelryHousePiecesProvider(_query));
    final total = pieces.isInitialLoading ? null : pieces.totalCount;
    final topInset = MediaQuery.paddingOf(context).top + 64;
    final heroHeight = topInset + 300;

    Widget bar({required bool floating}) => _CollectionBar(
      styles: styles,
      selectedStyle: _filters.subCategory,
      total: total,
      activeFilters: JewelryFilterSummary.of(_filters).total,
      sortLabel: jewelrySortLabel(context, _sort),
      floating: floating,
      onStyle: _selectStyle,
      onFilters: () => _openFilters(name),
      onSort: _openSort,
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
            child: CustomScrollView(
              controller: _scroll,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: _CollectionHero(
                    height: heroHeight,
                    house: house,
                    category: widget.category,
                    name: name,
                    cover: cover,
                    total: total,
                  ),
                ),
                SliverToBoxAdapter(
                  child: KeyedSubtree(
                    key: _barKey,
                    child: bar(floating: false),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 6)),
                ..._pieces(context, pieces),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.paddingOf(context).bottom + 40,
                  ),
                ),
              ],
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
              solidAfter: heroHeight - topInset,
              darkBackdrop: true,
              actions: (glass) => [
                TopBarActions(glass: glass),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _coverOf(List<JewelryHouseCollection>? collections) {
    for (final c in collections ?? const <JewelryHouseCollection>[]) {
      if (c.category.slug == widget.category) return c.cover;
    }
    return null;
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
      viewMode: LuxeViewMode.grid,
      idOf: (j) => j.id,
      cardOf: (j, _) => JewelryLuxeGridCard(
        jewelry: j,
        onTap: () => openJewelryDetail(context, j, among: items),
      ),
      entered: _entered,
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

/// The newest piece full-bleed on the dark stage, the house's mark and the
/// collection's name.
class _CollectionHero extends StatelessWidget {
  const _CollectionHero({
    required this.height,
    required this.house,
    required this.category,
    required this.name,
    required this.cover,
    required this.total,
  });

  final double height;
  final MarketplaceShop? house;
  final String category;
  final String name;
  final String? cover;
  final int? total;

  @override
  Widget build(BuildContext context) {
    final fallback = Image.asset(
      JewelleryCategoryImages.assetFor(category),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const SizedBox(),
    );
    final house = this.house;

    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const JewelryStageBackdrop(),
          Opacity(
            opacity: 0.9,
            child: cover == null
                ? fallback
                : AppNetworkImage(url: cover!, error: fallback),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  LuxeStage.obsidian.withValues(alpha: 0.55),
                  LuxeStage.obsidian.withValues(alpha: 0.05),
                  LuxeStage.obsidian.withValues(alpha: 0.6),
                  LuxeStage.obsidian,
                ],
                stops: const [0, 0.3, 0.7, 1],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (house != null)
                  Row(
                    children: [
                      JewelryHouseLogo(house: house, radius: 13),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          house.name.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: LuxeType.eyebrow(LuxeStage.gold),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 14),
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: LuxeType.display(46, LuxeStage.ink),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        context.tr(JewelryFlowL10n.houseCollectionsTitle),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LuxeType.displayItalic(18, LuxeStage.inkMuted),
                      ),
                    ),
                    if (total != null) ...[
                      const SizedBox(width: 12),
                      Container(width: 18, height: 0.8, color: LuxeStage.gold),
                      const SizedBox(width: 12),
                      Text(
                        context.tr(JewelryFlowL10n.results, {'count': total}),
                        style: LuxeType.label(LuxeStage.gold, size: 12),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The house's styles in this collection as editorial tabs with a gold
/// underline, then the count, Filters and Sort. Drawn inline and, frosted,
/// pinned under the header.
class _CollectionBar extends StatelessWidget {
  const _CollectionBar({
    required this.styles,
    required this.selectedStyle,
    required this.total,
    required this.activeFilters,
    required this.sortLabel,
    required this.floating,
    required this.onStyle,
    required this.onFilters,
    required this.onSort,
  });

  final List<MarketplaceCategory> styles;
  final String? selectedStyle;
  final int? total;
  final int activeFilters;
  final String sortLabel;
  final bool floating;
  final ValueChanged<String?> onStyle;
  final VoidCallback onFilters;
  final VoidCallback onSort;

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
            Container(
              height: 52,
              decoration: BoxDecoration(border: Border(bottom: hairline)),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: tabs.length,
                separatorBuilder: (_, _) => const SizedBox(width: 26),
                itemBuilder: (context, i) {
                  final t = tabs[i];
                  return _StyleTab(
                    label: t.label,
                    selected: t.slug == selectedStyle,
                    palette: p,
                    onTap: () => onStyle(t.slug),
                  );
                },
              ),
            ),
          SizedBox(
            height: 48,
            child: Row(
              children: [
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    total == null
                        ? ''
                        : context.tr(JewelryFlowL10n.results, {'count': total}),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LuxeType.label(p.inkMuted, size: 12),
                  ),
                ),
                _BarAction(
                  icon: Icons.tune_rounded,
                  label: context.tr(DiamondFlowL10n.filters),
                  badge: activeFilters,
                  palette: p,
                  onTap: onFilters,
                ),
                Container(width: 0.6, height: 18, color: p.hairline),
                _BarAction(
                  icon: Icons.swap_vert_rounded,
                  label: sortLabel,
                  palette: p,
                  onTap: onSort,
                ),
                const SizedBox(width: 8),
              ],
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

class _StyleTab extends StatelessWidget {
  const _StyleTab({
    required this.label,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final LuxePalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppHaptics.selection();
          onTap();
        },
        child: IntrinsicWidth(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedDefaultTextStyle(
                duration: LuxeMotion.fast,
                style: LuxeType.display(17, selected ? p.ink : p.inkFaint),
                child: Text(label, textAlign: TextAlign.center),
              ),
              const SizedBox(height: 10),
              AnimatedContainer(
                duration: LuxeMotion.medium,
                curve: LuxeMotion.settle,
                height: 1.6,
                color: selected ? p.accent : Colors.transparent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarAction extends StatelessWidget {
  const _BarAction({
    required this.icon,
    required this.label,
    required this.palette,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final LuxePalette palette;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: p.ink,
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: p.accent),
          const SizedBox(width: 6),
          Text(label, style: LuxeType.label(p.ink, size: 12.5)),
          if (badge > 0) ...[
            const SizedBox(width: 6),
            Container(
              constraints: const BoxConstraints(minWidth: 18),
              height: 18,
              padding: const EdgeInsets.symmetric(horizontal: 5),
              alignment: Alignment.center,
              decoration: ShapeDecoration(
                color: p.ink,
                shape: const StadiumBorder(),
              ),
              child: Text(
                '$badge',
                style: LuxeType.label(p.canvas, size: 10.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
