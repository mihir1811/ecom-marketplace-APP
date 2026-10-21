import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/haptics/app_haptics.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/theme/luxe_tokens.dart';
import '../../../application/diamond_simulator_controller.dart';
import '../../../domain/average_hand.dart';
import '../../../domain/diamond_grades.dart';
import '../../../simulation/sim_optics.dart';
import '../../../simulation/sim_renderer.dart';
import '../../../simulation/sim_inclusion_plot.dart';
import '../../../simulation/sim_wireframe.dart';
import 'diamond_sim_viewport.dart';
import 'sim_hand_painter.dart';

/// Logical pixels per millimetre on a typical phone (160 per inch), for
/// showing the hand at life size.
const _lifePxPerMm = 160 / 25.4;

/// Up to four stones on the fingers of an average hand, seen from above
/// so their face-up size reads true against the fingers. The hand rises
/// into view; the selected stone sits centred on the ring finger. Each
/// stone keeps its own spec; tap a finger to pick or add one, drag
/// sideways to spin the selected stone about its table.
class SimHandStage extends ConsumerStatefulWidget {
  const SimHandStage({required this.controller, this.topInset = 0, super.key});

  final SimViewportController controller;

  /// Room taken at the top by overlaid chrome.
  final double topInset;

  @override
  ConsumerState<SimHandStage> createState() => _SimHandStageState();
}

