import 'dart:math' as math;
import 'dart:typed_data';

import '../domain/diamond_proportions.dart';
import '../domain/diamond_shape.dart';
import 'sim_hull.dart';
import 'sim_outline.dart';

/// Region of the stone a facet belongs to.
enum SimFacetKind { table, crown, girdle, pavilion, culet }

/// A cut stone as a closed polyhedron of flat facets, in half-width units
/// (the stone is 2 wide), table up (+y), centred on its bounding box.
///
/// Every facet is planar: brilliant crowns and pavilions are solved so
/// that kites, stars and halves lie in one plane, and the girdle edge is
/// scalloped exactly where those planes meet the girdle, as on a real
/// stone. That keeps the ray tracer exact: a ray inside the stone leaves
/// through the nearest facet plane ahead of it.
class SimMesh {
  SimMesh._({
    required this.shape,
    required this.positions,
    required this.facetStart,
    required this.facetVerts,
    required this.planes,
    required this.kinds,
    required this.facetGroup,
    required this.girdleFacets,
    required Float64List Function() innerRadiusOf,
    required this.length,
    required this.width,
    required this.crownHeight,
    required this.pavilionDepth,
    required this.girdleThickness,
    required this.totalDepth,
    required this.volume,
    required this.radius,
    required this.fold,
    required this.tracedFacets,
  }) : _innerRadiusSource = innerRadiusOf;

  /// The classic shape it was cut as; null for a fancy cut built from
  /// its facet planes ([fromPlanes]).
  final SimShape? shape;

  /// How light is traced through a stone a plane tracer cannot follow
  /// whole, because it is concave. 0: the stone is convex and traced
  /// whole. 1: only its +x half is traced, with a mirror at x = 0 (a
  /// heart: its cleft makes it concave, but each half is convex, and a
  /// ray crossing into the −x half is the mirror image of one staying in
  /// the +x half). k >= 2: only the wedge 0 <= atan2(x, z) <= π/k is
  /// traced, between mirrors at its two sides, like a kaleidoscope: a
  /// star or a lily is k-fold symmetric, and each wedge is convex.
  final int fold;

  /// Whether only the +x half is traced ([fold] 1).
  bool get mirrorX => fold == 1;

  /// Facets `0 .. tracedFacets` bound the traced solid; any after them
  /// are their mirror images (see [fold]), drawn but never traced.
  final int tracedFacets;

  /// Vertex positions, xyz.
  final Float64List positions;

  /// Facet `f` uses `facetVerts[facetStart[f] .. facetStart[f + 1]]`, in
  /// order around the facet.
  final Int32List facetStart;
  final Int32List facetVerts;

  /// Outward unit normal and offset per facet: `n · p = d` on the facet.
  final Float64List planes;
  final Uint8List kinds;

  /// The cut facet each polygon belongs to: a facet a fancy outline bends
  /// slightly is split into triangles ([_Builder.finish]), and those
  /// share one group, so a line drawing never shows the split.
  final Int32List facetGroup;

  /// Girdle facets; a ray only needs to test them when it reaches the
  /// girdle band (see [innerRadius]).
  final Int32List girdleFacets;

  /// Conservative distance from the axis to the girdle, per angular bin
  /// of [radialBins] around +x. Points inside it are inside the girdle.
  /// Worked out on first use: only the CPU tracer needs it.
  late final Float64List innerRadius = _innerRadiusSource();
  final Float64List Function() _innerRadiusSource;
  static const radialBins = 96;

  /// Measurements, half-width units.
  final double length, width;
  final double crownHeight, pavilionDepth, girdleThickness, totalDepth;
  final double volume;

  /// Bounding radius around the origin.
  final double radius;

  int get facetCount => kinds.length;
  int get vertexCount => positions.length ~/ 3;

  /// Percentages of width, as on a grading report.
  double get crownHeightPct => crownHeight / width * 100;
  double get pavilionDepthPct => pavilionDepth / width * 100;
  double get totalDepthPct => totalDepth / width * 100;

  /// Distance from (x, y, z) to the nearest traced facet plane, negative
  /// outside the stone.
  double inset(double x, double y, double z) {
    (x, z) = foldIn(fold, x, z);
    var best = double.infinity;
    for (var f = 0; f < tracedFacets; f++) {
      final d =
          planes[f * 4 + 3] -
          (planes[f * 4] * x + planes[f * 4 + 1] * y + planes[f * 4 + 2] * z);
      if (d < best) best = d;
    }
    return best;
  }

  /// (x, z) turned and mirrored into the traced part of a stone of
  /// [fold] ([SimMesh.fold]); a convex stone's points stay as they are.
  static (double, double) foldIn(int fold, double x, double z) {
    if (fold == 0) return (x, z);
    if (fold == 1) return (x.abs(), z);
    final sector = 2 * math.pi / fold;
    var a = math.atan2(x, z) % sector;
    if (a > sector / 2) a = sector - a;
    final r = math.sqrt(x * x + z * z);
    return (r * math.sin(a), r * math.cos(a));
  }

  /// The mirrors bounding the traced part of a stone of [fold], as
  /// planes `n · p <= 0` (nx ny nz d each): x >= 0, and for k >= 2 the
  /// wedge's far side at π/k.
  static List<double> mirrorPlanes(int fold) => [
    if (fold >= 1) ...[-1.0, 0.0, 0.0, 0.0],
    if (fold >= 2) ...[
      math.cos(math.pi / fold),
      0.0,
      -math.sin(math.pi / fold),
      0.0,
    ],
  ];

  /// A stone already solved elsewhere (a shape morph): [positions] as
  /// xyz and its [facets], each a convex polygon of vertex indices with
  /// its kind. With a [fold] the facets are the traced part, and the rest
  /// of the stone is added as their mirror images. Kept where it is, not
  /// re-centred.
  static SimMesh fromFacets(
    SimShape? shape,
    List<double> positions,
    List<(List<int>, SimFacetKind)> facets, {
    int fold = 0,
    double crownHeight = 0,
    double pavilionDepth = 0,
    double girdleThickness = 0,
  }) {
    final b = _Builder(shape)
      .._pos.addAll(positions)
      .._polys.addAll(facets)
      .._crownHeight = crownHeight
      .._pavilionDepth = pavilionDepth
      .._girdle = girdleThickness;
    if (fold == 1) b._mirrorHalf();
    if (fold >= 2) b._kaleidoscope(fold);
    return b.finish(centre: false);
  }

