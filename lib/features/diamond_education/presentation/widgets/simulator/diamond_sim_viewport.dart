import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/haptics/app_haptics.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../application/diamond_simulator_controller.dart';
import '../../../domain/diamond_grades.dart';
import '../../sim_labels.dart';
import '../../../simulation/sim_optics.dart';
import '../../../simulation/sim_inclusion_plot.dart';
import '../../../simulation/sim_inclusions.dart';
import '../../../simulation/sim_mesh.dart';
import '../../../simulation/sim_morph.dart';
import '../../../simulation/sim_quality.dart';
import '../../../simulation/sim_renderer.dart';
import '../../../simulation/sim_wireframe.dart';
import 'sim_inclusion_callouts.dart';

/// Camera presets for the simulated stone.
enum SimViewPreset {
  faceUp(math.pi / 2),
  angled(0.95),
  profile(0),
  pavilion(-math.pi / 2);

  const SimViewPreset(this.tilt);

  final double tilt;
}

/// How the stone is drawn: traced in light, or as a 3D line drawing of
/// its facet edges alone. Every control works in both.
enum SimRenderMode { realistic, vector }

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

  SimRenderMode _mode = SimRenderMode.realistic;
  SimRenderMode get mode => _mode;
  set mode(SimRenderMode value) {
    if (value == _mode) return;
    _mode = value;
    notifyListeners();
  }

  bool get vector => _mode == SimRenderMode.vector;

  SimViewPreset _preset = SimViewPreset.angled;
  int _presetRequest = 0;
  SimViewPreset get preset => _preset;

  void show(SimViewPreset preset) {
    _preset = preset;
    _presetRequest++;
    notifyListeners();
  }

  /// Smoothed light performance, a few times a second. Measured only
  /// while something listens.
  final readout = _ReadoutNotifier();

  /// Current zoom (pinch), for the scale bar.
  final zoom = ValueNotifier(1.0);

  /// Whether the hand view shows the hand at life size rather than whole.
  final lifeSize = ValueNotifier(false);

  /// Whether the 3D hand has been turned away from its starting view.
  final handTurned = ValueNotifier(false);

  /// Bumped to turn the hand back to its starting view.
  final handRecentre = ValueNotifier(0);

  /// A shape change in progress (the shape dial): while set, the stone
  /// shown is this one rather than the selected stone.
  final morph = ValueNotifier<SimMorphFrame?>(null);

  /// Radius in logical pixels the stone should keep within, e.g. inside
  /// the shape dial's ring; null for its natural size. The stone eases to
  /// and from it.
  final fit = ValueNotifier<double?>(null);

  /// Where the stone should sit, e.g. above the inclusion picker with
  /// room for labels either side; null for the viewport's centre. Eases
  /// with [fit].
  final stage = ValueNotifier<Rect?>(null);

  /// Whether inclusions are labelled outside the stone, with arrows to
  /// each (line drawing only).
  final labelled = ValueNotifier(false);

  /// The inclusion kind whose label is highlighted; a tap on a label
  /// sets it.
  final focus = ValueNotifier<InclusionType?>(null);

  /// Whether the stone is shown for its inclusions: the traced stone's
  /// surface eases down so they read clearly through it.
  final inclusionView = ValueNotifier(false);

  @override
  void dispose() {
    inclusionView.dispose();
    fit.dispose();
    stage.dispose();
    labelled.dispose();
    focus.dispose();
    readout.dispose();
    zoom.dispose();
    lifeSize.dispose();
    handTurned.dispose();
    handRecentre.dispose();
    morph.dispose();
    super.dispose();
  }
}

/// The stone partway from one shape to the next: a single stone, worked
/// out only when drawn ([SimShapeMorph]).
class SimMorphFrame {
  SimMorphFrame({
    required this.from,
    required this.to,
    required this.t,
    this.morph,
  });

  /// Just [stone], at rest.
  SimMorphFrame.still(DiamondSimulatorState stone)
    : this(from: stone, to: stone, t: 0);

  final DiamondSimulatorState from, to;

  /// 0 at [from], 1 at [to].
  final double t;
  final SimShapeMorph? morph;

  late final SimMesh mesh = morph?.at(t) ?? (t < 0.5 ? from.mesh : to.mesh);

