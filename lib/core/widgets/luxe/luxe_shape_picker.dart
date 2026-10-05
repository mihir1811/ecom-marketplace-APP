import 'package:flutter/material.dart';

import '../../haptics/app_haptics.dart';
import '../../theme/luxe_tokens.dart';

/// One selectable shape: its filter value, display label and optional photo.
class LuxeShapeOption {
  const LuxeShapeOption({required this.value, required this.label, this.image});

  final String value;
  final String label;
  final String? image;
}

/// Draws a shape outline when no photo is available.
typedef LuxeShapeIconBuilder =
    Widget Function(String value, Color color, double size);

/// Multi-select shape picker: a swipeable strip of shapes that expands into
/// a centred grid. Selected shapes lift, gain an ink ring and a check mark.
class LuxeShapePicker extends StatefulWidget {
  const LuxeShapePicker({
    required this.shapes,
    required this.selected,
    required this.onToggle,
    required this.iconBuilder,
    required this.expandLabel,
    required this.collapseLabel,
    super.key,
  });

  final List<LuxeShapeOption> shapes;
  final List<String> selected;
  final ValueChanged<String> onToggle;
  final LuxeShapeIconBuilder iconBuilder;
  final String expandLabel;
  final String collapseLabel;

  @override
  State<LuxeShapePicker> createState() => _LuxeShapePickerState();
}

class _LuxeShapePickerState extends State<LuxeShapePicker> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);

    Widget tile(LuxeShapeOption shape, double width) => _ShapeTile(
      shape: shape,
      width: width,
      selected: widget.selected.contains(shape.value),
      iconBuilder: widget.iconBuilder,
      onTap: () => widget.onToggle(shape.value),
    );

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
              itemCount: widget.shapes.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) => tile(widget.shapes[i], 84),
            ),
          ),
          secondChild: LuxeShapeGrid(
            shapes: widget.shapes,
            selected: widget.selected,
            onToggle: widget.onToggle,
            iconBuilder: widget.iconBuilder,
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
              _showAll ? widget.collapseLabel : widget.expandLabel,
              style: LuxeType.label(p.accent, size: 12.5),
            ),
          ),
        ),
      ],
    );
  }
}

/// Every shape as a centred grid of cards, sized to fill the row.
class LuxeShapeGrid extends StatelessWidget {
  const LuxeShapeGrid({
    required this.shapes,
    required this.selected,
    required this.onToggle,
    required this.iconBuilder,
    super.key,
  });

  final List<LuxeShapeOption> shapes;
  final List<String> selected;
  final ValueChanged<String> onToggle;
  final LuxeShapeIconBuilder iconBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final columns = (constraints.maxWidth / 88).floor().clamp(3, 8);
        // Floor so rounding never pushes the last tile onto a new row.
        final w = ((constraints.maxWidth - gap * (columns - 1)) / columns)
            .floorToDouble();
        return Wrap(
          alignment: WrapAlignment.center,
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final s in shapes)
              _ShapeTile(
                shape: s,
                width: w,
                selected: selected.contains(s.value),
                iconBuilder: iconBuilder,
                onTap: () => onToggle(s.value),
              ),
          ],
        );
      },
    );
  }
}

class _ShapeTile extends StatelessWidget {
  const _ShapeTile({
    required this.shape,
    required this.width,
    required this.selected,
    required this.iconBuilder,
    required this.onTap,
  });

  final LuxeShapeOption shape;
  final double width;
  final bool selected;
  final LuxeShapeIconBuilder iconBuilder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final fallback = Center(child: iconBuilder(shape.value, p.inkMuted, 34));
    return Semantics(
      button: true,
      selected: selected,
      label: shape.label,
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
          // Expand so the column spans the whole tile and centres its
          // content instead of hugging the left edge.
          child: Stack(
            fit: StackFit.expand,
            children: [
              Column(
                children: [
                  Expanded(
                    child: AnimatedScale(
                      scale: selected ? 1.08 : 1,
                      duration: LuxeMotion.medium,
                      curve: LuxeMotion.settle,
                      child: shape.image == null
                          ? fallback
                          : Image.asset(
                              shape.image!,
                              fit: BoxFit.contain,
                              alignment: Alignment.center,
                              errorBuilder: (_, _, _) => fallback,
                            ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    shape.label,
                    textAlign: TextAlign.center,
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
