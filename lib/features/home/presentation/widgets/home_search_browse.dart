import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_names.dart';
import '../../../recently_viewed/application/recently_viewed_list_provider.dart';
import '../../../recently_viewed/domain/models/recently_viewed.dart';
import '../../../recently_viewed/presentation/widgets/recent/recent_piece.dart';
import '../../application/recent_searches_provider.dart';
import '../home_content.dart';
import '../theme/home_tokens.dart';

/// Drops [child] into place as the search route opens: it slides down from
/// above and fades in [order] beats after the route starts. Driven by the
/// route animation, so closing plays the same cascade in reverse.
class HomeSearchArrive extends StatelessWidget {
  const HomeSearchArrive({
    required this.animation,
    required this.order,
    required this.child,
    this.distance = 26,
    super.key,
  });

  final Animation<double> animation;
  final double order;
  final double distance;
  final Widget child;

  static const _lead = 0.1;
  static const _beat = 0.06;
  static const _span = 0.45;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final start = math.min(_lead + order * _beat, 1 - _span);
    final end = start + _span;
    final slide = animation.drive(
      CurveTween(curve: Interval(start, end, curve: HomeMotion.settle)),
    );
    final fade = animation.drive(
      CurveTween(curve: Interval(start, start + 0.25, curve: Curves.easeOut)),
    );
    return FadeTransition(
      opacity: fade,
      child: AnimatedBuilder(
        animation: slide,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, -distance * (1 - slide.value)),
          child: child,
        ),
        child: child,
      ),
    );
  }
}

/// Catalogue search's resting state: recent searches, diamond shapes,
/// recently viewed pieces and a stock / certificate number tip.
class HomeSearchBrowse extends ConsumerWidget {
  const HomeSearchBrowse({
    required this.animation,
    required this.onOpenRoute,
    required this.onSearch,
    super.key,
  });

  final Animation<double> animation;
  final ValueChanged<String> onOpenRoute;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(authProvider.select((s) => s.isAuthenticated));

    Widget arrive(double order, Widget child, {double distance = 26}) =>
        HomeSearchArrive(
          animation: animation,
          order: order,
          distance: distance,
          child: child,
        );

    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        14,
        16,
        32 + MediaQuery.paddingOf(context).bottom,
      ),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        arrive(3, _RecentSearchesCard(onSearch: onSearch)),
        arrive(5, _ShapesCard(onSearch: onSearch)),
        if (signedIn) arrive(6, _RecentCard(onOpenRoute: onOpenRoute)),
        const SizedBox(height: 12),
        arrive(7, const _NumberTip()),
      ],
    );
  }
}

