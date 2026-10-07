import 'dart:math' as math;
import 'dart:typed_data';

/// Diamond cuts the procedural mesh builder can produce.
enum GemCut {
  round,
  oval,
  princess,
  cushion,
  emerald,
  asscher,
  radiant,
  pear,
  marquise,
  heart,
}

/// Region of the stone a triangle belongs to; drives its optical response.
enum GemFacetKind { table, crown, girdle, pavilion }

/// One horizontal ring of the stone profile.
///
/// [count] samples of the girdle outline, scaled by [scale], at height [y].
/// [offset] shifts samples by half a step, which turns the band between two
/// rings into alternating triangles (brilliant stars / halves) instead of
/// quads (step cut).
class _Ring {
  const _Ring(this.count, this.scale, this.y, {this.offset = false});

  final int count;
  final double scale;
  final double y;
  final bool offset;
}

/// Faceted gem mesh built from a girdle outline and a ring profile.
///
/// Triangles are unshared (flat shaded) and wound counter-clockwise when seen
/// from outside, so back faces can be culled with the facet normal. Model
/// space: girdle fits a unit circle, y up, centred on the stone's height.
class GemMesh {
  GemMesh._(this.vertices, this.normals, this.kinds, this.seeds);

  /// Mesh from ready-made triangles (e.g. an imported model). [vertices]
  /// holds 9 floats per triangle, wound counter-clockwise from outside;
  /// facet normals are derived from the winding.
  factory GemMesh.fromTriangles(
    Float32List vertices,
    List<GemFacetKind> kinds,
    Float32List seeds,
  ) {
    final count = kinds.length;
    final normals = Float32List(count * 3);
    for (var t = 0; t < count; t++) {
      final b = t * 9;
      final ux = vertices[b + 3] - vertices[b];
      final uy = vertices[b + 4] - vertices[b + 1];
      final uz = vertices[b + 5] - vertices[b + 2];
      final vx = vertices[b + 6] - vertices[b];
      final vy = vertices[b + 7] - vertices[b + 1];
      final vz = vertices[b + 8] - vertices[b + 2];
      final nx = uy * vz - uz * vy;
      final ny = uz * vx - ux * vz;
      final nz = ux * vy - uy * vx;
      final len = math.max(1e-12, math.sqrt(nx * nx + ny * ny + nz * nz));
      normals
        ..[t * 3] = nx / len
        ..[t * 3 + 1] = ny / len
        ..[t * 3 + 2] = nz / len;
    }
    return GemMesh._(vertices, normals, List.unmodifiable(kinds), seeds);
  }

  /// Triangle corners, 9 floats (3 × xyz) per triangle.
  final Float32List vertices;

  /// Unit outward facet normal, 3 floats per triangle.
  final Float32List normals;

  /// Facet region per triangle.
  final List<GemFacetKind> kinds;

  /// Stable 0..1 value per facet; varies fire and sparkle.
  final Float32List seeds;

  int get triangleCount => kinds.length;

  static final Map<GemCut, GemMesh> _cache = {};

  /// Cached mesh for [cut]; built once on first use.
  static GemMesh of(GemCut cut) => _cache.putIfAbsent(cut, () => _build(cut));

