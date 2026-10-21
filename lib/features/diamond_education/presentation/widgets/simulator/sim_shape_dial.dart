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
import '../../../simulation/sim_fancy.dart';
import '../../../simulation/sim_morph.dart';
import '../../../simulation/sim_shape_line.dart';
import '../../sim_labels.dart';
import 'diamond_sim_viewport.dart';
import 'sim_viewport_overlay.dart';

/// The ten shapes on a ring around the stone, turned like a jeweller's
/// dial: the shape at the top is the stone's. Turning it recuts the one
/// stone continuously from shape to shape ([SimShapeMorph]), never
/// swapping one stone for another. Every stop clicks into place with a
/// detent you feel and hear, with a soft ratchet tick between stops. Left
/// alone a moment, the ring fades back so the eye rests on the stone.
///
/// Show more shapes opens the ring at the top, spreads it across the
/// screen and sets it down along the bottom as a half ring of every
/// shape, the classic ten among the fancy cuts ([SimShapeLine]), the
/// stone's shape at its centre and the stone above it. Fancy cuts are
/// shown as cut, as on the fancy shapes slider: only a classic shape
/// becomes the stone's.
class SimShapeDial extends ConsumerStatefulWidget {
  const SimShapeDial({
    required this.viewport,
    required this.radius,
    required this.bottomInset,
    required this.onDone,
    this.onMoreShapes,
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

  /// Called as the half ring of every shape starts to open (true) or to
  /// close (false), so the stone can make way above it.
  final ValueChanged<bool>? onMoreShapes;

  /// Width of the ring's band.
  static const band = 50.0;

  /// Bottom of the stone's room above the half ring, in a dial of [size].
  static double halfRingTop(Size size, double bottomInset) =>
      _Arc(size, bottomInset).searchTop - 6;

  @override
  ConsumerState<SimShapeDial> createState() => _SimShapeDialState();
}

class _SimShapeDialState extends ConsumerState<SimShapeDial>
    with TickerProviderStateMixin {
  static const _shapes = SimShape.values;
  static final _n = _shapes.length;
  static final _step = 2 * math.pi / _n;

  /// How slowly the ring fades back when left alone.
  static const _fadeBack = Duration(milliseconds: 1800);

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

  /// Half ring position in shapes along [_line]: shape i is at the centre
  /// when it is i.
  late final AnimationController _arc = AnimationController.unbounded(
    vsync: this,
  );

  /// 0 the ring, 1 the half ring.
  late final AnimationController _open = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1150),
    reverseDuration: const Duration(milliseconds: 950),
  );
  late final Listenable _motion = Listenable.merge([_dial, _arc, _open]);
  final _nearest = ValueNotifier<SimLineShape>(
    const SimLineShape.classic(SimShape.round),
  );

  /// The stone every other shape is cut from, and those cuts.
  DiamondSimulatorState? _base;
  final _stones = <SimShape, DiamondSimulatorState>{};

  /// Morphs from stop i to i + 1, by i mod n.
  final _pairs = <int, SimShapeMorph>{};
  int _generation = 0;

  /// Every shape on the half ring, once the fancy cuts have loaded; the
  /// fancy cuts as cut from [_base], and the morphs from i to i + 1.
  List<SimLineShape> _line = const [];
  final _fancyStones = <int, DiamondSimulatorState>{};
  final _linePairs = <int, SimShapeMorph>{};

  /// Whether the half ring is wanted (opening or open), and whether it is
  /// the half ring that turns the stone (from opening until it has closed).
  bool _more = false;
  bool _arcMode = false;

  double _prev = 0, _arcPrev = 0;
  int? _mark, _arcMark;
  Offset _center = Offset.zero;
  Size _size = Size.zero;
  Offset? _last;
  bool _dim = false;
  bool _closing = false;
  Timer? _dimTimer;

  /// The half ring's search: typed names are looked up a moment after the
  /// last key, and the half ring turns there.
  final _query = TextEditingController();
  final _queryFocus = FocusNode();
  Timer? _searchTimer;
  bool _missed = false;

  /// Turning on its own to a searched shape: detents only, no ticks.
  bool _gliding = false;

  @override
  void initState() {
    super.initState();
    _rebase(ref.read(diamondSimulatorProvider));
    _dial
      ..addListener(_onTurn)
      ..addStatusListener(_onStatus);
    _arc
      ..addListener(_onArc)
      ..addStatusListener(_onArcStatus);
    _open.addStatusListener((s) {
      if (s == AnimationStatus.dismissed) _maybeLeaveArc();
    });
    DialSounds.preload();
    final ready = SimFancyCatalog.loaded;
    if (ready != null) {
      _line = SimShapeLine.of(ready);
    } else {
      SimFancyCatalog.load().then((shapes) {
        if (mounted) setState(() => _line = SimShapeLine.of(shapes));
      });
    }
    _idle();
  }

