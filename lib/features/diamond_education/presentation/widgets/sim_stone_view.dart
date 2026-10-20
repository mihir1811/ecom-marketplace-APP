import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../domain/diamond_grades.dart';
import '../../domain/diamond_proportions.dart';
import '../../domain/diamond_shape.dart';
import '../../domain/diamond_spec.dart';
import '../../simulation/sim_inclusions.dart';
import '../../simulation/sim_mesh.dart';
import '../../simulation/sim_optics.dart';
import '../../simulation/sim_renderer.dart';

/// Backdrop tones for stages that show a traced stone: a lit, neutral
/// grey behind the stone, so its white light, dark contrast and outline
/// all read, falling off to the stage's dark edge.
abstract final class SimStageTones {
  static const lit = Color(0xFF6A717C);
  static const mid = Color(0xFF3A4049);
}

/// A small, self-running traced diamond: spins and rocks in the
/// jeweller's studio. Pauses while scrolled off screen and holds still under reduced
/// motion.
///
/// Nothing is built or traced until the page's route has finished its
/// transition, and the stone only shows once the GPU tracer is ready (the
/// CPU tracer is the fallback only where fragment programs fail), so
/// opening the page never stalls on it; the stone then fades in.
class SimStoneView extends StatefulWidget {
  const SimStoneView({
    this.shape = SimShape.round,
    this.size = 180,
    this.semanticLabel,
    super.key,
  });

  final SimShape shape;
  final double size;
  final String? semanticLabel;

  @override
  State<SimStoneView> createState() => _SimStoneViewState();
}

class _SimStoneViewState extends State<SimStoneView>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final _renderer = SimRenderer()
    ..maxBounces = 7
    ..measureStats = false;
  final _frame = ValueNotifier(0);
  ScrollPosition? _scroll;
  Duration _last = Duration.zero;
  double _time = 0;
  bool _visible = true;

  /// The route's push animation, while it runs.
  Animation<double>? _route;

  /// Whether setup has started, and whether the stone can be drawn (the
  /// GPU tracer loaded, or failed and the CPU tracer takes over).
  bool _started = false, _ready = false;

  void _onRoute() {
    if ((_route?.value ?? 1) >= 1) _start();
  }

  /// Builds the stone and loads the tracer once the page has settled.
  void _start() {
    _route?.removeListener(_onRoute);
    _route = null;
    if (_started || !mounted) return;
    _started = true;
    // One more frame so the first settled frame is not the costly one.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _stone();
      // Compiled at launch; waits here if that is still running.
      SimRenderer.warmUp()
          .then((_) => SimRenderer.loadProgram())
          .then((program) {
            if (!mounted) return;
            _renderer.shader = program.fragmentShader();
            _show();
          })
          .catchError((Object _) {
            // The CPU tracer draws instead.
            if (mounted) _show();
          });
    });
  }

  void _show() {
    setState(() => _ready = true);
    _sync();
    _frame.value++;
  }

  void _stone() {
    final spec = DiamondSpec(
      shape: widget.shape,
      proportions: DiamondProportions.ideal(widget.shape),
      clarity: ClarityGrade.vvs1,
    );
    final mesh = SimMesh.build(spec.shape, spec.proportions);
    _renderer
      ..setStone(mesh, SimInclusions.generate(mesh, spec.clarity))
      ..setOptics(SimOptics.of(spec, SimLighting.daylight));
  }

  @override
  void didUpdateWidget(SimStoneView old) {
    super.didUpdateWidget(old);
    if (_started && old.shape != widget.shape) {
      _stone();
      _frame.value++;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started && _route == null) {
      final route = ModalRoute.of(context)?.animation;
      if (route == null) {
        _start();
      } else {
        // On the first build the route's animation can still read 1: it is
        // a proxy, handed the push animation just after. Judge a frame on.
        _route = route..addListener(_onRoute);
        SchedulerBinding.instance.addPostFrameCallback((_) => _onRoute());
      }
    }
    final next = Scrollable.maybeOf(context)?.position;
    if (next != _scroll) {
      _scroll?.removeListener(_checkVisible);
      _scroll = next?..addListener(_checkVisible);
    }
    _sync();
  }

  @override
  void dispose() {
    _route?.removeListener(_onRoute);
    _scroll?.removeListener(_checkVisible);
    _ticker.dispose();
    _frame.dispose();
    _renderer.dispose();
    super.dispose();
  }

  void _checkVisible() {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return;
    final top = box.localToGlobal(Offset.zero).dy;
    final screen = MediaQuery.sizeOf(context).height;
    final visible = top < screen && top + box.size.height > 0;
    if (visible != _visible) {
      _visible = visible;
      _sync();
    }
  }

  void _sync() {
    final run = _ready && _visible && !MediaQuery.disableAnimationsOf(context);
    if (run && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    } else if (!run && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _tick(Duration elapsed) {
    // About 60 frames a second at most, on high refresh screens too.
    if (_last != Duration.zero &&
        elapsed - _last < const Duration(microseconds: 10500)) {
      return;
    }
    final dt = _last == Duration.zero
        ? 1 / 60
        : ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 1 / 20);
    _last = elapsed;
    _time += dt;
    _frame.value++;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: widget.semanticLabel,
      excludeSemantics: widget.semanticLabel == null,
      child: AnimatedOpacity(
        opacity: _ready ? 1 : 0,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOut,
        child: RepaintBoundary(
          child: CustomPaint(
            size: Size.square(widget.size),
            painter: _ready
                ? _StonePainter(this, MediaQuery.devicePixelRatioOf(context))
                : null,
          ),
        ),
      ),
    );
  }
}

class _StonePainter extends CustomPainter {
  _StonePainter(this.state, this.dpr) : super(repaint: state._frame);

  final _SimStoneViewState state;
  final double dpr;

  @override
  void paint(Canvas canvas, Size size) {
    final t = state._time;
    state._renderer.paint(
      canvas,
      size,
      view: SimView(
        tilt: 1.05 + 0.12 * math.sin(t * 0.9),
        spin: 0.4 + t * 0.35,
      ),
      pxPerUnit: size.shortestSide * 0.4,
      samplePx: 5,
      devicePixelRatio: dpr,
      // A small, always-moving stone: 1.5 traced pixels per point stays
      // sharp at under half the cost of full resolution.
      renderScale: math.min(dpr, 1.5),
      time: t,
      twinkle: true,
    );
  }

  @override
  bool shouldRepaint(covariant _StonePainter old) =>
      old.state != state || old.dpr != dpr;
}
