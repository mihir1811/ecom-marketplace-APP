import 'dart:math' as math;

/// Under-damped spring physics shared by the luxe surfaces (the brand
/// directory's A–Z index, the bottom navigation dock).
///
/// Springs are integrated by hand on a [Ticker] rather than through
/// [AnimationController]s so many bodies can share one ticker, retarget
/// mid-flight without restarting, and keep their velocity when they do.
abstract final class LuxeSpring {
  /// One semi-implicit Euler step of a damped spring towards [target].
  ///
  /// [k] is stiffness, [zeta] the damping ratio (< 1 overshoots). Writes the
  /// new position and velocity through [out] and returns a rough residual
  /// energy, so callers can stop their ticker once everything settles.
  static double step(
    double x,
    double v,
    double target,
    double k,
    double zeta,
    double dt,
    void Function(double x, double v) out,
  ) {
    final c = 2 * zeta * math.sqrt(k);
    final a = k * (target - x) - c * v;
    final nv = v + a * dt;
    final nx = x + nv * dt;
    out(nx, nv);
    return (target - nx).abs() + nv.abs() * 0.02;
  }

  /// Frame delta in seconds from two ticker timestamps, clamped so a slow
  /// frame can't blow up a stiff spring.
  static double frameDelta(Duration now, Duration last) {
    final dt = last == Duration.zero
        ? 1 / 60
        : (now - last).inMicroseconds / 1e6;
    return dt.clamp(1 / 240, 1 / 30);
  }

  /// Sub-steps for [dt] so stiff springs stay stable at any frame rate.
  static int subSteps(double dt) => (dt / (1 / 240)).ceil();

  /// Soft bump on u ∈ (-1, 1): an oval crown (≈ 1 − u²/2 at the top) whose
  /// shoulders meet the baseline with zero slope and finite curvature, so a
  /// surface bent by it never shows a corner where the bend begins.
  static double oval(double u) {
    if (u.abs() >= 1) return 0;
    final s = u * u;
    return (1 - s) * (1 - s) * (1 + 1.5 * s);
  }
}