  /// A fancy cut given as the facet planes that bound it (or, with a
  /// [fold], its traced part): [planes] as nx ny nz d (`n · p <= d`)
  /// with each plane's kind. Kept where it is, not re-centred.
  static SimMesh fromPlanes(
    List<double> planes,
    List<SimFacetKind> kinds, {
    int fold = 0,
  }) {
    final n = kinds.length;
    final all = Float64List.fromList([...planes, ...mirrorPlanes(fold)]);
    final hull = SimHull.cut(all, all.length ~/ 4);
    return fromFacets(null, hull.vertices, [
      for (final f in hull.faces)
        if (f.plane >= 0 && f.plane < n) (f.verts, kinds[f.plane]),
    ], fold: fold);
  }

  /// Builds [shape] cut to [proportions]. Meshes never change once built,
  /// so the last few are kept: a slider dragged back and forth, the shape
  /// dial and the hand's parked stones ask for the same cuts again and
  /// again, and a fancy cut takes milliseconds to build.
  static SimMesh build(SimShape shape, DiamondProportions proportions) {
    final key = (shape, proportions);
    final hit = _built.remove(key);
    if (hit != null) return _built[key] = hit;
    final mesh = _build(shape, proportions);
    if (_built.length >= _keep) _built.remove(_built.keys.first);
    return _built[key] = mesh;
  }

  /// Least recently built first. A mesh is a few kilobytes.
  static final Map<(SimShape, DiamondProportions), SimMesh> _built = {};
  static const _keep = 48;

  /// Drops the kept meshes, e.g. under memory pressure.
  static void trimCache() => _built.clear();

  static SimMesh _build(SimShape shape, DiamondProportions proportions) {
    final b = _Builder(shape);
    switch (shape) {
      case _ when shape.family == SimCutFamily.step:
        b.step(proportions);
      case SimShape.princess || SimShape.cushion || SimShape.heart:
        b.fancy(proportions);
      default:
        b.brilliant(proportions);
    }
    return b.finish();
  }
}

/// A point in model space.
typedef _V = ({double x, double y, double z});

/// A facet plane as a height field, y = a·x + b·z + c.
typedef _Plane = ({double a, double b, double c, SimFacetKind kind});

double _eval(_Plane p, double x, double z) => p.a * x + p.b * z + p.c;

/// Plane through three points.
_Plane _through(_V p, _V q, _V r, SimFacetKind kind) {
  final ux = q.x - p.x, uy = q.y - p.y, uz = q.z - p.z;
  final vx = r.x - p.x, vy = r.y - p.y, vz = r.z - p.z;
  return _normal(
    p,
    uy * vz - uz * vy,
    uz * vx - ux * vz,
    ux * vy - uy * vx,
    kind,
  );
}

/// Plane through [p] and [q], level across the plan line between them:
/// a facet symmetric about its own axis, like a kite or a main.
_Plane _axial(_V p, _V q, SimFacetKind kind) =>
    _level(p, q, -(q.z - p.z), q.x - p.x, kind);

/// Plane through [p] and [q], level along plan direction (dx, dz).
_Plane _level(_V p, _V q, double dx, double dz, SimFacetKind kind) {
  final ux = q.x - p.x, uy = q.y - p.y, uz = q.z - p.z;
  return _normal(p, uy * dz, uz * dx - ux * dz, -uy * dx, kind);
}

_Plane _normal(_V p, double nx, double ny, double nz, SimFacetKind kind) {
  final a = -nx / ny, b = -nz / ny;
  return (a: a, b: b, c: p.y - a * p.x - b * p.z, kind: kind);
}

/// A point on the line where planes [p] and [q] meet: at height [y]
/// where the line slopes, else nearest [near] in plan.
_V _meet(_Plane p, _Plane q, SimPoint near, double y) {
  final da = p.a - q.a, db = p.b - q.b, dc = p.c - q.c;
  final l2 = da * da + db * db;
  var x = near.x, z = near.z;
  if (l2 > 1e-12) {
    final f = (da * x + db * z + dc) / l2;
    x -= da * f;
    z -= db * f;
    // Along the line (−db, da), scaled to unit length in plan.
    final l = math.sqrt(l2);
    final ux = -db / l, uz = da / l;
    final rate = p.a * ux + p.b * uz;
    if (rate.abs() > 1e-6) {
      final s = ((y - _eval(p, x, z)) / rate).clamp(-0.5, 0.5);
      x += ux * s;
      z += uz * s;
    }
  }
  return (x: x, y: _eval(p, x, z), z: z);
}

/// Keeps the part of convex polygon [poly] where a·x + b·z + c ≤ 0.
List<SimPoint> _clip(List<SimPoint> poly, double a, double b, double c) {
  final out = <SimPoint>[];
  for (var i = 0; i < poly.length; i++) {
    final p = poly[i], q = poly[(i + 1) % poly.length];
    final fp = a * p.x + b * p.z + c, fq = a * q.x + b * q.z + c;
    if (fp <= 1e-12) out.add(p);
    if ((fp < -1e-12 && fq > 1e-12) || (fp > 1e-12 && fq < -1e-12)) {
      final s = fp / (fp - fq);
      out.add((x: p.x + (q.x - p.x) * s, z: p.z + (q.z - p.z) * s));
    }
  }
  return out;
}

double _area(List<SimPoint> poly) {
  var s = 0.0;
  for (var i = 0; i < poly.length; i++) {
    final p = poly[i], q = poly[(i + 1) % poly.length];
    s += p.x * q.z - q.x * p.z;
  }
  return s / 2;
}

class _Builder {
  _Builder(this._shape);

  final SimShape? _shape;
  SimShape get shape => _shape!;
  final List<double> _pos = [];
  final List<(List<int>, SimFacetKind)> _polys = [];
  double _crownHeight = 0, _pavilionDepth = 0, _girdle = 0;

  /// With a traced part ([SimMesh.fold]): how many of [_polys] are the
  /// traced part; the rest are its mirror images.
  int? _tracedPolys;
  int _fold = 0;