  @override
  void dispose() {
    _generation++;
    _dimTimer?.cancel();
    _searchTimer?.cancel();
    _query.dispose();
    _queryFocus.dispose();
    _dial.dispose();
    _arc.dispose();
    _open.dispose();
    _nearest.dispose();
    // Back to the selected stone, should the dial close mid-turn or on a
    // fancy cut.
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

  /// Where the classic shapes start on [_line].
  int get _classicStart => _line.indexWhere((s) => s.classic != null);

  int _lineIndexOf(SimShape shape) =>
      _line.indexWhere((s) => s.classic == shape);

  DiamondSimulatorState _lineStone(int j) {
    final s = _line[j];
    if (s.classic != null) return _stoneAt(_shapes.indexOf(s.classic!));
    // As the fancy shapes slider shows them: the stone's colour and
    // weight, no clarity characteristics.
    return _fancyStones[j] ??= _base!.copyWith(
      mesh: s.fancy!.mesh,
      inclusions: const [],
    );
  }

  SimShapeMorph _linePair(int j) {
    final a = _line[j].classic, b = _line[j + 1].classic;
    // Classic neighbours on the line are dial neighbours, in dial order.
    if (a != null && b != null) return _pairAt(_shapes.indexOf(a));
    return _linePairs[j] ??= SimShapeMorph(
      _lineStone(j).mesh,
      _lineStone(j + 1).mesh,
    );
  }

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
    _fancyStones.clear();
    _linePairs.clear();
    final cur = _dial.value;
    final target = cur + _wrap(_shapes.indexOf(stone.spec.shape) - cur);
    _dial.stop();
    _prev = target;
    _mark = (target * _marks).round();
    _dial.value = target;
    _nearest.value = SimLineShape.classic(stone.spec.shape);
    if (_arcMode && _line.isNotEmpty) {
      final at = _lineIndexOf(stone.spec.shape).toDouble();
      _arc.stop();
      _arcPrev = at;
      _arcMark = (at * _marks).round();
      _arc.value = at;
    }
    widget.viewport.morph.value = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _warm();
      if (_arcMode) _warmLine();
    });
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

  /// The same along the half ring, outward from where it stands.
  Future<void> _warmLine() async {
    final gen = _generation;
    final n = _line.length;
    final at = _arc.value.round().clamp(0, n - 1);
    for (var d = 0; d < n; d++) {
      for (final i in {at + d, at - d - 1}) {
        if (i < 0 || i >= n) continue;
        await Future<void>.delayed(const Duration(milliseconds: 24));
        if (!mounted || gen != _generation) return;
        _lineStone(i);
        if (i + 1 < n) _linePair(i);
      }
    }
  }

  /// Whether [s] is one of the dial's stones (so the dial chose it).
  bool _owns(DiamondSimulatorState s) => _stones.values.any(
    (c) => identical(c.mesh, s.mesh) && identical(c.spec, s.spec),
  );

  void _onTurn() {
    final p = _dial.value;
    // Turned along with the half ring, out of sight.
    if (_arcMode) {
      _prev = p;
      return;
    }
    _mark = _ticks(_prev, p, _mark);
    _prev = p;
    final near = _shapeAt(p.round());
    if (near != _nearest.value.classic) {
      _nearest.value = SimLineShape.classic(near);
    }
    _publish(p);
  }

  void _onArc() {
    if (!_arcMode || _line.isEmpty) return;
    final p = _arc.value;
    final n = _line.length;
    // Silent past either end, where the half ring only gives.
    if (p > -0.25 && p < n - 0.75) {
      _arcMark = _ticks(_arcPrev, p, _arcMark, soft: !_gliding);
    }
    _arcPrev = p;
    final near = _line[p.round().clamp(0, n - 1)];
    if (near != _nearest.value) _nearest.value = near;
    _publishArc(p);
  }

  /// Shows the stone at dial position [p]: at a stop, that shape; between
  /// stops, the one stone partway from one shape to the next. Eased so
  /// the shape holds near each stop and changes most between them.
  void _publish(double p) {
    final i = p.floor();
    final f = p - i;
    if (f < 1e-4 || f > 1 - 1e-4) {
      _show(_stoneAt(f < 0.5 ? i : i + 1));
      return;
    }
    widget.viewport.morph.value = SimMorphFrame(
      from: _stoneAt(i),
      to: _stoneAt(i + 1),
      t: f * f * (3 - 2 * f),
      morph: _pairAt(i),
    );
  }

  /// The same along the half ring.
  void _publishArc(double p) {
    final n = _line.length;
    final q = p.clamp(0.0, n - 1.0);
    final i = q.floor();
    final f = q - i;
    if (f < 1e-4 || f > 1 - 1e-4 || i >= n - 1) {
      _show(_lineStone(math.min(f < 0.5 ? i : i + 1, n - 1)));
      return;
    }
    widget.viewport.morph.value = SimMorphFrame(
      from: _lineStone(i),
      to: _lineStone(i + 1),
      t: f * f * (3 - 2 * f),
      morph: _linePair(i),
    );
  }

  /// [s] at rest: the selected stone itself, or shown in its place.
  void _show(DiamondSimulatorState s) {
    final current = ref.read(diamondSimulatorProvider);
    widget.viewport.morph.value =
        identical(s.mesh, current.mesh) && identical(s.spec, current.spec)
        ? null
        : SimMorphFrame.still(s);
  }

  /// A click for every ratchet mark crossed: a firm detent (felt and
  /// heard) at a shape, a soft tick between. Many marks in one frame (a
  /// fast flick) sound once; rocking back over the same mark is silent.
  /// Returns the mark last sounded. Without [soft], only the detents.
  int? _ticks(double prev, double cur, int? last, {bool soft = true}) {
    final a = (prev * _marks).floor(), b = (cur * _marks).floor();
    if (a == b) return last;
    final mark = b > a ? b : b + 1;
    if (mark == last) return last;
    final lo = math.min(a, b) + 1, hi = math.max(a, b);
    final stop = (hi / _marks).floor() * _marks >= lo;
    if (!stop && !soft) return last;
    if (stop) {
      AppHaptics.detent();
      DialSounds.detent();
    } else {
      AppHaptics.selection();
      DialSounds.tick();
    }
    return mark;
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _arcMode) return;
    final k = _dial.value.round();
    if ((_dial.value - k).abs() > 1e-3) return;
    if (_dial.value != k) _dial.value = k.toDouble();
    _commit(k);
    _idle();
    if (_closing) widget.onDone();
  }

  void _onArcStatus(AnimationStatus status) {
    if (status != AnimationStatus.forward) _gliding = false;
    if (status != AnimationStatus.completed || !_arcMode) return;
    final k = _arc.value.round();
    if ((_arc.value - k).abs() > 1e-3) return;
    if (_arc.value != k) _arc.value = k.toDouble();
    final classic = _line[k].classic;
    // A classic shape becomes the stone's; a fancy cut is only shown.
    if (classic != null) _commit(_shapes.indexOf(classic));
    _idle();
    _maybeLeaveArc();
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

  void _settleArc(double target, double velocity) {
    final p = _arc.value;
    final to = target.roundToDouble().clamp(0.0, _line.length - 1.0);
    if (to != p.roundToDouble()) _leaveScope();
    _arc.animateWith(SpringSimulation(_spring, p, to, velocity));
  }

  /// Opens the half ring of every shape, or closes it back into the ring
  /// on the classic shape nearest.
  Future<void> _toggleMore() async {
    _wake();
    if (_more) {
      _more = false;
      _searchTimer?.cancel();
      _queryFocus.unfocus();
      _query.clear();
      _missed = false;
      final start = _classicStart;
      final to = _arc.value.round().clamp(start, start + _n - 1);
      // The ring, out of sight, turns to the shape it will close on.
      final shape = _line[to].classic!;
      final cur = _dial.value.roundToDouble();
      _dial.value = cur + _wrap(_shapes.indexOf(shape) - cur);
      _mark = (_dial.value * _marks).round();
      _settleArc(to.toDouble(), 0);
      widget.onMoreShapes?.call(false);
      _open.reverse();
      setState(() {});
      return;
    }
    if (_line.isEmpty) {
      final shapes = await SimFancyCatalog.load();
      if (!mounted || _more) return;
      _line = SimShapeLine.of(shapes);
    }
    // From the shape at the top, at rest.
    _dial.stop();
    final k = _dial.value.round();
    if (_dial.value != k) _dial.value = k.toDouble();
    _commit(k);
    final at = _lineIndexOf(_shapeAt(k)).toDouble();
    _more = true;
    _arcMode = true;
    _arcPrev = at;
    _arcMark = (at * _marks).round();
    _arc.value = at;
    _nearest.value = _line[at.round()];
    widget.onMoreShapes?.call(true);
    _open.forward();
    setState(() {});
    _warmLine();
  }

  /// Hands the stone back to the ring once the half ring has closed and
  /// come to rest on a classic shape.
  void _maybeLeaveArc() {
    if (!_arcMode || _more || !_open.isDismissed || _arc.isAnimating) return;
    _arcMode = false;
    _prev = _dial.value;
    _nearest.value = SimLineShape.classic(_shapeAt(_dial.value.round()));
    _publish(_dial.value);
    setState(() {});
  }

  void _onQuery(String text) {
    _wake();
    _searchTimer?.cancel();
    _searchTimer = Timer(
      const Duration(milliseconds: 350),
      () => _search(text),
    );
  }

  static final _nonWord = RegExp(r'[^\p{L}\p{M}\p{N}]+', unicode: true);

  static String _norm(String s) =>
      s.toLowerCase().replaceAll(_nonWord, ' ').trim();

  /// Turns the half ring to the shape best matching [text]: a whole name,
  /// then a name or one of its words starting so, then any name holding
  /// it; the nearest of equals.
  void _search(String text) {
    _searchTimer?.cancel();
    if (!mounted || !_arcMode || !_more || _line.isEmpty) return;
    final q = _norm(text);
    if (q.isEmpty) {
      if (_missed) setState(() => _missed = false);
      return;
    }
    int? best;
    var bestScore = 0;
    var bestDistance = double.infinity;
    for (var j = 0; j < _line.length; j++) {
      final s = _line[j];
      var score = 0;
      for (final name in {
        _norm(_nameOf(context, s)),
        _norm(s.classic?.catalogValue ?? s.fancy!.id),
      }) {
        final words = name.split(' ');
        score = math.max(
          score,
          name == q
              ? 4
              : name.startsWith(q)
              ? 3
              : words.any((w) => w.startsWith(q))
              ? 2
              : name.contains(q)
              ? 1
              : 0,
        );
      }
      if (score == 0) continue;
      final distance = (j - _arc.value).abs();
      if (score > bestScore ||
          (score == bestScore && distance < bestDistance)) {
        best = j;
        bestScore = score;
        bestDistance = distance;
      }
    }
    setState(() => _missed = best == null);
    if (best != null) _glideTo(best);
  }

  /// Turns the half ring steadily to shape [j], however far: never a
  /// jump, the stone recut through every shape on the way.
  void _glideTo(int j) {
    final d = (j - _arc.value).abs();
    if (d < 1e-3) return;
    _wake();
    _leaveScope();
    _arc.stop();
    _gliding = true;
    _arc.animateTo(
      j.toDouble(),
      duration: Duration(
        milliseconds: (520 + 120 * d).clamp(650, 2800).round(),
      ),
      curve: Curves.easeInOutCubic,
    );
  }

  void _wake() {
    _dimTimer?.cancel();
    if (_dim) setState(() => _dim = false);
  }

  /// Fades the ring back after a moment untouched.
  void _idle() {
    _dimTimer?.cancel();
    _dimTimer = Timer(const Duration(milliseconds: 4200), () {
      if (mounted &&
          !_dial.isAnimating &&
          !_arc.isAnimating &&
          !_queryFocus.hasFocus) {
        setState(() => _dim = true);
      }
    });
  }

  /// The turning centre, controller and stop angle of whichever is shown.
  Offset get _pivot =>
      _arcMode ? _Arc(_size, widget.bottomInset).centre : _center;

  double get _stopAngle =>
      _arcMode ? _Arc(_size, widget.bottomInset).step : _step;

  void _onPanStart(DragStartDetails d) {
    _wake();
    (_arcMode ? _arc : _dial).stop();
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
    final c = _pivot;
    final from = _last! - c, to = d.localPosition - c;
    _last = d.localPosition;
    // Too near the centre to tell which way it turns.
    if (from.distance < 12 || to.distance < 12) return;
    final stops = -_wrapAngle(to.direction - from.direction) / _stopAngle;
    if (!_arcMode) {
      _dial.value -= _wrapAngle(to.direction - from.direction) / _step;
      return;
    }
    // Past either end the half ring gives, heavily.
    final p = _arc.value;
    final end = (p <= 0 && stops < 0) || (p >= _line.length - 1 && stops > 0);
    _arc.value = p + (end ? stops * 0.3 : stops);
  }

  void _onPanEnd(DragEndDetails d) {
    final c = _pivot;
    final r = (_last ?? c) - c;
    final v = d.velocity.pixelsPerSecond;
    final r2 = r.distanceSquared;
    // Angular speed about the centre, then in stops per second.
    final omega = r2 < 144 ? 0.0 : (r.dx * v.dy - r.dy * v.dx) / r2;
    final speed = (-omega / _stopAngle).clamp(-26.0, 26.0);
    if (_arcMode) {
      _settleArc(_arc.value + speed * 0.24, speed);
    } else {
      _settleTo(_dial.value + speed * 0.24, speed);
    }
  }

  void _onTapUp(TapUpDetails d) {
    final at = d.localPosition - _pivot;
    if (at.distance < 12) return;
    final turn = _wrapAngle(at.direction + math.pi / 2) / _stopAngle;
    if (_arcMode) {
      _settleArc(_arc.value + turn, 0);
    } else {
      _settleTo(_dial.value + turn, 0);
    }
    _idle();
  }

  void _turnBy(int stops) {
    _wake();
    if (_arcMode) {
      _settleArc(_arc.value.roundToDouble() + stops, 0);
    } else {
      _settleTo(_dial.value.roundToDouble() + stops, 0);
    }
  }

  void _done() {
    if (_arcMode) {
      if (_arc.isAnimating) {
        _closing = true;
        return;
      }
      // On a fancy cut the stone stays the classic shape it was.
      final classic = _line[_arc.value.round()].classic;
      if (classic != null) _commit(_shapes.indexOf(classic));
      widget.onDone();
      return;
    }
    if (_dial.isAnimating) {
      _closing = true;
      return;
    }
    _commit(_dial.value.round());
    widget.onDone();
  }

  _Frame _frame() => _Frame(
    u: _open.value,
    size: _size,
    centre: _center,
    radius: widget.radius,
    arc: _Arc(_size, widget.bottomInset),
    dial: _dial.value,
    pos: _arc.value,
    count: _n,
    lineCount: _line.length,
  );

  String _nameOf(BuildContext context, SimLineShape s) => s.classic != null
      ? context.shapeName(s.classic!)
      : context.fancyShapeName(s.fancy!);

  /// The shape [by] stops from [s], on the ring or along the half ring.
  SimLineShape? _beside(SimLineShape s, int by) {
    if (!_arcMode) {
      return SimLineShape.classic(
        _shapeAt(_shapes.indexOf(s.classic ?? SimShape.round) + _n + by),
      );
    }
    final i = _line.indexOf(s) + by;
    return i < 0 || i >= _line.length ? null : _line[i];
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
        _size = constraints.biggest;
        _center = _size.center(Offset.zero);
        final arc = _Arc(_size, widget.bottomInset);
        // Faded through its colours, never an opacity layer: an offscreen
        // pass every frame would compete with the stone's trace.
        Widget ring(double fade) => AnimatedBuilder(
          animation: _open,
          builder: (context, child) {
            final u = _open.value;
            final half = u >= 1;
            final c = half ? arc.centre : _center;
            final cr = half ? arc.radius : r;
            return IgnorePointer(
              // Only the ring or the half ring at rest takes a turn.
              ignoring: u > 0 && u < 1,
              child: _Annulus(
                centre: c,
                inner: cr - band / 2 - 10,
                outer: cr + band / 2 + 12,
                child: child,
              ),
            );
          },
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
                        motion: _motion,
                        frame: _frame,
                        accent: p.accent,
                        marks: _marks,
                        fade: fade,
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _motion,
                      builder: (context, _) => Stack(children: _icons(p, fade)),
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
              child: ValueListenableBuilder<SimLineShape>(
                valueListenable: _nearest,
                builder: (context, shape, child) {
                  final up = _beside(shape, 1), down = _beside(shape, -1);
                  return Semantics(
                    label: context.tr(EducationL10n.shape),
                    value: _nameOf(context, shape),
                    increasedValue: up == null ? null : _nameOf(context, up),
                    decreasedValue: down == null
                        ? null
                        : _nameOf(context, down),
                    onIncrease: up == null ? null : () => _turnBy(1),
                    onDecrease: down == null ? null : () => _turnBy(-1),
                    child: child,
                  );
                },
                child: _Entrance(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: _dim ? 0.22 : 1),
                    duration: _dim ? _fadeBack : LuxeMotion.fast,
                    curve: Curves.easeOut,
                    builder: (context, fade, _) => ring(fade),
                  ),
                ),
              ),
            ),
            // A small search above the half ring's name.
            if (_arcMode)
              AnimatedBuilder(
                animation: _open,
                builder: (context, child) {
                  final b = _frame().b;
                  return Positioned(
                    left: 0,
                    right: 0,
                    top: arc.searchTop,
                    height: _Arc.searchHeight,
                    child: IgnorePointer(
                      ignoring: !_more || b < 1,
                      child: Opacity(opacity: b.clamp(0.0, 1.0), child: child),
                    ),
                  );
                },
                child: Center(
                  child: SizedBox(
                    // The pill's own height: a text field alone is only as
                    // tall as its line.
                    height: _Arc.searchHeight,
                    width: math.min(_size.width - 48, 300),
                    child: _searchField(p),
                  ),
                ),
              ),
            // The shape's name: under the ring, or above the half ring.
            AnimatedBuilder(
              animation: _open,
              builder: (context, child) {
                final f = _frame();
                final first = f.u < 0.5;
                return Positioned(
                  left: 16,
                  right: 16,
                  top: first ? _center.dy + r + band / 2 + 12 : arc.nameTop,
                  child: Opacity(
                    opacity: (first ? 1 - f.a : f.b).clamp(0.0, 1.0),
                    child: child,
                  ),
                );
              },
              child: IgnorePointer(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: _dim ? 0.35 : 1),
                  duration: _dim ? _fadeBack : LuxeMotion.fast,
                  builder: (context, fade, _) =>
                      ValueListenableBuilder<SimLineShape>(
                        valueListenable: _nearest,
                        builder: (context, shape, _) => AnimatedSwitcher(
                          duration: LuxeMotion.fast,
                          child: Text(
                            _nameOf(context, shape),
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
                    label: context.tr(
                      _more
                          ? EducationL10n.fewerShapes
                          : EducationL10n.moreShapes,
                    ),
                    selected: false,
                    palette: p,
                    height: 40,
                    onTap: _toggleMore,
                  ),
                  const SizedBox(width: 10),
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

  Widget _searchField(LuxePalette p) =>
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: _query,
        builder: (context, value, _) => DecoratedBox(
          decoration: ShapeDecoration(
            color: const Color(0x8C101010),
            shape: StadiumBorder(
              side: BorderSide(
                color: _missed
                    ? p.inkFaint
                    : _queryFocus.hasFocus
                    ? p.accent.withValues(alpha: 0.6)
                    : LuxeStage.glassBorder,
              ),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Icon(Icons.search_rounded, size: 20, color: p.inkMuted),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: _query,
                  focusNode: _queryFocus,
                  onChanged: _onQuery,
                  onSubmitted: _search,
                  onTap: _wake,
                  textInputAction: TextInputAction.search,
                  cursorColor: p.accent,
                  style: LuxeType.label(p.ink, size: 15),
                  // Bare: the pill is the field, without the theme's own
                  // filled box inside it.
                  decoration: InputDecoration(
                    isDense: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: context.tr(EducationL10n.searchShapes),
                    hintStyle: LuxeType.label(p.inkFaint, size: 15),
                  ),
                ),
              ),
              if (_missed && value.text.isNotEmpty)
                Text(
                  context.tr(EducationL10n.noShapeFound),
                  style: LuxeType.label(p.inkFaint, size: 12),
                ),
              if (value.text.isNotEmpty)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    _searchTimer?.cancel();
                    _query.clear();
                    setState(() => _missed = false);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: p.inkMuted,
                    ),
                  ),
                )
              else
                const SizedBox(width: 16),
            ],
          ),
        ),
      );

  /// Each shape on the ring or the half ring, upright, growing and taking
  /// the accent as it nears the window. On the way between, the ring's
  /// shapes ride its band out as it opens and the half ring's slide in
  /// from its ends.
  List<Widget> _icons(LuxePalette p, double fade) {
    final f = _frame();
    final band = f.band;
    final out = <Widget>[];
    void put(String asset, double s, double near, double alpha) {
      // Fading out toward the band's ends, once it has any: the whole
      // ring has none, and its top (where it opens) holds the selection.
      final ends = band.length >= f.ringLength - 0.5
          ? 1.0
          : ((band.length / 2 - s.abs()) / 28).clamp(0.0, 1.0);
      final a = alpha * ends * fade;
      if (a <= 0.01) return;
      final c = band.at(s);
      final size = 24 + 12 * near;
      if (c.dx < -size || c.dx > _size.width + size) return;
      if (c.dy < -size || c.dy > _size.height + size) return;
      final color = Color.lerp(p.ink.withValues(alpha: 0.62), p.accent, near)!;
      out.add(
        Positioned(
          left: c.dx - size / 2,
          top: c.dy - size / 2,
          width: size,
          height: size,
          child: SvgPicture.asset(
            asset,
            colorFilter: ColorFilter.mode(
              color.withValues(alpha: color.a * a),
              BlendMode.srcIn,
            ),
            placeholderBuilder: (_) => const SizedBox.shrink(),
          ),
        ),
      );
    }

    if (f.a < 1) {
      final alpha = 1 - (f.a / 0.6).clamp(0.0, 1.0);
      for (var s = 0; s < _n; s++) {
        final rel = _wrap(s - f.dial);
        put(
          _shapes[s].svgAsset,
          f.ringAt(rel),
          (1 - rel.abs()).clamp(0.0, 1.0),
          alpha,
        );
      }
    }
    if (f.b > 0 && _line.isNotEmpty) {
      final n = _line.length;
      final reach = band.length / 2 / f.arc.spacing + 1;
      final first = math.max(0, (f.pos - reach).floor());
      final last = math.min(n - 1, (f.pos + reach).ceil());
      for (var j = first; j <= last; j++) {
        final q = j - f.pos;
        put(_line[j].svgAsset, f.arcAt(q), (1 - q.abs()).clamp(0.0, 1.0), f.b);
      }
    }
    return out;
  }
}