  static GemMesh _build(GemCut cut) {
    final outline = _Outline(cut);
    final rings = _profile(cut);

    var top = -double.infinity, bottom = double.infinity;
    for (final r in rings) {
      top = math.max(top, r.y);
      bottom = math.min(bottom, r.y);
    }
    final centreY = (top + bottom) / 2;

    List<List<double>> ringPoints(_Ring r) {
      if (r.count == 1 || r.scale == 0) {
        return [
          [0, r.y - centreY, 0],
        ];
      }
      return [
        for (var j = 0; j < r.count; j++)
          () {
            final t = (j + (r.offset ? 0.5 : 0)) / r.count;
            final p = outline.at(t);
            return [p.x * r.scale, r.y - centreY, p.z * r.scale];
          }(),
      ];
    }

    final verts = <double>[];
    final norms = <double>[];
    final kinds = <GemFacetKind>[];
    final seeds = <double>[];
    final rng = math.Random(cut.index * 97 + 13);

    void tri(List<double> a, List<double> b, List<double> c, GemFacetKind k,
        double seed) {
      final ux = b[0] - a[0], uy = b[1] - a[1], uz = b[2] - a[2];
      final vx = c[0] - a[0], vy = c[1] - a[1], vz = c[2] - a[2];
      var nx = uy * vz - uz * vy;
      var ny = uz * vx - ux * vz;
      var nz = ux * vy - uy * vx;
      final len = math.sqrt(nx * nx + ny * ny + nz * nz);
      if (len < 1e-9) return;
      nx /= len;
      ny /= len;
      nz /= len;
      verts.addAll([...a, ...b, ...c]);
      norms.addAll([nx, ny, nz]);
      kinds.add(k);
      seeds.add(seed);
    }

    // Table: fan from the centre, wound to face +y.
    final table = ringPoints(rings.first);
    final tableCentre = [0.0, rings.first.y - centreY, 0.0];
    final tableSeed = rng.nextDouble();
    for (var j = 0; j < table.length; j++) {
      tri(tableCentre, table[(j + 1) % table.length], table[j],
          GemFacetKind.table, tableSeed);
    }

    // Bands: zipper-walk two rings by outline parameter so any mix of
    // sample counts and half-step offsets triangulates without gaps.
    for (var b = 0; b < rings.length - 1; b++) {
      final ru = rings[b], rl = rings[b + 1];
      final up = ringPoints(ru), lo = ringPoints(rl);
      final kind = ru.scale == 1 && rl.scale == 1
          ? GemFacetKind.girdle
          : (rl.y >= 0 ? GemFacetKind.crown : GemFacetKind.pavilion);
      final quads = ru.count == rl.count && ru.offset == rl.offset;

      if (lo.length == 1) {
        for (var j = 0; j < up.length; j++) {
          tri(up[j], up[(j + 1) % up.length], lo[0], kind, rng.nextDouble());
        }
        continue;
      }

      double tu(int i) => (i + (ru.offset ? 0.5 : 0)) / ru.count;
      double tl(int k) => (k + (rl.offset ? 0.5 : 0)) / rl.count;
      var i = 0, k = 0;
      var pairSeed = rng.nextDouble();
      while (i < up.length || k < lo.length) {
        final advanceUpper =
            i < up.length && (k >= lo.length || tu(i + 1) <= tl(k + 1));
        final seed = quads ? pairSeed : rng.nextDouble();
        if (advanceUpper) {
          tri(up[i % up.length], up[(i + 1) % up.length], lo[k % lo.length],
              kind, seed);
          i++;
        } else {
          tri(up[i % up.length], lo[(k + 1) % lo.length], lo[k % lo.length],
              kind, seed);
          k++;
          pairSeed = rng.nextDouble();
        }
      }
    }

    // Guarantee outward winding: the table must face up.
    if (norms[1] < 0) {
      for (var t = 0; t < kinds.length; t++) {
        for (var c = 0; c < 3; c++) {
          final a = t * 9 + 3 + c, b = t * 9 + 6 + c;
          final tmp = verts[a];
          verts[a] = verts[b];
          verts[b] = tmp;
        }
        norms[t * 3] = -norms[t * 3];
        norms[t * 3 + 1] = -norms[t * 3 + 1];
        norms[t * 3 + 2] = -norms[t * 3 + 2];
      }
    }

    return GemMesh._(
      Float32List.fromList(verts),
      Float32List.fromList(norms),
      List.unmodifiable(kinds),
      Float32List.fromList(seeds),
    );
  }

  static List<_Ring> _profile(GemCut cut) {
    switch (cut) {
      case GemCut.emerald:
      case GemCut.asscher:
        final deep = cut == GemCut.asscher ? 0.06 : 0.0;
        return [
          const _Ring(16, 0.62, 0.25),
          const _Ring(16, 0.76, 0.17),
          const _Ring(16, 0.9, 0.08),
          const _Ring(16, 1, 0.02),
          const _Ring(16, 1, -0.02),
          _Ring(16, 0.74, -0.26 - deep),
          _Ring(16, 0.5, -0.48 - deep),
          _Ring(16, 0.26, -0.66 - deep),
          _Ring(1, 0, -0.8 - deep),
        ];
      case GemCut.princess:
        return const [
          _Ring(8, 0.72, 0.24),
          _Ring(16, 0.86, 0.14, offset: true),
          _Ring(16, 1, 0.02),
          _Ring(16, 1, -0.02),
          _Ring(8, 0.5, -0.45),
          _Ring(1, 0, -0.82),
        ];
      case GemCut.radiant:
        return const [
          _Ring(8, 0.6, 0.28, offset: true),
          _Ring(16, 0.8, 0.16),
          _Ring(16, 1, 0.02),
          _Ring(16, 1, -0.02),
          _Ring(8, 0.5, -0.48, offset: true),
          _Ring(1, 0, -0.84),
        ];
      case GemCut.round:
        return const [
          _Ring(8, 0.56, 0.30),
          _Ring(8, 0.80, 0.16, offset: true),
          _Ring(16, 1, 0.02),
          _Ring(16, 1, -0.02),
          _Ring(8, 0.46, -0.50, offset: true),
          _Ring(1, 0, -0.86),
        ];
      case GemCut.oval:
      case GemCut.cushion:
      case GemCut.pear:
      case GemCut.marquise:
      case GemCut.heart:
        return const [
          _Ring(8, 0.56, 0.28),
          _Ring(8, 0.80, 0.15, offset: true),
          _Ring(24, 1, 0.02),
          _Ring(24, 1, -0.02),
          _Ring(8, 0.46, -0.48, offset: true),
          _Ring(1, 0, -0.84),
        ];
    }
  }
}

