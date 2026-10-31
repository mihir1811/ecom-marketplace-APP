import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/gem3d/gem_mesh.dart';
import '../../../seller/presentation/atelier/atelier_components.dart';
import '../../../seller/presentation/atelier/atelier_feedback.dart';
import '../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../seller/presentation/atelier/atelier_theme.dart';
import '../../application/wishlist_provider.dart';
import '../../domain/models/wishlist_item.dart';
import '../maison/maison_kit.dart';
import '../maison/maison_layout.dart';
import '../widgets/wishlist/wishlist_piece_card.dart';

enum _WishSort {
  saved('As saved'),
  priceHigh('Price: high to low'),
  priceLow('Price: low to high'),
  name('Name A–Z');

  const _WishSort(this.label);
  final String label;
}

/// The buyer's saved pieces as a gallery (or list), with a category lens,
/// search and sort. Removing offers Undo.
class BuyerWishlistScreen extends ConsumerStatefulWidget {
  const BuyerWishlistScreen({super.key});

  @override
  ConsumerState<BuyerWishlistScreen> createState() =>
      _BuyerWishlistScreenState();
}

class _BuyerWishlistScreenState extends ConsumerState<BuyerWishlistScreen> {
  final _search = TextEditingController();
  WishlistCategory? _category;
  _WishSort _sort = _WishSort.saved;
  bool _grid = true;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() => ref.read(wishlistProvider.notifier).refresh();

  static double _price(WishlistItem i) =>
      double.tryParse(i.priceLabel.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;

  List<WishlistItem> _view(List<WishlistItem> items) {
    final q = _search.text.trim().toLowerCase();
    final out = [
      for (final i in items)
        if ((_category == null || i.category == _category) &&
            (q.isEmpty ||
                i.title.toLowerCase().contains(q) ||
                i.subtitle.toLowerCase().contains(q)))
          i,
    ];
    switch (_sort) {
      case _WishSort.saved:
        break;
      case _WishSort.priceHigh:
        out.sort((a, b) => _price(b).compareTo(_price(a)));
      case _WishSort.priceLow:
        out.sort((a, b) => _price(a).compareTo(_price(b)));
      case _WishSort.name:
        out.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
    }
    return out;
  }

  Future<void> _pickSort() async {
    final sort = await showAtelierOptions<_WishSort>(
      context: context,
      title: 'Sort wishlist',
      options: [
        for (final s in _WishSort.values)
          AtelierOption(
            value: s,
            label: s.label,
            selected: s == _sort,
            icon: switch (s) {
              _WishSort.saved => Icons.favorite_border_rounded,
              _WishSort.priceHigh => Icons.trending_up_rounded,
              _WishSort.priceLow => Icons.trending_down_rounded,
              _WishSort.name => Icons.sort_by_alpha_rounded,
            },
          ),
      ],
    );
    if (sort != null && mounted) setState(() => _sort = sort);
  }

  Future<void> _remove(WishlistItem item) async {
    final messenger = ScaffoldMessenger.of(context);
    final palette = context.atelier;
    final removedText = context.tr(AccountCommerceL10n.removedWishlist);
    final notifier = ref.read(wishlistProvider.notifier);
    AppHaptics.light();
    await notifier.remove(item.id, productType: item.productType);
    if (!mounted) return;
    final error = ref.read(wishlistProvider).errorMessage;
    if (error != null) {
      showMaisonToast(messenger, palette, error, tone: AtelierTone.ruby);
      return;
    }
    showMaisonToast(
      messenger,
      palette,
      removedText,
      icon: Icons.heart_broken_outlined,
      actionLabel: 'Undo',
      onAction: () => notifier.add(item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final wishlist = ref.watch(wishlistProvider);
    final items = wishlist.items;
    final present = [
      for (final c in WishlistCategory.values)
        if (items.any((i) => i.category == c)) c,
    ];
    // A category can empty out after a removal; fall back to All.
    final category = present.contains(_category) ? _category : null;
    if (category != _category) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _category = null);
      });
    }
    final visible = _view(items);
    final width = MediaQuery.sizeOf(context).width;
    final gutter = AtelierSpace.gutter(width);
    final count = items.length;

