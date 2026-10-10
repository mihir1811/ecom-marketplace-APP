import 'dart:math' as math;
import 'dart:typed_data';

/// The sheet the page is folded from: a square grid in normalised page
/// coordinates q ∈ [-1, 1]² (x right, y down).
///
/// The grid carries every fold crease exactly: the two axes and the
/// diamond |qx| + |qy| = 1 joining the edge midpoints. Each cell is split
/// along the diagonal parallel to its quadrant's crease, so the four corner
/// flaps and the four inner triangles are always flat, rigid pieces.
abstract final class DiamondGrid {
  static const size = 24;

  /// Facet lattice of the cut stone (cells per side; divides [size]). The
  /// sheet is pressed onto the cut one whole facet at a time.
  static const facets = 6;
  static const _half = size ~/ 2;
  static const stride = size + 1;
  static const vertexCount = stride * stride;
  static const triangleCount = size * size * 2;

  /// Normalised page coordinate of grid line [i].
  static double q(int i) => -1 + 2 * i / size;

  /// Grid vertex [k] (0–2) of triangle [t], wound clockwise on screen.
  static int vertex(int t, int k) {
    final cell = t >> 1;
    final row = cell ~/ size, col = cell % size;
    final a = row * stride + col, b = a + 1, d = a + stride, e = d + 1;
    // Mixed quadrant signs → the crease runs along a–e; otherwise b–d.
    final main = (col < _half) != (row < _half);
    if (main) {
      if ((t & 1) == 0) return k == 0 ? a : (k == 1 ? b : e);
      return k == 0 ? a : (k == 1 ? e : d);
    }
    if ((t & 1) == 0) return k == 0 ? a : (k == 1 ? b : d);
    return k == 0 ? b : (k == 1 ? e : d);
  }

  /// The sheet wrapped onto an octahedron: the centre becomes the front
  /// apex, the edge midpoints the four equator corners, and the four
  /// corner flaps fold behind to meet at the back apex. Written into
  /// [out] at [o] as x, y, z (z towards the viewer).
  static void octahedron(double qx, double qy, Float64List out, int o) {
    final r = qx.abs() + qy.abs();
    if (r <= 1) {
      out[o] = qx;
      out[o + 1] = qy;
    } else {
      out[o] = (qx < 0 ? -1 : 1) * (1 - qy.abs());
      out[o + 1] = (qy < 0 ? -1 : 1) * (1 - qx.abs());
    }
    out[o + 2] = 1 - r;
  }
}

/// How a cut spins while it carries a screen.
enum DiamondSpin {
  /// Even, gliding turn on a steady tilt.
  glide,

  /// Turntable feel: the tilt rocks with the facets as they index past.
  detent,

  /// Spinning-top precession: the axis leans and circles as it turns.
  precess,
}

enum _Outline { round, marquise, emerald }

/// One horizontal ring of facet corners (table edge, girdle, …).
class _Ring {
  const _Ring(this.row, this.y, this.scale, {this.corners, this.offset = 0});

  final int row;

  /// Height in girdle radii (negative = above the girdle).
  final double y;

  /// Size relative to the girdle outline.
  final double scale;

  /// Evenly spaced corner count; null uses the cut's own corner columns.
  final int? corners;

  /// Corner shift in columns (half a step twists the ring into kites and
  /// stars against its neighbours).
  final int offset;
}

/// A diamond silhouette and facet plan the folded sheet is pressed onto.
///
/// The cut is pure geometry in girdle radii: a stack of polygon rings whose
/// corners are offset against each other, reduced to the facet planes they
/// define. The sheet is pressed onto those planes along rays from the
/// centre, so every facet is flat; nothing is rendered as a 3D model.
class DiamondCut {
  DiamondCut._({
    required this.name,
    required this._outline,
    required this._rings,
    required this.tilt,
    required this.spin,
    required this.direction,
    this._cornerColumns,
  });

  final String name;

  /// Base forward tilt towards the viewer (radians), showing the table.
  final double tilt;
  final DiamondSpin spin;

  /// Preferred turning direction for an automatic transition (+1 / −1).
  final int direction;

  final _Outline _outline;
  final List<_Ring> _rings;
  final List<int>? _cornerColumns;

  /// The pressed sheet, built on first use (see [warmUp]).
  late final DiamondGem gem = DiamondGem._build(this);

  /// Round brilliant: eight-fold star and kite crown, sharp pavilion.
  static final brilliant = DiamondCut._(
    name: 'brilliant',
    outline: _Outline.round,
    tilt: 0.30,
    spin: DiamondSpin.glide,
    direction: 1,
    rings: const [
      _Ring(0, -0.30, 0.56, corners: 8),
      _Ring(5, -0.19, 0.80, corners: 8, offset: 4),
      _Ring(11, -0.015, 1, corners: 16),
      _Ring(12, 0.015, 1, corners: 16),
      _Ring(25, 0.52, 0.40, corners: 8, offset: 4),
      _Ring(36, 0.86, 0),
    ],
  );

