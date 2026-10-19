import 'dart:math' as math;
import 'dart:typed_data';

/// A 3D vector in millimetres (world: y up, z toward the default viewer).
/// Used to build geometry; per-frame code works on typed arrays instead.
class V3 {
  const V3(this.x, this.y, this.z);

  static const zero = V3(0, 0, 0);
  static const unitX = V3(1, 0, 0);
  static const unitY = V3(0, 1, 0);
  static const unitZ = V3(0, 0, 1);

  final double x, y, z;

  V3 operator +(V3 o) => V3(x + o.x, y + o.y, z + o.z);
  V3 operator -(V3 o) => V3(x - o.x, y - o.y, z - o.z);
  V3 operator -() => V3(-x, -y, -z);
  V3 operator *(double s) => V3(x * s, y * s, z * s);

  double dot(V3 o) => x * o.x + y * o.y + z * o.z;

  V3 cross(V3 o) => V3(y * o.z - z * o.y, z * o.x - x * o.z, x * o.y - y * o.x);

  double get length => math.sqrt(x * x + y * y + z * z);

  V3 get normalized {
    final l = length;
    return l < 1e-12 ? V3.unitY : V3(x / l, y / l, z / l);
  }

  /// Linear blend toward [o].
  V3 lerp(V3 o, double t) =>
      V3(x + (o.x - x) * t, y + (o.y - y) * t, z + (o.z - z) * t);

  /// Any unit vector at right angles to this one.
  V3 get anyPerpendicular {
    final a = x.abs() < 0.9 ? V3.unitX : V3.unitY;
    return cross(a).normalized;
  }

  @override
  String toString() =>
      'V3(${x.toStringAsFixed(3)}, ${y.toStringAsFixed(3)}, ${z.toStringAsFixed(3)})';
}

/// A rigid transform: rotation [r] (row-major 3×3) then translation [t].
/// Its columns are where the local x, y and z axes point.
class Xf {
  Xf(this.r, this.t);

  Xf.identity()
    : r = Float64List.fromList([1, 0, 0, 0, 1, 0, 0, 0, 1]),
      t = V3.zero;

  /// From where the local axes point; they must be orthonormal.
  factory Xf.axes(V3 x, V3 y, V3 z, [V3 t = V3.zero]) => Xf(
    Float64List.fromList([x.x, y.x, z.x, x.y, y.y, z.y, x.z, y.z, z.z]),
    t,
  );

  /// Local y along [up], local z as close to [front] as [up] allows.
  factory Xf.lookUp(V3 up, V3 front, [V3 t = V3.zero]) {
    final y = up.normalized;
    var z = front - y * front.dot(y);
    z = z.length < 1e-9 ? y.anyPerpendicular : z.normalized;
    return Xf.axes(y.cross(z), y, z, t);
  }

  /// Rotation by [angle] about unit [axis].
  factory Xf.rotation(V3 axis, double angle, [V3 t = V3.zero]) {
    final a = axis.normalized;
    final c = math.cos(angle), s = math.sin(angle), k = 1 - c;
    return Xf(
      Float64List.fromList([
        c + a.x * a.x * k,
        a.x * a.y * k - a.z * s,
        a.x * a.z * k + a.y * s,
        a.y * a.x * k + a.z * s,
        c + a.y * a.y * k,
        a.y * a.z * k - a.x * s,
        a.z * a.x * k - a.y * s,
        a.z * a.y * k + a.x * s,
        c + a.z * a.z * k,
      ]),
      t,
    );
  }

  final Float64List r;
  final V3 t;

  V3 rotate(V3 v) => V3(
    r[0] * v.x + r[1] * v.y + r[2] * v.z,
    r[3] * v.x + r[4] * v.y + r[5] * v.z,
    r[6] * v.x + r[7] * v.y + r[8] * v.z,
  );

  V3 apply(V3 v) => rotate(v) + t;

  /// This transform after [o]: `(a * o).apply(v) == a.apply(o.apply(v))`.
  Xf operator *(Xf o) {
    final m = Float64List(9);
    for (var i = 0; i < 3; i++) {
      for (var j = 0; j < 3; j++) {
        m[i * 3 + j] =
            r[i * 3] * o.r[j] +
            r[i * 3 + 1] * o.r[3 + j] +
            r[i * 3 + 2] * o.r[6 + j];
      }
    }
    return Xf(m, apply(o.t));
  }

