import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/luxe_tokens.dart';

/// Builds content against a 0→1 reveal animation.
typedef RevealBuilder =
    Widget Function(BuildContext context, Animation<double> reveal);

/// Plays a one-shot entrance once its box scrolls into view.
///
/// The Flutter counterpart of a GSAP ScrollTrigger: it listens to the nearest
/// [Scrollable] and fires when the top edge crosses [threshold] of the
/// viewport height. Respects the platform "reduce motion" setting.
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _triggered = true;
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
    if (_triggered || _checkScheduled) return;
    _checkScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScheduled = false;
      _check();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _check() {
    if (_triggered || !mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return;
    final top = box.localToGlobal(Offset.zero).dy;
    final viewport = MediaQuery.sizeOf(context).height;
    if (top < viewport * widget.threshold) {
      _triggered = true;
      _position?.removeListener(_scheduleCheck);
      _delay = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
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
    if (builder != null) return builder(context, _curve);
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) {
        final t = _curve.value;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * widget.offsetY),
            child: child,
          ),
        );
      },
    );
  }
}
