import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Optional tactile feedback for meaningful UI events.
///
/// Wraps [HapticFeedback] so missing platform support never throws.
/// Callers must invoke these at committed user/event boundaries, never
/// from `build()` or unrelated state updates.
abstract final class AppHaptics {
  static DateTime? _lastAt;
  static _Kind? _lastKind;

  /// Test hook to force a no-op without touching platform channels.
  @visibleForTesting
  static bool debugDisable = false;

  /// Test hook to clear debounce state between cases.
  @visibleForTesting
  static void debugReset() {
    debugDisable = false;
    _lastAt = null;
    _lastKind = null;
  }

  /// Level 1 — short, low-intensity confirmation.
  static void light() => _play(_Kind.light, HapticFeedback.lightImpact);

  /// Level 1 — option/tab/toggle selection changed.
  ///
  /// Repeats are allowed so discrete sliders can tick on every step.
  static void selection() =>
      _play(_Kind.selection, HapticFeedback.selectionClick, allowRepeat: true);

  /// Level 2 — firm detent while scrubbing an index or dial; repeats are
  /// allowed so every step is felt, even mid-flick.
  static void detent() =>
      _play(_Kind.detent, HapticFeedback.mediumImpact, allowRepeat: true);

  /// Level 2 — a meaningful action completed or was triggered.
  static void medium() => _play(_Kind.medium, HapticFeedback.mediumImpact);

  /// Level 3 — major completion or critical confirmation.
  static void heavy() => _play(_Kind.heavy, HapticFeedback.heavyImpact);

  /// Distinct success feedback for confirmed successful operations.
  static void success() => _play(_Kind.success, HapticFeedback.mediumImpact);

  /// Distinct warning for destructive confirms and blocking states.
  static void warning() => _play(_Kind.warning, HapticFeedback.heavyImpact);

  /// Magnetic dock: a firm impact as an element lands on a screen edge,
  /// followed by a soft settle tap, so the snap is felt rather than seen.
  static void magneticSnap() {
    _play(_Kind.snap, () async {
      await HapticFeedback.heavyImpact();
      await Future<void>.delayed(const Duration(milliseconds: 85));
      await HapticFeedback.lightImpact();
    });
  }

  /// Distinct error/validation pattern. Not for ordinary recoverable UI noise.
  static void error() {
    _play(_Kind.error, () async {
      await HapticFeedback.heavyImpact();
      await Future<void>.delayed(const Duration(milliseconds: 70));
      await HapticFeedback.mediumImpact();
    });
  }

  static void _play(
    _Kind kind,
    Future<void> Function() run, {
    bool allowRepeat = false,
  }) {
    if (_shouldSkip(kind, allowRepeat: allowRepeat)) return;
    _lastAt = DateTime.now();
    _lastKind = kind;
    unawaited(_safe(run));
  }

  static bool _shouldSkip(_Kind kind, {bool allowRepeat = false}) {
    if (debugDisable || kIsWeb) return true;
    if (_reduceMotion) return true;
    final lastAt = _lastAt;
    final lastKind = _lastKind;
    if (lastAt == null || lastKind == null) return false;
    final elapsed = DateTime.now().difference(lastAt);
    if (elapsed < const Duration(milliseconds: 40) && lastKind == kind) {
      return true;
    }
    if (!allowRepeat &&
        elapsed < const Duration(milliseconds: 180) &&
        kind.rank <= lastKind.rank) {
      return true;
    }
    return false;
  }

  static bool get _reduceMotion {
    try {
      return WidgetsBinding
          .instance
          .platformDispatcher
          .accessibilityFeatures
          .disableAnimations;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _safe(Future<void> Function() run) async {
    try {
      await run();
    } catch (_) {
      // Unsupported devices, desktop shells, and emulators no-op.
    }
  }
}

enum _Kind {
  selection(1),
  light(1),
  medium(2),
  detent(2),
  success(2),
  heavy(3),
  warning(3),
  snap(3),
  error(4);

  const _Kind(this.rank);
  final int rank;
}