  /// The cut facet of each polygon, where it is not the polygon's own
  /// index (see [SimMesh.facetGroup]).
  final Map<int, int> _groups = {};

  static const _cos8 = 0.9238795325112867;

  int _add(double x, double y, double z) {
    _pos
      ..add(x)
      ..add(y)
      ..add(z);
    return _pos.length ~/ 3 - 1;
  }

  double _y(int i) => _pos[i * 3 + 1];

  /// Height on the plane through vertices [a], [b], [c] at (x, z).
  double _planeY(int a, int b, int c, double x, double z) {
    final ax = _pos[a * 3], ay = _pos[a * 3 + 1], az = _pos[a * 3 + 2];
    final ux = _pos[b * 3] - ax, uy = _pos[b * 3 + 1] - ay;
    final uz = _pos[b * 3 + 2] - az;
    final vx = _pos[c * 3] - ax, vy = _pos[c * 3 + 1] - ay;
    final vz = _pos[c * 3 + 2] - az;
    final nx = uy * vz - uz * vy;
    final ny = uz * vx - ux * vz;
    final nz = ux * vy - uy * vx;
    if (ny.abs() < 1e-12) return ay;
    return ay - (nx * (x - ax) + nz * (z - az)) / ny;
  }

  void brilliant(DiamondProportions p) {
    const nodes = 16, sub = 3, n = nodes * sub;
    final t = p.tablePct / 100;
    final tc = math.tan(p.crownAngle * math.pi / 180);
    final tp = math.tan(p.pavilionAngle * math.pi / 180);
    final cs = p.culetScale;
    final g = p.girdle.percent / 100 * 2;

    // Scale toward the outline's area centroid so tables sit naturally on
    // pears and hearts.
    final ring = [for (var j = 0; j < n; j++) SimOutline.even(shape, j / n)];
    var area = 0.0, cx = 0.0, cz = 0.0;
    for (var j = 0; j < n; j++) {
      final a = ring[j], b = ring[(j + 1) % n];
      final cross = a.x * b.z - b.x * a.z;
      area += cross;
      cx += (a.x + b.x) * cross;
      cz += (a.z + b.z) * cross;
    }
    cx /= 3 * area;
    cz /= 3 * area;
    SimPoint at(double u, double s) {
      final o = SimOutline.even(shape, u);
      return (x: cx + (o.x - cx) * s, z: cz + (o.z - cz) * s);
    }

    final crown = <int>[], pavilion = <int>[];
    int vert(SimPoint q, double y, List<int> group) {
      final i = _add(q.x, y, q.z);
      group.add(i);
      return i;
    }

    // Crown, girdle-top nodes at y = 0. Each kite lies in one plane at the
    // crown angle; its corners' heights follow from their reach toward
    // the girdle along the kite's axis.
    final table = [
      for (var i = 0; i < 8; i++) vert(at(i / 8, t), tc * (1 - t), crown),
    ];
    final starS = t * _cos8 + 0.5 * (1 - t * _cos8);
    final star = [
      for (var i = 0; i < 8; i++)
        vert(at((i + 0.5) / 8, starS), tc * (1 - starS * _cos8), crown),
    ];
    final top = List<int>.filled(n, 0);
    for (var k = 0; k < nodes; k++) {
      top[k * sub] = vert(ring[k * sub], 0, crown);
    }
    var dip = 0.0;
    for (var j = 0; j < n; j++) {
      if (j % sub == 0) continue;
      final k = j ~/ sub;
      final q = ring[j];
      // Clamped where a fancy outline turns the plane nearly vertical
      // (the heart's cleft); such facets are split instead.
      final y = _planeY(
        star[k ~/ 2],
        top[k * sub],
        top[((k + 1) * sub) % n],
        q.x,
        q.z,
      ).clamp(-0.05, 0.05);
      dip = math.max(dip, -y);
      top[j] = vert(q, y, crown);
    }

    // Pavilion, girdle-bottom nodes at y = 0; mains at the pavilion angle.
    final lowS = math.max(0.23, cs + 0.06);
    final lower = [
      for (var i = 0; i < 8; i++)
        vert(at((i + 0.5) / 8, lowS), -tp * (1 - lowS * _cos8), pavilion),
    ];
    final culet = cs > 0.001
        ? [
            for (var i = 0; i < 8; i++)
              vert(at((i + 0.5) / 8, cs), -tp * (1 - cs * _cos8), pavilion),
          ]
        : [vert((x: cx, z: cz), -tp, pavilion)];
    final bottom = List<int>.filled(n, 0);
    for (var k = 0; k < nodes; k++) {
      bottom[k * sub] = vert(ring[k * sub], 0, pavilion);
    }
    var rise = 0.0;
    for (var j = 0; j < n; j++) {
      if (j % sub == 0) continue;
      final k = j ~/ sub;
      final q = ring[j];
      final y = _planeY(
        lower[k ~/ 2],
        bottom[k * sub],
        bottom[((k + 1) * sub) % n],
        q.x,
        q.z,
      ).clamp(-0.05, 0.05);
      rise = math.max(rise, y);
      bottom[j] = vert(q, y, pavilion);
    }

    // Open the girdle so its thinnest point is the requested thickness.
    final topShift = g / 2 + dip, bottomShift = -(g / 2 + rise);
    for (final i in crown) {
      _pos[i * 3 + 1] += topShift;
    }
    for (final i in pavilion) {
      _pos[i * 3 + 1] += bottomShift;
    }
    _crownHeight = _y(table[0]) - _y(top[0]);
    _pavilionDepth = _y(bottom[0]) - _y(culet[0]);
    _girdle = _y(top[0]) - _y(bottom[0]);

    _polys.add((table, SimFacetKind.table));
    for (var i = 0; i < 8; i++) {
      final next = (i + 1) % 8, prev = (i + 7) % 8;
      _polys
        ..add(([table[i], table[next], star[i]], SimFacetKind.crown))
        ..add((
          [table[i], star[i], top[2 * i * sub], star[prev]],
          SimFacetKind.crown,
        ))
        ..add((
          [
            bottom[2 * i * sub],
            lower[i],
            if (culet.length == 8) ...[culet[i], culet[prev]] else culet[0],
            lower[prev],
          ],
          SimFacetKind.pavilion,
        ));
    }
    for (var k = 0; k < nodes; k++) {
      _polys
        ..add((
          [star[k ~/ 2], for (var j = 0; j <= sub; j++) top[(k * sub + j) % n]],
          SimFacetKind.crown,
        ))
        ..add((
          [
            lower[k ~/ 2],
            for (var j = sub; j >= 0; j--) bottom[(k * sub + j) % n],
          ],
          SimFacetKind.pavilion,
        ));
    }
    for (var j = 0; j < n; j++) {
      final next = (j + 1) % n;
      _polys.add((
        [top[j], top[next], bottom[next], bottom[j]],
        SimFacetKind.girdle,
      ));
    }
    if (culet.length == 8) _polys.add((culet, SimFacetKind.culet));
  }

