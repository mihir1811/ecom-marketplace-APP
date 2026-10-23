import 'dart:math' as math;
import 'dart:typed_data';

import '../domain/hand_model.dart';
import '../domain/hand_ring.dart';
import 'sim_mesh.dart';

/// Triangles of one ring in hand space (mm), with smooth normals, wound
/// counter-clockwise seen from outside.
class RingMesh {
  RingMesh._(this.positions, this.normals, this.indices);

  final Float32List positions, normals;
  final Uint16List indices;

  int get vertexCount => positions.length ~/ 3;
  int get triangleCount => indices.length ~/ 3;
}

/// One claw's grip on the stone's girdle, in the stone's frame: [angle]
/// in its girdle plane from model x toward model z, the girdle's [reach]
/// from the centre that way and its [height] above the centre (mm).
typedef RingClaw = ({double angle, double reach, double height});

/// A stone's facet planes in hand space (`n · p <= d` inside it): what
/// keeps metal off the stone, and tells what stands in front of it.
class StoneHull {
  StoneHull._(this.planes);

  /// [mesh] scaled by [mmPerUnit], its model axes [x], [y], [z] laid
  /// along those hand-space directions about [centre].
  factory StoneHull.of(
    SimMesh mesh,
    double mmPerUnit,
    HandVec centre,
    HandVec x,
    HandVec y,
    HandVec z,
  ) {
    final src = mesh.planes, n = src.length ~/ 4;
    final out = Float64List(n * 4);
    for (var i = 0; i < n; i++) {
      final h = x * src[i * 4] + y * src[i * 4 + 1] + z * src[i * 4 + 2];
      out
        ..[i * 4] = h.x
        ..[i * 4 + 1] = h.y
        ..[i * 4 + 2] = h.z
        ..[i * 4 + 3] = src[i * 4 + 3] * mmPerUnit + h.dot(centre);
    }
    return StoneHull._(out);
  }

  /// nx ny nz d per facet, unit normals, mm.
  final Float64List planes;

  /// [p] moved off the stone until no facet plane has it nearer than
  /// [clear] mm. The farthest plane is never farther than the true
  /// distance, so a tube of radius [clear] through the result at most
  /// touches the stone.
  HandVec clear(HandVec p, double clear) {
    final pl = planes;
    var best = -double.infinity, at = 0;
    for (var i = 0; i < pl.length; i += 4) {
      final s = pl[i] * p.x + pl[i + 1] * p.y + pl[i + 2] * p.z - pl[i + 3];
      if (s > best) {
        best = s;
        at = i;
      }
    }
    if (best >= clear) return p;
    return p + HandVec(pl[at], pl[at + 1], pl[at + 2]) * (clear - best);
  }

  /// Whether the segment from [a] to [b] passes through the stone shrunk
  /// by [inset] mm (so metal resting on it does not count).
  bool blocks(HandVec a, HandVec b, {double inset = 0.05}) {
    final pl = planes;
    final dx = b.x - a.x, dy = b.y - a.y, dz = b.z - a.z;
    var t0 = 0.0, t1 = 1.0;
    for (var i = 0; i < pl.length; i += 4) {
      final den = pl[i] * dx + pl[i + 1] * dy + pl[i + 2] * dz;
      final num =
          pl[i + 3] - inset - (pl[i] * a.x + pl[i + 1] * a.y + pl[i + 2] * a.z);
      if (den.abs() < 1e-12) {
        if (num < 0) return false;
      } else if (den > 0) {
        t1 = math.min(t1, num / den);
      } else {
        t0 = math.max(t0, num / den);
      }
      if (t0 >= t1) return false;
    }
    return true;
  }
}

/// The stone a ring holds: its centre and axes in hand space (model x, y
/// = table normal, z), where its claws grip and the solid they wrap.
class RingHead {
  const RingHead({
    required this.centre,
    required this.x,
    required this.y,
    required this.z,
    required this.claws,
    required this.hull,
  });

  final HandVec centre, x, y, z;
  final List<RingClaw> claws;
  final StoneHull hull;

  /// Claws placed for [prongs] around [mesh] scaled by [mmPerUnit]: four
  /// on the diagonals (a princess's corners), six from model x (a pear's
  /// or marquise's points).
  static List<RingClaw> clawsFor(
    SimMesh mesh,
    double mmPerUnit,
    RingProngs prongs,
  ) {
    final key = (mesh, mmPerUnit, prongs);
    final cached = _claws[key];
    if (cached != null) return cached;
    final n = prongs.count;
    final offset = n == 4 ? math.pi / 4 : 0.0;
    final pos = mesh.positions;
    final out = <RingClaw>[];
    for (var k = 0; k < n; k++) {
      final a = offset + 2 * math.pi * k / n;
      final ca = math.cos(a), sa = math.sin(a);
      var best = -double.infinity, h = 0.0;
      for (var i = 0; i + 2 < pos.length; i += 3) {
        final s = pos[i] * ca + pos[i + 2] * sa;
        if (s > best) {
          best = s;
          h = pos[i + 1];
        }
      }
      out.add((angle: a, reach: best * mmPerUnit, height: h * mmPerUnit));
    }
    if (_claws.length > 32) _claws.clear();
    return _claws[key] = out;
  }

