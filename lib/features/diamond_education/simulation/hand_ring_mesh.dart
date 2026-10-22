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

/// The stone a ring holds: its centre and axes in hand space (model x, y
/// = table normal, z), and where its claws grip.
class RingHead {
  const RingHead({
    required this.centre,
    required this.x,
    required this.y,
    required this.z,
    required this.claws,
  });

  final HandVec centre, x, y, z;
  final List<RingClaw> claws;

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
/// given, a claw head holding it: claws rising from the band to the
/// girdle and curling over the crown, tied by a rail under the stone.
RingMesh buildRing(HandSeat seat, RingStyle style, RingHead? head) {
  final b = _Builder();
  _band(b, seat, style);
  if (head != null) _head(b, seat, style, head);
  return b.done();
}

/// Gap between the skin and the band's inside, mm.
const double _gap = 0.15;

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
  const around = 96;
  final lat = seat.lateral;
  // The skin's outline evened out, as a band rounds the finger: averaged
  // over ±22°, never pressing more than 3% into the flesh.
  final raw = [
    for (var i = 0; i < around; i++) seat.radiusAt(2 * math.pi * i / around),
  ];
  var even = raw;
  for (var pass = 0; pass < 2; pass++) {
    even = [
      for (var i = 0; i < around; i++)
        () {
          var sum = 0.0;
          for (var k = -6; k <= 6; k++) {
            sum += even[(i + k + around) % around];
          }
          return math.max(sum / 13, raw[i] * 0.97);
        }(),
    ];
  }
  final rows = <List<(HandVec, HandVec)>>[];
  for (var i = 0; i < around; i++) {
    final a = 2 * math.pi * i / around;
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
  final top = seat.position + seat.normal * (style.thickness * 0.55);
  final paths = <List<HandVec>>[];
  for (final c in claws) {
    final dir = head.x * math.cos(c.angle) + head.z * math.sin(c.angle);
    final girdle =
        head.centre + dir * (c.reach + pr * 0.55) + head.y * c.height;
    final tip =
        head.centre +
        dir * (c.reach - pr * 1.4) +
        head.y * (c.height + pr * 1.5);
    final spread = (0.3 * c.reach).clamp(0.8, seat.halfWidth * 0.6);
    final base = top + dir * spread;
    final mid = base + (girdle - base) * 0.55 + dir * (0.12 * c.reach);
    final path = _catmull([base, mid, girdle, tip], 5);
    paths.add(path);
    b.tube(path, pr, capEnd: true);
  }
  // The rail: a hoop through every claw a little under the stone.
  final rail = [for (final p in paths) p[(p.length * 0.38).round()]];
  if (rail.length >= 3) {
    b.tube(_catmull(rail, 6, closed: true), pr * 0.7, closed: true);
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