/// Girdle outline of a cut: counter-clockwise (x → z), centred, max half
/// extent 1. `t` runs 0..1 once around; tips and corners land on sample
/// parameters used by the profiles.
class _Outline {
  _Outline(this.cut) {
    var area = 0.0;
    var minX = double.infinity, maxX = -double.infinity;
    var minZ = double.infinity, maxZ = -double.infinity;
    const n = 192;
    for (var i = 0; i < n; i++) {
      final a = _raw(i / n), b = _raw((i + 1) / n);
      area += a.x * b.z - b.x * a.z;
      minX = math.min(minX, a.x);
      maxX = math.max(maxX, a.x);
      minZ = math.min(minZ, a.z);
      maxZ = math.max(maxZ, a.z);
    }
    _reverse = area < 0;
    _cx = (minX + maxX) / 2;
    _cz = (minZ + maxZ) / 2;
    _s = 1 / math.max((maxX - minX) / 2, (maxZ - minZ) / 2);
  }

  final GemCut cut;
  late final bool _reverse;
  late final double _cx, _cz, _s;

  ({double x, double z}) at(double t) {
    final p = _raw(_reverse ? (1 - t) % 1 : t);
    return (x: (p.x - _cx) * _s, z: (p.z - _cz) * _s);
  }

  ({double x, double z}) _raw(double t) {
    final a = 2 * math.pi * t;
    switch (cut) {
      case GemCut.round:
        return (x: math.cos(a), z: math.sin(a));
      case GemCut.oval:
        return (x: math.cos(a), z: 0.7 * math.sin(a));
      case GemCut.cushion:
        double se(double v) =>
            v.sign * math.pow(v.abs(), 2 / 3.4).toDouble();
        return (x: se(math.cos(a)), z: 0.9 * se(math.sin(a)));
      case GemCut.princess:
        return _square(t);
      case GemCut.emerald:
        return _octagon(t, 1, 0.68, 0.2);
      case GemCut.asscher:
        return _octagon(t, 1, 1, 0.3);
      case GemCut.radiant:
        return _octagon(t, 1, 0.78, 0.16);
      case GemCut.marquise:
        return _lens(a, 0.46);
      case GemCut.pear:
        const h = 0.62;
        if (math.cos(a) >= 0) return _lens(a, h);
        return (x: h * math.cos(a), z: h * math.sin(a));
      case GemCut.heart:
        final s = math.sin(a);
        return (
          x: 16 * s * s * s / 17,
          z: (13 * math.cos(a) -
                  5 * math.cos(2 * a) -
                  2 * math.cos(3 * a) -
                  math.cos(4 * a)) /
              17,
        );
    }
  }

  /// Pointed lens through (±1, 0) with half width [h].
  static ({double x, double z}) _lens(double a, double h) {
    final r = (h + 1 / h) / 2;
    final c = (1 / h - h) / 2;
    final x = math.cos(a);
    final z = math.sqrt(math.max(0, r * r - x * x)) - c;
    return (x: x, z: math.sin(a) >= 0 ? z : -z);
  }

  /// Square, perimeter-uniform from (1, 0); corners at t = 1/8 + k/4.
  static ({double x, double z}) _square(double t) {
    const v = [
      (x: 1.0, z: -1.0),
      (x: 1.0, z: 1.0),
      (x: -1.0, z: 1.0),
      (x: -1.0, z: -1.0),
    ];
    final u = (t * 4 + 0.5) % 4;
    final e = u.floor() % 4;
    final f = u - u.floor();
    final a = v[e], b = v[(e + 1) % 4];
    return (x: a.x + (b.x - a.x) * f, z: a.z + (b.z - a.z) * f);
  }

  /// Cut-corner rectangle; each of the 8 edges spans 1/8 of `t`, starting
  /// mid right edge, so vertices sit at t = 1/16 + k/8.
  static ({double x, double z}) _octagon(
    double t,
    double w,
    double h,
    double c,
  ) {
    final v = [
      (x: w, z: -h + c),
      (x: w, z: h - c),
      (x: w - c, z: h),
      (x: -w + c, z: h),
      (x: -w, z: h - c),
      (x: -w, z: -h + c),
      (x: -w + c, z: -h),
      (x: w - c, z: -h),
    ];
    final u = (t * 8 + 0.5) % 8;
    final e = u.floor() % 8;
    final f = u - u.floor();
    final a = v[e], b = v[(e + 1) % 8];
    return (x: a.x + (b.x - a.x) * f, z: a.z + (b.z - a.z) * f);
  }
}