    return MaisonLayout(
      scrollsBehindDock: true,
      child: RefreshIndicator(
        color: p.gold,
        backgroundColor: p.surface,
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
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
                          count: count,
                        ),
                        for (final c in present)
                          AtelierSegment(
                            value: c,
                            label: wishlistCategoryLabel(c),
                            icon: wishlistCategoryIcon(c),
                            count: items.where((i) => i.category == c).length,
                          ),
                      ],
                      selected: category,
                      onChanged: (c) => setState(() => _category = c),
                    ),
                    const SizedBox(height: 12),
                    MaisonSearchRow(
                      controller: _search,
                      hint: 'Search your saved pieces',
                      onChanged: (_) => setState(() {}),
                      sortLabel: _sort.label,
                      sortActive: _sort != _WishSort.saved,
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
              visible: wishlist.isLoading && items.isNotEmpty,
            ),
            ..._body(context, wishlist, visible, width, gutter),
            // The list scrolls behind the floating dock; end clear of it.
            SliverToBoxAdapter(
              child: SizedBox(height: MediaQuery.paddingOf(context).bottom),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _body(
    BuildContext context,
    WishlistUiState wishlist,
    List<WishlistItem> visible,
    double width,
    double gutter,
  ) {
    Widget boxed(Widget child) => SliverPadding(
      padding: EdgeInsets.fromLTRB(gutter, 6, gutter, 32),
      sliver: SliverToBoxAdapter(child: MaisonCentered(child: child)),
    );

    final items = wishlist.items;
    if (wishlist.isLoading && items.isEmpty) {
      return [_skeletonGrid(width, gutter)];
    }
    if (wishlist.errorMessage != null && items.isEmpty) {
      return [
        boxed(
          AtelierErrorState(
            title: 'Wishlist unavailable',
            message: wishlist.errorMessage!,
            onRetry: _refresh,
          ),
        ),
      ];
    }
    if (items.isEmpty) {
      return [
        boxed(
          MaisonEmptyState(
            cut: GemCut.heart,
            title: context.tr(AccountCommerceL10n.wishlistEmpty),
            message: context.tr(AccountCommerceL10n.wishlistEmptyHint),
            actionLabel: 'Discover pieces',
            actionIcon: Icons.arrow_forward_rounded,
            onAction: () => context.switchToRoute(AppRouteNames.home),
          ),
        ),
      ];
    }
    if (visible.isEmpty) {
      return [
        boxed(
          AtelierEmptyState(
            icon: Icons.search_off_rounded,
            title: 'No matches',
            message: 'Nothing saved matches “${_search.text.trim()}”.',
            actionLabel: 'Clear search',
            onAction: () {
              _search.clear();
              setState(() => _category = null);
            },
          ),
        ),
      ];
    }

    final side = math.max(gutter, (width - 1040) / 2);
    final padding = EdgeInsets.fromLTRB(side, 10, side, 36);

    if (!_grid) {
      return [
        SliverPadding(
          padding: padding,
          sliver: SliverList.separated(
            itemCount: visible.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final item = visible[i];
              return Reveal(
                key: ValueKey('row-${item.id}'),
                index: i < 8 ? i : 0,
                child: WishlistPieceCard(
                  item: item,
                  compact: true,
                  onRemove: () => _remove(item),
                ),
              );
            },
          ),
        ),
      ];
    }

    final grid = _gridMetrics(width, side);
    return [
      SliverPadding(
        padding: padding,
        sliver: SliverGrid.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: grid.columns,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            mainAxisExtent: grid.extent,
          ),
          itemCount: visible.length,
          itemBuilder: (context, i) {
            final item = visible[i];
            return Reveal(
              key: ValueKey('tile-${item.id}'),
              index: i < 8 ? i : 0,
              child: WishlistPieceCard(
                item: item,
                onRemove: () => _remove(item),
              ),
            );
          },
        ),
      ),
    ];
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

  Widget _skeletonGrid(double width, double gutter) {
    final side = math.max(gutter, (width - 1040) / 2);
    final grid = _gridMetrics(width, side);
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(side, 10, side, 36),
      sliver: SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: grid.columns,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          mainAxisExtent: grid.extent,
        ),
        itemCount: grid.columns * 2,
        itemBuilder: (context, _) => const _SkeletonTile(),
      ),
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
            padding: EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 110, height: 12),
                SizedBox(height: 8),
                SkeletonBox(width: 70, height: 10),
                SizedBox(height: 14),
                SkeletonBox(width: 90, height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
