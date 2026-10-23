import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sim_mesh.dart';

/// What the operating system reports about this device right now. Every
/// field may be missing (web, desktop, tests): quality then follows the
/// measured frame times alone.
@immutable
class SimDeviceState {
  const SimDeviceState({
    this.appMemoryBytes,
    this.availableBytes,
    this.lowMemory = false,
    this.powerSaving = false,
    this.thermal = 0,
  });

  /// Memory the OS lets this app use on this device: Android's memory
  /// class, the memory still available to the process on iOS.
  final int? appMemoryBytes;

  /// Memory free on the whole device (Android).
  final int? availableBytes;

  /// The OS reports memory running low, or a low-RAM device.
  final bool lowMemory;

  /// Battery saver is on: the user asked for less work.
  final bool powerSaving;

  /// Thermal stress, 0 (cool) to 1 (throttling hard), from the OS's own
  /// scale: Android's thermal headroom (1.0 = severe throttling) and
  /// status, iOS's thermal state.
  final double thermal;

  static SimDeviceState parse(Map<Object?, Object?> m) {
    int? bytes(String k) => (m[k] as num?)?.toInt();
    var thermal = 0.0;
    final headroom = (m['thermalHeadroom'] as num?)?.toDouble();
    if (headroom != null && headroom.isFinite) {
      // Stress builds over the last quarter before severe throttling.
      thermal = math.max(thermal, ((headroom - 0.75) / 0.25).clamp(0.0, 1.0));
    }
    final status = (m['thermalStatus'] as num?)?.toInt();
    if (status != null) {
      // NONE, LIGHT, MODERATE, SEVERE, CRITICAL, EMERGENCY, SHUTDOWN.
      thermal = math.max(thermal, ((status - 1) / 3).clamp(0.0, 1.0));
    }
    final state = (m['thermalState'] as num?)?.toInt();
    if (state != null) {
      // nominal, fair, serious, critical.
      thermal = math.max(
        thermal,
        const [0.0, 0.25, 0.7, 1.0][state.clamp(0, 3)],
      );
    }
    return SimDeviceState(
      appMemoryBytes: bytes('appMemoryBytes'),
      availableBytes: bytes('availableBytes'),
      lowMemory: m['lowMemory'] == true,
      powerSaving: m['powerSaving'] == true,
      thermal: thermal,
    );
  }
}

/// Adapts the diamond simulator's rendering to the device it runs on,
/// from what it measures there, never from a fixed device class:
///
/// * **Frame times.** Raster (GPU) times of frames drawn while a stone or
///   the hand moves are compared with the display's own frame budget. Too
///   slow, and moving frames are traced at fewer pixels (cost follows
///   pixel count, so the step is the square root of the overshoot), then,
///   at the floor, less often ([pace]). Fast again, and pace returns
///   first, then pixels. Smoothed, with a dead band, a settling batch
///   after each change, and quicker first steps while it learns a new
///   device; it steps down faster than up so it never oscillates.
/// * **Interaction.** Only moving frames are reduced, and the
///   surface-detail extras ([draft]) go only once pixels have; a stone at
///   rest is traced again at full quality. Geometry, facets, bounces and
///   fire are never touched, so the stone keeps its look.
/// * **Memory.** The images kept on the GPU stay within a share of the
///   memory the OS grants this app ([pixelBudget]); low memory and the
///   OS's memory pressure warnings shrink it for a while.
/// * **Heat and battery saver.** The OS's thermal headroom tightens the
///   frame budget before the device throttles, and at its hottest caps
///   still frames too.
///
/// What it learns is kept for this device, so the next session starts
/// tuned.
class SimQuality with WidgetsBindingObserver {
  SimQuality._();

  static final SimQuality instance = SimQuality._();

  static const _channel = MethodChannel('gemworld/device_perf');
  static const _prefsKey = 'sim_quality.v1';

  /// Share of the memory the OS grants this app (or of what is free on
  /// the device) the simulator's GPU images may hold.
  static const _appMemoryShare = 0.10, _availableShare = 0.02;

  /// Lowest share of the screen's resolution, per axis, a moving frame is
  /// traced at (a quarter of the pixels), and when the device is
  /// throttling hard.
  static const _floor = 0.5, _hotFloor = 0.42;

