import 'dart:math' as math;

import 'average_hand.dart';

part 'hand_scan_data.dart';

/// A point or direction in the 3D hand's space, millimetres: x toward the
/// thumb, y toward the fingertips, z out of the back of the hand. The hand
/// is a left hand, so seen from its back the thumb is on the right.
class HandVec {
  const HandVec(this.x, this.y, this.z);

  final double x, y, z;

  HandVec operator +(HandVec o) => HandVec(x + o.x, y + o.y, z + o.z);
  HandVec operator -(HandVec o) => HandVec(x - o.x, y - o.y, z - o.z);
  HandVec operator *(double k) => HandVec(x * k, y * k, z * k);
  HandVec operator -() => HandVec(-x, -y, -z);

  double dot(HandVec o) => x * o.x + y * o.y + z * o.z;

  HandVec cross(HandVec o) =>
      HandVec(y * o.z - z * o.y, z * o.x - x * o.z, x * o.y - y * o.x);

  double get length => math.sqrt(dot(this));

  HandVec get unit {
    final l = length;
    return l == 0 ? this : this * (1 / l);
  }
}

/// A capsule that stays inside the flesh of one segment of the hand, for
/// telling when the hand stands between the eye and a stone.
class HandBone {
  const HandBone(this.start, this.end, this.r0, this.r1);

  final HandVec start, end;

  /// Radius at [start] and at [end].
  final double r0, r1;

  double radius(double h) => r0 + (r1 - r0) * h;
}

/// Where a ring sits on a finger: around the base of the proximal
/// phalanx against the web, its stone on the back of the finger.
class HandSeat {
  const HandSeat({
    required this.position,
    required this.normal,
    required this.along,
    required this.halfWidth,
    required this.bone,
    required this.centre,
    required this.radii,
  });

  /// On the skin at the back of the finger, where the stone's head sits.
  final HandVec position;

  /// Out of the back of the finger, and along it toward the tip.
  final HandVec normal, along;

  /// Half the finger's width just past the web (its ring size).
  final double halfWidth;

  /// Index of the finger's proximal segment in [HandModel.bones].
  final int bone;

  /// The finger's cross-section through the seat: its centre, and the
  /// skin's distance from it every 360° / [radii].length, starting at
  /// [normal] and turning toward [lateral].
  final HandVec centre;
  final List<double> radii;

  /// Across the finger: [along] × [normal].
  HandVec get lateral => along.cross(normal);

  /// The skin's distance from [centre] at angle [a] (radians from
  /// [normal] toward [lateral]).
  double radiusAt(double a) {
    final n = radii.length;
    var t = a / (2 * math.pi) * n;
    t -= n * (t / n).floorToDouble();
    final i = t.floor() % n;
    final f = t - t.floorToDouble();
    return radii[i] + (radii[(i + 1) % n] - radii[i]) * f;
  }
}

/// A real adult left hand: a photographed 3D scan (LibHand, CC BY 3.0) in
/// its relaxed pose, drawn by `HandRenderer` from `assets/models/hand.bin`.
///
/// Scaled so the hand measures about 168 mm from wrist crease to middle
/// fingertip, with each finger slimmed to an average ring size where a
/// ring sits, as [AverageHand] does: ring US 6 (16.5 mm), middle US 7,
/// index US 6½, little US 4, so stones read the same as on the trade
/// charts. This class holds what the stage needs without the mesh: ring
/// seats, framing points and occluding capsules.
abstract final class HandModel {
  static const List<HandBone> bones = _scanBones;

  static int _digit(HandFinger f) => switch (f) {
    HandFinger.little => 0,
    HandFinger.ring => 1,
    HandFinger.middle => 2,
    HandFinger.forefinger => 3,
  };

  static final Map<HandFinger, HandSeat> _seats = {
    for (final f in HandFinger.values)
      f: () {
        final s = _scanSeats[_digit(f)];
        final n = s.normal.unit;
        final a = s.along - n * s.along.dot(n);
        return HandSeat(
          position: s.centre + n * s.radii[0],
          normal: n,
          along: a.unit,
          halfWidth: s.halfWidth,
          bone: s.bone,
          centre: s.centre,
          radii: s.radii,
        );
      }(),
  };

  static HandSeat seat(HandFinger f) => _seats[f]!;