  /// Princess, cushion and heart, cut facet by facet as on a cutter's
  /// diagram: every facet is a plane set by the points it meets (table
  /// corners, star and girdle points, the culet), and the stone is
  /// whatever those planes leave standing. That makes each facet exactly
  /// flat and the solid exactly convex, however unusual the plan.
  ///
  /// - Princess (square modified brilliant): a brilliant crown with corner
  ///   and side bezels, and a pavilion of chevrons, nested V-shaped tiers
  ///   along each side that steepen toward the girdle, around the four
  ///   corner mains that read as an X face up.
  /// - Cushion (cushion brilliant): a brilliant crown and pavilion, eight
  ///   mains and sixteen lower halves, on a pillowed square.
  /// - Heart: a brilliant on a heart outline, built as its +x half
  ///   ([SimMesh.mirrorX]): mains at the cleft, both lobes, shoulders,
  ///   wings and point.
  void fancy(DiamondProportions p) {
    final half = shape == SimShape.heart;
    final t = p.tablePct / 100;
    final tc = math.tan(p.crownAngle * math.pi / 180);
    final tp = math.tan(p.pavilionAngle * math.pi / 180);
    final cs = p.culetScale;
    final g = p.girdle.percent / 100 * 2;

    const n = 48;
    final ring = [for (var j = 0; j < n; j++) SimOutline.even(shape, j / n)];
    var area = 0.0, cx = 0.0, cz = 0.0;
    for (var j = 0; j < n; j++) {
      final a = ring[j], b = ring[(j + 1) % n];
      final cross = a.x * b.z - b.x * a.z;
      area += cross;
      cx += (a.x + b.x) * cross;
      cz += (a.z + b.z) * cross;
    }
    cx /= 3 * area;
    cz /= 3 * area;
    if (half) cx = 0;
    SimPoint at(double u, double s) {
      final o = SimOutline.even(shape, u);
      return (x: cx + (o.x - cx) * s, z: cz + (o.z - cz) * s);
    }

    _V v(SimPoint q, double y) => (x: q.x, y: y, z: q.z);

    // Plan of the traced solid: the girdle outline, or its +x half closed
    // along the axis (the last edge, from point back to cleft).
    final domain = <SimPoint>[
      for (var j = 0; j <= (half ? n ~/ 2 : n - 1); j++)
        if (half && (j == 0 || j == n ~/ 2))
          (x: 0.0, z: ring[j].z)
        else
          ring[j],
    ];
    if (half) {
      // The lobes' widest point, so the stone measures its true width.
      var best = 0.0, bestU = 0.0;
      for (var u = 0.0; u <= 0.5; u += 1 / 4096) {
        final x = SimOutline.even(shape, u).x;
        if (x > best) {
          best = x;
          bestU = u;
        }
      }
      final i = (bestU * n).floor() + 1;
      if ((bestU * n - i + 1).abs() > 1e-6) {
        domain.insert(i, SimOutline.even(shape, bestU));
      }
    }
    // Straight runs of girdle are one facet each.
    for (var i = domain.length - 1; i >= 0 && domain.length > 3; i--) {
      final a = domain[(i - 1) % domain.length], b = domain[i];
      final c = domain[(i + 1) % domain.length];
      final cross = (b.x - a.x) * (c.z - b.z) - (b.z - a.z) * (c.x - b.x);
      if (cross.abs() < 1e-9) domain.removeAt(i);
    }

    final mains = half ? 5 : 8, stars = half ? 4 : 8, nodes = half ? 9 : 16;
    final princess = shape == SimShape.princess;
    SimPoint node(int j) => at(j / 16, 1);

    // Level direction of a main reaching the girdle at u: along the
    // girdle there, so the facet meets it at that point and stays clear
    // of it elsewhere (the outline is convex). Null at a corner (a
    // princess corner, the heart's point): the facet is then level across
    // its own axis. At the heart's cleft, along the lobe.
    (double, double)? level(double u) {
      const e = 1e-4;
      final m = at(u, 1), b = at(u + e, 1);
      if (half && u == 0) return (b.x - m.x, b.z - m.z);
      final a = at(u - e, 1);
      final ax = m.x - a.x, az = m.z - a.z, bx = b.x - m.x, bz = b.z - m.z;
      final turn =
          (ax * bz - az * bx) /
          math.sqrt((ax * ax + az * az) * (bx * bx + bz * bz));
      return turn.abs() > 0.05 ? null : (b.x - a.x, b.z - a.z);
    }

    /// Unit plan direction from main k's girdle point straight into the
    /// stone, across its level line.
    SimPoint inward(int k) {
      final m = node(2 * k % 16);
      final d = level(k / 8);
      var nx = cx - m.x, nz = cz - m.z;
      if (d != null) {
        final l = math.sqrt(d.$1 * d.$1 + d.$2 * d.$2);
        final px = -d.$2 / l, pz = d.$1 / l;
        final sign = px * nx + pz * nz >= 0 ? 1.0 : -1.0;
        return (x: px * sign, z: pz * sign);
      }
      final l = math.sqrt(nx * nx + nz * nz);
      nx /= l;
      nz /= l;
      return (x: nx, z: nz);
    }

    _Plane main(_V inner, int k, SimFacetKind kind, [double y = 0]) {
      final m = v(node(2 * k % 16), y);
      final d = level(k / 8);
      return d == null
          ? _axial(inner, m, kind)
          : _level(inner, m, d.$1, d.$2, kind);
    }

    // Crown. A princess's corners sit a touch low, so its corner bezels
    // stand clear of the side bezels, which meet the straight girdle along
    // a stretch rather than at a point.
    final hT = tc * (1 - t);
    final corner = princess ? tc * 0.06 : 0.0;
    _V girdleAt(int j) => v(node(j % 16), j % 4 == 2 ? -corner : 0);
    final crown = <_Plane>[(a: 0, b: 0, c: hT, kind: SimFacetKind.table)];
    // A princess table's corners sit a touch in from a true square, so
    // its stars have room between the side bezels and the table. At a
    // heart's cleft the table comes no nearer than the crown angle
    // allows, so the cleft bezels are no steeper than the rest.
    _V tableAt(int k) {
      if (half && k == 0) {
        final m = node(2 * k % 16), n = inward(k);
        return v((x: m.x + n.x * (1 - t), z: m.z + n.z * (1 - t)), hT);
      }
      return v(at((k % 8) / 8, princess && k.isOdd ? t * 0.93 : t), hT);
    }

    final bezels = [
      for (var k = 0; k < mains; k++)
        main(tableAt(k), k, SimFacetKind.crown, girdleAt(2 * k).y),
    ];
    crown.addAll(bezels);
    final starS = t * _cos8 + 0.5 * (1 - t * _cos8);
    final star = <_V>[];
    for (var k = 0; k < stars; k++) {
      // Star point: on the line where two neighbouring bezels meet, so
      // both stay flat kites.
      final q = _meet(
        bezels[k],
        bezels[(k + 1) % mains],
        at((k + 0.5) / 8, starS),
        tc * (1 - starS * _cos8),
      );
      star.add(half && q.x < 0 ? (x: 0.0, y: q.y, z: q.z) : q);
      // A star that would reach down past the girdle (at a heart's
      // cleft) is left uncut: the bezels on either side meet instead.
      final p = _through(
        tableAt(k),
        tableAt(k + 1),
        star[k],
        SimFacetKind.crown,
      );
      if (domain.every((d) => _eval(p, d.x, d.z) > -0.005)) crown.add(p);
    }
    for (var j = 0; j < nodes - (half ? 1 : 0); j++) {
      crown.add(
        _through(
          star[j ~/ 2],
          girdleAt(j),
          girdleAt(j + 1),
          SimFacetKind.crown,
        ),
      );
    }

    // Pavilion.
    final pavilion = <_Plane>[];
    final apex = (x: cx, y: -tp, z: cz);
    _V bottomAt(int j) => v(node(j % 16), 0);
    if (princess) {
      // Ridge down each side's centre line: girdle, three chevron tiers,
      // then the corner mains, each tier shallower toward the culet.
      const reach = [1.0, 0.75, 0.5, 0.3];
      const slope = [1.4, 1.2, 1.0];
      for (var s = 0; s < 4; s++) {
        final side = at(s / 4, 1);
        final ridge = <_V>[v(side, 0)];
        for (var j = 0; j < 3; j++) {
          final y = ridge.last.y - tp * slope[j] * (reach[j] - reach[j + 1]);
          ridge.add(v((x: side.x * reach[j + 1], z: side.z * reach[j + 1]), y));
        }
        for (final c in [at(s / 4 - 1 / 8, 1), at(s / 4 + 1 / 8, 1)]) {
          for (var j = 0; j < 3; j++) {
            pavilion.add(
              _through(v(c, 0), ridge[j], ridge[j + 1], SimFacetKind.pavilion),
            );
          }
        }
        pavilion.add(main(apex, 2 * s + 1, SimFacetKind.pavilion));
      }
    } else {
      final mainsP = [
        for (var k = 0; k < mains; k++) main(apex, k, SimFacetKind.pavilion),
      ];
      final lowS = math.max(0.23, cs + 0.06);
      final lower = <_V>[];
      for (var k = 0; k < stars; k++) {
        lower.add(
          _meet(
            mainsP[k],
            mainsP[(k + 1) % mains],
            at((k + 0.5) / 8, lowS),
            -tp * (1 - lowS * _cos8),
          ),
        );
      }
      pavilion.addAll(mainsP);
      for (var j = 0; j < nodes - (half ? 1 : 0); j++) {
        pavilion.add(
          _through(
            lower[j ~/ 2],
            bottomAt(j),
            bottomAt(j + 1),
            SimFacetKind.pavilion,
          ),
        );
      }
    }
    if (cs > 0.001) {
      pavilion.add((
        a: 0,
        b: 0,
        c: -tp * (1 - cs * _cos8),
        kind: SimFacetKind.culet,
      ));
    }

    // Each facet is the part of the plan where its plane is the crown's
    // lowest (the pavilion's highest).
    List<List<SimPoint>> regions(List<_Plane> planes, double sign) {
      final out = <List<SimPoint>>[];
      for (var i = 0; i < planes.length; i++) {
        var poly = domain;
        final pi = planes[i];
        for (var j = 0; j < planes.length && poly.length >= 3; j++) {
          if (j == i) continue;
          final pj = planes[j];
          final da = pi.a - pj.a, db = pi.b - pj.b, dc = pi.c - pj.c;
          if (da.abs() + db.abs() + dc.abs() < 1e-10) {
            if (j < i) poly = const [];
            continue;
          }
          poly = _clip(poly, da * sign, db * sign, dc * sign);
        }
        out.add(poly.length >= 3 && _area(poly).abs() > 1e-7 ? poly : const []);
      }
      return out;
    }

    final crownCells = regions(crown, 1), pavilionCells = regions(pavilion, -1);
    double crownY(double x, double z) {
      var y = double.infinity;
      for (final q in crown) {
        y = math.min(y, _eval(q, x, z));
      }
      return y;
    }

    double pavilionY(double x, double z) {
      var y = -double.infinity;
      for (final q in pavilion) {
        y = math.max(y, _eval(q, x, z));
      }
      return y;
    }

    // Girdle edges (all but the mirror axis) and the cell corners on each.
    final edges = half ? domain.length - 1 : domain.length;
    double? along(int e, SimPoint q) {
      final a = domain[e], b = domain[(e + 1) % domain.length];
      final ex = b.x - a.x, ez = b.z - a.z;
      final len2 = ex * ex + ez * ez;
      final s = ((q.x - a.x) * ex + (q.z - a.z) * ez) / len2;
      final off = (q.x - a.x) * ez - (q.z - a.z) * ex;
      if (off * off > 1e-16 * len2 || s < -1e-9 || s > 1 + 1e-9) return null;
      return s;
    }

    List<double> breaks(int e, List<List<SimPoint>> cells) {
      final out = <double>[0, 1];
      for (final c in cells) {
        for (final q in c) {
          final s = along(e, q);
          if (s != null && s > 1e-9 && s < 1 - 1e-9) out.add(s);
        }
      }
      out.sort();
      for (var i = out.length - 1; i > 0; i--) {
        if (out[i] - out[i - 1] < 1e-9) out.removeAt(i);
      }
      return out;
    }

    SimPoint lerp(int e, double s) {
      final a = domain[e], b = domain[(e + 1) % domain.length];
      return (x: a.x + (b.x - a.x) * s, z: a.z + (b.z - a.z) * s);
    }

    // Open the girdle so its thinnest point is the requested thickness.
    final tops = [for (var e = 0; e < edges; e++) breaks(e, crownCells)];
    final bottoms = [for (var e = 0; e < edges; e++) breaks(e, pavilionCells)];
    var thinnest = double.infinity;
    for (var e = 0; e < edges; e++) {
      for (final s in [...tops[e], ...bottoms[e]]) {
        final q = lerp(e, s);
        thinnest = math.min(thinnest, crownY(q.x, q.z) - pavilionY(q.x, q.z));
      }
    }
    final lift = g - thinnest;

    final ids = <(int, int, int), int>{};
    int vert(double x, double y, double z) => ids.putIfAbsent((
      (x * 1e7).round(),
      (y * 1e7).round(),
      (z * 1e7).round(),
    ), () => _add(x, y, z));

    for (var i = 0; i < crown.length; i++) {
      if (crownCells[i].isEmpty) continue;
      _polys.add((
        [
          for (final q in crownCells[i])
            vert(q.x, _eval(crown[i], q.x, q.z) + lift, q.z),
        ],
        crown[i].kind,
      ));
    }
    for (var i = 0; i < pavilion.length; i++) {
      if (pavilionCells[i].isEmpty) continue;
      _polys.add((
        [
          for (final q in pavilionCells[i])
            vert(q.x, _eval(pavilion[i], q.x, q.z), q.z),
        ],
        pavilion[i].kind,
      ));
    }
    int top(int e, double s) {
      final q = lerp(e, s);
      return vert(q.x, crownY(q.x, q.z) + lift, q.z);
    }

    int bottom(int e, double s) {
      final q = lerp(e, s);
      return vert(q.x, pavilionY(q.x, q.z), q.z);
    }

    for (var e = 0; e < edges; e++) {
      _polys.add((
        [
          for (final s in tops[e]) top(e, s),
          for (final s in bottoms[e].reversed) bottom(e, s),
        ],
        SimFacetKind.girdle,
      ));
    }

    final m0 = node(0);
    _crownHeight = hT - crownY(m0.x, m0.z);
    _pavilionDepth =
        pavilionY(m0.x, m0.z) - (cs > 0.001 ? -tp * (1 - cs * _cos8) : -tp);
    _girdle = crownY(m0.x, m0.z) + lift - pavilionY(m0.x, m0.z);

    if (half) _mirrorHalf();
  }

