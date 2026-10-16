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

/// A small, self-running traced diamond: spins and rocks in the dark
/// studio. Pauses while scrolled off screen and holds still under reduced
/// motion.
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
  final _renderer = SimRenderer()..maxBounces = 10;
  final _frame = ValueNotifier(0);
  ScrollPosition? _scroll;
  Duration _last = Duration.zero;
  double _time = 0;
  double _spin = 0.4, _tilt = 1.05;
  double _wSpin = 0, _wTilt = 0;
  bool _dragging = false;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _stone();
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
    if (old.shape != widget.shape) {
      _stone();
      _frame.value++;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = Scrollable.maybeOf(context)?.position;
    if (next != _scroll) {
      _scroll?.removeListener(_checkVisible);
      _scroll = next?..addListener(_checkVisible);
    }
    _sync();
  }

  @override
  void dispose() {
    _scroll?.removeListener(_checkVisible);
    _ticker.dispose();
    _frame.dispose();
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
    final run =
        _visible && (_dragging || !MediaQuery.disableAnimationsOf(context));
    if (run && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    } else if (!run && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 1 / 60
        : ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 1 / 20);
    _last = elapsed;
    _time += dt;
    if (!_dragging) {
      _spin += (0.32 + _wSpin) * dt;
      _tilt = (_tilt + _wTilt * dt).clamp(-math.pi / 2, math.pi / 2);
      final decay = math.exp(-3.0 * dt);
      _wSpin *= decay;
      _wTilt *= decay;
    }
    _frame.value++;
  }

  @override
  Widget build(BuildContext context) {
    final k = 2.6 / math.max(180.0, widget.size);
    return Semantics(
      image: true,
      label: widget.semanticLabel,
      excludeSemantics: widget.semanticLabel == null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) {
          _dragging = true;
          _wSpin = 0;
          _wTilt = 0;
          _sync();
        },
        onPanUpdate: (d) {
          _spin += d.delta.dx * k * 1.2;
          _tilt = (_tilt + d.delta.dy * k).clamp(-math.pi / 2, math.pi / 2);
          _frame.value++;
        },
        onPanEnd: (d) {
          _dragging = false;
          final v = d.velocity.pixelsPerSecond;
          _wSpin = (v.dx * k * 0.8).clamp(-6.0, 6.0);
          _wTilt = (v.dy * k * 0.4).clamp(-2.5, 2.5);
          _sync();
        },
        child: RepaintBoundary(
          child: CustomPaint(
            size: Size.square(widget.size),
            painter: _StonePainter(this),
          ),
        ),
      ),
    );
  }
}

class _StonePainter extends CustomPainter {
  _StonePainter(this.state) : super(repaint: state._frame);

  final _SimStoneViewState state;

  @override
  void paint(Canvas canvas, Size size) {
    final t = state._time;
    final rock = state._dragging ? 0.0 : 0.10 * math.sin(t * 0.9);
    state._renderer.paint(
      canvas,
      size,
      view: SimView(
        tilt: (state._tilt + rock).clamp(-math.pi / 2, math.pi / 2),
        spin: state._spin,
      ),
      pxPerUnit: size.shortestSide * 0.45,
      samplePx: 3.6,
      time: t,
      twinkle: true,
    );
  }

  @override
  bool shouldRepaint(covariant _StonePainter old) => old.state != state;
}
