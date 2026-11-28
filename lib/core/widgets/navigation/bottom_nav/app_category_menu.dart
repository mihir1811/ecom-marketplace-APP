import 'package:flutter/material.dart';

import '../../../../features/home/presentation/home_content.dart';
import '../../../haptics/app_haptics.dart';
import '../../../l10n/app_localizations.dart';
import '../../../router/route_names.dart';
import '../../../theme/luxe_tokens.dart';
import '../../app_network_image.dart';

/// The category menu, popped up above the bottom bar. Pushed on the root
/// [navigator], whose pages run behind the floating dock with their bottom
/// padding clearing it, so the menu sits just above the dock's Categories
/// bubble, never under it. Resolves to the picked category's route, or null
/// when dismissed.
///
/// No barrier colour: the bar keeps its own look (its Categories bubble
/// stays popped) and the page behind dims under [_CategoryMenu]'s scrim.
class AppCategoryMenuRoute extends PopupRoute<String> {
  AppCategoryMenuRoute._({
    required this.barrierLabel,
    required this.disableAnimations,
  });

  factory AppCategoryMenuRoute.of(NavigatorState navigator) {
    final context = navigator.context;
    return AppCategoryMenuRoute._(
      barrierLabel: context.tr(NavL10n.closeCategories),
      disableAnimations: MediaQuery.disableAnimationsOf(context),
    );
  }

  final bool disableAnimations;

  @override
  final String barrierLabel;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  Duration get transitionDuration =>
      disableAnimations ? Duration.zero : LuxeMotion.medium;

  @override
  Duration get reverseTransitionDuration =>
      disableAnimations ? Duration.zero : LuxeMotion.fast;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => _CategoryMenu(animation: animation);
}

class _CategoryMenu extends StatelessWidget {
  const _CategoryMenu({required this.animation});

  final Animation<double> animation;

  /// Room for the popped bubble that pokes up above the dock, on top of the
  /// page padding that already clears the dock itself.
  static const _bubbleClearance = 40.0;

