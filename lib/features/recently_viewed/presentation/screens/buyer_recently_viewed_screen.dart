import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../buyer/domain/models/wishlist_item.dart';
import '../../../buyer/presentation/maison/maison_kit.dart';
import '../../../buyer/presentation/maison/maison_layout.dart';
import '../../../buyer/presentation/widgets/wishlist/wishlist_piece_card.dart';
import '../../../seller/presentation/atelier/atelier_components.dart';
import '../../../seller/presentation/atelier/atelier_feedback.dart';
import '../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../seller/presentation/atelier/atelier_theme.dart';
import '../../application/recently_viewed_list_provider.dart';
import '../../application/recently_viewed_providers.dart';
import '../../data/repositories/recently_viewed_repository_impl.dart';
import '../../domain/models/recently_viewed.dart';
import '../widgets/recent/recent_piece.dart';
import '../widgets/recent/recent_piece_card.dart';

enum _RecentSort {
  recent('Most recent'),
  priceHigh('Price: high to low'),
  priceLow('Price: low to high'),
  name('Name A–Z');

  const _RecentSort(this.label);
  final String label;
}

/// The buyer's viewing trail: the last piece in an onyx spotlight, then
/// every piece grouped by day, with a category lens, search, sort and a
/// gallery / list switch. History can be cleared in one confirmed step.
class BuyerRecentlyViewedScreen extends ConsumerStatefulWidget {
  const BuyerRecentlyViewedScreen({super.key});

  @override
  ConsumerState<BuyerRecentlyViewedScreen> createState() =>
      _BuyerRecentlyViewedScreenState();
}

