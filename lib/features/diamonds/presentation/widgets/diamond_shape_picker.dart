import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../application/diamond_search_provider.dart';
import 'diamond_svg_data.dart';

/// Multi-select shape picker: a swipeable strip of shapes that expands into
/// a full grid. Selected shapes lift, gain an ink ring and a check mark.
class DiamondShapePicker extends ConsumerStatefulWidget {
  const DiamondShapePicker({super.key});

  @override
  ConsumerState<DiamondShapePicker> createState() => _DiamondShapePickerState();
}

class _DiamondShapePickerState extends ConsumerState<DiamondShapePicker> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final selected = ref.watch(diamondSearchProvider.select((s) => s.shapes));
    final notifier = ref.read(diamondSearchProvider.notifier);

    Widget tile(Map<String, String> shape, {double width = 84}) {
      final name = shape['name']!;
      return _ShapeTile(
        name: name,
        image: shape['image'],
        width: width,
        selected: selected.contains(name),
        onTap: () => notifier.toggleShape(name),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedCrossFade(
          duration: LuxeMotion.medium,
          sizeCurve: LuxeMotion.settle,
          crossFadeState: _showAll
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: SizedBox(
            height: 112,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: kAllShapes.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) => tile(kAllShapes[i]),
            ),
          ),
          secondChild: LayoutBuilder(
            builder: (context, constraints) {
              const gap = 8.0;
              final columns = (constraints.maxWidth / 88).floor().clamp(3, 8);
              final w = (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [for (final s in kAllShapes) tile(s, width: w)],
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {
              AppHaptics.selection();
              setState(() => _showAll = !_showAll);
            },
            style: TextButton.styleFrom(foregroundColor: p.accent),
            icon: AnimatedRotation(
              turns: _showAll ? 0.5 : 0,
              duration: LuxeMotion.medium,
              child: const Icon(Icons.expand_more_rounded, size: 18),
            ),
            label: Text(
              context.tr(
                _showAll
                    ? DiamondFlowL10n.fewerShapes
                    : DiamondFlowL10n.allShapes,
              ),
              style: LuxeType.label(p.accent, size: 12.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _ShapeTile extends StatelessWidget {
  const _ShapeTile({
    required this.name,
    required this.image,
    required this.width,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final String? image;
  final double width;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final fallback = renderShapeSvg(name, size: 34, color: p.inkMuted);
    return Semantics(
      button: true,
      selected: selected,
      label: name,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          AppHaptics.selection();
          onTap();
        },
        child: AnimatedContainer(
          duration: LuxeMotion.medium,
          curve: LuxeMotion.settle,
          width: width,
          height: 104,
          padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
          decoration: BoxDecoration(
            color: selected ? p.surface : p.surfaceRaised,
            borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall + 2),
            border: Border.all(
              color: selected ? p.ink : Colors.transparent,
              width: 1.3,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: p.isDark ? 0.4 : 0.08,
                      ),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : const [],
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: AnimatedScale(
                      scale: selected ? 1.08 : 1,
                      duration: LuxeMotion.medium,
                      curve: LuxeMotion.settle,
                      child: image == null
                          ? fallback
                          : Image.asset(
                              image!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => fallback,
                            ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LuxeType.label(
                      selected ? p.ink : p.inkMuted,
                      size: 11.5,
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 0,
                right: 0,
                child: AnimatedScale(
                  scale: selected ? 1 : 0,
                  duration: LuxeMotion.medium,
                  curve: Curves.easeOutBack,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.ink,
                    ),
                    child: Icon(Icons.check_rounded, size: 12, color: p.canvas),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
