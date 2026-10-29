import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/luxe_scope.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_system_back_scope.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../../core/widgets/luxe/luxe_layout.dart';
import '../../../../core/widgets/luxe/luxe_listing.dart';
import '../../../../core/widgets/navigation/top_bar/top_bar_actions.dart';
import '../../../product_detail/product_detail_navigation.dart';
import '../../application/jewelry_filter_provider.dart';
import '../../application/jewelry_list_provider.dart';
import '../../domain/models/jewelry_filter_state.dart';
import '../widgets/jewelry_filter_labels.dart';
import '../widgets/jewelry_luxe_cards.dart';
import '../widgets/jewelry_quick_filters.dart';

/// Jewelry results on the shared luxe listing pieces.
///
/// Search, style chips, metal tones and active-filter pills scroll away;
/// the Filters / Sort / view toolbar stays pinned. Cards enter with a short
/// stagger, skeletons cover loading and empty / error states offer the next
/// step.
class JewelryListingScreen extends ConsumerStatefulWidget {
  const JewelryListingScreen({
    this.initialCategory,
    this.initialStyle,
    this.initialMetal,
    super.key,
  });

  final String? initialCategory;

  /// Style (sub-category slug) to open with, e.g. from the house landing.
  final String? initialStyle;

  /// Metal enum to open with, e.g. `ROSE_GOLD`.
  final String? initialMetal;

  @override
  ConsumerState<JewelryListingScreen> createState() =>
      _JewelryListingScreenState();
}