  /// Adds the −x half as the mirror image of every polygon so far, which
  /// become the traced half ([SimMesh.mirrorX]).
  void _mirrorHalf() {
    _tracedPolys = _polys.length;
    _fold = 1;
    final mirrored = <int, int>{};
    int flip(int i) => mirrored.putIfAbsent(i, () {
      final x = _pos[i * 3];
      return x.abs() < 1e-9 ? i : _add(-x, _pos[i * 3 + 1], _pos[i * 3 + 2]);
    });
    for (var k = 0, end = _polys.length; k < end; k++) {
      final (poly, kind) = _polys[k];
      _polys.add(([for (final i in poly.reversed) flip(i)], kind));
    }
  }

  /// Adds the rest of a [fold]-fold stone as the mirror images of the
  /// traced wedge so far (its turns by 2π/fold, each also mirrored at
  /// x = 0). Facets the mirrors cut through (the table, a bezel lying
  /// across one) are pieced back together by their group.
  void _kaleidoscope(int fold) {
    _tracedPolys = _polys.length;
    _fold = fold;
    final ids = <(int, int, int), int>{};
    int at(double x, double y, double z) => ids.putIfAbsent((
      (x * 1e6).round(),
      (y * 1e6).round(),
      (z * 1e6).round(),
    ), () => _add(x, y, z));
    // The traced corners join the same lookup, so images meet them.
    final traced = _pos.length ~/ 3;
    final own = List<int>.generate(
      traced,
      (i) => at(_pos[i * 3], _pos[i * 3 + 1], _pos[i * 3 + 2]),
    );
    final planeGroup = <(int, int, int, int), int>{};
    int groupOf(List<int> poly, int fallback) {
      // Newell normal and offset, rounded: coplanar pieces share one.
      var nx = 0.0, ny = 0.0, nz = 0.0, cx = 0.0, cy = 0.0, cz = 0.0;
      for (var k = 0; k < poly.length; k++) {
        final a = poly[k] * 3, b = poly[(k + 1) % poly.length] * 3;
        nx += (_pos[a + 1] - _pos[b + 1]) * (_pos[a + 2] + _pos[b + 2]);
        ny += (_pos[a + 2] - _pos[b + 2]) * (_pos[a] + _pos[b]);
        nz += (_pos[a] - _pos[b]) * (_pos[a + 1] + _pos[b + 1]);
        cx += _pos[a];
        cy += _pos[a + 1];
        cz += _pos[a + 2];
      }
      final l = math.sqrt(nx * nx + ny * ny + nz * nz);
      if (l < 1e-12) return fallback;
      final d = (nx * cx + ny * cy + nz * cz) / (l * poly.length);
      return planeGroup.putIfAbsent((
        (nx / l * 2e3).round(),
        (ny / l * 2e3).round(),
        (nz / l * 2e3).round(),
        (d * 2e3).round(),
      ), () => fallback);
    }

    final end = _polys.length;
    for (var k = 0; k < end; k++) {
      final (poly, kind) = _polys[k];
      final mapped = [for (final i in poly) own[i]];
      _polys[k] = (mapped, kind);
      _groups[k] = groupOf(mapped, k);
    }
    for (var j = 0; j < fold; j++) {
      final c = math.cos(2 * math.pi * j / fold);
      final s = math.sin(2 * math.pi * j / fold);
      for (final mirror in const [false, true]) {
        if (j == 0 && !mirror) continue;
        for (var k = 0; k < end; k++) {
          final (poly, kind) = _polys[k];
          final image = <int>[];
          for (final i in poly) {
            var x = _pos[i * 3];
            final z = _pos[i * 3 + 2];
            if (mirror) x = -x;
            // Turned about y by 2πj/fold, from +z toward +x.
            image.add(at(x * c + z * s, _pos[i * 3 + 1], z * c - x * s));
          }
          final ordered = mirror ? image.reversed.toList() : image;
          _groups[_polys.length] = groupOf(ordered, _polys.length);
          _polys.add((ordered, kind));
        }
      }
    }
  }