  static final Map<(SimMesh, double, RingProngs), List<RingClaw>> _claws = {};
}

/// Builds a comfort-fit band hugging [seat]'s finger, and, when [head] is
/// given, a claw head holding it: claws rising from the band, hugging the
/// pavilion, gripping the girdle and curling onto the crown, never
/// cutting into the stone.
RingMesh buildRing(HandSeat seat, RingStyle style, RingHead? head) {
  final b = _Builder();
  _band(b, seat, style);
  if (head != null) _head(b, seat, style, head);
  return b.done();
}

/// Gap between the skin and the band's inside, mm.
const double _gap = 0.15;

/// The top of [style]'s band over the back of [seat]'s finger, where a
/// stone's culet rests.
HandVec ringCrest(HandSeat seat, RingStyle style) =>
    seat.centre + seat.normal * (_evenRadii(seat)[0] + _gap + style.thickness);

const int _around = 96;
final Expando<List<double>> _evenCache = Expando();

/// The skin's outline evened out, as a band rounds the finger: averaged
/// over ±22°, never pressing more than 3% into the flesh. [_around]
/// samples from [HandSeat.normal] toward [HandSeat.lateral].
List<double> _evenRadii(HandSeat seat) {
  final cached = _evenCache[seat];
  if (cached != null) return cached;
  final raw = [
    for (var i = 0; i < _around; i++) seat.radiusAt(2 * math.pi * i / _around),
  ];
  var even = raw;
  for (var pass = 0; pass < 2; pass++) {
    even = [
      for (var i = 0; i < _around; i++)
        () {
          var sum = 0.0;
          for (var k = -6; k <= 6; k++) {
            sum += even[(i + k + _around) % _around];
          }
          return math.max(sum / 13, raw[i] * 0.97);
        }(),
    ];
  }
  return _evenCache[seat] = even;
}

void _band(_Builder b, HandSeat seat, RingStyle style) {
  final w = style.bandWidth, t = style.thickness;
  final e = 0.45 * t;
  // Profile across the band (along the finger, out from the skin, and
  // the outward normal in that plane): straight sides, domed top.
  final profile = <(double, double, double, double)>[
    (-w / 2, 0, -1, 0),
    (-w / 2, e, -1, 0),
  ];
  const dome = 9;
  for (var j = 0; j <= dome; j++) {
    final p = math.pi * j / dome;
    final x = -w / 2 * math.cos(p), h = e + (t - e) * math.sin(p);
    final nx = -(t - e) * math.cos(p), nh = w / 2 * math.sin(p);
    final l = math.sqrt(nx * nx + nh * nh);
    profile.add((x, h, nx / l, nh / l));
  }
  profile
    ..add((w / 2, e, 1, 0))
    ..add((w / 2, 0, 1, 0));
  final lat = seat.lateral;
  final even = _evenRadii(seat);
  final rows = <List<(HandVec, HandVec)>>[];
  for (var i = 0; i < _around; i++) {
    final a = 2 * math.pi * i / _around;
    final dir = seat.normal * math.cos(a) + lat * math.sin(a);
    final r = even[i] + _gap;
    rows.add([
      for (final (x, h, nx, nh) in profile)
        (
          seat.centre + seat.along * x + dir * (r + h),
          (seat.along * nx + dir * nh).unit,
        ),
    ]);
  }
  b.grid(rows, closedRows: true);
}

void _head(_Builder b, HandSeat seat, RingStyle style, RingHead head) {
  final claws = head.claws;
  if (claws.isEmpty) return;
  var mean = 0.0;
  for (final c in claws) {
    mean += c.reach;
  }
  mean /= claws.length;
  final pr = (0.085 * mean).clamp(0.35, 0.8);
  // Claws rise from inside the band's crown, within its width.
  final top = ringCrest(seat, style) - seat.normal * (style.thickness * 0.45);
  final alongMax = math.max(0.0, style.bandWidth / 2 - pr * 0.6);
  // Resting on the stone, a hair short of the radius so no gap shows
  // between metal and stone.
  final rest = pr * 0.97;
  for (final c in claws) {
    final dir = head.x * math.cos(c.angle) + head.z * math.sin(c.angle);
    final girdle = head.centre + dir * (c.reach + pr) + head.y * c.height;
    final tip =
        head.centre +
        dir * (c.reach - pr * 1.6) +
        head.y * (c.height + pr * 0.5);
    final spread = (0.3 * c.reach).clamp(0.8, seat.halfWidth * 0.6);
    var foot = dir * spread;
    final al = foot.dot(seat.along);
    foot = foot + seat.along * (al.clamp(-alongMax, alongMax) - al);
    final base = top + foot;
    final mid = base + (girdle - base) * 0.55 + dir * (0.12 * c.reach);
    // Every sample pushed off the stone: the claw hugs the pavilion,
    // grips the girdle and lies on the crown instead of passing through.
    final path = [
      for (final p in _catmull([base, mid, girdle, tip], 10))
        head.hull.clear(p, rest),
    ];
    b.tube(path, pr, capEnd: true);
  }
}