class _JewelryListingScreenState extends ConsumerState<JewelryListingScreen>
    with LuxeListingMixin {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    initListing();
    final q = ref.read(jewelryFilterProvider).searchQuery;
    if (q.isNotEmpty) _searchController.text = q;
    final category = widget.initialCategory;
    final hasEntry =
        (category != null && category.isNotEmpty) ||
        widget.initialStyle != null ||
        widget.initialMetal != null;
    if (hasEntry) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(jewelryFilterProvider.notifier)
            .openCollection(
              category: category ?? ref.read(jewelryFilterProvider).category,
              style: widget.initialStyle,
              metal: widget.initialMetal,
            );
      });
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    disposeListing();
    super.dispose();
  }

  @override
  bool get listingCanLoadMore {
    final s = ref.read(jewelryListProvider).valueOrNull;
    return s != null &&
        s.hasMore &&
        !s.isLoadingMore &&
        !s.isInitialLoading &&
        !s.isRefreshing;
  }

  @override
  void listingLoadMore() =>
      ref.read(jewelryListProvider.notifier).loadNextPage();

  @override
  int get listingItemCount =>
      ref.read(jewelryListProvider).valueOrNull?.items.length ?? 0;

  @override
  LuxeViewMode get listingViewMode =>
      ref.read(jewelryViewModeProvider) == JewelryViewMode.grid
      ? LuxeViewMode.grid
      : LuxeViewMode.list;

  @override
  void listingApplyViewMode(LuxeViewMode mode) =>
      ref
          .read(jewelryViewModeProvider.notifier)
          .state = mode == LuxeViewMode.grid
      ? JewelryViewMode.grid
      : JewelryViewMode.list;

  /// Debounced so typing does not refetch on every keystroke.
  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        ref.read(jewelryFilterProvider.notifier).setSearchQuery(value);
      }
    });
  }

  void _onSearchSubmitted(String value) {
    _searchDebounce?.cancel();
    ref.read(jewelryFilterProvider.notifier).setSearchQuery(value);
  }

  void _openFilters() {
    // Flush a pending search first so the draft starts from it and a late
    // debounce can't overwrite the draft while the filters are open.
    if (_searchDebounce?.isActive ?? false) {
      _searchDebounce!.cancel();
      ref
          .read(jewelryFilterProvider.notifier)
          .setSearchQuery(_searchController.text);
    }
    ref.read(jewelryFilterDraftProvider.notifier).syncFromApplied();
    context.push(AppRouteNames.jewelryFilters);
  }

  void _clearAll() {
    _searchDebounce?.cancel();
    ref.read(jewelryFilterProvider.notifier).reset();
  }

  void _clearEverything() {
    _searchDebounce?.cancel();
    final n = ref.read(jewelryFilterProvider.notifier)..reset();
    n.setSearchQuery('');
    _searchController.clear();
  }

  Future<void> _openSort() async {
    final searching = ref.read(jewelryFilterProvider).searchQuery.isNotEmpty;
    final selected = await showLuxeChoiceSheet<JewelrySortOption>(
      context,
      title: context.tr(JewelryFlowL10n.sortTitle),
      options: [
        if (searching) JewelrySortOption.relevance,
        JewelrySortOption.newest,
        JewelrySortOption.priceAsc,
        JewelrySortOption.priceDesc,
        JewelrySortOption.popular,
      ],
      // The API default: relevance while searching, else newest.
      current:
          ref.read(jewelrySortProvider) ??
          (searching ? JewelrySortOption.relevance : JewelrySortOption.newest),
      labelOf: (o) => jewelrySortLabel(context, o),
    );
    if (selected != null && mounted) {
      ref.read(jewelrySortProvider.notifier).state = selected;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSystemBackScope(
      child: LuxeScope(child: Builder(builder: _buildScaffold)),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final p = LuxePalette.of(context);
    return AppScaffold(
      // Runs on behind the floating dock; the scroll view clears it.
      safeBottom: false,
      backgroundColor: p.canvas,
      appBar: LuxeTopBar(
        title: JewelryCollectionTitle.watch(context, ref),
        subtitle: Consumer(
          builder: (context, ref, _) => JewelryCountLine(
            total: ref.watch(
              jewelryListProvider.select((v) {
                final s = v.valueOrNull;
                return s == null || s.isInitialLoading ? null : s.totalCount;
              }),
            ),
          ),
        ),
        scrollOffset: listingOffset,
        actions: const [TopBarActions()],
      ),
      body: LuxeListingScrollView(
        controller: listingScroll,
        offset: listingOffset,
        onRefresh: () => ref.read(jewelryListProvider.notifier).refresh(),
        onBackToTop: listingBackToTop,
        backToTopLabel: context.tr(DiamondFlowL10n.backToTop),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              key: listingHeaderKey,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                  child: LuxeSearchField(
                    controller: _searchController,
                    hintText: context.tr(CatalogL10n.searchJewelry),
                    onChanged: _onSearchChanged,
                    onSubmitted: _onSearchSubmitted,
                  ),
                ),
                const _ShopPill(),
                const JewelryStyleChips(),
                const SizedBox(height: 10),
                const JewelryMetalChips(),
                JewelryActiveFilterPills(
                  onEdit: _openFilters,
                  onReset: _clearAll,
                ),
              ],
            ),
          ),
          LuxePinnedBar(
            child: Center(
              child: JewelryListingToolbar(
                onFilters: _openFilters,
                onSort: _openSort,
                onViewMode: switchListingViewMode,
              ),
            ),
          ),
          ..._content(context),
        ],
      ),
    );
  }

  List<Widget> _content(BuildContext context) {
    final stateAsync = ref.watch(jewelryListProvider);
    final grid = ref.watch(jewelryViewModeProvider) == JewelryViewMode.grid;
    final state = stateAsync.valueOrNull;
    final error =
        stateAsync.whenOrNull(error: (e, _) => e.toString()) ??
        state?.errorMessage;
    final listed = state?.items ?? const [];
    return luxeResultSlivers(
      context: context,
      initialLoading:
          !stateAsync.hasError && (state == null || state.isInitialLoading),
      error: error,
      items: listed,
      isLoadingMore: state?.isLoadingMore ?? false,
      viewMode: grid ? LuxeViewMode.grid : LuxeViewMode.list,
      idOf: (j) => j.id,
      cardOf: (j, mode) => mode == LuxeViewMode.grid
          ? JewelryLuxeGridCard(
              jewelry: j,
              onTap: () => openJewelryDetail(context, j, among: listed),
            )
          : JewelryLuxeListCard(
              jewelry: j,
              onTap: () => openJewelryDetail(context, j, among: listed),
            ),
      entered: listingEntered,
      loadingMoreLabel: context.tr(DiamondFlowL10n.loadingMore),
      emptyView: LuxeStateView(
        icon: Icons.diamond_outlined,
        title: context.tr(CatalogL10n.noProducts),
        message: context.tr(CatalogL10n.adjustOrClear),
        actionLabel: context.tr(DiamondFlowL10n.editFilters),
        onAction: _openFilters,
        secondaryLabel: context.tr(CatalogL10n.clearAll),
        onSecondary: _clearEverything,
      ),
      errorView: (message) => LuxeStateView(
        icon: Icons.cloud_off_rounded,
        tone: LuxeTone.error,
        title: context.tr(CatalogFlowL10n.errorTitle),
        message: message,
        actionLabel: context.tr(CatalogL10n.retry),
        onAction: () => ref.read(jewelryListProvider.notifier).refresh(),
        secondaryLabel: context.tr(DiamondFlowL10n.editFilters),
        onSecondary: _openFilters,
      ),
    );
  }
}

/// "Pureyou ×" while results are narrowed to one shop.
class _ShopPill extends ConsumerWidget {
  const _ShopPill();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shop = ref.watch(jewelryFilterProvider.select((s) => s.shop));
    if (shop == null || shop.isEmpty) return const SizedBox.shrink();
    final p = LuxePalette.of(context);
    final name = ref.watch(
      jewelryListProvider.select((v) {
        final items = v.valueOrNull?.items ?? const [];
        return items.isEmpty ? null : items.first.shopName;
      }),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: InputChip(
          avatar: Icon(Icons.storefront_outlined, size: 16, color: p.accent),
          label: Text(
            context.tr(JewelryMarketL10n.shopFilter, {'shop': name ?? shop}),
            style: LuxeType.label(p.ink, size: 13),
          ),
          backgroundColor: p.surface,
          side: BorderSide(color: p.hairline),
          shape: const StadiumBorder(),
          onDeleted: ref.read(jewelryFilterProvider.notifier).clearShop,
        ),
      ),
    );
  }
}
