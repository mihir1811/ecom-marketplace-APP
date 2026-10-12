import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/luxe_scope.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../../core/widgets/luxe/luxe_layout.dart';
import '../../../../core/widgets/luxe/luxe_listing.dart';
import '../../../catalog_flow/presentation/widgets/catalog_flow_actions.dart';
import '../../../comparison/presentation/widgets/comparison_bottom_bar.dart';
import '../../../product_detail/product_detail_navigation.dart';
import '../../application/brand_watch_filter_provider.dart';
import '../../application/brand_watch_list_provider.dart';
import '../../application/watch_filter_provider.dart';
import '../../domain/models/watch_filter_state.dart';
import '../widgets/watch_brand_assets.dart';
import '../widgets/watch_filter_labels.dart';
import '../widgets/watch_luxe_cards.dart';

/// One maison's watches: a quiet brand masthead over the shared luxe
/// results layout (pinned filter / sort / view toolbar, staggered cards).
class BrandWatchScreen extends ConsumerStatefulWidget {
  const BrandWatchScreen({required this.brandName, super.key});

  final String brandName;

  @override
  ConsumerState<BrandWatchScreen> createState() => _BrandWatchScreenState();
}

class _BrandWatchScreenState extends ConsumerState<BrandWatchScreen>
    with LuxeListingMixin {
  @override
  void initState() {
    super.initState();
    initListing();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(brandWatchListProvider.notifier).setBrandName(widget.brandName);
    });
  }

  @override
  void didUpdateWidget(covariant BrandWatchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.brandName != widget.brandName) {
      ref.read(brandWatchListProvider.notifier).setBrandName(widget.brandName);
    }
  }

  @override
  void dispose() {
    disposeListing();
    super.dispose();
  }

  @override
  bool get listingCanLoadMore {
    final s = ref.read(brandWatchListProvider).valueOrNull;
    return s != null && s.hasMore && !s.isLoadingMore && !s.isInitialLoading;
  }

  @override
  void listingLoadMore() =>
      ref.read(brandWatchListProvider.notifier).loadNextPage();

  @override
  int get listingItemCount =>
      ref.read(brandWatchListProvider).valueOrNull?.watches.length ?? 0;

  @override
  LuxeViewMode get listingViewMode =>
      ref.read(watchViewModeProvider) == WatchViewMode.grid
      ? LuxeViewMode.grid
      : LuxeViewMode.list;

  @override
  void listingApplyViewMode(LuxeViewMode mode) =>
      ref.read(watchViewModeProvider.notifier).state = mode == LuxeViewMode.grid
      ? WatchViewMode.grid
      : WatchViewMode.list;

  void _openFilters() {
    ref.read(brandWatchFilterDraftProvider.notifier).syncFromApplied();
    context.push(AppRouteNames.brandWatchFiltersPath(widget.brandName));
  }

  void _clearAll() => ref.read(brandWatchFilterProvider.notifier).reset();

  Future<void> _openSort() async {
    final selected = await showLuxeChoiceSheet<WatchSortOption>(
      context,
      title: context.tr(CatalogFlowL10n.watchSort),
      options: brandWatchSortOptions,
      current: ref.read(brandWatchSortProvider),
      labelOf: (o) => o.label,
    );
    if (selected != null && mounted) {
      ref.read(brandWatchSortProvider.notifier).state = selected;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LuxeScope(child: Builder(builder: _buildScaffold));
  }

  Widget _buildScaffold(BuildContext context) {
    final p = LuxePalette.of(context);
    return AppScaffold(
      backgroundColor: p.canvas,
      appBar: LuxeTopBar(
        title: widget.brandName,
        subtitle: Consumer(
          builder: (context, ref, _) => WatchCountLine(
            total: ref.watch(
              brandWatchListProvider.select((v) {
                final s = v.valueOrNull;
                return s == null || s.isInitialLoading ? null : s.totalCount;
              }),
            ),
          ),
        ),
        scrollOffset: listingOffset,
        actions: const [CatalogFlowActions()],
      ),
      body: ComparisonTrayHost(
        child: LuxeListingScrollView(
          controller: listingScroll,
          offset: listingOffset,
          onRefresh: () => ref.read(brandWatchListProvider.notifier).refresh(),
          onBackToTop: listingBackToTop,
          backToTopLabel: context.tr(DiamondFlowL10n.backToTop),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                key: listingHeaderKey,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BrandMasthead(brandName: widget.brandName),
                  WatchActiveFilterPills(
                    provider: brandWatchFilterProvider,
                    onEdit: _openFilters,
                    onReset: _clearAll,
                  ),
                ],
              ),
            ),
            LuxePinnedBar(
              child: Center(
                child: WatchListingToolbar(
                  filters: brandWatchFilterProvider,
                  sort: brandWatchSortProvider,
                  onFilters: _openFilters,
                  onSort: _openSort,
                  onViewMode: switchListingViewMode,
                ),
              ),
            ),
            ..._content(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context) {
    final state = ref.watch(brandWatchListProvider).valueOrNull;
    final grid = ref.watch(watchViewModeProvider) == WatchViewMode.grid;
    final listed = state?.watches ?? const [];
    return luxeResultSlivers(
      context: context,
      initialLoading: state == null || state.isInitialLoading,
      error: state?.errorMessage,
      items: listed,
      isLoadingMore: state?.isLoadingMore ?? false,
      viewMode: grid ? LuxeViewMode.grid : LuxeViewMode.list,
      idOf: (w) => w.id,
      cardOf: (w, mode) => mode == LuxeViewMode.grid
          ? WatchLuxeGridCard(
              watch: w,
              onTap: () => openWatchDetail(context, w, among: listed),
            )
          : WatchLuxeListCard(
              watch: w,
              onTap: () => openWatchDetail(context, w, among: listed),
            ),
      entered: listingEntered,
      loadingMoreLabel: context.tr(DiamondFlowL10n.loadingMore),
      emptyView: LuxeStateView(
        icon: Icons.watch_outlined,
        title: 'No ${widget.brandName} watches match your filters',
        message: context.tr(CatalogL10n.adjustWatchFilters),
        actionLabel: context.tr(DiamondFlowL10n.editFilters),
        onAction: _openFilters,
        secondaryLabel: context.tr(CatalogL10n.clearAll),
        onSecondary: _clearAll,
      ),
      errorView: (message) => LuxeStateView(
        icon: Icons.cloud_off_rounded,
        tone: LuxeTone.error,
        title: context.tr(CatalogFlowL10n.errorTitle),
        message: message,
        actionLabel: context.tr(CatalogL10n.retry),
        onAction: () => ref.read(brandWatchListProvider.notifier).refresh(),
        secondaryLabel: context.tr(DiamondFlowL10n.editFilters),
        onSecondary: _openFilters,
      ),
    );
  }
}

/// Centred brand logo (or monogram) on a soft raised plate.
class _BrandMasthead extends StatelessWidget {
  const _BrandMasthead({required this.brandName});

  final String brandName;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final logo = WatchBrandAssets.logoPath(brandName);
    final initial = brandName.trim().isEmpty
        ? '·'
        : brandName.trim()[0].toUpperCase();
    final monogram = Text(initial, style: LuxeType.display(44, p.accent));
    Widget plate = Container(
      height: 112,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 22),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(LuxeSpace.radius),
        border: Border.all(color: p.hairline),
      ),
      alignment: Alignment.center,
      child: logo == null
          ? monogram
          : ColorFiltered(
              // Same inversion the brand carousel uses so dark logos stay
              // legible on the dark surface.
              colorFilter: p.isDark
                  ? const ColorFilter.matrix(<double>[
                      -1, 0, 0, 0, 255, //
                      0, -1, 0, 0, 255, //
                      0, 0, -1, 0, 255, //
                      0, 0, 0, 1, 0, //
                    ])
                  : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
              child: Image.asset(
                logo,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => monogram,
              ),
            ),
    );
    if (!MediaQuery.disableAnimationsOf(context)) {
      plate = plate
          .animate()
          .fadeIn(duration: 500.ms)
          .scaleXY(begin: 0.97, end: 1, curve: LuxeMotion.settle);
    }
    return plate;
  }
}