  /// Marquise: long pointed lens with a shallow crown.
  static final marquise = DiamondCut._(
    name: 'marquise',
    outline: _Outline.marquise,
    tilt: 0.36,
    spin: DiamondSpin.precess,
    direction: -1,
    rings: const [
      _Ring(0, -0.26, 0.52, corners: 8),
      _Ring(6, -0.15, 0.82, corners: 16, offset: 2),
      _Ring(11, -0.015, 1, corners: 16),
      _Ring(12, 0.015, 1, corners: 16),
      _Ring(22, 0.40, 0.55, corners: 16, offset: 2),
      _Ring(36, 0.78, 0),
    ],
  );

  /// Emerald step cut: chamfered rectangle, concentric steps, keel culet.
  static final emerald = DiamondCut._(
    name: 'emerald',
    outline: _Outline.emerald,
    tilt: 0.34,
    spin: DiamondSpin.detent,
    direction: 1,
    // Chamfer corners of the rectangle, snapped to ring columns.
    cornerColumns: const [8, 12, 20, 24, 40, 44, 52, 56],
    rings: const [
      _Ring(0, -0.22, 0.64),
      _Ring(4, -0.15, 0.80),
      _Ring(8, -0.07, 0.92),
      _Ring(11, -0.015, 1),
      _Ring(12, 0.015, 1),
      _Ring(19, 0.27, 0.76),
      _Ring(26, 0.52, 0.52),
      _Ring(32, 0.70, 0.28),
      _Ring(36, 0.80, 0.08),
    ],
  );

  static List<DiamondCut> get all => [brilliant, marquise, emerald];

  /// Builds every cut's geometry ahead of the first transition.
  static void warmUp(Iterable<DiamondCut> cuts) {
    for (final cut in cuts) {
      cut.gem;
    }
  }
}

/// A cut's pressed sheet, in girdle radii centred on mid-height.
class DiamondGem {
  DiamondGem._({required this.positions, required this.normals});

  /// Sheet vertex on the gem: x, y, z per [DiamondGrid] vertex.
  final Float32List positions;

  /// Facet normal under each sheet triangle: x, y, z per triangle.
  final Float32List normals;

  // Ring mesh the facet planes are read from.
  static const _cols = 64;
  static const _rows = 36;
  static const _vc = _cols + 1;
  static const _faces = _cols * _rows * 2;

  static double _azimuth(num c) => (c / _cols - 0.5) * 2 * math.pi;

  static int _corner(int t, int k) {
    final cell = t >> 1;
    final a = (cell ~/ _cols) * _vc + cell % _cols;
    if ((t & 1) == 0) return k == 0 ? a : (k == 1 ? a + 1 : a + _vc);
    return k == 0 ? a + 1 : (k == 1 ? a + _vc + 1 : a + _vc);
  }