  void step(DiamondProportions p) {
    final o = StepOutline.of(shape);
    final t = p.tablePct / 100;
    final tc = math.tan(p.crownAngle * math.pi / 180);
    final tp = math.tan(p.pavilionAngle * math.pi / 180);
    final cs = p.culetScale;
    final g = p.girdle.percent / 100 * 2;

    List<int> ring(double inset, double y) {
      final pts = StepOutline.ring(o.halfLength, o.corner, inset);
      final out = <int>[];
      for (var k = 0; k < pts.length; k++) {
        final q = pts[k];
        int? same(int i) =>
            (_pos[i * 3] - q.x).abs() < 1e-9 &&
                (_pos[i * 3 + 2] - q.z).abs() < 1e-9
            ? i
            : null;
        final reuse =
            (out.isEmpty ? null : same(out.last)) ??
            (k == pts.length - 1 ? same(out.first) : null);
        out.add(reuse ?? _add(q.x, y, q.z));
      }
      return out;
    }

    // Crown: three steps, steepest at the girdle, to the table.
    final run = 1 - t;
    const crownSlopes = [1.2, 1.0, 0.8];
    final crown = [ring(0, g / 2)];
    var y = g / 2;
    for (var j = 0; j < 3; j++) {
      y += tc * crownSlopes[j] * run / 3;
      crown.add(ring(run * (j + 1) / 3, y));
    }
    _crownHeight = y - g / 2;

    // Pavilion: four steps easing toward the keel; scaled so the mains
    // average the pavilion angle.
    const fractions = [0.0, 0.32, 0.6, 0.83, 1.0];
    const pavilionSlopes = [1.32, 1.1, 0.9, 0.68];
    final reach = 1 - cs;
    var raw = 0.0;
    for (var j = 0; j < 4; j++) {
      raw += pavilionSlopes[j] * (fractions[j + 1] - fractions[j]);
    }
    final scale = tp / raw;
    final pavilion = [ring(0, -g / 2)];
    y = -g / 2;
    for (var j = 0; j < 4; j++) {
      y -=
          scale * pavilionSlopes[j] * (fractions[j + 1] - fractions[j]) * reach;
      pavilion.add(ring(fractions[j + 1] * reach, y));
    }
    _pavilionDepth = -g / 2 - y;
    _girdle = g;

    void band(List<int> a, List<int> b, SimFacetKind kind) {
      for (var e = 0; e < 8; e++) {
        final n = (e + 1) % 8;
        _polys.add(([a[e], a[n], b[n], b[e]], kind));
      }
    }

    _polys.add((crown.last, SimFacetKind.table));
    for (var j = 0; j < 3; j++) {
      band(crown[j], crown[j + 1], SimFacetKind.crown);
    }
    band(crown.first, pavilion.first, SimFacetKind.girdle);
    for (var j = 0; j < 4; j++) {
      band(pavilion[j], pavilion[j + 1], SimFacetKind.pavilion);
    }
    if (cs > 0.001) _polys.add((pavilion.last, SimFacetKind.culet));
  }