class _BuyerRecentlyViewedScreenState
    extends ConsumerState<BuyerRecentlyViewedScreen> {
  final _search = TextEditingController();
  WishlistCategory? _category;
  _RecentSort _sort = _RecentSort.recent;
  bool _grid = true;
  bool _loadingMore = false;
  String? _loadMoreError;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _loadMoreError = null);
    ref.invalidate(recentlyViewedListProvider);
    try {
      await ref.read(recentlyViewedListProvider.future);
    } catch (_) {
      // The error surfaces through the provider state.
    }
  }

  Future<void> _loadMore() async {
    final page = ref.read(recentlyViewedListProvider).value;
    if (_loadingMore || page == null || !page.hasMore) return;
    setState(() {
      _loadingMore = true;
      _loadMoreError = null;
    });
    await ref.read(recentlyViewedListProvider.notifier).loadMore();
    if (!mounted) return;
    final after = ref.read(recentlyViewedListProvider).value;
    setState(() {
      _loadingMore = false;
      if (after != null &&
          after.hasMore &&
          after.currentPage == page.currentPage) {
        _loadMoreError = 'We couldn’t load more pieces.';
      }
    });
  }

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis == Axis.vertical &&
        n.metrics.extentAfter < 480 &&
        _loadMoreError == null) {
      _loadMore();
    }
    return false;
  }

  Future<void> _clearHistory() async {
    final messenger = ScaffoldMessenger.of(context);
    final palette = context.atelier;
    final clearedText = context.tr(AccountCommerceL10n.recentCleared);
    final cleared = await showAtelierDialog<bool>(
      context: context,
      builder: (dialogContext) => MaisonActionDialog(
        title: dialogContext.tr(AccountCommerceL10n.clearRecentTitle),
        message: dialogContext.tr(AccountCommerceL10n.clearRecentBody),
        confirmLabel: dialogContext.tr(AccountCommerceL10n.clearAll),
        cancelLabel: dialogContext.tr(CoreL10n.cancel),
        icon: Icons.delete_sweep_outlined,
        destructive: true,
        onConfirm: (ref) =>
            maisonOutcome(ref.read(recentlyViewedRepositoryProvider).clear()),
      ),
    );
    if (cleared != true || !mounted) return;
    AppHaptics.medium();
    ref.read(recentlyViewedIdsProvider.notifier).clearLocal();
    ref.invalidate(recentlyViewedListProvider);
    setState(() {
      _category = null;
      _search.clear();
      _loadMoreError = null;
    });
    showMaisonToast(
      messenger,
      palette,
      clearedText,
      icon: Icons.auto_awesome_rounded,
    );
  }

  Future<void> _pickSort() async {
    final sort = await showAtelierOptions<_RecentSort>(
      context: context,
      title: 'Sort your trail',
      options: [
        for (final s in _RecentSort.values)
          AtelierOption(
            value: s,
            label: s.label,
            selected: s == _sort,
            hint: s == _RecentSort.recent ? 'Grouped by day' : null,
            icon: switch (s) {
              _RecentSort.recent => Icons.history_rounded,
              _RecentSort.priceHigh => Icons.trending_up_rounded,
              _RecentSort.priceLow => Icons.trending_down_rounded,
              _RecentSort.name => Icons.sort_by_alpha_rounded,
            },
          ),
      ],
    );
    if (sort != null && mounted) setState(() => _sort = sort);
  }

  void _clearFilters() {
    _search.clear();
    setState(() {
      _category = null;
      _sort = _RecentSort.recent;
    });
  }

  List<RecentlyViewedEntry> _view(List<RecentlyViewedEntry> items) {
    final q = _search.text.trim().toLowerCase();
    final out = [
      for (final e in items)
        if ((_category == null || e.category == _category) &&
            (q.isEmpty ||
                e.displayTitle.toLowerCase().contains(q) ||
                (e.detailLine ?? '').toLowerCase().contains(q) ||
                (e.stockNumber ?? '').toLowerCase().contains(q) ||
                e.typeLabel.toLowerCase().contains(q)))
          e,
    ];
    switch (_sort) {
      case _RecentSort.recent:
        // The API already returns the trail newest first.
        break;
      case _RecentSort.priceHigh:
        out.sort((a, b) => b.priceValue.compareTo(a.priceValue));
      case _RecentSort.priceLow:
        out.sort((a, b) {
          // Unpriced pieces sink to the end.
          final av = a.priceValue <= 0 ? double.infinity : a.priceValue;
          final bv = b.priceValue <= 0 ? double.infinity : b.priceValue;
          return av.compareTo(bv);
        });
      case _RecentSort.name:
        out.sort(
          (a, b) => a.displayTitle.toLowerCase().compareTo(
            b.displayTitle.toLowerCase(),
          ),
        );
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final async = ref.watch(recentlyViewedListProvider);
    final page = async.value;
    final items = page?.items ?? const <RecentlyViewedEntry>[];
    final present = [
      for (final c in WishlistCategory.values)
        if (items.any((e) => e.category == c)) c,
    ];
    // A category can disappear after a refresh; fall back to All.
    final category = present.contains(_category) ? _category : null;
    if (category != _category) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _category = null);
      });
    }
    final visible = _view(items);
    final width = MediaQuery.sizeOf(context).width;
    final gutter = AtelierSpace.gutter(width);

    return MaisonLayout(
      detail: true,
      child: RefreshIndicator(
        color: p.gold,
        backgroundColor: p.surface,
        onRefresh: _refresh,
        child: NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(gutter, 6, gutter, 8),
                sliver: SliverToBoxAdapter(
                  child: MaisonCentered(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (items.isNotEmpty)
                          Reveal(child: _TrailBar(onClear: _clearHistory)),
                      ],
                    ),
                  ),
                ),
              ),
              if (items.isNotEmpty)
                MaisonPinnedBar(
                  height: 124,
                  gutter: gutter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AtelierSegmented<WishlistCategory?>(
                        dense: true,
                        segments: [
                          AtelierSegment(
                            value: null,
                            label: context.tr(RemainingL10n.all),
                            count: items.length,
                          ),
                          for (final c in present)
                            AtelierSegment(
                              value: c,
                              label: wishlistCategoryLabel(c),
                              icon: wishlistCategoryIcon(c),
                              count: items.where((e) => e.category == c).length,
                            ),
                        ],
                        selected: category,
                        onChanged: (c) => setState(() => _category = c),
                      ),
                      const SizedBox(height: 8),
                      MaisonSearchRow(
                        controller: _search,
                        hint: 'Search pieces, grades or stock no.',
                        onChanged: (_) => setState(() {}),
                        sortLabel: _sort.label,
                        sortActive: _sort != _RecentSort.recent,
                        onSort: _pickSort,
                        trailing: AtelierIconButton(
                          icon: _grid
                              ? Icons.view_agenda_outlined
                              : Icons.grid_view_rounded,
                          tooltip: _grid ? 'List view' : 'Gallery view',
                          filled: true,
                          size: 46,
                          onPressed: () => setState(() => _grid = !_grid),
                        ),
                      ),
                    ],
                  ),
                ),
              MaisonRefreshHairline(
                visible: async.isLoading && items.isNotEmpty,
              ),
              ..._body(context, async, items, visible, width, gutter),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _body(
    BuildContext context,
    AsyncValue<RecentlyViewedListPage> async,
    List<RecentlyViewedEntry> items,
    List<RecentlyViewedEntry> visible,
    double width,
    double gutter,
  ) {
    Widget boxed(Widget child) => SliverPadding(
      padding: EdgeInsets.fromLTRB(gutter, 5, gutter, 20),
      sliver: SliverToBoxAdapter(child: MaisonCentered(child: child)),
    );

    final error = async.error;
    final errorText = error is Failure
        ? error.message
        : context.tr(AccountCommerceL10n.recentLoadFailed);

    if (items.isEmpty && async.isLoading) {
      return [_skeleton(width, gutter)];
    }
    if (items.isEmpty && async.hasError) {
      return [
        boxed(
          AtelierErrorState(
            title: 'Your trail is out of reach',
            message: errorText,
            onRetry: _refresh,
          ),
        ),
      ];
    }
    if (items.isEmpty) {
      return [
        boxed(
          MaisonEmptyState(
            title: context.tr(AccountCommerceL10n.noRecent),
            message: context.tr(AccountCommerceL10n.noRecentHint),
            actionLabel: 'Explore the collection',
            actionIcon: Icons.arrow_forward_rounded,
            onAction: () => context.switchToRoute(AppRouteNames.home),
          ),
        ),
      ];
    }

    final page = async.value;
    final hasMore = page?.hasMore ?? false;
    final side = math.max(gutter, (width - 1040) / 2);
    final slivers = <Widget>[];

    if (async.hasError && !async.isLoading) {
      slivers.add(
        SliverPadding(
          padding: EdgeInsets.fromLTRB(side, 8, side, 0),
          sliver: SliverToBoxAdapter(
            child: Reveal(
              child: AtelierNotice(
                text: 'Showing your saved trail — $errorText',
                tone: AtelierTone.ruby,
                icon: Icons.cloud_off_rounded,
                actionLabel: context.tr(AccountCommerceL10n.retry),
                onAction: _refresh,
              ),
            ),
          ),
        ),
      );
    }

    if (visible.isEmpty) {
      slivers.add(
        boxed(
          AtelierEmptyState(
            icon: Icons.search_off_rounded,
            title: 'No matches',
            message: _search.text.trim().isEmpty
                ? 'Nothing in this category yet.'
                : 'No viewed piece matches “${_search.text.trim()}”.',
            actionLabel: 'Clear filters',
            onAction: _clearFilters,
          ),
        ),
      );
    } else {
      // Day groups only make sense in time order.
      final groups = <({String label, List<RecentlyViewedEntry> items})>[];
      if (_sort == _RecentSort.recent) {
        for (final e in visible) {
          final label = e.dayGroup;
          if (groups.isEmpty || groups.last.label != label) {
            groups.add((label: label, items: [e]));
          } else {
            groups.last.items.add(e);
          }
        }
      } else {
        groups.add((label: '', items: visible));
      }

      var revealed = 0;
      for (final group in groups) {
        if (group.label.isNotEmpty) {
          slivers.add(
            SliverPadding(
              padding: EdgeInsets.fromLTRB(side, 8, side, 0),
              sliver: SliverToBoxAdapter(
                child: MaisonGroupLabel(
                  label: group.label,
                  count: group.items.length,
                ),
              ),
            ),
          );
        }
        final start = revealed;
        slivers.add(
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              side,
              group.label.isEmpty ? 8 : 0,
              side,
              8,
            ),
            sliver: _grid
                ? _gridSliver(group.items, width, side, start)
                : SliverList.separated(
                    itemCount: group.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final entry = group.items[i];
                      final n = start + i;
                      return Reveal(
                        key: ValueKey('row-${entry.id}-${entry.productId}'),
                        index: n < 8 ? n : 0,
                        child: RecentPieceCard(entry: entry, compact: true),
                      );
                    },
                  ),
          ),
        );
        revealed += group.items.length;
      }
    }

    slivers.add(
      SliverPadding(
        padding: EdgeInsets.fromLTRB(side, 4, side, 36),
        sliver: SliverToBoxAdapter(
          child: MaisonListFooter(
            loadingMore: _loadingMore,
            hasMore: hasMore,
            errorMessage: _loadMoreError,
            onLoadMore: () {
              setState(() => _loadMoreError = null);
              _loadMore();
            },
            endLabel: 'The beginning of your trail',
          ),
        ),
      ),
    );
    return slivers;
  }

  Widget _gridSliver(
    List<RecentlyViewedEntry> entries,
    double width,
    double side,
    int start,
  ) {
    final grid = _gridMetrics(width, side);
    return SliverGrid.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: grid.columns,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: grid.extent,
      ),
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final entry = entries[i];
        final n = start + i;
        return Reveal(
          key: ValueKey('tile-${entry.id}-${entry.productId}'),
          index: n < 8 ? n : 0,
          child: RecentPieceCard(entry: entry),
        );
      },
    );
  }

  static ({int columns, double extent}) _gridMetrics(
    double width,
    double side,
  ) {
    final content = width - side * 2;
    final columns = content >= 900
        ? 4
        : content >= 600
        ? 3
        : 2;
    final tile = (content - (columns - 1) * 14) / columns;
    return (columns: columns, extent: tile + 104);
  }

  Widget _skeleton(double width, double gutter) {
    final side = math.max(gutter, (width - 1040) / 2);
    final grid = _gridMetrics(width, side);
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(side, 4, side, 36),
      sliver: SliverMainAxisGroup(
        slivers: [
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: SkeletonBox(height: 136, radius: AtelierRadius.xl),
            ),
          ),
          SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: grid.columns,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              mainAxisExtent: grid.extent,
            ),
            itemCount: grid.columns * 2,
            itemBuilder: (context, _) => const _SkeletonTile(),
          ),
        ],
      ),
    );
  }
}

/// Quiet line above the spotlight: what it is, and the one destructive
/// action kept small and out of the way of browsing.
class _TrailBar extends StatelessWidget {
  const _TrailBar({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    // Just the clear action, right-aligned.
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Tooltip(
          message: context.tr(AccountCommerceL10n.clearRecentTitle),
          child: Pressable(
            onTap: onClear,
            scale: 0.94,
            semanticLabel: context.tr(AccountCommerceL10n.clearRecentTitle),
            borderRadius: BorderRadius.circular(AtelierRadius.pill),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AtelierRadius.pill),
                border: Border.all(color: p.hairline),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete_sweep_outlined, size: 15, color: p.muted),
                  const SizedBox(width: 5),
                  Text(
                    'Clear history',
                    style: AtelierType.label(p.inkSoft, size: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SkeletonTile extends StatelessWidget {
  const _SkeletonTile();

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AtelierRadius.lg),
        border: Border.all(color: p.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: SkeletonBox(height: double.infinity, radius: 0),
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 110, height: 12),
                SizedBox(height: 6),
                SkeletonBox(width: 70, height: 10),
                SizedBox(height: 10),
                SkeletonBox(width: 90, height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