  /// Dead band around the target frame time, and the largest step down
  /// and up per change.
  static const _band = 0.12, _maxDown = 0.25, _maxUp = 0.08;

  /// Share of the display's frame budget traced frames may take, leaving
  /// the rest for everything else on screen.
  static const _budgetShare = 0.75;

  SimDeviceState _device = const SimDeviceState();
  SimDeviceState get device => _device;

  /// Share of full resolution, per axis, moving frames are traced at.
  double _motion = 1;

  /// 0 traces a moving stone up to about 60 times a second, 1 about 45 or
  /// 30, 2 about 30 (see the diamond viewport's frame gaps).
  int _pace = 0;
  int get pace => math.max(_pace, _device.thermal >= 0.85 ? 1 : 0);

  double _ewma = 0;
  int _judged = 0, _trend = 0, _settle = 0;
  Duration _motionAt = const Duration(days: -1);
  Duration _pressureUntil = Duration.zero;
  final Stopwatch _clock = Stopwatch()..start();

  int _users = 0;
  Timer? _poll;
  bool _restored = false, _dirty = false;

  /// While anything uses the simulator's renderers: frame times, memory
  /// warnings and the device's state are watched only then.
  void attach() {
    if (_users++ > 0) return;
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refresh());
    // Thermal headroom moves over seconds; asked more than once a second
    // Android answers nothing.
    _poll = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
    if (!_restored) unawaited(_restore());
  }

  void detach() {
    if (_users == 0 || --_users > 0) return;
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    _poll = null;
    if (_dirty) unawaited(_save());
  }

  /// Called on every frame a renderer draws something in motion: only
  /// those frames steer quality.
  void markMotion() => _motionAt = _clock.elapsed;

  bool get _underPressure =>
      _device.lowMemory || _clock.elapsed < _pressureUntil;

  /// Stress from heat, or the user's battery saver.
  double get _stress =>
      math.max(_device.thermal, _device.powerSaving ? 0.5 : 0.0);

  /// Traced pixels per logical pixel for a view at [dpr]: full resolution
  /// at rest, as the device affords while [moving]. Capped by
  /// [pixelBudget] separately, by the renderer, which knows its area.
  double traceScale(double dpr, {required bool moving}) {
    final stress = _stress;
    // At its hottest, still frames give a little too.
    final still = stress > 0.6 ? 1 - 0.25 * (stress - 0.6) / 0.4 : 1.0;
    final share = math.min(moving ? _motion : 1.0, still);
    final floor = math.min(
      dpr,
      math.max(1.0, dpr * (stress >= 0.85 ? _hotFloor : _floor)),
    );
    return math.max(floor, dpr * share);
  }

  /// Whether a moving frame also drops the costly surface extras (the
  /// silhouette's extra coverage samples, the clouds' finer march): only
  /// once resolution has already given way.
  bool draft({required bool moving}) => moving && _motion < 0.8;

  /// Most pixels the simulator's images may hold at once on the GPU; null
  /// where the OS does not say (no limit beyond frame times).
  int? get pixelBudget {
    final d = _device;
    double? bytes;
    if (d.appMemoryBytes case final app?) bytes = app * _appMemoryShare;
    if (d.availableBytes case final free?) {
      final b = free * _availableShare;
      bytes = bytes == null ? b : math.min(bytes, b);
    }
    if (bytes == null) return null;
    if (_underPressure) bytes *= 0.5;
    return (bytes / 4).round();
  }

  @override
  void didHaveMemoryPressure() {
    _pressureUntil = _clock.elapsed + const Duration(seconds: 45);
    SimMesh.trimCache();
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    try {
      final m = await _channel.invokeMapMethod<Object?, Object?>('snapshot');
      if (m != null) _device = SimDeviceState.parse(m);
    } catch (_) {
      // No such channel here (web, desktop, tests): frame times alone.
    }
  }

  void _onTimings(List<FrameTiming> timings) {
    // Only frames drawn while something moved; still frames trace once.
    if (timings.isEmpty || _clock.elapsed - _motionAt > _recent) return;
    if (_settle > 0) {
      // The batch after a change still holds frames from before it.
      _settle--;
      return;
    }
    // Paced, only some frames trace and the rest copy the last picture:
    // the slowest quarter are the traced ones. GPU time, not CPU: fewer
    // pixels only help the raster thread.
    final ms = [for (final t in timings) t.rasterDuration.inMicroseconds]
      ..sort();
    final top = ms.sublist(ms.length - math.max(1, ms.length ~/ 4));
    final traced = top.reduce((a, b) => a + b) / top.length / 1000;
    _ewma = _ewma == 0 ? traced : _ewma * 0.5 + traced * 0.5;
    _judged++;
    final ratio = _ewma / _targetMs;
    // While learning a new device, act on the first slow batch.
    final learning = _judged <= 3;
    if (ratio > 1 + _band) {
      _trend = math.max(1, _trend + 1);
      if (_trend < (learning ? 1 : 2)) return;
      _trend = 0;
      if (_motion > _floor + 1e-3) {
        final step = math.max(
          1 / math.sqrt(ratio),
          1 - (learning ? 0.4 : _maxDown),
        );
        _setMotion(math.max(_floor, _motion * step));
      } else if (_pace < 2) {
        _pace++;
        _changed();
      }
    } else if (ratio < 1 - _band) {
      _trend = math.min(-1, _trend - 1);
      if (_trend > -3) return;
      _trend = 0;
      // Smoothness first: pace returns before pixels do.
      if (_pace > 0) {
        _pace--;
        _changed();
      } else if (_motion < 1) {
        final step = math.min(1 / math.sqrt(ratio), 1 + _maxUp);
        _setMotion(math.min(1, _motion * step));
      }
    } else {
      _trend = 0;
    }
  }

  static const _recent = Duration(milliseconds: 300);

  /// The display's frame budget (at least a 60 Hz frame: moving stones
  /// are paced to about 60 new pictures a second), the share traced frames
  /// may take, tightened as the device heats up.
  double get _targetMs {
    var hz = 60.0;
    try {
      final views = ui.PlatformDispatcher.instance.views;
      if (views.isNotEmpty) hz = views.first.display.refreshRate;
    } catch (_) {}
    if (!hz.isFinite || hz <= 0) hz = 60;
    final budget = 1000 / math.min(hz, 60);
    return budget * _budgetShare * (1 - 0.3 * _stress);
  }

  void _setMotion(double value) {
    // Sixteenths, so tiny changes never reallocate the traced image.
    final q = (value * 16).round() / 16;
    if (q == _motion) return;
    _motion = q.clamp(_floor, 1.0);
    _changed();
  }

  void _changed() {
    _settle = 1;
    _ewma = 0;
    _dirty = true;
  }

  /// This device's screen, so what was learned on another (a restored
  /// backup) is not taken for this one.
  static String _fingerprint() {
    try {
      final v = ui.PlatformDispatcher.instance.views.first;
      final s = v.physicalSize;
      return '${s.shortestSide.round()}x${s.longestSide.round()}'
          '@${v.devicePixelRatio.toStringAsFixed(2)}';
    } catch (_) {
      return '';
    }
  }

  Future<void> _restore() async {
    _restored = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_prefsKey);
      if (saved == null || saved.length < 3 || saved[0] != _fingerprint()) {
        return;
      }
      // Only if nothing was learned meanwhile.
      if (_dirty) return;
      _motion = (double.tryParse(saved[1]) ?? 1).clamp(_floor, 1.0);
      _pace = (int.tryParse(saved[2]) ?? 0).clamp(0, 2);
      // A start, not a verdict: still re-checked from the first batch.
      _judged = 0;
    } catch (_) {}
  }

  Future<void> _save() async {
    _dirty = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, [
        _fingerprint(),
        _motion.toString(),
        _pace.toString(),
      ]);
    } catch (_) {}
  }

  @visibleForTesting
  void debugReset() {
    _device = const SimDeviceState();
    _motion = 1;
    _pace = 0;
    _ewma = 0;
    _judged = _trend = _settle = 0;
    _pressureUntil = Duration.zero;
    _restored = true;
    _dirty = false;
  }

  @visibleForTesting
  void debugSetDevice(SimDeviceState device) => _device = device;

  @visibleForTesting
  void debugJudge(List<FrameTiming> timings) {
    markMotion();
    _onTimings(timings);
  }

  @visibleForTesting
  double get debugMotion => _motion;
}