/// The half ring at rest along the bottom of a dial of [size]: an arc of
/// a circle whose centre lies below the screen, its top under the stone.
class _Arc {
  _Arc(Size size, double bottomInset) : width = size.width {
    // Bowed well down to either side, as a dial seen from its rim.
    radius = (width * 0.66).clamp(240.0, 640.0);
    // Its inner edge just clear of the buttons under it (Show fewer
    // shapes and Done, about 130 either side of the middle); the name and
    // the search above it.
    final buttonsTop = size.height - bottomInset - 14 - 40;
    final buttons = math.min(width / 2 - 16, 130.0);
    final dip = radius - math.sqrt(radius * radius - buttons * buttons);
    apex = buttonsTop - 6 - SimShapeDial.band / 2 - dip;
    nameTop = apex - SimShapeDial.band / 2 - 12 - 28;
    searchTop = nameTop - 8 - searchHeight;
    final reach = math.min(1.0, (width / 2 + SimShapeDial.band) / radius);
    length = 2 * radius * (math.asin(reach) + 0.15);
    centre = Offset(width / 2, apex + radius);
    // Five shapes in full across the screen, the next either side cut by
    // its edges.
    final edge = radius * math.asin(math.min(1.0, width / 2 / radius));
    spacing = math.min(edge / 3, 96.0);
  }