  SimMesh finish({bool centre = true}) {
    // Centre on the bounding box.
    var minX = double.infinity, maxX = -double.infinity;
    var minY = double.infinity, maxY = -double.infinity;
    var minZ = double.infinity, maxZ = -double.infinity;
    for (var i = 0; i < _pos.length; i += 3) {
      minX = math.min(minX, _pos[i]);
      maxX = math.max(maxX, _pos[i]);
      minY = math.min(minY, _pos[i + 1]);
      maxY = math.max(maxY, _pos[i + 1]);
      minZ = math.min(minZ, _pos[i + 2]);
      maxZ = math.max(maxZ, _pos[i + 2]);
    }
    // A mirrored half keeps its mirror plane at x = 0.
    final ox = _tracedPolys != null || !centre ? 0.0 : (minX + maxX) / 2;
    final oy = centre ? (minY + maxY) / 2 : 0.0;
    final oz = centre ? (minZ + maxZ) / 2 : 0.0;
    final pos = Float64List(_pos.length);
    var radius = 0.0;
    for (var i = 0; i < _pos.length; i += 3) {
      final x = _pos[i] - ox, y = _pos[i + 1] - oy, z = _pos[i + 2] - oz;
      pos
        ..[i] = x
        ..[i + 1] = y
        ..[i + 2] = z;
      radius = math.max(radius, x * x + y * y + z * z);
    }

    final starts = <int>[0], verts = <int>[], planes = <double>[];
    final kinds = <int>[], girdle = <int>[], groups = <int>[];
    var volume = 0.0;

    void emit(List<int> poly, SimFacetKind kind, int group) {
      var cx = 0.0, cy = 0.0, cz = 0.0;
      for (final i in poly) {
        cx += pos[i * 3];
        cy += pos[i * 3 + 1];
        cz += pos[i * 3 + 2];
      }
      cx /= poly.length;
      cy /= poly.length;
      cz /= poly.length;
      // Newell normal: twice the area along the facet normal.
      var nx = 0.0, ny = 0.0, nz = 0.0;
      for (var k = 0; k < poly.length; k++) {
        final a = poly[k] * 3, b = poly[(k + 1) % poly.length] * 3;
        nx += (pos[a + 1] - pos[b + 1]) * (pos[a + 2] + pos[b + 2]);
        ny += (pos[a + 2] - pos[b + 2]) * (pos[a] + pos[b]);
        nz += (pos[a] - pos[b]) * (pos[a + 1] + pos[b + 1]);
      }
      final len = math.sqrt(nx * nx + ny * ny + nz * nz);
      if (len < 1e-9) return;
      nx /= len;
      ny /= len;
      nz /= len;
      var ordered = poly;
      if (nx * cx + ny * cy + nz * cz < 0) {
        nx = -nx;
        ny = -ny;
        nz = -nz;
        ordered = poly.reversed.toList();
      }
      if (kind == SimFacetKind.girdle) girdle.add(kinds.length);
      verts.addAll(ordered);
      starts.add(verts.length);
      final d = nx * cx + ny * cy + nz * cz;
      planes.addAll([nx, ny, nz, d]);
      kinds.add(kind.index);
      groups.add(group);
      volume += len / 2 * d / 3;
    }

    var traced = -1;
    for (var k = 0; k < _polys.length; k++) {
      if (k == _tracedPolys) traced = kinds.length;
      final (raw, kind) = _polys[k];
      // Drop repeated corners left by collapsed rings.
      final poly = <int>[];
      for (final i in raw) {
        if (poly.isEmpty || poly.last != i) poly.add(i);
      }
      while (poly.length > 1 && poly.first == poly.last) {
        poly.removeLast();
      }
      if (poly.length < 3) continue;
      final group = _groups[k] ?? k;
      if (_isPlanar(poly, pos)) {
        emit(poly, kind, group);
      } else {
        // Fancy outlines bend a few kites and mains slightly: split them.
        for (var j = 1; j < poly.length - 1; j++) {
          emit([poly[0], poly[j], poly[j + 1]], kind, group);
        }
      }
    }

    final ext = (x: maxX - minX, z: maxZ - minZ);
    final heart = _shape == SimShape.heart;
    if (traced < 0) traced = kinds.length;
    final tracedGirdle = [
      for (final f in girdle)
        if (f < traced) f,
    ];
    return SimMesh._(
      shape: _shape,
      positions: pos,
      facetStart: Int32List.fromList(starts),
      facetVerts: Int32List.fromList(verts),
      planes: Float64List.fromList(planes),
      kinds: Uint8List.fromList(kinds),
      facetGroup: Int32List.fromList(groups),
      girdleFacets: Int32List.fromList(girdle),
      innerRadiusOf: () => _innerRadius(pos, verts, starts, tracedGirdle),
      length: heart ? ext.z : ext.x,
      width: heart ? ext.x : ext.z,
      crownHeight: _crownHeight,
      pavilionDepth: _pavilionDepth,
      girdleThickness: _girdle,
      totalDepth: maxY - minY,
      volume: volume,
      radius: math.sqrt(radius),
      fold: _fold,
      tracedFacets: traced,
    );
  }

