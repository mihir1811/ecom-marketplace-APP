import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/haptics/app_haptics.dart';
import '../../../application/diamond_simulator_controller.dart';
import '../../../simulation/sim_optics.dart';
import '../../../simulation/sim_renderer.dart';

/// Camera presets for the simulated stone.
enum SimViewPreset {
  faceUp(math.pi / 2),
  angled(0.95),
  profile(0),
  pavilion(-math.pi / 2);

  const SimViewPreset(this.tilt);

  final double tilt;
}

/// Light performance read off the rendered stone, 0..1.
@immutable
class SimLightReadout {
  const SimLightReadout({this.brightness = 0, this.fire = 0, this.sparkle = 0});

  final double brightness, fire, sparkle;
}

/// Commands and readouts shared by the viewport and the controls around
/// it, so neither rebuilds the other.
class SimViewportController extends ChangeNotifier {
  bool _autoRotate = true;
  bool get autoRotate => _autoRotate;
  set autoRotate(bool value) {
    if (value == _autoRotate) return;
    _autoRotate = value;
    notifyListeners();
  }

  SimViewPreset _preset = SimViewPreset.angled;
  int _presetRequest = 0;
  SimViewPreset get preset => _preset;

  void show(SimViewPreset preset) {
    _preset = preset;
    _presetRequest++;
    notifyListeners();
  }

  /// Smoothed light performance, a few times a second.
  final readout = ValueNotifier(const SimLightReadout());

  /// Current zoom (pinch), for the scale bar.
  final zoom = ValueNotifier(1.0);

  @override
  void dispose() {
    readout.dispose();
    zoom.dispose();
    super.dispose();
  }
}

/// On-screen scale of the stone, shared with the scale bar.
abstract final class SimScale {
  /// Logical pixels per millimetre at zoom 1 for a stone of bounding
  /// radius [radiusMm] in a viewport of [size]: true relative size across
  /// carat weights, shrunk only when a stone would overflow.
  static double pxPerMm(Size size, double radiusMm) {
    final short = size.shortestSide;
    var px = short * 0.085;
    final reach = radiusMm * px;
    if (reach > short * 0.44) px *= short * 0.44 / reach;
    return px;
  }
}

/// The live 3D stone. Drag to turn it (with inertia), pinch to zoom,
/// double-tap to reset. Spins slowly with a gentle rock while auto-rotate
/// is on; otherwise it renders only when something changes, and then
/// once more at higher quality when the stone comes to rest.
///
/// Rendering adapts to the device: frame cost is measured every frame and
/// the sampling density follows it, so slow devices keep a fluid stone.
class DiamondSimViewport extends ConsumerStatefulWidget {
  const DiamondSimViewport({required this.controller, super.key});

  final SimViewportController controller;

  @override
  ConsumerState<DiamondSimViewport> createState() => _DiamondSimViewportState();
}