  static const searchHeight = 52.0;

  final double width;

  /// [spacing]: arc length between neighbouring shapes.
  late final double radius, apex, nameTop, searchTop, length, spacing;
  late final Offset centre;

  /// Angle between neighbouring shapes about [centre].
  double get step => spacing / radius;
}

/// A stretch of band: a circular arc (or a line) of [length], measured
/// from its middle [mid], where it runs level, bending by [k] (1 / its
/// radius; positive when it curves up either side, as round the bottom
/// of a ring, negative when it falls away, as the half ring does).
class _Band {
  const _Band(this.mid, this.k, this.length);

  final Offset mid;
  final double k, length;

  /// The point [s] along from the middle, positive to the right.
  Offset at(double s) {
    if (k.abs() < 1e-7) return mid + Offset(s, -k * s * s / 2);
    final t = k * s;
    return mid + Offset(math.sin(t) / k, -(1 - math.cos(t)) / k);
  }

  /// Unit normal at [s] toward the band's outer edge (away from the
  /// circle's centre).
  Offset outward(double s) {
    final t = k * s;
    final n = Offset(math.sin(t), math.cos(t));
    return k > 0 ? n : -n;
  }
}

/// Everything about the dial at one moment: the ring, the half ring, and
/// the way between ([u] 0 to 1). The ring first opens at the top, its
/// ends drawing down and apart as it widens across the screen ([a]);
/// then, lying along the bottom, it straightens and bows into the half
/// ring ([b]).
class _Frame {
  _Frame({
    required this.u,
    required this.size,
    required this.centre,
    required this.radius,
    required this.arc,
    required this.dial,
    required this.pos,
    required this.count,
    required this.lineCount,
  });