  static DiamondGem _build(DiamondCut cut) {
    final s = _surface(cut);

    // Facet planes: outward normal and offset (n·p), one per flat facet.
    final planes = <double>[];
    int planeFor(double nx, double ny, double nz, double h) {
      for (var k = 0; k < planes.length; k += 4) {
        final same =
            nx * planes[k] + ny * planes[k + 1] + nz * planes[k + 2] >
                0.99995 &&
            (h - planes[k + 3]).abs() < 1e-3;
        if (same) return k ~/ 4;
      }
      planes.addAll([nx, ny, nz, h]);
      return planes.length ~/ 4 - 1;
    }

    for (var t = 0; t < _faces; t++) {
      final i0 = _corner(t, 0) * 3;
      final i1 = _corner(t, 1) * 3;
      final i2 = _corner(t, 2) * 3;
      final ex = s[i1] - s[i0], ey = s[i1 + 1] - s[i0 + 1];
      final ez = s[i1 + 2] - s[i0 + 2];
      final fx = s[i2] - s[i0], fy = s[i2 + 1] - s[i0 + 1];
      final fz = s[i2 + 2] - s[i0 + 2];
      var nx = ey * fz - ez * fy;
      var ny = ez * fx - ex * fz;
      var nz = ex * fy - ey * fx;
      final len = math.sqrt(nx * nx + ny * ny + nz * nz);
      if (len < 1e-7) continue; // collapsed at the culet
      nx /= len;
      ny /= len;
      nz /= len;
      planeFor(nx, ny, nz, nx * s[i0] + ny * s[i0 + 1] + nz * s[i0 + 2]);
    }
    // The table: a horizontal plane through the first ring.
    planeFor(0, -1, 0, -s[1]);

    // Rays start at the girdle's centre, so the sheet's diagonal fold line
    // (the octahedron's equator) lands exactly on the girdle.
    final girdleRow = cut._rings.firstWhere((r) => r.scale == 1).row;
    final cy =
        (s[girdleRow * _vc * 3 + 1] + s[(girdleRow + 1) * _vc * 3 + 1]) / 2;
    double reach(double dx, double dy, double dz) {
      var best = double.infinity;
      for (var k = 0; k < planes.length; k += 4) {
        final dn = dx * planes[k] + dy * planes[k + 1] + dz * planes[k + 2];
        if (dn <= 1e-6) continue;
        final t = (planes[k + 3] - planes[k + 1] * cy) / dn;
        if (t < best) best = t;
      }
      return best.isFinite ? best : 0;
    }

    // Press the coarse facet lattice onto the cut along octahedral rays.
    const k = DiamondGrid.facets;
    const kv = k + 1;
    final octa = Float64List(3);
    final coarse = Float64List(kv * kv * 3);
    for (var j = 0; j <= k; j++) {
      for (var i = 0; i <= k; i++) {
        DiamondGrid.octahedron(-1 + 2 * i / k, -1 + 2 * j / k, octa, 0);
        final len = math.sqrt(
          octa[0] * octa[0] + octa[1] * octa[1] + octa[2] * octa[2],
        );
        final dx = octa[0] / len, dy = octa[1] / len, dz = octa[2] / len;
        final r = reach(dx, dy, dz);
        final o = (j * kv + i) * 3;
        coarse[o] = dx * r;
        coarse[o + 1] = cy + dy * r;
        coarse[o + 2] = dz * r;
      }
    }

    // Sheet vertices sit flat inside their coarse facet, so every facet is
    // one plane and no sheet grid ever shows on the stone.
    const n = DiamondGrid.size;
    const m = n ~/ k;
    final positions = Float32List(DiamondGrid.vertexCount * 3);
    for (var j = 0; j <= n; j++) {
      final cj = math.min(j ~/ m, k - 1);
      final v = (j - cj * m) / m;
      for (var i = 0; i <= n; i++) {
        final ci = math.min(i ~/ m, k - 1);
        final u = (i - ci * m) / m;
        final a = (cj * kv + ci) * 3, b = a + 3;
        final d = a + kv * 3, e = d + 3;
        final main = (ci < k ~/ 2) != (cj < k ~/ 2);
        final o = (j * DiamondGrid.stride + i) * 3;
        for (var x = 0; x < 3; x++) {
          final double p;
          if (main) {
            p = u >= v
                ? coarse[a + x] +
                      u * (coarse[b + x] - coarse[a + x]) +
                      v * (coarse[e + x] - coarse[b + x])
                : coarse[a + x] +
                      v * (coarse[d + x] - coarse[a + x]) +
                      u * (coarse[e + x] - coarse[d + x]);
          } else {
            p = u + v <= 1
                ? coarse[a + x] +
                      u * (coarse[b + x] - coarse[a + x]) +
                      v * (coarse[d + x] - coarse[a + x])
                : coarse[e + x] +
                      (1 - u) * (coarse[d + x] - coarse[e + x]) +
                      (1 - v) * (coarse[b + x] - coarse[e + x]);
          }
          positions[o + x] = p;
        }
      }
    }

    // Facet normal of every sheet triangle (all coplanar within a facet).
    final normals = Float32List(DiamondGrid.triangleCount * 3);
    for (var t = 0; t < DiamondGrid.triangleCount; t++) {
      final i0 = DiamondGrid.vertex(t, 0) * 3;
      final i1 = DiamondGrid.vertex(t, 1) * 3;
      final i2 = DiamondGrid.vertex(t, 2) * 3;
      final ex = positions[i1] - positions[i0];
      final ey = positions[i1 + 1] - positions[i0 + 1];
      final ez = positions[i1 + 2] - positions[i0 + 2];
      final fx = positions[i2] - positions[i0];
      final fy = positions[i2 + 1] - positions[i0 + 1];
      final fz = positions[i2 + 2] - positions[i0 + 2];
      var nx = ey * fz - ez * fy;
      var ny = ez * fx - ex * fz;
      var nz = ex * fy - ey * fx;
      final len = math.sqrt(nx * nx + ny * ny + nz * nz);
      if (len < 1e-9) {
        nx = 0;
        ny = 1; // collapsed at the culet
        nz = 0;
      } else {
        nx /= len;
        ny /= len;
        nz /= len;
      }
      normals[t * 3] = nx;
      normals[t * 3 + 1] = ny;
      normals[t * 3 + 2] = nz;
    }

    return DiamondGem._(positions: positions, normals: normals);
  }