class _DiamondSimViewportState extends ConsumerState<DiamondSimViewport>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final _renderer = SimRenderer();
  final _frame = ValueNotifier(0);
  Timer? _refineTimer;

  double _tilt = SimViewPreset.angled.tilt, _spin = 0.4, _zoom = 1;
  double _wSpin = 0, _wTilt = 0;
  double _time = 0;
  Duration _last = Duration.zero;
  bool _dragging = false;
  double _startZoom = 1;

  // Preset transition.
  double _fromTilt = 0, _toTilt = 0, _anim = 1;
  int _seenRequest = 0;

  // Adaptive quality.
  double _samplePx = 7.5;
  double _cost = 0;
  bool _refined = false;
  int _frames = 0;
  double _brightness = 0, _fire = 0, _sparkle = 0;

  double _mmPerUnit = 1, _radius = 1;
  double _dpr = 1;

  SimViewportController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    final s = ref.read(diamondSimulatorProvider);
    _renderer
      ..setStone(s.mesh, s.inclusions)
      ..setOptics(SimOptics.of(s.spec, s.lighting));
    _mmPerUnit = s.mmPerUnit;
    _radius = s.mesh.radius;
    _seenRequest = _c._presetRequest;
    _c.addListener(_onCommand);
    _syncTicker();
    SimRenderer.loadProgram()
        .then((program) {
          if (!mounted) return;
          _renderer.shader = program.fragmentShader();
          _invalidate();
        })
        .catchError((Object _) {
          // The CPU tracer keeps drawing.
        });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) && _c.autoRotate) {
      // Settle without motion; the user can still turn it by hand.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _c.autoRotate = false;
      });
    }
  }

  @override
  void dispose() {
    _c.removeListener(_onCommand);
    _refineTimer?.cancel();
    _ticker.dispose();
    _frame.dispose();
    _renderer.shader?.dispose();
    super.dispose();
  }

  void _onCommand() {
    if (_c._presetRequest != _seenRequest) {
      _seenRequest = _c._presetRequest;
      _fromTilt = _tilt;
      _toTilt = _c.preset.tilt;
      _anim = 0;
      _wTilt = 0;
    }
    _syncTicker();
    _invalidate();
  }

  bool get _moving =>
      _c.autoRotate ||
      _dragging ||
      _anim < 1 ||
      _wSpin.abs() > 0.004 ||
      _wTilt.abs() > 0.004;

  void _syncTicker() {
    if (_moving && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    } else if (!_moving && _ticker.isActive) {
      _ticker.stop();
      _scheduleRefine();
    }
  }

  /// Something changed: draw it now, refine once things settle.
  void _invalidate() {
    _refined = false;
    _frame.value++;
    if (!_ticker.isActive) _scheduleRefine();
  }

  void _scheduleRefine() {
    _refineTimer?.cancel();
    _refineTimer = Timer(const Duration(milliseconds: 220), () {
      if (!mounted || _ticker.isActive) return;
      _refined = true;
      _frame.value++;
    });
  }

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 1 / 60
        : ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 1 / 20);
    _last = elapsed;
    _time += dt;
    if (!_dragging) {
      if (_c.autoRotate) _spin += 0.3 * dt;
      _spin += _wSpin * dt;
      _tilt = (_tilt + _wTilt * dt).clamp(-math.pi / 2, math.pi / 2);
      final decay = math.exp(-2.6 * dt);
      _wSpin *= decay;
      _wTilt *= decay;
    }
    if (_anim < 1) {
      _anim = math.min(1, _anim + dt / 0.7);
      final e = 1 - math.pow(1 - _anim, 3).toDouble();
      _tilt = _fromTilt + (_toTilt - _fromTilt) * e;
    }
    _refined = false;
    _frame.value++;
    if (!_moving) _syncTicker();
  }

  void _paint(Canvas canvas, Size size) {
    final pxPerMm = SimScale.pxPerMm(size, _radius * _mmPerUnit);
    // A gentle rock while spinning, as a jeweller tilts a stone in light.
    final rock = _c.autoRotate && !_dragging
        ? 0.07 * math.sin(_time * 1.15)
        : 0.0;
    final quality = _refined;
    final gpu = _renderer.shader != null;
    // The GPU traces every pixel deeply at any time; holding the depth
    // steady means nothing shifts when the stone comes to rest.
    _renderer.maxBounces = gpu ? 10 : (quality ? 11 : 8);
    final sw = Stopwatch()..start();
    _renderer.paint(
      canvas,
      size,
      view: SimView(
        tilt: (_tilt + rock).clamp(-math.pi / 2, math.pi / 2),
        spin: _spin,
        zoom: _zoom,
      ),
      pxPerUnit: pxPerMm * _mmPerUnit,
      samplePx: quality ? math.max(3.6, _samplePx * 0.55) : _samplePx,
      devicePixelRatio: _dpr,
      time: _time,
      twinkle: _ticker.isActive,
    );
    sw.stop();
    if (!quality && !gpu) _adapt(sw.elapsedMicroseconds / 1000);
    _report();
  }

  /// Keeps moving frames near 7 ms of tracing.
  void _adapt(double ms) {
    _cost = _cost == 0 ? ms : _cost * 0.8 + ms * 0.2;
    if (_cost > 9) {
      _samplePx = math.min(20, _samplePx * 1.1);
    } else if (_cost < 4.5) {
      _samplePx = math.max(5.5, _samplePx / 1.06);
    }
  }

  void _report() {
    final s = _renderer.stats;
    const k = 0.2;
    _brightness += (s.brightness - _brightness) * k;
    _fire += (s.fire - _fire) * k;
    _sparkle += (s.sparkle - _sparkle) * k;
    if (++_frames % 10 != 0 && _ticker.isActive) return;
    final value = SimLightReadout(
      brightness: _brightness,
      fire: _fire,
      sparkle: _sparkle,
    );
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) _c.readout.value = value;
    });
  }

  void _ensureTicking() {
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    _dpr = MediaQuery.devicePixelRatioOf(context);
    ref.listen(diamondSimulatorProvider.select((s) => (s.mesh, s.inclusions)), (
      _,
      next,
    ) {
      _renderer.setStone(next.$1, next.$2);
      _radius = next.$1.radius;
      _invalidate();
    });
    ref.listen(diamondSimulatorProvider.select((s) => (s.spec, s.lighting)), (
      _,
      next,
    ) {
      _renderer.setOptics(SimOptics.of(next.$1, next.$2));
      _invalidate();
    });
    ref.listen(diamondSimulatorProvider.select((s) => s.mmPerUnit), (_, next) {
      _mmPerUnit = next;
      _invalidate();
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final k = 2.8 / math.max(160.0, constraints.biggest.shortestSide);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onDoubleTap: () {
            AppHaptics.light();
            _zoom = 1;
            _c.zoom.value = 1;
            _c.show(SimViewPreset.angled);
          },
          onScaleStart: (d) {
            _dragging = true;
            _startZoom = _zoom;
            _anim = 1;
            _wSpin = 0;
            _wTilt = 0;
            _ensureTicking();
          },
          onScaleUpdate: (d) {
            _spin += d.focalPointDelta.dx * k * 1.2;
            _tilt = (_tilt + d.focalPointDelta.dy * k).clamp(
              -math.pi / 2,
              math.pi / 2,
            );
            if (d.pointerCount > 1) {
              _zoom = (_startZoom * d.scale).clamp(0.6, 3.2);
              _c.zoom.value = _zoom;
            }
          },
          onScaleEnd: (d) {
            _dragging = false;
            final v = d.velocity.pixelsPerSecond;
            _wSpin = (v.dx * k * 1.2).clamp(-9.0, 9.0);
            _wTilt = (v.dy * k * 0.5).clamp(-3.0, 3.0);
            _syncTicker();
          },
          child: RepaintBoundary(
            child: CustomPaint(painter: _SimPainter(this), size: Size.infinite),
          ),
        );
      },
    );
  }
}

class _SimPainter extends CustomPainter {
  _SimPainter(this.state) : super(repaint: state._frame);

  final _DiamondSimViewportState state;

  @override
  void paint(Canvas canvas, Size size) => state._paint(canvas, size);

  @override
  bool shouldRepaint(covariant _SimPainter old) => old.state != state;
}