  final double u;
  final Size size;
  final Offset centre;
  final double radius;
  final _Arc arc;

  /// Ring position in stops, half ring position in shapes.
  final double dial, pos;
  final int count, lineCount;

  late final double a = Curves.easeInOutCubic.transform(
    (u / 0.5).clamp(0.0, 1.0),
  );
  late final double b = Curves.easeInOutCubic.transform(
    ((u - 0.4) / 0.6).clamp(0.0, 1.0),
  );

  /// The ring's whole length, and its spacing between stops.
  late final double ringLength = 2 * math.pi * radius;
  late final double ringSpacing = ringLength / count;

  late final _Band band = () {
    final w = size.width;
    double mix(double ring, double spread, double half) {
      final x = ring + (spread - ring) * a;
      return x + (half - x) * b;
    }

    final spreadMid = math.min(
      arc.apex - 10,
      centre.dy + radius + SimShapeDial.band,
    );
    return _Band(
      Offset(w / 2, mix(centre.dy + radius, spreadMid, arc.apex)),
      mix(1 / radius, 1 / (0.95 * w), -1 / arc.radius),
      mix(ringLength, 1.5 * w, arc.length),
    );
  }();

  /// Where a ring shape [rel] stops from the top lies along the band:
  /// measured from the ring's bottom, squeezed as the band shortens.
  double ringAt(double rel) {
    var s = ringLength / 2 - rel * ringSpacing;
    if (s > ringLength / 2) s -= ringLength;
    return s * band.length / ringLength;
  }