  /// Clarity characteristics are each stone's own: the old ones shrink
  /// away over the first half, the new ones grow in over the second, so
  /// none ever jumps.
  late final List<SimInclusion> inclusions = _inclusions();

  List<SimInclusion> _inclusions() {
    if (t <= 0) return from.inclusions;
    if (t >= 1) return to.inclusions;
    final k = t < 0.5 ? 1 - 2 * t : 2 * t - 1;
    final source = t < 0.5 ? from.inclusions : to.inclusions;
    if (k <= 0.001) return const [];
    return [for (final c in source) c.resized(c.size * k)];
  }

  /// Model units to logical pixels in a viewport of [size]: each stone's
  /// true scale for its carat weight, eased between the two.
  double pxPerUnit(Size size) {
    double of(DiamondSimulatorState s) =>
        SimScale.pxPerMm(size, s.mesh.radius * s.mmPerUnit) * s.mmPerUnit;
    final a = of(from);
    if (t <= 0) return a;
    final b = of(to);
    return a * math.pow(b / a, t).toDouble();
  }
}

/// [SimLightReadout] that knows whether anyone is showing it.
class _ReadoutNotifier extends ValueNotifier<SimLightReadout> {
  _ReadoutNotifier() : super(const SimLightReadout());

  /// Called when a listener arrives, so fresh numbers can be measured.
  VoidCallback? onWatch;

  bool get watched => hasListeners;

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    onWatch?.call();
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
/// A stone at rest is always traced at the screen's full resolution.
/// While it moves (a drag, a fling, auto-rotate, a slider being dragged),
/// [SimQuality] adapts it to what the device measurably affords: fewer
/// traced pixels, scaled up, then the surface extras, then fewer new
/// pictures a second (about 60 at most, down to 30), every other frame
/// reusing the last one untraced. Geometry, facets, bounces and fire never
/// change, and the full frame returns once the stone settles. The stone
/// starts only once the page has finished sliding in and the tracer has
/// loaded, and light is measured only while the meters are on screen. On
/// the CPU fallback, frame cost sets the sample spacing.
class DiamondSimViewport extends ConsumerStatefulWidget {
  const DiamondSimViewport({required this.controller, super.key});

  final SimViewportController controller;

  @override
  ConsumerState<DiamondSimViewport> createState() => _DiamondSimViewportState();
}

class _DiamondSimViewportState extends ConsumerState<DiamondSimViewport>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  // A frame traced in the background goes up as soon as it is ready.
  late final _renderer = SimRenderer()
    ..lowResInBackground = true
    ..onFrameReady = () {
      if (mounted) _frame.value++;
    };
  final _wire = SimWireRenderer();
  final _incPlot = SimInclusionPlot();
  final _callouts = SimInclusionCallouts();
  Locale? _calloutLocale;
  Rect? _lastStage;
  double _dt = 0;
  late SimMesh _mesh;
  late List<SimInclusion> _inclusions;

  /// What the renderer holds: the selected stone, or a morph frame's.
  SimMesh? _shownMesh;
  List<SimInclusion>? _shownInclusions;
  late SimWireStyle _wireStyle;
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

  // GPU budget, set by [SimQuality] from measured raster times. The same
  // [SimRenderer.bounces] always: changing them made facets flicker. A
  // moving stone on a device that cannot keep up is traced at fewer
  // pixels first, then, at the floor, less often; the frames between reuse
  // the last one at no tracing cost, and motion keeps its speed.
  final _quality = SimQuality.instance;

  /// Shortest gaps between newly traced frames per [SimQuality.pace],
  /// fastest first: about 60 a second (every frame on 60 and 90 Hz
  /// screens, every other on 120), then about 45 or 30, then 30.
  static const _frameGaps = [
    Duration(microseconds: 10500),
    Duration(microseconds: 20500),
    Duration(microseconds: 31000),
  ];

  /// Whether the GPU tracer is in, or failed to load (then the CPU tracer
  /// draws). Until then nothing is drawn: never a coarse stand-in.
  bool _tracerSettled = false;

  // Shrinking to sit inside [SimViewportController.fit], 0..1.
  double _fitAmount = 0;

