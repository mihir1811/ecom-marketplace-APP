import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../theme/luxe_tokens.dart';
import 'diamond_mesh.dart';
import 'diamond_transition_controller.dart';

/// Hosts the page area for [DiamondTransitionController].
///
/// The live page always stays mounted and painted inside a repaint
/// boundary (that is what gets captured); while a transition runs, an
/// opaque [CustomPaint] above it draws the gem and the page ignores
/// pointers. Only the overlay repaints per frame; nothing rebuilds.
class DiamondTabTransition extends StatefulWidget {
  const DiamondTabTransition({
    required this.controller,
    required this.child,
    super.key,
  });

  final DiamondTransitionController controller;
  final Widget child;

  @override
  State<DiamondTabTransition> createState() => _DiamondTabTransitionState();
}

class _DiamondTabTransitionState extends State<DiamondTabTransition> {
  final _boundary = GlobalKey();
  final _mesh = DiamondMesh();
  PageTransitionsTheme? _inner;
  PageTransitionsTheme? _held;

  @override
  void initState() {
    super.initState();
    widget.controller.capture = _capture;
  }

  @override
  void didUpdateWidget(DiamondTabTransition old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      if (old.controller.capture == _capture) old.controller.capture = null;
      widget.controller.capture = _capture;
    }
  }

  @override
  void dispose() {
    if (widget.controller.capture == _capture) widget.controller.capture = null;
    super.dispose();
  }

  DiamondSnapshot? _capture(double scale) {
    if (!mounted) return null;
    final box = _boundary.currentContext?.findRenderObject();
    if (box is! RenderRepaintBoundary || !box.attached || !box.hasSize) {
      return null;
    }
    if (box.size.isEmpty) return null;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final ratio = math.max(0.5, dpr * scale);
    return DiamondSnapshot(box.toImageSync(pixelRatio: ratio), ratio, box.size);
  }

  /// The ambient page transitions, held at rest while a switch is running.
  PageTransitionsTheme _transitions(PageTransitionsTheme inner) {
    if (_inner == inner && _held != null) return _held!;
    _inner = inner;
    final hold = widget.controller.suppressRouteTransitions;
    return _held = PageTransitionsTheme(
      builders: {
        for (final platform in TargetPlatform.values)
          platform: _HeldPageTransitions(
            inner.builders[platform] ?? const ZoomPageTransitionsBuilder(),
            hold,
          ),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = LuxePalette.of(context);
    final controller = widget.controller;
    final style = DiamondStyle(
      backdrop: palette.canvas,
      sheetBack: palette.surfaceRaised,
      accent: palette.accent,
      isDark: palette.isDark,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        ValueListenableBuilder<bool>(
          valueListenable: controller.active,
          builder: (context, active, page) =>
              IgnorePointer(ignoring: active, child: page),
          child: RepaintBoundary(
            key: _boundary,
            child: Theme(
              data: theme.copyWith(
                pageTransitionsTheme: _transitions(theme.pageTransitionsTheme),
              ),
              child: widget.child,
            ),
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: controller.active,
          builder: (context, active, _) => active
              ? RepaintBoundary(
                  child: CustomPaint(
                    isComplex: true,
                    willChange: true,
                    painter: _DiamondPainter(controller, _mesh, style),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _DiamondPainter extends CustomPainter {
  _DiamondPainter(this.controller, this.mesh, this.style)
    : super(repaint: controller);

  final DiamondTransitionController controller;
  final DiamondMesh mesh;
  final DiamondStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    if (!controller.isActive) {
      canvas.drawRect(Offset.zero & size, Paint()..color = style.backdrop);
      return;
    }
    mesh.paint(canvas, size, controller, style);
  }

  @override
  bool shouldRepaint(_DiamondPainter old) =>
      old.controller != controller || old.style != style;
}

/// Delegates to the app's page transition, but shows routes at rest while
/// [hold] is set: the incoming tab is captured settled, never mid-slide.
/// The widget structure is unchanged either way, so page state survives
/// the flag flipping.
class _HeldPageTransitions extends PageTransitionsBuilder {
  const _HeldPageTransitions(this.inner, this.hold);

  final PageTransitionsBuilder inner;
  final ValueListenable<bool> hold;

  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      inner.delegatedTransition;

  @override
  Duration get transitionDuration => inner.transitionDuration;

  @override
  Duration get reverseTransitionDuration => inner.reverseTransitionDuration;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final held = hold.value;
    return inner.buildTransitions(
      route,
      context,
      held ? kAlwaysCompleteAnimation : animation,
      held ? kAlwaysDismissedAnimation : secondaryAnimation,
      child,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is _HeldPageTransitions &&
      other.inner == inner &&
      other.hold == hold;

  @override
  int get hashCode => Object.hash(inner, hold);
}