  /// Where a half ring shape [q] from the centre lies, sliding in from
  /// the ends as the half ring forms.
  double arcAt(double q) =>
      q * arc.spacing + q.sign * (1 - b) * size.width * 0.5;
}

/// The frosted band, its ratchet marks turning with the dial, and the
/// window that holds the selected shape.
class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.motion,
    required this.frame,
    required this.accent,
    required this.marks,
    required this.fade,
  }) : super(repaint: motion);

  final Listenable motion;
  final _Frame Function() frame;
  final Color accent;
  final int marks;

  /// 1 in full view, less as the ring fades back.
  final double fade;

  late final Paint _band = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = SimShapeDial.band
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
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
    final f = frame();
    const half = SimShapeDial.band / 2;
    final band = f.band;

    if (f.u <= 0) {
      final c = f.centre;
      canvas
        ..drawCircle(c, f.radius, _band)
        ..drawCircle(c, f.radius + half, _edge)
        ..drawCircle(c, f.radius - half, _edge);
    } else {
      // Sampled finely enough to read as a true curve at any width.
      const segments = 120;
      final mid = Path(), outer = Path(), inner = Path();
      for (var i = 0; i <= segments; i++) {
        final s = -band.length / 2 + band.length * i / segments;
        final p = band.at(s), n = band.outward(s) * half;
        final o = p + n, q = p - n;
        if (i == 0) {
          mid.moveTo(p.dx, p.dy);
          outer.moveTo(o.dx, o.dy);
          inner.moveTo(q.dx, q.dy);
        } else {
          mid.lineTo(p.dx, p.dy);
          outer.lineTo(o.dx, o.dy);
          inner.lineTo(q.dx, q.dy);
        }
      }
      canvas
        ..drawPath(mid, _band)
        ..drawPath(outer, _edge)
        ..drawPath(inner, _edge);
    }

    // The ring's window at the top, gone as soon as the ring opens there.
    final ringWindow = (1 - f.a * 4).clamp(0.0, 1.0);
    if (ringWindow > 0) {
      final step = 2 * math.pi / f.count;
      canvas.drawArc(
        Rect.fromCircle(center: f.centre, radius: f.radius),
        -math.pi / 2 - step * 0.42,
        step * 0.84,
        false,
        _window(SimShapeDial.band - 8, 0.16 * fade * ringWindow),
      );
      _pointer(canvas, f.centre + Offset(0, -f.radius - half + 1), ringWindow);
    }
    // The half ring's window at its middle.
    if (f.b > 0) {
      final w = Path();
      const k = 10;
      for (var i = 0; i <= k; i++) {
        final p = band.at(math.min(f.arc.spacing * 0.42, 30) * (2 * i / k - 1));
        i == 0 ? w.moveTo(p.dx, p.dy) : w.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(w, _window(SimShapeDial.band - 8, 0.16 * fade * f.b));
      _pointer(canvas, band.at(0) + band.outward(0) * (half - 1), f.b);
    }

    // Ratchet marks along the outer edge, turning with the dial; the
    // shapes sit on every fourth.
    void mark(double s, double near, double alpha) {
      if (s.abs() > band.length / 2 - 4) return;
      final p = band.at(s), n = band.outward(s);
      _mark.color = Color.fromRGBO(
        255,
        255,
        255,
        (0.16 + 0.3 * near) * fade * alpha,
      );
      canvas.drawLine(p + n * (half - 8), p + n * (half - 3), _mark);
    }

    final ringMarks = 1 - (f.a / 0.6).clamp(0.0, 1.0);
    if (ringMarks > 0) {
      final total = f.count * marks;
      for (var m = 0; m < total; m++) {
        if (m % marks == 0) continue;
        var rel = m / marks - f.dial;
        rel -= (rel / f.count + 0.5).floorToDouble() * f.count;
        mark(f.ringAt(rel), (1 - rel.abs() / 2).clamp(0.0, 1.0), ringMarks);
      }
    }
    if (f.b > 0 && f.lineCount > 0) {
      final reach = band.length / 2 / f.arc.spacing + 1;
      final first = math.max(0, ((f.pos - reach) * marks).floor());
      final last = math.min(
        (f.lineCount - 1) * marks,
        ((f.pos + reach) * marks).ceil(),
      );
      for (var m = first; m <= last; m++) {
        if (m % marks == 0) continue;
        final q = m / marks - f.pos;
        mark(f.arcAt(q), (1 - q.abs() / 2).clamp(0.0, 1.0), f.b);
      }
    }
  }

  Paint _window(double width, double alpha) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..color = accent.withValues(alpha: alpha);

  /// A pointer just outside the band, pointing in at the window.
  void _pointer(Canvas canvas, Offset tip, double alpha) {
    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy + 2)
        ..lineTo(tip.dx - 6, tip.dy - 7)
        ..lineTo(tip.dx + 6, tip.dy - 7)
        ..close(),
      Paint()..color = accent.withValues(alpha: accent.a * fade * alpha),
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.accent != accent ||
      old.marks != marks ||
      old.fade != fade ||
      old.motion != motion ||
      old.frame != frame;
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

/// Takes touches only on the band, so the stone inside it and the stage
/// outside it keep their own gestures.
class _Annulus extends SingleChildRenderObjectWidget {
  const _Annulus({
    required this.centre,
    required this.inner,
    required this.outer,
    super.child,
  });

  final Offset centre;
  final double inner, outer;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderAnnulus(centre, inner, outer);

  @override
  void updateRenderObject(BuildContext context, _RenderAnnulus renderObject) {
    renderObject
      ..centre = centre
      ..inner = inner
      ..outer = outer;
  }
}

class _RenderAnnulus extends RenderProxyBox {
  _RenderAnnulus(this.centre, this.inner, this.outer);

  Offset centre;
  double inner, outer;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final d = (position - centre).distance;
    if (d < inner || d > outer) return false;
    return super.hitTest(result, position: position);
  }
}
