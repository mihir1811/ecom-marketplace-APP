import 'dart:math' as math;
import 'dart:typed_data';

import '../domain/diamond_proportions.dart';
import '../domain/diamond_shape.dart';
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
    required this.girdleFacets,
    required this.innerRadius,
    required this.length,
    required this.width,
    required this.crownHeight,
    required this.pavilionDepth,
    required this.girdleThickness,
    required this.totalDepth,
    required this.volume,
    required this.radius,
  });

  final SimShape shape;

  /// Vertex positions, xyz.
  final Float64List positions;

  /// Facet `f` uses `facetVerts[facetStart[f] .. facetStart[f + 1]]`, in
  /// order around the facet.
  final Int32List facetStart;
  final Int32List facetVerts;

  /// Outward unit normal and offset per facet: `n · p = d` on the facet.
  final Float64List planes;
  final Uint8List kinds;

  /// Girdle facets; a ray only needs to test them when it reaches the
  /// girdle band (see [innerRadius]).
  final Int32List girdleFacets;

  /// Conservative distance from the axis to the girdle, per angular bin
  /// of [radialBins] around +x. Points inside it are inside the girdle.
  final Float64List innerRadius;
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

  /// Builds [shape] cut to [proportions].
  static SimMesh build(SimShape shape, DiamondProportions proportions) {
    final b = _Builder(shape);
    if (shape.family == SimCutFamily.step) {
      b.step(proportions);
    } else {
      b.brilliant(proportions);
    }
    return b.finish();
  }
}

class _Builder {
  _Builder(this.shape);

  final SimShape shape;
  final List<double> _pos = [];
  final List<(List<int>, SimFacetKind)> _polys = [];
  double _crownHeight = 0, _pavilionDepth = 0, _girdle = 0;

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

  SimMesh finish() {
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
    final ox = (minX + maxX) / 2, oy = (minY + maxY) / 2;
    final oz = (minZ + maxZ) / 2;
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
    final kinds = <int>[], girdle = <int>[];
    var volume = 0.0;

    void emit(List<int> poly, SimFacetKind kind) {
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
      volume += len / 2 * d / 3;
    }

    for (final (raw, kind) in _polys) {
      // Drop repeated corners left by collapsed rings.
      final poly = <int>[];
      for (final i in raw) {
        if (poly.isEmpty || poly.last != i) poly.add(i);
      }
      while (poly.length > 1 && poly.first == poly.last) {
        poly.removeLast();
      }
      if (poly.length < 3) continue;
      if (_isPlanar(poly, pos)) {
        emit(poly, kind);
      } else {
        // Fancy outlines bend a few kites and mains slightly: split them.
        for (var k = 1; k < poly.length - 1; k++) {
          emit([poly[0], poly[k], poly[k + 1]], kind);
        }
      }
    }

    final ext = (x: maxX - minX, z: maxZ - minZ);
    final heart = shape == SimShape.heart;
    return SimMesh._(
      shape: shape,
      positions: pos,
      facetStart: Int32List.fromList(starts),
      facetVerts: Int32List.fromList(verts),
      planes: Float64List.fromList(planes),
      kinds: Uint8List.fromList(kinds),
      girdleFacets: Int32List.fromList(girdle),
      innerRadius: _innerRadius(pos, verts, starts, girdle),
      length: heart ? ext.z : ext.x,
      width: heart ? ext.x : ext.z,
      crownHeight: _crownHeight,
      pavilionDepth: _pavilionDepth,
      girdleThickness: _girdle,
      totalDepth: maxY - minY,
      volume: volume,
      radius: math.sqrt(radius),
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
    // Girdle edges in plan view: each girdle facet's first two corners.
    final edges = <double>[];
    for (final f in girdle) {
      final a = verts[starts[f]] * 3, b = verts[starts[f] + 1] * 3;
      edges.addAll([pos[a], pos[a + 2], pos[b], pos[b + 2]]);
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