  /// Ring mesh of the cut: x, y, z per (row, column) vertex.
  static Float64List _surface(DiamondCut cut) {
    final rings = cut._rings;
    assert(rings.first.row == 0 && rings.last.row == _rows);

    // Corner points of every ring, then each column projected radially onto
    // the ring's polygon so the facets between corners stay flat.
    final ringX = <Float64List>[];
    final ringZ = <Float64List>[];
    for (final ring in rings) {
      final corners = <int>[
        if (ring.corners case final n?)
          for (var k = 0; k < n; k++) ring.offset + k * (_cols ~/ n)
        else
          ...?cut._cornerColumns,
      ]..sort();
      assert(corners.isNotEmpty || ring.scale == 0);
      final xs = Float64List(_vc);
      final zs = Float64List(_vc);
      for (var c = 0; c <= _cols; c++) {
        final p = _onPolygon(c, corners, ring.scale, cut._outline);
        xs[c] = p.$1;
        zs[c] = p.$2;
      }
      ringX.add(xs);
      ringZ.add(zs);
    }

    final mid = (rings.first.y + rings.last.y) / 2;
    final out = Float64List(_vc * (_rows + 1) * 3);
    var r = 0;
    for (var j = 0; j <= _rows; j++) {
      while (r < rings.length - 2 && rings[r + 1].row <= j) {
        r++;
      }
      final a = rings[r], b = rings[r + 1];
      final t = (j - a.row) / (b.row - a.row);
      final y = a.y + (b.y - a.y) * t - mid;
      for (var c = 0; c <= _cols; c++) {
        final i = (j * _vc + c) * 3;
        out[i] = ringX[r][c] + (ringX[r + 1][c] - ringX[r][c]) * t;
        out[i + 1] = y;
        out[i + 2] = ringZ[r][c] + (ringZ[r + 1][c] - ringZ[r][c]) * t;
      }
    }
    return out;
  }

  /// Point of the ring polygon in the direction of column [c].
  static (double, double) _onPolygon(
    int c,
    List<int> corners,
    double scale,
    _Outline outline,
  ) {
    if (scale == 0) return (0, 0);
    // Bracketing corners (periodic).
    var c0 = corners.last - _cols, c1 = corners.first;
    for (var k = 0; k < corners.length; k++) {
      if (corners[k] <= c) {
        c0 = corners[k];
        c1 = k + 1 < corners.length ? corners[k + 1] : corners.first + _cols;
      }
    }
    (double, double) corner(int col) {
      final a = _azimuth(col);
      final rad = scale * _radius(outline, a);
      return (rad * math.sin(a), rad * math.cos(a));
    }

    final p0 = corner(c0), p1 = corner(c1);
    if (c == c0) return p0;
    final a = _azimuth(c);
    final dx = math.sin(a), dz = math.cos(a);
    final ex = p1.$1 - p0.$1, ez = p1.$2 - p0.$2;
    final denom = dx * ez - dz * ex;
    if (denom.abs() < 1e-9) return p0;
    final t = (p0.$1 * ez - p0.$2 * ex) / denom;
    return (t * dx, t * dz);
  }

  /// Outline radius at azimuth [a] (x = sin, z = cos).
  static double _radius(_Outline outline, double a) {
    switch (outline) {
      case _Outline.round:
        return 1;
      case _Outline.marquise:
        // Lens of two arcs: tips at x = ±1, half-width 0.55.
        const rho = 1.184, d = 0.634;
        final c = math.cos(a).abs();
        return -d * c + math.sqrt(d * d * c * c + rho * rho - d * d);
      case _Outline.emerald:
        return _octagonRadius(a);
    }
  }

  static const _octagon = <(double, double)>[
    (0.75, 0.70),
    (1.0, 0.45),
    (1.0, -0.45),
    (0.75, -0.70),
    (-0.75, -0.70),
    (-1.0, -0.45),
    (-1.0, 0.45),
    (-0.75, 0.70),
  ];

  static double _octagonRadius(double a) {
    final dx = math.sin(a), dz = math.cos(a);
    var best = double.infinity;
    for (var k = 0; k < _octagon.length; k++) {
      final p0 = _octagon[k], p1 = _octagon[(k + 1) % _octagon.length];
      final ex = p1.$1 - p0.$1, ez = p1.$2 - p0.$2;
      final denom = dx * ez - dz * ex;
      if (denom.abs() < 1e-9) continue;
      final t = (p0.$1 * ez - p0.$2 * ex) / denom;
      final s = (p0.$1 * dz - p0.$2 * dx) / denom;
      if (t > 0 && s >= -1e-6 && s <= 1 + 1e-6 && t < best) best = t;
    }
    return best.isFinite ? best : 1;
  }
}