class _BrowseCard extends StatelessWidget {
  const _BrowseCard({
    required this.eyebrow,
    required this.child,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 10),
  });

  final String eyebrow;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(HomeSpace.radius),
        border: Border.all(color: palette.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 28,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    eyebrow.toUpperCase(),
                    style: HomeType.eyebrow(palette.inkMuted),
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

/// What the buyer searched for lately, kept on this device. Tap to search
/// again; the cross forgets one entry. Hidden until there is history.
class _RecentSearchesCard extends ConsumerWidget {
  const _RecentSearchesCard({required this.onSearch});

  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = HomePalette.of(context);
    final searches = ref.watch(recentSearchesProvider);
    final notifier = ref.read(recentSearchesProvider.notifier);

    return AnimatedSize(
      duration: HomeMotion.medium,
      curve: HomeMotion.settle,
      alignment: Alignment.topCenter,
      child: searches.isEmpty
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _BrowseCard(
                eyebrow: context.tr(HomeL10n.recentSearchesEyebrow),
                padding: const EdgeInsets.fromLTRB(16, 10, 6, 6),
                trailing: TextButton(
                  onPressed: () {
                    AppHaptics.light();
                    notifier.clear();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: palette.accent,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(
                    context.tr(CatalogL10n.clearAll),
                    style: HomeType.label(palette.accent),
                  ),
                ),
                child: Column(
                  children: [
                    for (final query in searches)
                      _RecentSearchRow(
                        key: ValueKey(query),
                        query: query,
                        onTap: () => onSearch(query),
                        onRemove: () {
                          AppHaptics.selection();
                          notifier.remove(query);
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _RecentSearchRow extends StatelessWidget {
  const _RecentSearchRow({
    required this.query,
    required this.onTap,
    required this.onRemove,
    super.key,
  });

  final String query;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(HomeSpace.radiusSmall),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Row(
          children: [
            Icon(Icons.history_rounded, size: 19, color: palette.inkFaint),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                query,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: HomeType.body(palette.ink, size: 14),
              ),
            ),
            IconButton(
              tooltip: context.tr(HomeL10n.removeRecentSearch),
              onPressed: onRemove,
              visualDensity: VisualDensity.compact,
              icon: Icon(
                Icons.close_rounded,
                size: 18,
                color: palette.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Diamond shapes; picking one searches the catalogue for it.
class _ShapesCard extends StatelessWidget {
  const _ShapesCard({required this.onSearch});

  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    const shapes = HomeContent.shapes;
    return _BrowseCard(
      eyebrow: context.tr(HomeL10n.searchShapesEyebrow),
      padding: const EdgeInsets.fromLTRB(16, 16, 0, 14),
      child: SizedBox(
        height: 86,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsetsDirectional.only(end: 16),
          itemCount: shapes.length,
          separatorBuilder: (_, _) => const SizedBox(width: 6),
          itemBuilder: (context, i) => InkWell(
            onTap: () => onSearch(shapes[i].name),
            borderRadius: BorderRadius.circular(HomeSpace.radiusSmall),
            child: SizedBox(
              width: 64,
              child: Column(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: palette.canvas,
                      border: Border.all(color: palette.hairline),
                    ),
                    child: Image.asset(
                      shapes[i].image,
                      fit: BoxFit.contain,
                      cacheWidth: 120,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    shapes[i].name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HomeType.label(palette.inkMuted, size: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The buyer's latest viewed pieces. Grows into place once loaded so the
/// tip below eases down instead of jumping.
class _RecentCard extends ConsumerWidget {
  const _RecentCard({required this.onOpenRoute});

  final ValueChanged<String> onOpenRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = HomePalette.of(context);
    final entries =
        ref.watch(recentlyViewedListProvider).valueOrNull?.items ??
        const <RecentlyViewedEntry>[];
    final visible = entries.take(10).toList();

    return AnimatedSize(
      duration: HomeMotion.medium,
      curve: HomeMotion.settle,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: HomeMotion.medium,
        child: visible.isEmpty
            ? const SizedBox(width: double.infinity)
            : Padding(
                key: const ValueKey('recent'),
                padding: const EdgeInsets.only(top: 12),
                child: _BrowseCard(
                  eyebrow: context.tr(AccountCommerceL10n.recentlyViewed),
                  padding: const EdgeInsets.fromLTRB(16, 10, 0, 14),
                  trailing: TextButton(
                    onPressed: () =>
                        onOpenRoute(AppRouteNames.buyerRecentlyViewed),
                    style: TextButton.styleFrom(
                      foregroundColor: palette.accent,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(
                      context.tr(RemainingL10n.viewAll),
                      style: HomeType.label(palette.accent),
                    ),
                  ),
                  child: SizedBox(
                    height: _RecentTile.height(context),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsetsDirectional.only(end: 16),
                      itemCount: visible.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, i) =>
                          _RecentTile(entry: visible[i]),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _RecentTile extends ConsumerWidget {
  const _RecentTile({required this.entry});

  final RecentlyViewedEntry entry;

  /// Image + gaps + both text lines at the current text scale, so larger
  /// system fonts never overflow the strip.
  static double height(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final palette = HomePalette.of(context);
    double line(TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: 'Ag', style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final h = painter.height;
      painter.dispose();
      return h;
    }

    return 100 +
        7 +
        line(HomeType.label(palette.ink)) +
        2 +
        line(HomeType.body(palette.inkMuted, size: 12)) +
        4;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = HomePalette.of(context);
    return SizedBox(
      width: 100,
      child: InkWell(
        onTap: () {
          AppHaptics.light();
          openRecentPiece(context, ref, entry);
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox.square(
                dimension: 100,
                child: RecentPieceImage(
                  entry: entry,
                  iconSize: 24,
                  memCacheWidth: 300,
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              entry.listTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: HomeType.label(palette.ink),
            ),
            const SizedBox(height: 2),
            Text(
              entry.priceLabel ?? entry.typeLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: HomeType.body(palette.inkMuted, size: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberTip extends StatelessWidget {
  const _NumberTip();

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.accentSoft,
        borderRadius: BorderRadius.circular(HomeSpace.radius),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.surface,
            ),
            child: Icon(Icons.tag_rounded, size: 20, color: palette.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(HomeL10n.searchTipTitle),
                  style: HomeType.label(palette.ink, size: 14),
                ),
                const SizedBox(height: 3),
                Text(
                  context.tr(HomeL10n.searchTipBody),
                  style: HomeType.body(palette.inkMuted, size: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
