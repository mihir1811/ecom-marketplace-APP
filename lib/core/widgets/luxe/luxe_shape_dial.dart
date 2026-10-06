import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../haptics/app_haptics.dart';
import '../../theme/luxe_tokens.dart';
import 'luxe_shape_picker.dart';
import 'luxe_wheel.dart';

/// Jeweller's-loupe dial of shapes: an edge-to-edge carousel of shapes on
/// a [LuxeWheel], with a graduated ring round the centred shape that turns
/// as the wheel is swiped.
///
/// Pass [selected] for multi-select pickers: chosen shapes carry a check
/// and the ring turns gold while a chosen shape is centred. [onCentreTap]
/// fires for a tap on the centred shape; tapping a side shape turns the
/// wheel to it.
class LuxeShapeDial extends StatefulWidget {
  const LuxeShapeDial({
    required this.shapes,
    required this.onCentreTap,
    super.key,
    this.iconBuilder,
    this.selected,
    this.initialIndex = 0,
    this.onChanged,
    this.height = 250,
    this.bleed = 0,
  });

  final List<LuxeShapeOption> shapes;
  final ValueChanged<int> onCentreTap;
  final LuxeShapeIconBuilder? iconBuilder;
  final List<String>? selected;
  final int initialIndex;
  final ValueChanged<int>? onChanged;
  final double height;

  /// Extends the dial past the parent's horizontal padding so the shapes
  /// run to the edges of the enclosing card or screen.
  final double bleed;

  @override
  State<LuxeShapeDial> createState() => _LuxeShapeDialState();
}

class _LuxeShapeDialState extends State<LuxeShapeDial> {
  static const _fraction = 0.34;

  late final PageController _controller = PageController(
    viewportFraction: _fraction,
    initialPage: widget.initialIndex,
  );
  late int _current = widget.initialIndex;

