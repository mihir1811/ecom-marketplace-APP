import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/luxe/luxe_shape_dial.dart';
import '../../../../core/widgets/luxe/luxe_shape_picker.dart';
import '../../../diamonds/application/diamond_search_provider.dart';
import '../../../diamonds/domain/models/diamond_filter_state.dart';
import '../home_content.dart';
import '../theme/home_tokens.dart';
import 'home_section.dart';
import '../../../../core/widgets/luxe/scroll_reveal.dart';

/// Dial of diamond shapes; turn the knob or swipe, the centred shape opens
/// matching results.
class HomeShapeAtelier extends ConsumerStatefulWidget {
  const HomeShapeAtelier({super.key});

  @override
  ConsumerState<HomeShapeAtelier> createState() => _HomeShapeAtelierState();
}

class _HomeShapeAtelierState extends ConsumerState<HomeShapeAtelier> {
  static const _initial = 1;
  int _current = _initial;

  void _explore() {
    final shape = HomeContent.shapes[_current].name;
    ref
        .read(diamondSearchProvider.notifier)
        .replaceFilters(DiamondFilterState(shapes: [shape]));
    context.openRoute(AppRouteNames.diamondResults);
  }

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    final gutter = homeGutter(context);
    final shape = HomeContent.shapes[_current].name;

    return Padding(
      padding: const EdgeInsets.only(top: HomeSpace.section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: gutter),
            child: HomeSectionHeading(
              index: '03',
              eyebrow: context.tr(HomeL10n.shapesEyebrow),
              title: context.tr(HomeL10n.shapesTitle),
            ),
          ),
          const SizedBox(height: 12),
          ScrollReveal(
            child: LuxeShapeDial(
              shapes: [
                for (final s in HomeContent.shapes)
                  LuxeShapeOption(value: s.name, label: s.name, image: s.image),
              ],
              initialIndex: _initial,
              onChanged: (i) => setState(() => _current = i),
              onCentreTap: (_) => _explore(),
            ),
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: HomeMotion.medium,
            switchInCurve: HomeMotion.settle,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: Text(
              shape,
              key: ValueKey(shape),
              textAlign: TextAlign.center,
              style: HomeType.displayItalic(32, palette.ink),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton(
              onPressed: _explore,
              style: FilledButton.styleFrom(
                backgroundColor: palette.ink,
                foregroundColor: palette.canvas,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 26,
                  vertical: 16,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      context.tr(HomeL10n.exploreShape, {'shape': shape}),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: HomeType.label(palette.canvas, size: 14),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