  Xf get inverse {
    final m = Float64List.fromList([
      r[0],
      r[3],
      r[6],
      r[1],
      r[4],
      r[7],
      r[2],
      r[5],
      r[8],
    ]);
    final inv = Xf(m, V3.zero);
    return Xf(m, -inv.rotate(t));
  }

  V3 get xAxis => V3(r[0], r[3], r[6]);
  V3 get yAxis => V3(r[1], r[4], r[7]);
  V3 get zAxis => V3(r[2], r[5], r[8]);

  /// Writes this transform into a 12-float row-major 3×4 matrix.
  void writeTo(Float64List m) {
    m[0] = r[0];
    m[1] = r[1];
    m[2] = r[2];
    m[3] = t.x;
    m[4] = r[3];
    m[5] = r[4];
    m[6] = r[5];
    m[7] = t.y;
    m[8] = r[6];
    m[9] = r[7];
    m[10] = r[8];
    m[11] = t.z;
  }
}

/// 3×4 row-major matrix helpers on raw [Float64List]s, for per-frame use.
abstract final class M34 {
  static Float64List identity() =>
      Float64List.fromList([1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0]);

  /// out = a · b (each a rigid 3×4 transform). [out] may not alias.
  static void mul(Float64List a, Float64List b, Float64List out) {
    for (var i = 0; i < 3; i++) {
      final a0 = a[i * 4], a1 = a[i * 4 + 1], a2 = a[i * 4 + 2];
      out[i * 4] = a0 * b[0] + a1 * b[4] + a2 * b[8];
      out[i * 4 + 1] = a0 * b[1] + a1 * b[5] + a2 * b[9];
      out[i * 4 + 2] = a0 * b[2] + a1 * b[6] + a2 * b[10];
      out[i * 4 + 3] = a0 * b[3] + a1 * b[7] + a2 * b[11] + a[i * 4 + 3];
    }
  }

  static V3 apply(Float64List m, V3 v) => V3(
    m[0] * v.x + m[1] * v.y + m[2] * v.z + m[3],
    m[4] * v.x + m[5] * v.y + m[6] * v.z + m[7],
    m[8] * v.x + m[9] * v.y + m[10] * v.z + m[11],
  );

  static V3 rotate(Float64List m, V3 v) => V3(
    m[0] * v.x + m[1] * v.y + m[2] * v.z,
    m[4] * v.x + m[5] * v.y + m[6] * v.z,
    m[8] * v.x + m[9] * v.y + m[10] * v.z,
  );

  /// Sets [m] from orthonormal axes [x], [y], [z] and origin [t].
  static void setAxes(Float64List m, V3 x, V3 y, V3 z, V3 t) {
    m[0] = x.x;
    m[1] = y.x;
    m[2] = z.x;
    m[3] = t.x;
    m[4] = x.y;
    m[5] = y.y;
    m[6] = z.y;
    m[7] = t.y;
    m[8] = x.z;
    m[9] = y.z;
    m[10] = z.z;
    m[11] = t.z;
  }
}

/// Smooth path through [pts] (Catmull–Rom), [steps] points per span.
List<V3> smoothPath(List<V3> pts, {int steps = 4, bool closed = false}) {
  final n = pts.length;
  if (n < 3) return pts;
  final out = <V3>[];
  final spans = closed ? n : n - 1;
  V3 at(int i) => closed ? pts[(i % n + n) % n] : pts[i.clamp(0, n - 1)];
  for (var i = 0; i < spans; i++) {
    final p0 = at(i - 1), p1 = at(i), p2 = at(i + 1), p3 = at(i + 2);
    for (var s = 0; s < steps; s++) {
      final t = s / steps, t2 = t * t, t3 = t2 * t;
      out.add(
        p0 * (-0.5 * t3 + t2 - 0.5 * t) +
            p1 * (1.5 * t3 - 2.5 * t2 + 1) +
            p2 * (-1.5 * t3 + 2 * t2 + 0.5 * t) +
            p3 * (0.5 * t3 - 0.5 * t2),
      );
    }
  }
  if (!closed) out.add(pts.last);
  return out;
}

double smoothstep(double e0, double e1, double x) {
  final t = ((x - e0) / (e1 - e0)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}
