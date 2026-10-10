import 'package:flutter/material.dart';

import '../../../../features/home/presentation/home_content.dart';
import '../../../haptics/app_haptics.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/luxe_tokens.dart';
import '../../app_network_image.dart';

/// The category menu, popped up above the bottom bar. Pushed on the root
/// [navigator], whose pages end at the bar, so it sits just above the bar's
/// Categories bubble, never full screen. Resolves to the picked category's
/// route, or null when dismissed.
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

  /// Clearance for the popped bubble that pokes up above the bar.
  static const _bubbleClearance = 44.0;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final open = CurvedAnimation(
      parent: animation,
      curve: LuxeMotion.settle,
      reverseCurve: Curves.easeInCubic,
    );
    const items = HomeContent.collections;

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
            padding: const EdgeInsets.fromLTRB(16, 0, 16, _bubbleClearance),
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
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 14),
                            child: Text(
                              context.tr(NavL10n.categories).toUpperCase(),
                              style: LuxeType.eyebrow(p.inkMuted),
                            ),
                          ),
                          GridView.count(
                            crossAxisCount: 3,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.8,
                            children: [
                              for (var i = 0; i < items.length; i++)
                                _CategoryTile(
                                  item: items[i],
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
              const SizedBox(height: 8),
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