  static bool _isPlanar(List<int> poly, Float64List pos) {
    if (poly.length == 3) return true;
    final a = poly[0] * 3, b = poly[1] * 3;
    final ux = pos[b] - pos[a], uy = pos[b + 1] - pos[a + 1];
    final uz = pos[b + 2] - pos[a + 2];
    var best = 0.0;
    var nx = 0.0, ny = 0.0, nz = 0.0;
    // Use the widest corner for a stable reference normal.
    for (var k = 2; k < poly.length; k++) {
      final q = poly[k] * 3;
      final vx = pos[q] - pos[a], vy = pos[q + 1] - pos[a + 1];
      final vz = pos[q + 2] - pos[a + 2];
      final cx = uy * vz - uz * vy, cy = uz * vx - ux * vz;
      final cz = ux * vy - uy * vx;
      final l = cx * cx + cy * cy + cz * cz;
      if (l > best) {
        best = l;
        nx = cx;
        ny = cy;
        nz = cz;
      }
    }
    if (best < 1e-18) return true;
    final l = math.sqrt(best);
    nx /= l;
    ny /= l;
    nz /= l;
    final d = nx * pos[a] + ny * pos[a + 1] + nz * pos[a + 2];
    for (final i in poly) {
      final off = nx * pos[i * 3] + ny * pos[i * 3 + 1] + nz * pos[i * 3 + 2];
      if ((off - d).abs() > 2e-4) return false;
    }
    return true;
  }

  /// Distance from the axis to the girdle's inner edge per angular bin,
  /// shrunk slightly so it never overstates.
  static Float64List _innerRadius(
    Float64List pos,
    List<int> verts,
    List<int> starts,
    List<int> girdle,
  ) {
    // Girdle edges in plan view: every side of each girdle facet (its
    // upright sides have no length in plan and drop out below).
    final edges = <double>[];
    for (final f in girdle) {
      final k = starts[f + 1] - starts[f];
      for (var j = 0; j < k; j++) {
        final a = verts[starts[f] + j] * 3;
        final b = verts[starts[f] + (j + 1) % k] * 3;
        edges.addAll([pos[a], pos[a + 2], pos[b], pos[b + 2]]);
      }
    }
    const bins = SimMesh.radialBins;
    final out = Float64List(bins);
    for (var k = 0; k < bins; k++) {
      var best = double.infinity;
      for (var s = 0; s <= 2; s++) {
        final a = 2 * math.pi * (k + s / 2) / bins;
        final dx = math.cos(a), dz = math.sin(a);
        for (var e = 0; e < edges.length; e += 4) {
          final x0 = edges[e], z0 = edges[e + 1];
          final ex = edges[e + 2] - x0, ez = edges[e + 3] - z0;
          final den = dx * ez - dz * ex;
          if (den.abs() < 1e-12) continue;
          final r = (x0 * ez - z0 * ex) / den;
          final w = (x0 * dz - z0 * dx) / den;
          if (r > 0 && w >= -1e-6 && w <= 1 + 1e-6) best = math.min(best, r);
        }
      }
      out[k] = best.isFinite ? best * 0.985 : 0;
    }
    return out;
  }
}
