import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../../luxe/luxe_spring.dart';
import 'diamond_cut.dart';
import 'diamond_mesh.dart';

/// Where a tab transition currently is.
enum DiamondTransitionPhase {
  idle,

  /// The outgoing page folds into the gem (or unfolds back on cancel).
  wrapping,

  /// The gem has just closed.
  formed,

  /// The gem turns; facets passing behind it swap to the incoming page.
  rotating,

  /// Finger down on the bar: progress, turn and cut follow the finger.
  previewing,

  /// The incoming page unfolds out of the gem.
  unwrapping,

  /// Final frame before the live page takes over.
  completed,
}

enum _Mode { idle, arming, gesture, cancelling, auto }

/// Captures the page area at [scale] × the device pixel ratio.
typedef DiamondCapture = DiamondSnapshot? Function(double scale);

/// State machine for the diamond tab transition.
///
/// One normalised progress value drives the whole sequence:
///
/// ```text
/// 0 ── fold ── 0.44 ── formed / rotate ── 0.62 ── unfold ── 1
/// ```
///
/// A tap runs it automatically. A held or dragged bar ([scrubStart] …
/// [scrubEnd]) maps the finger to progress (distance from the original tab,
/// up to the formed gem), turn (signed offset) and cut (position between
/// tabs). Nothing advances on its own while the finger is down, and the
/// destination is only resolved — and navigated to, once — on release.
///
/// The outgoing page is snapshot and re-captured while it is still mounted;
/// after navigation the incoming page is captured live every few frames, so
/// both halves stay current. Grid columns swap from outgoing to incoming
/// only while they are turned away from the viewer, so the swap itself is
/// never seen.
class DiamondTransitionController extends ChangeNotifier
    implements DiamondFrameSource {
  DiamondTransitionController({
    required TickerProvider vsync,
    required this.routes,
    required this.cuts,
    required this.navigate,
    required this.currentPath,
    required this.currentTab,
  }) : assert(routes.length == cuts.length && routes.length >= 2) {
    _ticker = vsync.createTicker(_tick);
    _lifecycle = AppLifecycleListener(onStateChange: _onLifecycle);
    // Facet geometry is built once per cut; do it while the app is idle.
    SchedulerBinding.instance.scheduleTask(
      () => DiamondCut.warmUp(cuts),
      Priority.idle,
    );
  }

  /// Route of each tab, in bar order.
  final List<String> routes;

  /// Cut each tab transforms into.
  final List<DiamondCut> cuts;

  final ValueChanged<String> navigate;
  final ValueGetter<String> currentPath;

  /// Tab index the current route belongs to (browse screens count as
  /// their tab), or null.
  final ValueGetter<int?> currentTab;

  /// Installed by [DiamondTabTransition] while it is mounted.
  DiamondCapture? capture;

  static const wrapEnd = 0.44;
  static const unwrapStart = 0.62;
  static const _spinEnd = 0.84;
  static const _forceSwap = 0.70;
  static const duration = Duration(milliseconds: 820);

  /// Finger distance (in tab widths) that fully forms the gem.
  static const _formDistance = 0.85;

  /// Turn per tab width of finger travel.
  static const _turnPerTab = 0.85 * math.pi;
  static const _follow = 0.06; // s
  static const _cutFollow = 0.12; // s

  late final Ticker _ticker;
  late final AppLifecycleListener _lifecycle;
  Duration _last = Duration.zero;
  int _frame = 0;

  _Mode _mode = _Mode.idle;
  DiamondTransitionPhase _phase = DiamondTransitionPhase.idle;
  double _p = 0;
  double _angle = 0;

  // Gesture.
  int _origin = 0;
  String _originRoute = '';
  double _finger = 0;
  double _fingerShown = 0;
  bool _lateGesture = false;
  bool _releasePending = false;
  double _cancelFromP = 0, _cancelFromAngle = 0;

  // Commit.
  int? _dest;
  int? _armedDest;
  int? _queuedDest;
  bool _reforming = false;
  String? _expectedRoute;
  double _spinFrom = 0, _spinTo = 0, _spinP0 = 0, _spinP1 = _spinEnd;
  double _holdFor = 0;

  // Cut blend.
  DiamondCut _cutFrom = DiamondCut.brilliant;
  DiamondCut _cutTo = DiamondCut.brilliant;
  double _blend = 1;

  // Textures.
  final _snaps = <int, DiamondSnapshot>{};
  final _faces = Uint8List(DiamondGrid.triangleCount);
  int _live = 0;
  int _target = 0;
  bool _captureQueued = false;
  double _captureScale = 1;

  /// True while the overlay covers the page.
  final ValueNotifier<bool> active = ValueNotifier(false);

  /// Route transitions are neutralised while a committed switch runs, so
  /// the incoming page is captured at rest.
  final ValueNotifier<bool> suppressRouteTransitions = ValueNotifier(false);

  /// Tab under the finger while previewing.
  final ValueNotifier<int?> preview = ValueNotifier(null);

  DiamondTransitionPhase get phase => _phase;
  double get progress => _p;
  bool get isActive => _mode != _Mode.idle;

  /// The route the app should be on right now; any other route change
  /// while active is external and aborts the transition.
  String? get expectedRoute => _mode == _Mode.idle ? null : _expectedRoute;

  // DiamondFrameSource.
  @override
  double get wrap => wrapOf(_p);
  @override
  double get angle => _angle;
  @override
  DiamondCut get cutFrom => _cutFrom;
  @override
  DiamondCut get cutTo => _cutTo;
  @override
  double get cutBlend => _blend;
  @override
  Uint8List get faceTextures => _faces;
  @override
  int get swapTo =>
      _mode == _Mode.auto && _snaps[_target] != null ? _target : -1;
  @override
  DiamondSnapshot? snapshot(int id) => _snaps[id];

  /// Wrap amount at progress [p].
  static double wrapOf(double p) {
    if (p <= wrapEnd) return (p / wrapEnd).clamp(0.0, 1.0);
    if (p <= unwrapStart) return 1;
    return ((1 - p) / (1 - unwrapStart)).clamp(0.0, 1.0);
  }

  // ---------------------------------------------------------------------------
  // Input

  /// Tap on tab [index]: run (or redirect) a full transition.
  void requestTab(int index) {
    switch (_mode) {
      case _Mode.idle:
        if (routes[index] == currentPath()) return;
        _arm(tapDest: index);
      case _Mode.arming:
        if (_armedDest != null) _armedDest = index;
      case _Mode.gesture:
        break;
      case _Mode.cancelling:
        if (routes[index] == _originRoute) return;
        _commit(index, cuts[index].direction * (index >= _origin ? 1 : -1));
      case _Mode.auto:
        _retarget(index);
    }
  }

  /// Finger down / drag start on the bar at tab coordinate [slot]
  /// (0 = centre of the first tab, 1 = the next, …).
  void scrubStart(double slot) {
    _finger = slot;
    switch (_mode) {
      case _Mode.idle:
        _arm();
      case _Mode.cancelling:
        // Grab the gem again on its way back.
        _mode = _Mode.gesture;
        _releasePending = false;
        _wake();
      case _Mode.auto:
        _lateGesture = true;
      case _Mode.arming:
      case _Mode.gesture:
        break;
    }
    _syncPreview();
  }

  void scrubUpdate(double slot) {
    _finger = slot;
    if (_mode == _Mode.gesture) _wake();
    _syncPreview();
  }

  /// Finger lifted: resolve the destination under it.
  void scrubEnd() {
    switch (_mode) {
      case _Mode.arming:
        _releasePending = true;
      case _Mode.gesture:
        _release();
      case _Mode.auto:
        if (_lateGesture) _retarget(_hovered);
      case _Mode.idle:
      case _Mode.cancelling:
        break;
    }
    _lateGesture = false;
    _syncPreview();
  }

  /// Gesture taken away (system, scroll, popup): restore the origin.
  void scrubCancel() {
    _lateGesture = false;
    if (_mode == _Mode.gesture) _cancel();
    if (_mode == _Mode.arming && _armedDest == null) _finishIdle();
    _syncPreview();
  }

  /// External navigation or lost surface: drop the overlay immediately.
  void abort() {
    if (_mode == _Mode.idle) return;
    _finishIdle();
  }

  int get _hovered => _finger.round().clamp(0, routes.length - 1);

  void _syncPreview() {
    final shown = _mode == _Mode.gesture || _mode == _Mode.arming
        ? (_armedDest == null ? _hovered : null)
        : (_lateGesture ? _hovered : null);
    if (preview.value != shown) preview.value = shown;
  }

  // ---------------------------------------------------------------------------
  // Transitions

  void _arm({int? tapDest}) {
    final path = currentPath();
    _origin = currentTab() ?? _hovered;
    _originRoute = path;
    _expectedRoute = path;
    _armedDest = tapDest;
    _releasePending = false;
    _p = 0;
    _angle = 0;
    _fingerShown = _finger;
    final cut = cuts[tapDest ?? _origin];
    _cutFrom = cut;
    _cutTo = cut;
    _blend = 1;
    _mode = _Mode.arming;
    // Capture once the current frame has painted the page.
    SchedulerBinding.instance.addPostFrameCallback((_) => _armed());
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  void _armed() {
    if (_mode != _Mode.arming) return;
    final snap = _capture(1);
    final dest = _armedDest;
    if (snap == null) {
      // Nothing to wrap: plain navigation.
      _finishIdle();
      if (dest != null) navigate(routes[dest]);
      return;
    }
    _disposeSnaps();
    _live = _target = 0;
    _snaps[0] = snap;
    _faces.fillRange(0, _faces.length, 0);
    active.value = true;
    if (dest != null) {
      _commit(dest, cuts[dest].direction * (dest >= _origin ? 1 : -1));
    } else {
      _mode = _Mode.gesture;
      if (_releasePending) _release();
    }
    _syncPreview();
    _wake();
  }

  void _release() {
    final dest = _hovered;
    if (routes[dest] == _originRoute) {
      _cancel();
    } else {
      final sign = _finger >= _origin ? 1 : -1;
      _commit(dest, sign);
    }
  }

  void _cancel() {
    _mode = _Mode.cancelling;
    _cancelFromP = _p;
    _cancelFromAngle = _angle;
    _wake();
  }

  /// Navigates to [dest] and plans the rest of the sequence from the
  /// current state, so nothing jumps.
  void _commit(int dest, int sign) {
    _dest = dest;
    _queuedDest = null;
    _reforming = false;
    _mode = _Mode.auto;
    _holdFor = 0;
    // Formed gem: rewind inside the formed band (same shape) so the turn
    // gets its full stage.
    if (_p > wrapEnd) _p = wrapEnd;

    const clearance = math.pi + 0.6; // enough turn to hide every column
    const lap = 2 * math.pi;
    _spinFrom = _angle;
    _spinTo = sign >= 0
        ? lap * ((_angle + clearance) / lap).ceil()
        : lap * ((_angle - clearance) / lap).floor();
    _spinP0 = _p;
    _spinP1 = math.max(_spinEnd, _p + 0.2);

    // Fresh texture slot for the incoming page; the previous live page is
    // frozen as it is.
    _target = _live = _freeSlot();
    _expectedRoute = routes[dest];
    suppressRouteTransitions.value = true;
    navigate(routes[dest]);
    _wake();
  }

  void _retarget(int dest) {
    if (dest == _dest && _queuedDest == null) return;
    if (_p > unwrapStart) {
      // Fold the half-revealed page back into the gem first.
      _reforming = true;
      _queuedDest = dest == _dest ? null : dest;
      if (_queuedDest == null) _reforming = false;
    } else {
      _commit(dest, _spinTo >= _spinFrom ? 1 : -1);
    }
    _wake();
  }

  int _freeSlot() {
    for (var id = 0; id < 255; id++) {
      if (!_snaps.containsKey(id) && !_faces.contains(id)) return id;
    }
    return 0;
  }

  void _finishIdle() {
    _ticker.stop();
    _mode = _Mode.idle;
    _phase = DiamondTransitionPhase.idle;
    _p = 0;
    _angle = 0;
    _dest = _armedDest = _queuedDest = null;
    _reforming = _lateGesture = _releasePending = false;
    _expectedRoute = null;
    active.value = false;
    suppressRouteTransitions.value = false;
    _disposeSnaps();
    _syncPreview();
    notifyListeners();
  }

  void _onLifecycle(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed || _mode == _Mode.idle) return;
    // Never leave the app half-transitioned in the background.
    final queued = _queuedDest;
    _finishIdle();
    if (queued != null) navigate(routes[queued]);
  }

  // ---------------------------------------------------------------------------
  // Frame loop

  void _wake() {
    if (_mode == _Mode.idle || _mode == _Mode.arming) return;
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _tick(Duration now) {
    final dt = LuxeSpring.frameDelta(now, _last);
    _last = now;
    _frame++;
    final speed = dt * 1000 / duration.inMilliseconds;
    var resting = false;

    switch (_mode) {
      case _Mode.idle:
      case _Mode.arming:
        _ticker.stop();
        return;

      case _Mode.gesture:
        resting = _followFinger(dt);

      case _Mode.cancelling:
        _p = math.max(0, _p - speed);
        _angle = _cancelFromP <= 1e-6
            ? 0
            : _cancelFromAngle * (_p / _cancelFromP);
        if (_p <= 0) {
          _phase = DiamondTransitionPhase.completed;
          _finishIdle();
          return;
        }

      case _Mode.auto:
        _followCut(dt, cuts[_dest!]);
        if (_reforming) {
          _p = math.max(unwrapStart, _p - speed);
          if (_p <= unwrapStart) {
            final queued = _queuedDest;
            _reforming = false;
            if (queued != null) {
              _commit(queued, _spinTo >= _spinFrom ? 1 : -1);
            }
          }
        } else {
          final waiting = _snaps[_target] == null && _p >= wrapEnd;
          if (waiting && _holdFor < 1.2) {
            _holdFor += dt;
          } else {
            _p = math.min(1, _p + speed);
          }
          final t = ((_p - _spinP0) / (_spinP1 - _spinP0)).clamp(0.0, 1.0);
          _angle = _spinFrom + (_spinTo - _spinFrom) * _spinCurve(t);
        }
        _settleFaces();
        if (_p >= 1) {
          _phase = DiamondTransitionPhase.completed;
          notifyListeners();
          _finishIdle();
          return;
        }
    }

    _phase = _phaseNow();
    _queueCapture();
    notifyListeners();
    if (resting) _ticker.stop();
  }

  /// Gesture targets from the finger; returns true once at rest there.
  bool _followFinger(double dt) {
    final offset = _finger - _origin;
    final form = (offset.abs() / _formDistance).clamp(0.0, 1.0);
    final targetP = wrapEnd * form;
    // The turn engages as the gem closes, so a flat page never spins.
    final gate = _smooth(0.2, 0.8, wrapOf(targetP));
    final targetAngle = _turnPerTab * offset * gate;

    final k = 1 - math.exp(-dt / _follow);
    _p += (targetP - _p) * k;
    _angle += (targetAngle - _angle) * k;
    _fingerShown += (_finger - _fingerShown) * k;

    final last = cuts.length - 1;
    final x = _fingerShown.clamp(0.0, last.toDouble());
    final i0 = x.floor().clamp(0, last - 1);
    _cutFrom = cuts[i0];
    _cutTo = cuts[i0 + 1];
    _blend = _smooth(0.25, 0.75, x - i0);

    // Within an invisible margin: land exactly and stop the ticker.
    final rest =
        (targetP - _p).abs() < 5e-4 &&
        (targetAngle - _angle).abs() < 2e-3 &&
        (_finger - _fingerShown).abs() < 2e-3;
    if (rest) {
      _p = targetP;
      _angle = targetAngle;
      _fingerShown = _finger;
    }
    return rest;
  }

  void _followCut(double dt, DiamondCut dest) {
    final k = 1 - math.exp(-dt / _cutFollow);
    if (_cutTo == dest) {
      _blend += (1 - _blend) * k;
    } else if (_cutFrom == dest) {
      _blend += (0 - _blend) * k;
    } else {
      _cutFrom = _blend < 0.5 ? _cutFrom : _cutTo;
      _cutTo = dest;
      _blend = 0;
    }
  }

  double _spinCurve(double t) {
    final spin = cuts[_dest!].spin;
    switch (spin) {
      case DiamondSpin.glide:
        return Curves.easeInOutCubic.transform(t);
      case DiamondSpin.detent:
        // Indexes past its stop and settles back, like a turntable.
        return const Cubic(0.55, 0, 0.3, 1.18).transform(t);
      case DiamondSpin.precess:
        return Curves.easeInOutSine.transform(t);
    }
  }

  /// Faces swap to the incoming page while turned away (in the mesh);
  /// past [_forceSwap] any left over swap regardless.
  void _settleFaces() {
    if (_p >= _forceSwap && _snaps[_target] != null) {
      _faces.fillRange(0, _faces.length, _target);
    }
    _retireSnaps();
  }

  DiamondTransitionPhase _phaseNow() {
    switch (_mode) {
      case _Mode.idle:
        return DiamondTransitionPhase.idle;
      case _Mode.gesture:
        return DiamondTransitionPhase.previewing;
      case _Mode.arming:
      case _Mode.cancelling:
        return DiamondTransitionPhase.wrapping;
      case _Mode.auto:
        if (_reforming) return DiamondTransitionPhase.rotating;
        if (_p < wrapEnd) return DiamondTransitionPhase.wrapping;
        if (_p < wrapEnd + 0.05) return DiamondTransitionPhase.formed;
        if (_p <= unwrapStart) return DiamondTransitionPhase.rotating;
        return DiamondTransitionPhase.unwrapping;
    }
  }

  // ---------------------------------------------------------------------------
  // Snapshots

  void _queueCapture() {
    final committed = _mode == _Mode.auto;
    final missing = _snaps[_live] == null;
    final every = !committed
        ? 2
        : (missing || _p > unwrapStart || _reforming ? 1 : 3);
    if (_frame % every != 0 && !missing) return;
    if (_captureQueued) return;
    _captureQueued = true;
    // A small gem doesn't need full resolution.
    _captureScale = wrap > 0.7 ? 0.5 : 1;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _captureQueued = false;
      if (_mode == _Mode.idle || _mode == _Mode.arming) return;
      final snap = _capture(_captureScale);
      if (snap == null) return;
      _snaps.remove(_live)?.dispose();
      _snaps[_live] = snap;
    });
  }

  DiamondSnapshot? _capture(double scale) {
    try {
      return capture?.call(scale);
    } catch (_) {
      return null;
    }
  }

  void _retireSnaps() {
    final keep = <int>{..._faces, _live, _target};
    _snaps.removeWhere((id, snap) {
      if (keep.contains(id)) return false;
      snap.dispose();
      return true;
    });
  }

  void _disposeSnaps() {
    for (final snap in _snaps.values) {
      snap.dispose();
    }
    _snaps.clear();
  }

  static double _smooth(double a, double b, double x) {
    final t = ((x - a) / (b - a)).clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _lifecycle.dispose();
    _disposeSnaps();
    active.dispose();
    suppressRouteTransitions.dispose();
    preview.dispose();
    super.dispose();
  }
}