/// Catmull-Rom through [pts], [steps] samples per span; open curves keep
/// their ends.
List<HandVec> _catmull(List<HandVec> pts, int steps, {bool closed = false}) {
  HandVec at(int i) =>
      closed ? pts[i % pts.length] : pts[i.clamp(0, pts.length - 1)];
  final out = <HandVec>[];
  final spans = closed ? pts.length : pts.length - 1;
  for (var s = 0; s < spans; s++) {
    final p0 = at(s - 1), p1 = at(s), p2 = at(s + 1), p3 = at(s + 2);
    for (var k = 0; k < steps; k++) {
      final t = k / steps, t2 = t * t, t3 = t2 * t;
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

class _Builder {
  final List<double> _p = [], _n = [];
  final List<int> _i = [];

  int get _count => _p.length ~/ 3;

  int _vertex(HandVec p, HandVec n) {
    _p.addAll([p.x, p.y, p.z]);
    _n.addAll([n.x, n.y, n.z]);
    return _count - 1;
  }

  HandVec _pos(int i) => HandVec(_p[i * 3], _p[i * 3 + 1], _p[i * 3 + 2]);
  HandVec _nrm(int i) => HandVec(_n[i * 3], _n[i * 3 + 1], _n[i * 3 + 2]);

  /// A triangle wound so its face agrees with its vertices' normals.
  void _tri(int a, int b, int c) {
    final g = (_pos(b) - _pos(a)).cross(_pos(c) - _pos(a));
    if (g.dot(_nrm(a) + _nrm(b) + _nrm(c)) < 0) {
      _i.addAll([a, c, b]);
    } else {
      _i.addAll([a, b, c]);
    }
  }

  void grid(List<List<(HandVec, HandVec)>> rows, {bool closedRows = false}) {
    final base = _count, m = rows.first.length;
    for (final row in rows) {
      for (final (p, n) in row) {
        _vertex(p, n);
      }
    }
    final last = closedRows ? rows.length : rows.length - 1;
    for (var i = 0; i < last; i++) {
      final i2 = (i + 1) % rows.length;
      for (var j = 0; j < m - 1; j++) {
        final a = base + i * m + j, b = base + i2 * m + j;
        _tri(a, b, b + 1);
        _tri(a, b + 1, a + 1);
      }
    }
  }

  void tube(
    List<HandVec> path,
    double radius, {
    bool capEnd = false,
    bool closed = false,
  }) {
    const sides = 8;
    final n = path.length;
    HandVec tangent(int i) {
      final a = closed ? path[(i - 1 + n) % n] : path[math.max(i - 1, 0)];
      final b = closed ? path[(i + 1) % n] : path[math.min(i + 1, n - 1)];
      return (b - a).unit;
    }

    // Parallel-transported frame along the path.
    final t0 = tangent(0);
    var u =
        (t0.cross(const HandVec(0, 0, 1)).length > 0.1
                ? t0.cross(const HandVec(0, 0, 1))
                : t0.cross(const HandVec(1, 0, 0)))
            .unit;
    final rows = <List<(HandVec, HandVec)>>[];
    for (var i = 0; i < n; i++) {
      final t = tangent(i);
      u = (u - t * u.dot(t)).unit;
      final v = t.cross(u);
      rows.add([
        for (var k = 0; k <= sides; k++)
          () {
            final a = 2 * math.pi * k / sides;
            final d = u * math.cos(a) + v * math.sin(a);
            return (path[i] + d * radius, d);
          }(),
      ]);
    }
    grid(rows, closedRows: closed);
    if (capEnd) {
      final t = tangent(n - 1);
      final end = path.last;
      final ring = rows.last;
      final mid = [
        for (final (p, d) in ring)
          (end + (p - end) * 0.7 + t * (radius * 0.6), (d + t).unit),
      ];
      grid([ring, mid]);
      final apex = _vertex(end + t * radius, t);
      final s = _count - 1 - mid.length;
      for (var k = 0; k < mid.length - 1; k++) {
        _tri(s + k, s + k + 1, apex);
      }
    }
  }

  RingMesh done() => RingMesh._(
    Float32List.fromList(_p),
    Float32List.fromList(_n),
    Uint16List.fromList(_i),
  );
}
