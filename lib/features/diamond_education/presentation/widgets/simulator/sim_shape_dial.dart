import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../core/audio/dial_sounds.dart';
import '../../../../../core/haptics/app_haptics.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/theme/luxe_tokens.dart';
import '../../../application/diamond_simulator_controller.dart';
import '../../../domain/diamond_grades.dart';
import '../../../domain/diamond_shape.dart';
import '../../../simulation/sim_morph.dart';
import '../../sim_labels.dart';
import 'diamond_sim_viewport.dart';
import 'sim_viewport_overlay.dart';

/// The ten shapes on a ring around the stone, turned like a jeweller's
/// dial: the shape at the top is the stone's. Turning it recuts the one
/// stone continuously from shape to shape ([SimShapeMorph]), never
/// swapping one stone for another. Every stop clicks into place with a
/// detent you feel and hear, with a soft ratchet tick between stops. Left
/// alone a moment, the ring fades back so the eye rests on the stone.
class SimShapeDial extends ConsumerStatefulWidget {
  const SimShapeDial({
    required this.viewport,
    required this.radius,
    required this.bottomInset,
    required this.onDone,
    super.key,
  });

  final SimViewportController viewport;

  /// Radius of the ring's centre line, logical pixels, around the centre
  /// of this widget (where the stone sits).
  final double radius;

  /// Clearance below the Done button (the device's bottom inset).
  final double bottomInset;

  /// Called once the dial has come to rest on a shape after Done.
  final VoidCallback onDone;

  /// Width of the ring's band.
  static const band = 50.0;

  @override
  ConsumerState<SimShapeDial> createState() => _SimShapeDialState();
}

