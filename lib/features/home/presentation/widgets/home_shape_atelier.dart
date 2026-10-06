import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/luxe/luxe_shape_dial.dart';
import '../../../../core/widgets/luxe/luxe_shape_picker.dart';
import '../../../ai_chat/application/ai_pending_filters.dart';
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

  void _explore({bool labGrown = false}) {
    final filters = DiamondFilterState(
      shapes: [HomeContent.shapes[_current].name],
    );
    if (labGrown) {
      // The lab-grown catalog has its own scoped search state, created when
      // its route mounts; the listing applies these filters on arrival.
      ref.read(aiPendingDiamondFiltersProvider.notifier).state =
          AiPendingDiamondFilters(filters: filters, isLabGrown: true);
      context.openRoute(AppRouteNames.labGrownDiamondResults);
      return;
    }
    ref.read(diamondSearchProvider.notifier).replaceFilters(filters);
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
          const SizedBox(height: 6),
          Text(
            context.tr(HomeL10n.exploreShape, {'shape': shape}).toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: HomeType.eyebrow(palette.inkMuted),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: gutter),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Row(
                  children: [
                    Expanded(
                      child: _OriginButton(
                        label: context.tr(CatalogL10n.natural),
                        icon: Icons.diamond_outlined,
                        filled: true,
                        semanticLabel:
                            '${context.tr(CatalogL10n.natural)} · $shape',
                        onTap: _explore,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _OriginButton(
                        label: context.tr(CatalogL10n.labGrown),
                        icon: Icons.science_outlined,
                        filled: false,
                        semanticLabel:
                            '${context.tr(CatalogL10n.labGrown)} · $shape',
                        onTap: () => _explore(labGrown: true),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pill that opens the centred shape in the natural or lab-grown catalog.
class _OriginButton extends StatelessWidget {
  const _OriginButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.semanticLabel,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    final fg = filled ? palette.canvas : palette.ink;
    final style = ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(
        filled ? palette.ink : Colors.transparent,
      ),
      foregroundColor: WidgetStatePropertyAll(fg),
      overlayColor: WidgetStatePropertyAll(fg.withValues(alpha: 0.08)),
      shape: const WidgetStatePropertyAll(StadiumBorder()),
      side: WidgetStatePropertyAll(BorderSide(color: palette.ink, width: 1.2)),
      minimumSize: const WidgetStatePropertyAll(Size(0, 52)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 14),
      ),
    );
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: OutlinedButton(
        onPressed: onTap,
        style: style,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: fg),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: HomeType.label(fg, size: 14),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.arrow_forward_rounded, size: 16, color: fg),
          ],
        ),
      ),
    );
  }
}