  // Where the stone sits while fitted: its fit radius and centre (null
  // for the viewport's centre), glided from where they were whenever
  // they change, e.g. from the ring's middle up above the half ring. The
  // last ones stay for easing back out to natural size.
  double _fitFrom = 0, _fitTo = 0;
  Offset? _anchorFrom, _anchorTo;
  double _place = 1;
  Size _size = Size.zero;

  // Toning the surface down for [SimViewportController.inclusionView],
  // 0..1.
  double _focus = 0;

  // Start after the route transition; fade in.
  Animation<double>? _route;
  bool _ready = true;
  double _appear = 1;
  final Paint _fadePaint = Paint();

  SimViewportController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    final s = ref.read(diamondSimulatorProvider);
    final optics = SimOptics.of(s.spec, s.lighting);
    _renderer.setOptics(optics);
    _mesh = s.mesh;
    _inclusions = s.inclusions;
    _wireStyle = SimWireStyle.of(optics);
    _mmPerUnit = s.mmPerUnit;
    _radius = s.mesh.radius;
    _seenRequest = _c._presetRequest;
    _c.addListener(_onCommand);
    _c.morph.addListener(_invalidate);
    _c.fit.addListener(_onCommand);
    _c.stage.addListener(_onCommand);
    _c.labelled.addListener(_invalidate);
    _c.focus.addListener(_invalidate);
    _c.inclusionView.addListener(_onCommand);
    _c.readout.onWatch = _onReadoutWatched;
    _quality.attach();
    SimRenderer.loadProgram()
        .then((program) {
          if (!mounted) return;
          _renderer.shader = program.fragmentShader();
          _tracerSettled = true;
          _invalidate();
        })
        .catchError((Object _) {
          // The CPU tracer draws instead.
          if (!mounted) return;
          _tracerSettled = true;
          _invalidate();
        });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context)?.animation;
    if (route != _route) {
      _route?.removeStatusListener(_onRouteStatus);
      _route = route;
      if (route != null && !route.isCompleted) {
        // Hold the stone back while the page slides in: tracing it then
        // would compete with the transition for the GPU.
        _ready = false;
        _appear = 0;
        route.addStatusListener(_onRouteStatus);
      } else {
        _ready = true;
      }
    }
    _syncTicker();
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
    _c.morph.removeListener(_invalidate);
    _c.fit.removeListener(_onCommand);
    _c.stage.removeListener(_onCommand);
    _c.labelled.removeListener(_invalidate);
    _c.focus.removeListener(_invalidate);
    _c.inclusionView.removeListener(_onCommand);
    if (_c.readout.onWatch == _onReadoutWatched) _c.readout.onWatch = null;
    _route?.removeStatusListener(_onRouteStatus);
    _quality.detach();
    _refineTimer?.cancel();
    _ticker.dispose();
    _frame.dispose();
    _renderer.dispose();
    _callouts.clear();
    super.dispose();
  }

  void _onRouteStatus(AnimationStatus status) {
    if (!mounted || status != AnimationStatus.completed || _ready) return;
    _route?.removeStatusListener(_onRouteStatus);
    _ready = true;
    if (MediaQuery.disableAnimationsOf(context)) _appear = 1;
    _syncTicker();
    _invalidate();
  }

  void _onReadoutWatched() {
    // Listeners arrive during build; measure on the next frame.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _renderer.requestStats();
      _invalidate();
    });
  }

  void _onCommand() {
    _retarget();
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

  /// A new fit or stage: glides there from where the stone is now, or
  /// starts there when the stone is at its natural size and place.
  void _retarget() {
    final fit = _c.fit.value;
    if (fit == null) return;
    final anchor = _c.stage.value?.center;
    if (fit == _fitTo && anchor == _anchorTo) return;
    if (_fitAmount <= 0) {
      _fitFrom = fit;
      _anchorFrom = anchor;
      _place = 1;
    } else {
      _fitFrom = _fitRadiusNow;
      _anchorFrom = _anchorNow(_size);
      _place = 0;
    }
    _fitTo = fit;
    _anchorTo = anchor;
  }

  double get _placeEase => Curves.easeInOutCubic.transform(_place);

  double get _fitRadiusNow => _fitFrom + (_fitTo - _fitFrom) * _placeEase;

  Offset _anchorNow(Size size) {
    final c = size.center(Offset.zero);
    return Offset.lerp(_anchorFrom ?? c, _anchorTo ?? c, _placeEase)!;
  }

  double get _fitGoal => _c.fit.value == null ? 0 : 1;

  double get _focusGoal => _c.inclusionView.value ? 1 : 0;

  bool get _moving =>
      _appear < 1 ||
      _fitAmount != _fitGoal ||
      _place < 1 ||
      _focus != _focusGoal ||
      _c.autoRotate ||
      _dragging ||
      _anim < 1 ||
      _wSpin.abs() > 0.004 ||
      _wTilt.abs() > 0.004;

  void _syncTicker() {
    if (!_ready) {
      if (_ticker.isActive) _ticker.stop();
      return;
    }
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

  /// Waits out a burst of changes (a slider drag, quick taps) so the
  /// full resolution frame never lands between two of them.
  void _scheduleRefine() {
    _refineTimer?.cancel();
    _refineTimer = Timer(const Duration(milliseconds: 380), () {
      if (!mounted || _ticker.isActive) return;
      _refined = true;
      _frame.value++;
    });
  }

  void _tick(Duration elapsed) {
    if (_last != Duration.zero && elapsed - _last < _frameGaps[_quality.pace]) {
      return;
    }
    final dt = _last == Duration.zero
        ? 1 / 60
        : ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 1 / 20);
    _last = elapsed;
    _time += dt;
    _dt = dt;
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
    if (_appear < 1) _appear = math.min(1, _appear + dt / 0.35);
    final stage = _c.stage.value;
    if (stage != null) _lastStage = stage;
    if (_place < 1) _place = math.min(1, _place + dt / 0.6);
    final goal = _fitGoal;
    if (_fitAmount != goal) {
      _fitAmount = goal > _fitAmount
          ? math.min(goal, _fitAmount + dt / 0.45)
          : math.max(goal, _fitAmount - dt / 0.45);
    }
    final focus = _focusGoal;
    if (_focus != focus) {
      _focus = focus > _focus
          ? math.min(focus, _focus + dt / 0.4)
          : math.max(focus, _focus - dt / 0.4);
    }
    _refined = false;
    _frame.value++;
    if (!_moving) _syncTicker();
  }

  void _paint(Canvas canvas, Size size) {
    if (!_ready) return;
    // Mid shape change, the morphing stone; otherwise the selected one.
    final morph = _c.morph.value;
    final mesh = morph?.mesh ?? _mesh;
    final inclusions = morph?.inclusions ?? _inclusions;
    if (!identical(mesh, _shownMesh) ||
        !identical(inclusions, _shownInclusions)) {
      _shownMesh = mesh;
      _shownInclusions = inclusions;
      _renderer.setStone(mesh, inclusions);
    }
    var pxPerUnit =
        morph?.pxPerUnit(size) ??
        SimScale.pxPerMm(size, _radius * _mmPerUnit) * _mmPerUnit;
    _size = size;
    var centre = size.center(Offset.zero);
    final fitRadius = _fitRadiusNow;
    if (_fitAmount > 0 && fitRadius > 0) {
      final e = Curves.easeInOutCubic.transform(_fitAmount);
      final reach = mesh.radius * pxPerUnit;
      if (reach > fitRadius) {
        pxPerUnit *= 1 + (fitRadius / reach - 1) * e;
      }
      centre = Offset.lerp(centre, _anchorNow(size), e)!;
    }
    // A gentle rock while spinning, as a jeweller tilts a stone in light.
    final rock = _c.autoRotate && !_dragging
        ? 0.07 * math.sin(_time * 1.15)
        : 0.0;
    final view = SimView(
      tilt: (_tilt + rock).clamp(-math.pi / 2, math.pi / 2),
      spin: _spin,
      zoom: _zoom,
    );
    if (_c.vector) {
      _paintVector(canvas, size, view, pxPerUnit, mesh, inclusions, centre);
      return;
    }
    if (!_tracerSettled) return;
    final quality = _refined;
    final gpu = _renderer.shader != null;
    // Moving, or changed moments ago (a slider mid-drag): traced as the
    // device affords, and in full once it settles.
    final moving = !quality;
    if (moving && gpu) _quality.markMotion();
    // The same bounces moving and still, so light never jumps. A stone
    // mid-morph is not measured: the meters wait for the new shape.
    _renderer
      ..draft = gpu && _quality.draft(moving: moving)
      ..maxBounces = SimRenderer.bounces
      ..measureStats = _c.readout.watched && morph == null
      ..inclusionFocus = Curves.easeInOut.transform(_focus);
    if (quality) _renderer.requestStats();
    final fade = _appear < 1;
    if (fade) {
      _fadePaint.color = Color.fromRGBO(0, 0, 0, _appear);
      canvas.saveLayer(Offset.zero & size, _fadePaint);
    }
    final sw = Stopwatch()..start();
    _renderer.paint(
      canvas,
      size,
      view: view,
      pxPerUnit: pxPerUnit,
      samplePx: quality ? math.max(3.6, _samplePx * 0.55) : _samplePx,
      devicePixelRatio: _dpr,
      renderScale: _quality.traceScale(_dpr, moving: moving),
      pixelBudget: _quality.pixelBudget,
      time: _time,
      twinkle: _ticker.isActive,
      centre: centre,
    );
    sw.stop();
    if (fade) canvas.restore();
    if (!quality && !gpu) _adapt(sw.elapsedMicroseconds / 1000);
    if (_c.readout.watched && morph == null) _report();
  }

  /// The stone as a line drawing; light is still measured for the meters.
  void _paintVector(
    Canvas canvas,
    Size size,
    SimView view,
    double pxPerUnit,
    SimMesh mesh,
    List<SimInclusion> inclusions,
    Offset centre,
  ) {
    final fade = _appear < 1;
    if (fade) {
      _fadePaint.color = Color.fromRGBO(0, 0, 0, _appear);
      canvas.saveLayer(Offset.zero & size, _fadePaint);
    }
    _wire.paint(
      canvas,
      size,
      mesh: mesh,
      view: view,
      pxPerUnit: pxPerUnit,
      style: _wireStyle,
      inclusions: inclusions,
      inclusionPlot: _incPlot,
      centre: centre,
    );
    if (_c.labelled.value && _fitAmount > 0) {
      // Labels glide while the stone moves and settle on the still frame.
      _callouts.paint(
        canvas,
        anchors: _incPlot.anchors,
        mesh: mesh,
        stone: _wire.bounds,
        stage: _c.stage.value ?? _lastStage ?? Offset.zero & size,
        dt: _ticker.isActive ? _dt : 0,
        opacity: Curves.easeInCubic.transform(_fitAmount),
        focus: _c.focus.value,
      );
    } else {
      _callouts.rects.clear();
    }
    if (fade) canvas.restore();
    if (_c.readout.watched && _c.morph.value == null) {
      if (_refined) _renderer.requestStats();
      _renderer.measure(view);
      _report();
    }
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

  /// The labels' text in the current language.
  void _syncCalloutText(BuildContext context) {
    final locale = Localizations.maybeLocaleOf(context);
    if (locale == _calloutLocale && _calloutLocale != null) return;
    _calloutLocale = locale;
    _callouts.text = SimCalloutText(
      names: {
        for (final t in InclusionType.values) t: context.inclusionName(t),
      },
      internal: context.tr(EducationL10n.incInternal),
      external: context.tr(EducationL10n.incExternal),
      places: {for (final f in SimFacetKind.values) f: context.facetPlace(f)},
    );
  }

  /// A tap on a label highlights its kind.
  void _onTapUp(TapUpDetails d) {
    if (!_c.labelled.value) return;
    for (final e in _callouts.rects.entries) {
      if (e.value.inflate(6).contains(d.localPosition)) {
        AppHaptics.selection();
        _c.focus.value = e.key;
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _dpr = MediaQuery.devicePixelRatioOf(context);
    _syncCalloutText(context);
    ref.listen(diamondSimulatorProvider.select((s) => (s.mesh, s.inclusions)), (
      _,
      next,
    ) {
      _mesh = next.$1;
      _inclusions = next.$2;
      _radius = next.$1.radius;
      _invalidate();
    });
    ref.listen(diamondSimulatorProvider.select((s) => (s.spec, s.lighting)), (
      _,
      next,
    ) {
      final optics = SimOptics.of(next.$1, next.$2);
      _renderer.setOptics(optics);
      _wireStyle = SimWireStyle.of(optics);
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
          onTapUp: _onTapUp,
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