class _SimShapeDialState extends ConsumerState<SimShapeDial>
    with SingleTickerProviderStateMixin {
  static const _shapes = SimShape.values;
  static final _n = _shapes.length;
  static final _step = 2 * math.pi / _n;

  /// Ratchet marks per stop; every fourth is a shape.
  static const _marks = 4;

  /// A firm, slightly lively spring: the dial settles with the barest
  /// overshoot, like a detent wheel.
  static final _spring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 130,
    ratio: 0.86,
  );

  late final DiamondSimulatorController _stone = ref.read(
    diamondSimulatorProvider.notifier,
  );

  /// Dial position in stops: shape `i % n` is at the top when it is i.
  late final AnimationController _dial = AnimationController.unbounded(
    vsync: this,
  );
  final _nearest = ValueNotifier<SimShape>(SimShape.round);

  /// The stone every other shape is cut from, and those cuts.
  DiamondSimulatorState? _base;
  final _stones = <SimShape, DiamondSimulatorState>{};

  /// Morphs from stop i to i + 1, by i mod n.
  final _pairs = <int, SimShapeMorph>{};
  int _generation = 0;

  double _prev = 0;
  int? _mark;
  Offset _center = Offset.zero;
  Offset? _last;
  bool _dim = false;
  bool _closing = false;
  Timer? _dimTimer;

  @override
  void initState() {
    super.initState();
    _rebase(ref.read(diamondSimulatorProvider));
    _dial
      ..addListener(_onTurn)
      ..addStatusListener(_onStatus);
    DialSounds.preload();
    _idle();
  }

  @override
  void dispose() {
    _generation++;
    _dimTimer?.cancel();
    _dial.dispose();
    _nearest.dispose();
    // Back to the selected stone, should the dial close mid-turn.
    widget.viewport.morph.value = null;
    super.dispose();
  }

  SimShape _shapeAt(int i) => _shapes[i % _n];

  DiamondSimulatorState _stoneAt(int i) {
    final shape = _shapeAt(i);
    return _stones[shape] ??= _stone.preview(shape, from: _base);
  }

  SimShapeMorph _pairAt(int i) =>
      _pairs[i % _n] ??= SimShapeMorph(_stoneAt(i).mesh, _stoneAt(i + 1).mesh);

  /// [x] wrapped into [−n/2, n/2): the shortest way round, in stops.
  static double _wrap(double x) => x - (x / _n + 0.5).floorToDouble() * _n;

  static double _wrapAngle(double a) =>
      a - (a / (2 * math.pi) + 0.5).floorToDouble() * 2 * math.pi;

  /// Starts over from [stone], e.g. after a reset: no turn, no sound.
  void _rebase(DiamondSimulatorState stone) {
    _generation++;
    _base = stone;
    _stones
      ..clear()
      ..[stone.spec.shape] = stone;
    _pairs.clear();
    final cur = _dial.value;
    final target = cur + _wrap(_shapes.indexOf(stone.spec.shape) - cur);
    _dial.stop();
    _prev = target;
    _mark = (target * _marks).round();
    _dial.value = target;
    _nearest.value = stone.spec.shape;
    widget.viewport.morph.value = null;
    WidgetsBinding.instance.addPostFrameCallback((_) => _warm());
  }

  /// Cuts the other shapes and their morphs ahead of use, nearest first,
  /// one per frame or so, so turning never waits on them.
  Future<void> _warm() async {
    final gen = _generation;
    final at = _dial.value.round();
    Future<bool> pause() async {
      await Future<void>.delayed(const Duration(milliseconds: 24));
      return mounted && gen == _generation;
    }

    for (var d = 1; d <= _n ~/ 2; d++) {
      for (final i in [at + d, at - d]) {
        if (!await pause()) return;
        _stoneAt(i);
      }
    }
    for (var d = 0; d < _n ~/ 2; d++) {
      for (final i in {at + d, at - d - 1}) {
        if (!await pause()) return;
        _pairAt(i);
      }
    }
  }

  /// Whether [s] is one of the dial's stones (so the dial chose it).
  bool _owns(DiamondSimulatorState s) => _stones.values.any(
    (c) => identical(c.mesh, s.mesh) && identical(c.spec, s.spec),
  );

  void _onTurn() {
    final p = _dial.value;
    _ticks(_prev, p);
    _prev = p;
    final near = _shapeAt(p.round());
    if (near != _nearest.value) _nearest.value = near;
    _publish(p);
  }

  /// Shows the stone at dial position [p]: at a stop, that shape; between
  /// stops, the one stone partway from one shape to the next. Eased so
  /// the shape holds near each stop and changes most between them.
  void _publish(double p) {
    final i = p.floor();
    final f = p - i;
    if (f < 1e-4 || f > 1 - 1e-4) {
      final s = _stoneAt(f < 0.5 ? i : i + 1);
      final current = ref.read(diamondSimulatorProvider);
      widget.viewport.morph.value =
          identical(s.mesh, current.mesh) && identical(s.spec, current.spec)
          ? null
          : SimMorphFrame.still(s);
      return;
    }
    widget.viewport.morph.value = SimMorphFrame(
      from: _stoneAt(i),
      to: _stoneAt(i + 1),
      t: f * f * (3 - 2 * f),
      morph: _pairAt(i),
    );
  }

  /// A click for every ratchet mark crossed: a firm detent (felt and
  /// heard) at a shape, a soft tick between. Many marks in one frame (a
  /// fast flick) sound once; rocking back over the same mark is silent.
  void _ticks(double prev, double cur) {
    final a = (prev * _marks).floor(), b = (cur * _marks).floor();
    if (a == b) return;
    final mark = b > a ? b : b + 1;
    if (mark == _mark) return;
    _mark = mark;
    final lo = math.min(a, b) + 1, hi = math.max(a, b);
    final stop = (hi / _marks).floor() * _marks >= lo;
    if (stop) {
      AppHaptics.detent();
      DialSounds.detent();
    } else {
      AppHaptics.selection();
      DialSounds.tick();
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    final k = _dial.value.round();
    if ((_dial.value - k).abs() > 1e-3) return;
    if (_dial.value != k) _dial.value = k.toDouble();
    _commit(k);
    _idle();
    if (_closing) widget.onDone();
  }

  /// Makes the shape at stop [k] the stone's.
  void _commit(int k) {
    _stone.commitShape(_stoneAt(k));
    widget.viewport.morph.value = null;
  }

  void _settleTo(double target, double velocity) {
    final p = _dial.value;
    final to = target.clamp(p - _n, p + _n).roundToDouble();
    if (to != p.roundToDouble()) _leaveScope();
    _dial.animateWith(SpringSimulation(_spring, p, to, velocity));
  }

  void _wake() {
    _dimTimer?.cancel();
    if (_dim) setState(() => _dim = false);
  }

  /// Fades the ring back after a moment untouched.
  void _idle() {
    _dimTimer?.cancel();
    _dimTimer = Timer(const Duration(milliseconds: 2600), () {
      if (mounted && !_dial.isAnimating) setState(() => _dim = true);
    });
  }

  void _onPanStart(DragStartDetails d) {
    _wake();
    _dial.stop();
    _last = d.localPosition;
    _leaveScope();
  }

  /// A scope only holds a round: a turn starts in daylight.
  void _leaveScope() {
    if (ref.read(diamondSimulatorProvider).lighting ==
        SimLighting.heartsArrows) {
      _stone.setHeartsArrows(false);
    }
  }

  void _onPanUpdate(DragUpdateDetails d) {
    final from = _last! - _center, to = d.localPosition - _center;
    _last = d.localPosition;
    // Too near the centre to tell which way it turns.
    if (from.distance < 12 || to.distance < 12) return;
    _dial.value -= _wrapAngle(to.direction - from.direction) / _step;
  }

  void _onPanEnd(DragEndDetails d) {
    final r = (_last ?? _center) - _center;
    final v = d.velocity.pixelsPerSecond;
    final r2 = r.distanceSquared;
    // Angular speed about the centre, then in stops per second.
    final omega = r2 < 144 ? 0.0 : (r.dx * v.dy - r.dy * v.dx) / r2;
    final speed = (-omega / _step).clamp(-26.0, 26.0);
    _settleTo(_dial.value + speed * 0.24, speed);
  }

  void _onTapUp(TapUpDetails d) {
    final at = d.localPosition - _center;
    if (at.distance < 12) return;
    final p = _dial.value;
    _settleTo(p + _wrapAngle(at.direction + math.pi / 2) / _step, 0);
    _idle();
  }

  void _turnBy(int stops) {
    _wake();
    _settleTo(_dial.value.roundToDouble() + stops, 0);
  }

  void _done() {
    if (_dial.isAnimating) {
      _closing = true;
      return;
    }
    _commit(_dial.value.round());
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    // A stone changed elsewhere (reset, another finger): start from it.
    ref.listen(diamondSimulatorProvider, (_, next) {
      if (!_owns(next)) _rebase(next);
    });
    final p = LuxePalette.of(context);
    final r = widget.radius;
    const band = SimShapeDial.band;

    return LayoutBuilder(
      builder: (context, constraints) {
        _center = constraints.biggest.center(Offset.zero);
        // Faded through its colours, never an opacity layer: an offscreen
        // pass every frame would compete with the stone's trace.
        Widget ring(double fade) => _Annulus(
          inner: r - band / 2 - 10,
          outer: r + band / 2 + 12,
          child: Listener(
            onPointerDown: (_) => _wake(),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              onTapUp: _onTapUp,
              child: RepaintBoundary(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: _RingPainter(
                        dial: _dial,
                        radius: r,
                        accent: p.accent,
                        count: _n,
                        marks: _marks,
                        fade: fade,
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _dial,
                      builder: (context, _) =>
                          Stack(children: _icons(p, r, fade)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: ValueListenableBuilder<SimShape>(
                valueListenable: _nearest,
                builder: (context, shape, child) => Semantics(
                  label: context.tr(EducationL10n.shape),
                  value: context.shapeName(shape),
                  increasedValue: context.shapeName(
                    _shapeAt(_shapes.indexOf(shape) + 1),
                  ),
                  decreasedValue: context.shapeName(
                    _shapeAt(_shapes.indexOf(shape) + _n - 1),
                  ),
                  onIncrease: () => _turnBy(1),
                  onDecrease: () => _turnBy(-1),
                  child: child,
                ),
                child: _Entrance(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: _dim ? 0.22 : 1),
                    duration: _dim
                        ? const Duration(milliseconds: 900)
                        : LuxeMotion.fast,
                    curve: Curves.easeOut,
                    builder: (context, fade, _) => ring(fade),
                  ),
                ),
              ),
            ),
            // The shape's name under the ring.
            Positioned(
              left: 16,
              right: 16,
              top: _center.dy + r + band / 2 + 12,
              child: IgnorePointer(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: _dim ? 0.35 : 1),
                  duration: _dim
                      ? const Duration(milliseconds: 900)
                      : LuxeMotion.fast,
                  builder: (context, fade, _) =>
                      ValueListenableBuilder<SimShape>(
                        valueListenable: _nearest,
                        builder: (context, shape, _) => AnimatedSwitcher(
                          duration: LuxeMotion.fast,
                          child: Text(
                            context.shapeName(shape),
                            key: ValueKey(shape),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: LuxeType.display(
                              20,
                              p.ink.withValues(alpha: p.ink.a * fade),
                            ),
                          ),
                        ),
                      ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: widget.bottomInset + 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SimGlassPill(
                    label: context.tr(EducationL10n.done),
                    selected: true,
                    palette: p,
                    height: 40,
                    onTap: _done,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Each shape on the ring, upright, growing and taking the accent as it
  /// nears the top.
  List<Widget> _icons(LuxePalette p, double r, double fade) {
    final pos = _dial.value;
    return [
      for (var s = 0; s < _n; s++)
        () {
          final rel = _wrap(s - pos);
          final a = -math.pi / 2 + rel * _step;
          final near = (1 - rel.abs()).clamp(0.0, 1.0);
          final size = 24 + 12 * near;
          final color = Color.lerp(
            p.ink.withValues(alpha: 0.62),
            p.accent,
            near,
          )!;
          final shown = color.withValues(alpha: color.a * fade);
          final c = _center + Offset(math.cos(a), math.sin(a)) * r;
          return Positioned(
            left: c.dx - size / 2,
            top: c.dy - size / 2,
            width: size,
            height: size,
            child: SvgPicture.asset(
              _shapes[s].svgAsset,
              colorFilter: ColorFilter.mode(shown, BlendMode.srcIn),
              placeholderBuilder: (_) => const SizedBox.shrink(),
            ),
          );
        }(),
    ];
  }
}

/// Fades and settles the ring in when the dial opens.
class _Entrance extends StatelessWidget {
  const _Entrance({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 460),
    curve: LuxeMotion.settle,
    child: child,
    builder: (context, v, child) => v >= 1
        ? child!
        : Opacity(
            opacity: v,
            child: Transform.scale(scale: 0.94 + 0.06 * v, child: child),
          ),
  );
}

/// The frosted band, its ratchet marks turning with the dial, and the
/// window at the top that holds the selected shape.
class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.dial,
    required this.radius,
    required this.accent,
    required this.count,
    required this.marks,
    required this.fade,
  }) : super(repaint: dial);

  final Animation<double> dial;
  final double radius;
  final Color accent;
  final int count, marks;

  /// 1 in full view, less as the ring fades back.
  final double fade;

  late final Paint _band = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = SimShapeDial.band
    ..color = Color.fromRGBO(16, 17, 20, 0.32 * fade);
  late final Paint _edge = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..color = Color.fromRGBO(255, 255, 255, 0.18 * fade);
  final Paint _mark = Paint()
    ..strokeWidth = 1.2
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    const half = SimShapeDial.band / 2;
    final step = 2 * math.pi / count;
    canvas
      ..drawCircle(c, radius, _band)
      ..drawCircle(c, radius + half, _edge)
      ..drawCircle(c, radius - half, _edge);

    // The window at the top: a soft accent glow across one stop.
    final window = Rect.fromCircle(center: c, radius: radius);
    canvas.drawArc(
      window,
      -math.pi / 2 - step * 0.42,
      step * 0.84,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = SimShapeDial.band - 8
        ..strokeCap = StrokeCap.round
        ..color = accent.withValues(alpha: 0.16 * fade),
    );
    // A pointer above the window.
    final tip = c + Offset(0, -radius - half + 1);
    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy + 2)
        ..lineTo(tip.dx - 6, tip.dy - 7)
        ..lineTo(tip.dx + 6, tip.dy - 7)
        ..close(),
      Paint()..color = accent.withValues(alpha: accent.a * fade),
    );

    // Ratchet marks along the outer edge, turning with the dial; the
    // shapes sit on every fourth.
    final pos = dial.value;
    final total = count * marks;
    for (var m = 0; m < total; m++) {
      if (m % marks == 0) continue;
      var rel = m / marks - pos;
      rel -= (rel / count + 0.5).floorToDouble() * count;
      final a = -math.pi / 2 + rel * step;
      final near = (1 - rel.abs() / 2).clamp(0.0, 1.0);
      final dir = Offset(math.cos(a), math.sin(a));
      _mark.color = Color.fromRGBO(255, 255, 255, (0.16 + 0.3 * near) * fade);
      canvas.drawLine(
        c + dir * (radius + half - 8),
        c + dir * (radius + half - 3),
        _mark,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.radius != radius ||
      old.accent != accent ||
      old.count != count ||
      old.marks != marks ||
      old.fade != fade ||
      old.dial != dial;
}

/// Takes touches only on the ring's band, so the stone inside it and the
/// stage outside it keep their own gestures.
class _Annulus extends SingleChildRenderObjectWidget {
  const _Annulus({required this.inner, required this.outer, super.child});

  final double inner, outer;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderAnnulus(inner, outer);

  @override
  void updateRenderObject(BuildContext context, _RenderAnnulus renderObject) {
    renderObject
      ..inner = inner
      ..outer = outer;
  }
}

class _RenderAnnulus extends RenderProxyBox {
  _RenderAnnulus(this.inner, this.outer);

  double inner, outer;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final d = (position - size.center(Offset.zero)).distance;
    if (d < inner || d > outer) return false;
    return super.hitTest(result, position: position);
  }
}