  static const _gridCount = 6;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final open = CurvedAnimation(
      parent: animation,
      curve: LuxeMotion.settle,
      reverseCurve: Curves.easeInCubic,
    );
    const items = HomeContent.collections;
    // Six worlds fill the 3 × 2 grid; any more get a full-width row each.
    final grid = items.take(_gridCount).toList();
    final rows = items.skip(_gridCount).toList();
    final padding = MediaQuery.paddingOf(context);

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).maybePop(),
            child: FadeTransition(
              opacity: animation,
              child: ColoredBox(
                color: Colors.black.withValues(alpha: p.isDark ? 0.5 : 0.28),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              12,
              padding.top + 12,
              12,
              padding.bottom + _bubbleClearance,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              // Grows out of the Categories bubble below it.
              child: AnimatedBuilder(
                animation: open,
                builder: (context, child) => Opacity(
                  opacity: animation.value.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, 28 * (1 - open.value)),
                    child: Transform.scale(
                      scale: 0.82 + 0.18 * open.value,
                      alignment: Alignment.bottomCenter,
                      child: child,
                    ),
                  ),
                ),
                child: Material(
                  color: p.surface,
                  elevation: 0,
                  borderRadius: BorderRadius.circular(LuxeSpace.radius + 6),
                  clipBehavior: Clip.antiAlias,
                  shadowColor: Colors.transparent,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: p.hairline, width: 0.8),
                      borderRadius: BorderRadius.circular(LuxeSpace.radius + 6),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 10),
                            child: Text(
                              context.tr(NavL10n.categories).toUpperCase(),
                              style: LuxeType.eyebrow(p.inkMuted),
                            ),
                          ),
                          // Short screens scroll the grid instead of
                          // pushing it under the dock.
                          Flexible(
                            child: GridView.count(
                              crossAxisCount: 3,
                              shrinkWrap: true,
                              physics: const ClampingScrollPhysics(),
                              padding: EdgeInsets.zero,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 8,
                              childAspectRatio: 0.8,
                              children: [
                                for (var i = 0; i < grid.length; i++)
                                  _CategoryTile(
                                    item: grid[i],
                                    reveal: CurvedAnimation(
                                      parent: animation,
                                      curve: Interval(
                                        0.15 + i * 0.07,
                                        (0.6 + i * 0.07).clamp(0.0, 1.0),
                                        curve: LuxeMotion.settle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          for (final item in rows) ...[
                            const SizedBox(height: 10),
                            _CollectionRow(
                              item: item,
                              reveal: CurvedAnimation(
                                parent: animation,
                                curve: const Interval(
                                  0.25,
                                  1,
                                  curve: LuxeMotion.settle,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          _LiveShowsRow(
                            reveal: CurvedAnimation(
                              parent: animation,
                              curve: const Interval(
                                0.3,
                                1,
                                curve: LuxeMotion.settle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.item, required this.reveal});

  final HomeCollection item;
  final Animation<double> reveal;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final title = context.tr(item.titleKey);
    final cacheWidth = (120 * MediaQuery.devicePixelRatioOf(context)).round();

    return AnimatedBuilder(
      animation: reveal,
      builder: (context, child) => Opacity(
        opacity: reveal.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - reveal.value)),
          child: child,
        ),
      ),
      child: Semantics(
        button: true,
        label: title,
        excludeSemantics: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall),
          onTap: () {
            AppHaptics.selection();
            Navigator.of(context).pop(item.route);
          },
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall),
                  child: ColoredBox(
                    color: p.surfaceRaised,
                    child: SizedBox.expand(
                      child: AppNetworkImage(
                        url: item.imageUrl,
                        memCacheWidth: cacheWidth,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: LuxeType.label(p.ink, size: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A catalogue world past the grid (rough diamonds): thumbnail, title and
/// chevron on one row, styled like the live shows row.
class _CollectionRow extends StatelessWidget {
  const _CollectionRow({required this.item, required this.reveal});

  final HomeCollection item;
  final Animation<double> reveal;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final title = context.tr(item.titleKey);
    final cacheWidth = (40 * MediaQuery.devicePixelRatioOf(context)).round();

    return FadeTransition(
      opacity: reveal,
      child: Semantics(
        button: true,
        label: title,
        excludeSemantics: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall),
          onTap: () {
            AppHaptics.selection();
            Navigator.of(context).pop(item.route);
          },
          child: Ink(
            padding: const EdgeInsets.fromLTRB(6, 6, 10, 6),
            decoration: BoxDecoration(
              color: p.surfaceRaised,
              borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall),
              border: Border.all(color: p.hairline, width: 0.8),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(
                    LuxeSpace.radiusSmall - 2,
                  ),
                  child: SizedBox.square(
                    dimension: 36,
                    child: AppNetworkImage(
                      url: item.imageUrl,
                      memCacheWidth: cacheWidth,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LuxeType.label(p.ink, size: 13),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 20, color: p.inkMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Live shows sit beside the categories so every viewer, signed in or not,
/// reaches them from the dock.
class _LiveShowsRow extends StatelessWidget {
  const _LiveShowsRow({required this.reveal});

  final Animation<double> reveal;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final title = context.tr(NavL10n.liveShows);

    return FadeTransition(
      opacity: reveal,
      child: Semantics(
        button: true,
        label: title,
        excludeSemantics: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall),
          onTap: () {
            AppHaptics.selection();
            Navigator.of(context).pop(AppRouteNames.liveShows);
          },
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: p.surfaceRaised,
              borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall),
              border: Border.all(color: p.hairline, width: 0.8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.live_tv_outlined,
                  size: 20,
                  color: Color(0xFFFF3D57),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LuxeType.label(p.ink, size: 13),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 20, color: p.inkMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