  /// The point the hand turns about: among the ring seats, a little in
  /// from the back of the hand.
  static final HandVec pivot = () {
    var s = const HandVec(0, 0, 0);
    for (final f in HandFinger.values) {
      s = s + seat(f).position;
    }
    return s * (1 / HandFinger.values.length) + const HandVec(0, -8, -10);
  }();

  /// The forearm fades out between these heights (hand y, mm).
  static const double fadeStart = _scanFadeStart, fadeEnd = _scanFadeEnd;

  /// Points on the skin all over the hand above the wrist, for framing.
  static final List<HandVec> outline = [
    for (var i = 0; i + 2 < _scanOutline.length; i += 3)
      HandVec(_scanOutline[i], _scanOutline[i + 1], _scanOutline[i + 2]),
  ];

  /// Points on the four fingers, knuckles up: what the stage frames.
  static final List<HandVec> focus = [
    for (var i = 0; i + 2 < _scanFocus.length; i += 3)
      HandVec(_scanFocus[i], _scanFocus[i + 1], _scanFocus[i + 2]),
  ];

  /// Texture coordinates (0..1) of a white patch of the skin and normal
  /// maps that no skin maps to, for drawing other things in the G-buffer.
  static const double patchU = _scanPatchU, patchV = _scanPatchV;

  /// A sphere around the whole hand, forearm stub included.
  static final ({HandVec c, double r}) bounds = () {
    var lo = const HandVec(1e9, 1e9, 1e9), hi = const HandVec(-1e9, -1e9, -1e9);
    void add(HandVec p, double r) {
      lo = HandVec(
        math.min(lo.x, p.x - r),
        math.min(lo.y, p.y - r),
        math.min(lo.z, p.z - r),
      );
      hi = HandVec(
        math.max(hi.x, p.x + r),
        math.max(hi.y, p.y + r),
        math.max(hi.z, p.z + r),
      );
    }

    for (final p in outline) {
      add(p, 4);
    }
    // The forearm stub below the framing points: as wide as the wrist.
    add(HandVec((lo.x + hi.x) / 2, fadeEnd, (lo.z + hi.z) / 2), 32);
    final c = (lo + hi) * 0.5;
    var r = 0.0;
    for (final p in outline) {
      r = math.max(r, (p - c).length + 4);
    }
    r = math.max(r, (HandVec(c.x, fadeEnd, c.z) - c).length + 32);
    return (c: c, r: r);
  }();

  /// How much of a stone [lift] mm above [seat] can be seen from [eye]
  /// (hand space), 0..1: none once the back of the finger turns away or
  /// another part of the hand stands in the line of sight.
  static double visibility(HandSeat seat, HandVec eye, double lift) {
    final p = seat.position + seat.normal * lift;
    final toEye = eye - p;
    final facing = toEye.unit.dot(seat.normal);
    final face = _smooth(-0.02, 0.22, facing);
    if (face <= 0) return 0;
    final end = p + toEye.unit * 400;
    var clear = double.infinity;
    for (var i = 0; i < bones.length; i++) {
      if (i == seat.bone) continue;
      final b = bones[i];
      final c = _closest(p, end, b.start, b.end);
      clear = math.min(clear, c.d - b.radius(c.h));
    }
    return face * _smooth(-1.5, 2.0, clear);
  }
}

double _smooth(double e0, double e1, double x) {
  final t = ((x - e0) / (e1 - e0)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

/// Closest approach between segments p0–p1 and q0–q1: the distance and
/// how far along q (0..1) it falls.
({double d, double h}) _closest(
  HandVec p0,
  HandVec p1,
  HandVec q0,
  HandVec q1,
) {
  final d1 = p1 - p0, d2 = q1 - q0, r = p0 - q0;
  final a = d1.dot(d1), e = d2.dot(d2), f = d2.dot(r);
  final c = d1.dot(r), b = d1.dot(d2);
  final denom = a * e - b * b;
  var s = denom > 1e-9 ? ((b * f - c * e) / denom).clamp(0.0, 1.0) : 0.0;
  var t = (b * s + f) / e;
  if (t < 0) {
    t = 0;
    s = (-c / a).clamp(0.0, 1.0);
  } else if (t > 1) {
    t = 1;
    s = ((b - c) / a).clamp(0.0, 1.0);
  }
  final pc = p0 + d1 * s, qc = q0 + d2 * t;
  return (d: (pc - qc).length, h: t);
}
