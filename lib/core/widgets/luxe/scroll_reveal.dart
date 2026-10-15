import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../theme/luxe_tokens.dart';

/// Builds content against a 0→1 reveal animation.
typedef RevealBuilder =
    Widget Function(BuildContext context, Animation<double> reveal);

/// Lets every [ScrollReveal] below replay its entrance each time it scrolls
/// back into view, arriving from the edge it enters through.
class ScrollRevealScope extends InheritedWidget {
  const ScrollRevealScope({
    required super.child,
    super.key,
    this.replay = true,
  });

  final bool replay;

  static bool replayOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ScrollRevealScope>()?.replay ??
      false;

  @override
  bool updateShouldNotify(ScrollRevealScope oldWidget) =>
      oldWidget.replay != replay;
}

/// Plays an entrance once its box scrolls into view.
///
/// The Flutter counterpart of a GSAP ScrollTrigger: it listens to the nearest
/// [Scrollable] and fires when the box crosses [threshold] of the viewport.
/// One-shot by default; under a replaying [ScrollRevealScope] it resets once
/// fully off screen and plays again from the side it re-enters, which
/// [ScrollReveal.directionOf] reports to builders. Respects the platform
/// "reduce motion" setting.
class ScrollReveal extends StatefulWidget {
  const ScrollReveal({
    required Widget this.child,
    super.key,
    this.delay = Duration.zero,
    this.offsetY = 28,
    this.duration = LuxeMotion.reveal,
    this.threshold = 0.92,
  }) : builder = null;

  const ScrollReveal.builder({
    required RevealBuilder this.builder,
    super.key,
    this.delay = Duration.zero,
    this.duration = LuxeMotion.reveal,
    this.threshold = 0.92,
  }) : child = null,
       offsetY = 0;

  final Widget? child;
  final RevealBuilder? builder;
  final Duration delay;
  final double offsetY;
  final Duration duration;
  final double threshold;

  /// 1 when the box enters from below, -1 when it enters from above.
  static double directionOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_RevealDirection>()?.sign ?? 1;

  @override
  State<ScrollReveal> createState() => _ScrollRevealState();
}

class _ScrollRevealState extends State<ScrollReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: LuxeMotion.settle,
  );
  ScrollPosition? _position;
  Timer? _delay;
  bool _triggered = false;
  bool _checkScheduled = false;
  bool _replay = false;
  double _sign = 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _replay = ScrollRevealScope.replayOf(context);
    if (MediaQuery.disableAnimationsOf(context)) {
      _triggered = true;
      _replay = false;
      _controller.value = 1;
      return;
    }
    // Items inside horizontal rails still reveal on the page's vertical scroll.
    var scrollable = Scrollable.maybeOf(context);
    while (scrollable != null &&
        axisDirectionToAxis(scrollable.axisDirection) != Axis.vertical) {
      scrollable = Scrollable.maybeOf(scrollable.context);
    }
    final next = scrollable?.position;
    if (next != _position) {
      _position?.removeListener(_scheduleCheck);
      _position = next;
      _position?.addListener(_scheduleCheck);
    }
    _scheduleCheck();
  }

  /// Measures after layout so positions reflect the latest scroll offset.
  void _scheduleCheck() {
    if ((_triggered && !_replay) || _checkScheduled) return;
    _checkScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScheduled = false;
      _check();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _check() {
    if (!mounted || (_triggered && !_replay)) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return;
    final top = box.localToGlobal(Offset.zero).dy;
    final bottom = top + box.size.height;
    final viewport = MediaQuery.sizeOf(context).height;
    if (_triggered) {
      // Fully off screen: rewind so the next pass plays again.
      if (bottom <= 0 || top >= viewport) {
        _triggered = false;
        _delay?.cancel();
        _controller.value = 0;
      }
      return;
    }
    final enters = _replay
        ? top < viewport * widget.threshold &&
              bottom > viewport * (1 - widget.threshold)
        : top < viewport * widget.threshold;
    if (!enters) return;
    _triggered = true;
    if (!_replay) _position?.removeListener(_scheduleCheck);
    // Scrolling toward the top brings content in from above.
    final sign =
        _replay && _position?.userScrollDirection == ScrollDirection.forward
        ? -1.0
        : 1.0;
    if (sign != _sign) setState(() => _sign = sign);
    _delay = Timer(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _delay?.cancel();
    _position?.removeListener(_scheduleCheck);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final builder = widget.builder;
    if (builder != null) {
      return _RevealDirection(
        sign: _sign,
        child: Builder(builder: (context) => builder(context, _curve)),
      );
    }
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) {
        final t = _curve.value;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * widget.offsetY * _sign),
            child: child,
          ),
        );
      },
    );
  }
}

class _RevealDirection extends InheritedWidget {
  const _RevealDirection({required this.sign, required super.child});

  final double sign;

  @override
  bool updateShouldNotify(_RevealDirection oldWidget) => oldWidget.sign != sign;
}