class _SimHandStageState extends ConsumerState<SimHandStage>
    with TickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final AnimationController _zoom = AnimationController(
    vsync: this,
    duration: LuxeMotion.medium,
    value: widget.controller.lifeSize.value ? 1 : 0,
  );
  late final Ticker _spinTicker = createTicker(_tickSpin);

  final Map<HandFinger, double> _spin = {};
  double _velocity = 0;
  Duration _last = Duration.zero;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    widget.controller.lifeSize.addListener(_onLifeSize);
    widget.controller.addListener(_onMode);
    _vector = widget.controller.vector;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _enter.value = 1;
      } else {
        _enter.forward();
      }
    });
  }

  @override
  void dispose() {
    widget.controller.lifeSize.removeListener(_onLifeSize);
    widget.controller.removeListener(_onMode);
    _enter.dispose();
    _zoom.dispose();
    _spinTicker.dispose();
    super.dispose();
  }

  late bool _vector;

  void _onMode() {
    if (widget.controller.vector != _vector) {
      setState(() => _vector = widget.controller.vector);
    }
  }

  void _onLifeSize() {
    widget.controller.lifeSize.value ? _zoom.forward() : _zoom.reverse();
  }

  void _tickSpin(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 1 / 60
        : ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 1 / 20);
    _last = elapsed;
    final f = ref.read(simHandProvider).active;
    setState(() {
      _spin[f] = (_spin[f] ?? 0) + _velocity * dt;
      _velocity *= math.exp(-3 * dt);
    });
    if (_velocity.abs() < 0.01) {
      _spinTicker.stop();
      setState(() => _velocity = 0);
    }
  }

  /// Framing: the whole hand centred and in view, or life size centred
  /// on the selected stone.
  ({double px, Offset origin}) _frame(Size size, HandFinger active) {
    final usable = math.max(120.0, size.height - widget.topInset);
    final span = AverageHand.spanRight - AverageHand.spanLeft;
    // Width shows the whole hand, thumb included; height may crop the
    // fingertips under the chrome, never the stones.
    final fit = math
        .min((size.width - 24) / span, usable * 0.56 / -AverageHand.top * 1.35)
        .clamp(1.5, 9.0);
    final z = Curves.easeInOutCubic.transform(_zoom.value);
    final px = fit + (_lifePxPerMm - fit) * z;
    final seat = AverageHand.of(active).seatPoint;
    final middle = (AverageHand.spanLeft + AverageHand.spanRight) / 2;
    final focus = Offset(middle + (seat.x - middle) * z, seat.y * z);
    final centre = Offset(size.width / 2, widget.topInset + usable * 0.56);
    return (px: px, origin: centre - focus * px);
  }

  HandFinger? _fingerAt(Offset local, Size size, HandFinger active) {
    final f = _frame(size, active);
    HandFinger? best;
    var bestD = 18.0;
    for (final finger in HandFinger.values) {
      final seat = AverageHand.of(finger).seatPoint;
      final at = f.origin + Offset(seat.x, seat.y) * f.px;
      final d = (at - local).distance / f.px;
      if (d < bestD) {
        bestD = d;
        best = finger;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final hand = ref.watch(simHandProvider);
    final active = ref.watch(diamondSimulatorProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) {
            final f = _fingerAt(d.localPosition, size, hand.active);
            if (f == null) return;
            AppHaptics.selection();
            ref.read(simHandProvider.notifier).select(f);
          },
          onHorizontalDragStart: (_) {
            _dragging = true;
            _spinTicker.stop();
            _velocity = 0;
          },
          onHorizontalDragUpdate: (d) => setState(() {
            _spin[hand.active] = (_spin[hand.active] ?? 0) + d.delta.dx * 0.012;
          }),
          onHorizontalDragEnd: (d) {
            _dragging = false;
            _velocity = (d.velocity.pixelsPerSecond.dx * 0.012).clamp(
              -12.0,
              12.0,
            );
            if (_velocity.abs() > 0.05) {
              _last = Duration.zero;
              _spinTicker.start();
            } else {
              setState(() {});
            }
          },
          child: AnimatedBuilder(
            animation: Listenable.merge([_enter, _zoom]),
            builder: (context, _) {
              final frame = _frame(size, hand.active);
              final rise = Curves.easeOutCubic.transform(_enter.value);
              final stones = CurvedAnimation(
                parent: _enter,
                curve: const Interval(0.55, 1, curve: Curves.easeOutBack),
              ).value;
              return Stack(
                clipBehavior: Clip.none,
                fit: StackFit.expand,
                children: [
                  // A dark stage, so the model's glow reads; pitch black
                  // under ultraviolet, as in a darkened viewing box.
                  if (active.lighting == SimLighting.ultraviolet)
                    const ColoredBox(color: Color(0xFF000000))
                  else
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment(0, -0.2),
                          radius: 1.1,
                          colors: [Color(0xFF16181A), Color(0xFF050505)],
                        ),
                      ),
                    ),
                  Opacity(
                    opacity: rise.clamp(0.0, 1.0),
                    child: Transform(
                      alignment: Alignment.bottomCenter,
                      transform: Matrix4.identity()
                        ..translateByDouble(
                          0,
                          (1 - rise) * size.height * 0.6,
                          0,
                          1,
                        )
                        ..rotateZ((1 - rise) * -0.12),
                      child: Stack(
                        clipBehavior: Clip.none,
                        fit: StackFit.expand,
                        children: [
                          RepaintBoundary(
                            child: CustomPaint(
                              painter: SimHandPainter(
                                origin: frame.origin,
                                pxPerMm: frame.px,
                              ),
                            ),
                          ),
                          for (final f in HandFinger.values)
                            ..._finger(
                              f,
                              frame,
                              f == hand.active ? active : hand.parked[f],
                              selected: f == hand.active,
                              appear: stones,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  List<Widget> _finger(
    HandFinger f,
    ({double px, Offset origin}) frame,
    DiamondSimulatorState? stone, {
    required bool selected,
    required double appear,
  }) {
    final digit = AverageHand.of(f);
    final seat = digit.seatPoint;
    final at = frame.origin + Offset(seat.x, seat.y) * frame.px;
    final p = LuxePalette.of(context);
    final widgets = <Widget>[];

    if (stone != null) {
      final radiusMm = stone.mesh.radius * stone.mmPerUnit;
      final side = radiusMm * 2 * frame.px * 1.2 + 4;
      widgets.add(
        Positioned(
          left: at.dx - side / 2,
          top: at.dy - side / 2,
          width: side,
          height: side,
          child: IgnorePointer(
            child: Opacity(
              opacity: appear.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: 0.6 + 0.4 * appear,
                child: SimFingerStone(
                  stone: stone,
                  pxPerMm: frame.px,
                  // Long shapes run along the finger.
                  spin: math.pi / 2 - digit.lean + (_spin[f] ?? 0),
                  moving: selected && (_dragging || _spinTicker.isActive),
                  vector: _vector,
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      widgets.add(
        Positioned(
          left: at.dx - 24,
          top: at.dy - 14,
          width: 48,
          height: 28,
          child: IgnorePointer(
            child: Opacity(
              opacity: appear.clamp(0.0, 1.0),
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: const Color(0x66000000),
                  shape: StadiumBorder(
                    side: BorderSide(color: p.accent.withValues(alpha: 0.7)),
                  ),
                ),
                child: Center(
                  child: Text(
                    context.tr(EducationL10n.addStone),
                    style: LuxeType.label(p.ink, size: 11),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }
}

/// One traced stone, face up, at the hand's scale. Redraws only when the
/// stone, its spin or the scale change; full quality once it is still.
class SimFingerStone extends StatefulWidget {
  const SimFingerStone({
    required this.stone,
    required this.pxPerMm,
    required this.spin,
    required this.moving,
    this.vector = false,
    super.key,
  });

  final DiamondSimulatorState stone;
  final double pxPerMm;
  final double spin;
  final bool moving;

  /// Drawn as facet edges only (see [SimRenderMode.vector]).
  final bool vector;

  @override
  State<SimFingerStone> createState() => _SimFingerStoneState();
}

class _SimFingerStoneState extends State<SimFingerStone> {
  final _renderer = SimRenderer()..measureStats = false;
  final _wire = SimWireRenderer();
  final _inclusions = SimInclusionPlot();
  late SimWireStyle _wireStyle;
  int _version = 0;

  /// Whether the stone changed moments ago: while edits keep coming (a
  /// slider drag, quick taps) the CPU fallback samples coarser, and finer
  /// once they stop. The GPU always traces at full resolution.
  bool _settling = false;
  Timer? _settle;

  /// Whether the GPU tracer is in, or failed to load (then the CPU tracer
  /// draws). Until then nothing is drawn: never a coarse stand-in.
  bool _tracerSettled = false;

  @override
  void initState() {
    super.initState();
    _load(widget.stone, mesh: true);
    SimRenderer.loadProgram()
        .then((program) {
          if (!mounted) return;
          setState(() {
            _renderer.shader = program.fragmentShader();
            _tracerSettled = true;
            _version++;
          });
        })
        .catchError((Object _) {
          // The CPU tracer draws instead.
          if (!mounted) return;
          setState(() {
            _tracerSettled = true;
            _version++;
          });
        });
  }

  void _load(DiamondSimulatorState s, {required bool mesh}) {
    if (mesh) _renderer.setStone(s.mesh, s.inclusions);
    final optics = SimOptics.of(s.spec, s.lighting);
    _renderer.setOptics(optics);
    _wireStyle = SimWireStyle.of(optics);
    _version++;
  }

  @override
  void didUpdateWidget(SimFingerStone old) {
    super.didUpdateWidget(old);
    final a = old.stone, b = widget.stone;
    if (identical(a, b)) return;
    _load(
      b,
      mesh:
          !identical(a.mesh, b.mesh) || !identical(a.inclusions, b.inclusions),
    );
    _settling = true;
    _settle?.cancel();
    _settle = Timer(const Duration(milliseconds: 380), () {
      if (!mounted) return;
      setState(() {
        _settling = false;
        _version++;
      });
    });
  }

  @override
  void dispose() {
    _settle?.cancel();
    _renderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: _FingerStonePainter(
          renderer: _renderer,
          wire: widget.vector ? _wire : null,
          inclusions: _inclusions,
          stone: widget.stone,
          wireStyle: _wireStyle,
          version: _version,
          pxPerUnit: widget.pxPerMm * widget.stone.mmPerUnit,
          spin: widget.spin,
          moving: widget.moving || _settling,
          ready: _tracerSettled,
          dpr: dpr,
        ),
      ),
    );
  }
}

class _FingerStonePainter extends CustomPainter {
  _FingerStonePainter({
    required this.renderer,
    required this.wire,
    required this.inclusions,
    required this.stone,
    required this.wireStyle,
    required this.version,
    required this.pxPerUnit,
    required this.spin,
    required this.moving,
    required this.ready,
    required this.dpr,
  });

  final SimRenderer renderer;
  final SimWireRenderer? wire;
  final SimInclusionPlot inclusions;
  final DiamondSimulatorState stone;
  final SimWireStyle wireStyle;
  final int version;
  final double pxPerUnit, spin, dpr;
  final bool moving, ready;

  @override
  void paint(Canvas canvas, Size size) {
    final wire = this.wire;
    if (wire != null) {
      wire.paint(
        canvas,
        size,
        mesh: stone.mesh,
        view: SimView(tilt: math.pi / 2, spin: spin),
        pxPerUnit: pxPerUnit,
        style: wireStyle,
        inclusions: stone.inclusions,
        inclusionPlot: inclusions,
      );
      return;
    }
    if (!ready) return;
    renderer.maxBounces = SimRenderer.bounces;
    renderer.paint(
      canvas,
      size,
      view: SimView(tilt: math.pi / 2, spin: spin),
      pxPerUnit: pxPerUnit,
      samplePx: moving ? 4 : 2.5,
      // Always one traced path per device pixel, spinning or still.
      devicePixelRatio: dpr,
    );
  }

  @override
  bool shouldRepaint(covariant _FingerStonePainter old) =>
      old.version != version ||
      old.wire != wire ||
      !identical(old.stone, stone) ||
      old.pxPerUnit != pxPerUnit ||
      old.spin != spin ||
      old.moving != moving ||
      old.ready != ready ||
      old.dpr != dpr;
}
