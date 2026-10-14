import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../../theme/luxe_tokens.dart';

/// Drives the tab switch: the incoming page grows out of the touch point
/// on the bar and settles full screen on a lightly under-damped spring.
///
/// Nothing is captured or rasterised: the live page is clipped and scaled
/// directly, so a switch costs a clip and a transform per frame.
class TabRevealController {
  TabRevealController({required TickerProvider vsync})
    : _motion = AnimationController.unbounded(vsync: vsync) {
    _motion.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        active.value = false;
      }
    });
  }

  final AnimationController _motion;

  /// Slightly springy: a small overshoot, then a soft settle.
  static final _spring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 210,
    ratio: 0.68,
  );

  /// Where the finger touched, in global coordinates.
  Offset origin = Offset.zero;

  /// True while a reveal is running.
  final ValueNotifier<bool> active = ValueNotifier(false);

  /// Reveal progress: 0 at the touch point, 1 full screen (overshoots).
  Animation<double> get progress => _motion;

  /// Starts a reveal from [from] (global); call right before navigating.
  void reveal(Offset from) {
    origin = from;
    _motion.value = 0;
    active.value = true;
    _motion.animateWith(
      SpringSimulation(_spring, 0, 1, 0, tolerance: _tolerance),
    );
  }

  static const _tolerance = Tolerance(distance: 0.002, velocity: 0.02);

  /// Drops a running reveal (external navigation, reduced motion).
  void stop() {
    _motion.stop();
    _motion.value = 1;
    active.value = false;
  }

  void dispose() {
    _motion.dispose();
    active.dispose();
  }
}

/// Hosts the page area for [TabRevealController].
class TabRevealTransition extends StatefulWidget {
  const TabRevealTransition({
    required this.controller,
    required this.child,
    super.key,
  });

  final TabRevealController controller;
  final Widget child;

  @override
  State<TabRevealTransition> createState() => _TabRevealTransitionState();
}

class _TabRevealTransitionState extends State<TabRevealTransition> {
  PageTransitionsTheme? _inner;
  PageTransitionsTheme? _held;

  /// The ambient page transitions, held at rest while a reveal is running
  /// so the incoming route doesn't slide in on top of it.
  PageTransitionsTheme _transitions(PageTransitionsTheme inner) {
    if (_inner == inner && _held != null) return _held!;
    _inner = inner;
    final hold = widget.controller.active;
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
    final controller = widget.controller;
    final page = Theme(
      data: theme.copyWith(
        pageTransitionsTheme: _transitions(theme.pageTransitionsTheme),
      ),
      child: widget.child,
    );

    return ColoredBox(
      color: LuxePalette.of(context).canvas,
      child: ValueListenableBuilder<bool>(
        valueListenable: controller.active,
        child: page,
        builder: (context, active, page) => IgnorePointer(
          ignoring: active,
          child: _Reveal(
            progress: active ? controller.progress : kAlwaysCompleteAnimation,
            origin: active ? _local(controller.origin) : null,
            child: page!,
          ),
        ),
      ),
    );
  }

  Offset? _local(Offset global) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.globalToLocal(global);
  }
}

/// Clips [child] to a rounded blob growing from [origin] and scales it up
/// from there. Keeps the same widget structure at rest so page state is
/// never rebuilt when a reveal starts or ends.
class _Reveal extends AnimatedWidget {
  const _Reveal({
    required Animation<double> progress,
    required this.origin,
    required this.child,
  }) : super(listenable: progress);

  final Offset? origin;
  final Widget child;

  Animation<double> get _progress => listenable as Animation<double>;

  @override
  Widget build(BuildContext context) {
    final t = _progress.value;
    final at = origin;
    final resting = at == null;
    return ClipPath(
      clipper: resting ? null : _BlobClipper(at, t),
      clipBehavior: resting ? Clip.none : Clip.antiAlias,
      child: Transform(
        transform: resting ? Matrix4.identity() : _scale(at, t),
        child: Opacity(
          // The very first frames are a pinpoint: fade the content in so
          // it never pops.
          opacity: resting
              ? 1
              : Curves.easeOut.transform((t / 0.35).clamp(0.0, 1.0)),
          child: child,
        ),
      ),
    );
  }

  /// Grows from 0.86 at the touch point; the spring's overshoot swells it
  /// a touch past full size before it settles.
  static Matrix4 _scale(Offset at, double t) {
    final s = lerpDouble(0.86, 1, t)!;
    return Matrix4.translationValues(at.dx, at.dy, 0)
      ..scaleByDouble(s, s, 1, 1)
      ..translateByDouble(-at.dx, -at.dy, 0, 1);
  }
}

/// A rounded rect that starts as a small disc on the touch point, leans
/// upward (it rises out of the bar) and opens to the full page.
class _BlobClipper extends CustomClipper<Path> {
  _BlobClipper(this.origin, this.t);

  final Offset origin;
  final double t;

  static const _seed = 28.0;

  @override
  Path getClip(Size size) {
    final full = Offset.zero & size;
    final start = Rect.fromCircle(center: origin, radius: _seed);
    // Width trails height slightly, so the page reads as rising out of the
    // bar rather than inflating evenly.
    final w = t.clamp(0.0, 1.15);
    final h = math.min(1.15, t * 1.08);
    final rect = Rect.fromLTRB(
      lerpDouble(start.left, full.left, w)!,
      lerpDouble(start.top, full.top, h)!,
      lerpDouble(start.right, full.right, w)!,
      lerpDouble(start.bottom, full.bottom, w)!,
    );
    final radius = lerpDouble(
      _seed,
      0,
      t.clamp(0.0, 1.0),
    )!.clamp(0.0, rect.shortestSide / 2);
    final corner = Radius.circular(radius);
    return Path()..addRRect(RRect.fromRectAndRadius(rect, corner));
  }

  @override
  bool shouldReclip(_BlobClipper old) => old.origin != origin || old.t != t;
}

/// Delegates to the app's page transition, but shows routes at rest while
/// [hold] is set. The widget structure is unchanged either way, so page
/// state survives the flag flipping.
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