  double get _page =>
      _controller.hasClients && _controller.position.haveDimensions
      ? _controller.page ?? _current.toDouble()
      : _current.toDouble();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapItem(int index) {
    if (index == _current) {
      widget.onCentreTap(index);
      return;
    }
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 650),
      curve: LuxeMotion.settle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final centred = widget.shapes[_current].value;
    final picked = widget.selected?.contains(centred) ?? false;
    return LayoutBuilder(
      builder: (context, constraints) {
        final inner = constraints.maxWidth;
        final width = inner + widget.bleed * 2;
        final height = widget.height;
        // Hugs the centred shape (one slot wide) with a slim margin.
        final diameter = math.min(height - 12, width * _fraction * 1.22);

        return SizedBox(
          width: inner,
          height: height,
          child: OverflowBox(
            minWidth: width,
            maxWidth: width,
            child: SizedBox(
              width: width,
              height: height,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Loupe ring: turns with the wheel, scroll-linked.
                  IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) => CustomPaint(
                        size: Size.square(diameter),
                        painter: _DialPainter(
                          rotation: _page * math.pi / 10,
                          accent: p.accent,
                          hairline: picked ? p.accent : p.hairline,
                        ),
                      ),
                    ),
                  ),
                  PageView.builder(
                    controller: _controller,
                    clipBehavior: Clip.none,
                    itemCount: widget.shapes.length,
                    onPageChanged: (i) {
                      AppHaptics.selection();
                      setState(() => _current = i);
                      widget.onChanged?.call(i);
                    },
                    itemBuilder: (context, i) => LuxeWheelItem(
                      controller: _controller,
                      index: i,
                      fallbackPage: _current.toDouble(),
                      child: LuxeWheelFocus(
                        controller: _controller,
                        index: i,
                        fallbackPage: _current.toDouble(),
                        // Neighbours stay recognisable: a hint of softness only.
                        sideBlur: 0.5,
                        sideOpacity: 0.9,
                        child: _ShapeItem(
                          shape: widget.shapes[i],
                          selected:
                              widget.selected?.contains(
                                widget.shapes[i].value,
                              ) ??
                              false,
                          iconBuilder: widget.iconBuilder,
                          onTap: () => _onTapItem(i),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ShapeItem extends StatelessWidget {
  const _ShapeItem({
    required this.shape,
    required this.selected,
    required this.iconBuilder,
    required this.onTap,
  });

  final LuxeShapeOption shape;
  final bool selected;
  final LuxeShapeIconBuilder? iconBuilder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final fallback = Center(
      child:
          iconBuilder?.call(shape.value, p.inkMuted, 56) ??
          Icon(Icons.diamond_outlined, color: p.inkMuted, size: 48),
    );
    return Semantics(
      button: true,
      selected: selected,
      label: shape.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              shape.image == null
                  ? fallback
                  : Image.asset(
                      shape.image!,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (_, _, _) => fallback,
                    ),
              Align(
                alignment: const Alignment(0.55, -0.7),
                child: AnimatedScale(
                  scale: selected ? 1 : 0,
                  duration: LuxeMotion.medium,
                  curve: Curves.easeOutBack,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.ink,
                    ),
                    child: Icon(Icons.check_rounded, size: 13, color: p.canvas),
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

/// Loupe ring of fine graduations; no plate, so the shapes sit straight on
/// the page.
class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.rotation,
    required this.accent,
    required this.hairline,
  });

  final double rotation;
  final Color accent;
  final Color hairline;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    canvas.drawCircle(
      c,
      r - 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = hairline,
    );
    final tick = Paint()
      ..strokeCap = StrokeCap.round
      ..color = accent.withValues(alpha: 0.7);
    for (var i = 0; i < 72; i++) {
      final a = rotation + i * math.pi * 2 / 72;
      final major = i % 6 == 0;
      tick.strokeWidth = major ? 1.4 : 0.8;
      final inner = r - (major ? 12 : 8);
      final u = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + u * inner, c + u * (r - 3), tick);
    }
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.rotation != rotation ||
      old.accent != accent ||
      old.hairline != hairline;
}

/// Multi-select finder picker on the [LuxeShapeDial]: swipe to a shape, then
/// tap it to add or remove it from the filter. With
/// [expandLabel] / [collapseLabel] a "view all" control swaps the dial for a
/// grid of every shape as cards.
class LuxeShapeDialPicker extends StatefulWidget {
  const LuxeShapeDialPicker({
    required this.shapes,
    required this.selected,
    required this.onToggle,
    super.key,
    this.iconBuilder,
    this.bleed = 18,
    this.expandLabel,
    this.collapseLabel,
  });

  final List<LuxeShapeOption> shapes;
  final List<String> selected;
  final ValueChanged<String> onToggle;
  final LuxeShapeIconBuilder? iconBuilder;
  final double bleed;
  final String? expandLabel;
  final String? collapseLabel;

  @override
  State<LuxeShapeDialPicker> createState() => _LuxeShapeDialPickerState();
}

class _LuxeShapeDialPickerState extends State<LuxeShapeDialPicker> {
  late int _current = math.max(
    0,
    widget.shapes.indexWhere((s) => widget.selected.contains(s.value)),
  );
  bool _showAll = false;

  void _toggle(int index) {
    AppHaptics.selection();
    widget.onToggle(widget.shapes[index].value);
  }

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final shape = widget.shapes[_current];
    final dial = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LuxeShapeDial(
          shapes: widget.shapes,
          selected: widget.selected,
          iconBuilder: widget.iconBuilder,
          initialIndex: _current,
          bleed: widget.bleed,
          height: 184,
          onChanged: (i) => setState(() => _current = i),
          onCentreTap: _toggle,
        ),
        const SizedBox(height: 4),
        AnimatedSwitcher(
          duration: LuxeMotion.medium,
          switchInCurve: LuxeMotion.settle,
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
            shape.label,
            key: ValueKey(shape.value),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: LuxeType.displayItalic(28, p.ink),
          ),
        ),
      ],
    );

    final expand = widget.expandLabel;
    if (expand == null) return dial;
    final collapse = widget.collapseLabel ?? expand;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedCrossFade(
          duration: LuxeMotion.medium,
          sizeCurve: LuxeMotion.settle,
          crossFadeState: _showAll
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: dial,
          secondChild: LuxeShapeGrid(
            shapes: widget.shapes,
            selected: widget.selected,
            onToggle: widget.onToggle,
            iconBuilder:
                widget.iconBuilder ??
                (_, color, size) =>
                    Icon(Icons.diamond_outlined, color: color, size: size),
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
              _showAll ? collapse : expand,
              style: LuxeType.label(p.accent, size: 12.5),
            ),
          ),
        ),
      ],
    );
  }
}
