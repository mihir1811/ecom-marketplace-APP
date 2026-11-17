import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'diamond_mesh.dart';
import 'gem_mesh.dart';

/// Converts a faceted stone from a binary glTF (.glb) file into a
/// [DiamondModel]. Pure Dart: it runs in the offline bake
/// (`tool/bake_gem_models.dart`), never in the app.
///
/// The model's triangles are grouped into planar facets (a cut stone is
/// convex, so each plane holds exactly one facet) and every facet is
/// rebuilt over its convex outline. That drops the exporter's tessellation
/// (T-junctions, collinear girdle samples, zero-area slivers) without
/// changing the silhouette or the facet pattern. The result is normalised
/// to the [GemMesh] model space: table up (+y), girdle within the unit
/// circle, centred on the stone's height.
abstract final class GemGlb {
  static DiamondModel convert(String name, Uint8List bytes) {
    final facets = _Facet.read(bytes);
    return DiamondModel(
      name: name,
      detail: _mesh(facets, simplify: 0.005, minArea: 0),
      coarse: _mesh(facets, simplify: 0.02, minArea: 1.6e-3, girdle: false),
    );
  }

  /// Outline corners that carve off less than [simplify] of the facet area
  /// are dropped, and facets smaller than [minArea] (model units²) are
  /// skipped, as is the girdle band unless [girdle]. Corners shared by
  /// neighbouring facets become one vertex.
  static DiamondMesh _mesh(
    List<_Facet> facets, {
    required double simplify,
    required double minArea,
    bool girdle = true,
  }) {
    final positions = <double>[];
    final shared = <String, int>{};
    final normals = <double>[];
    final seeds = <double>[];
    final kinds = <int>[];
    final vertStart = <int>[0];
    final verts = <int>[];
    final triStart = <int>[0];
    final tris = <int>[];
    for (final f in facets) {
      if (f.area < minArea || (!girdle && f.kind == GemFacetKind.girdle)) {
        continue;
      }
      final local = <int>[];
      int use(_V3 p) {
        final key =
            '${(p[0] * 1e5).round()},${(p[1] * 1e5).round()},'
            '${(p[2] * 1e5).round()}';
        final global = shared.putIfAbsent(key, () {
          positions.addAll(p);
          return positions.length ~/ 3 - 1;
        });
        final i = local.indexOf(global);
        if (i >= 0) return i;
        local.add(global);
        return local.length - 1;
      }

      final corners = <int>[];
      void triangle(int a, int b, int c) {
        if (a != b && b != c && a != c) corners.addAll([a, b, c]);
      }

      final outline = f.outline;
      if (outline != null) {
        final ring = [for (final p in f.simplified(simplify)) use(p)];
        for (var j = 1; j < ring.length - 1; j++) {
          triangle(ring[0], ring[j], ring[j + 1]);
        }
      } else {
        final c = f.corners!;
        for (var j = 0; j < c.length; j += 3) {
          triangle(use(c[j]), use(c[j + 1]), use(c[j + 2]));
        }
      }
      if (corners.isEmpty) continue;
      normals.addAll(f.normal);
      seeds.add(f.seed);
      kinds.add(f.kind.index);
      verts.addAll(local);
      vertStart.add(verts.length);
      tris.addAll(corners);
      triStart.add(tris.length);
    }
    return DiamondMesh(
      positions: Float32List.fromList(positions),
      normals: Float32List.fromList(normals),
      seeds: Float32List.fromList(seeds),
      kinds: Uint8List.fromList(kinds),
      vertStart: Uint32List.fromList(vertStart),
      verts: Uint16List.fromList(verts),
      triStart: Uint32List.fromList(triStart),
      tris: Uint16List.fromList(tris),
    );
  }
}

typedef _V3 = List<double>;

/// One planar facet in normalised model space: its convex [outline],
/// counter-clockwise seen from outside, or, when the facet is not convex
/// (a heart's cleft) or not one piece, its original triangle [corners].
class _Facet {
  _Facet.convex(
    List<_V3> this.outline,
    this.area,
    this.normal,
    this.kind,
    this.seed,
  ) : corners = null;

  _Facet.triangles(
    List<_V3> this.corners,
    this.area,
    this.normal,
    this.kind,
    this.seed,
  ) : outline = null;

  final List<_V3>? outline;
  final List<_V3>? corners;
  final double area;
  final _V3 normal;
  final GemFacetKind kind;
  final double seed;

  List<_V3> simplified(double tolerance) {
    final ring = [...outline!];
    while (ring.length > 3) {
      var best = double.infinity;
      var at = -1;
      for (var i = 0; i < ring.length; i++) {
        final a = _triArea(
          ring[(i - 1 + ring.length) % ring.length],
          ring[i],
          ring[(i + 1) % ring.length],
        );
        if (a < best) {
          best = a;
          at = i;
        }
      }
      if (best > tolerance * area) break;
      ring.removeAt(at);
    }
    return ring;
  }

  static List<_Facet> read(Uint8List bytes) {
    final primitives = _Glb(bytes).primitives();
    if (primitives.every((p) => p.isEmpty)) {
      throw const FormatException('GLB has no triangles');
    }

    var lo = [double.infinity, double.infinity, double.infinity];
    var hi = [-double.infinity, -double.infinity, -double.infinity];
    for (final tris in primitives) {
      for (var i = 0; i < tris.length; i += 3) {
        for (var c = 0; c < 3; c++) {
          lo[c] = math.min(lo[c], tris[i + c]);
          hi[c] = math.max(hi[c], tris[i + c]);
        }
      }
    }
    final size = math.max(
      hi[0] - lo[0],
      math.max(hi[1] - lo[1], hi[2] - lo[2]),
    );

    // Exporters usually emit one primitive per facet, as a slightly warped
    // polygon. A primitive whose triangles all face within ~11° of each
    // other is one facet; otherwise its triangles are grouped by plane
    // (normals within ~5°, offsets within a small fraction of the size).
    final groups = <_Group>[];
    for (final tris in primitives) {
      final kept = <({_V3 a, _V3 b, _V3 c, _V3 n, _V3 u})>[];
      var sum = <double>[0, 0, 0];
      for (var t = 0; t < tris.length; t += 9) {
        final a = [tris[t], tris[t + 1], tris[t + 2]];
        final b = [tris[t + 3], tris[t + 4], tris[t + 5]];
        final c = [tris[t + 6], tris[t + 7], tris[t + 8]];
        final n = _cross(_sub(b, a), _sub(c, a));
        final len = _len(n);
        // Fan-triangulated facets leave zero-area slivers along collinear
        // edges; their normals are noise. Height over the longest edge
        // tells them apart from thin but genuine fan triangles.
        final edge = math.max(
          _dot(_sub(b, a), _sub(b, a)),
          math.max(_dot(_sub(c, b), _sub(c, b)), _dot(_sub(a, c), _sub(a, c))),
        );
        if (len < 2e-4 * size * math.sqrt(edge) || len < 1e-12 * size * size) {
          continue;
        }
        kept.add((a: a, b: b, c: c, n: n, u: _scale(n, 1 / len)));
        sum = _add(sum, n);
      }
      if (kept.isEmpty) continue;
      final mean = _scale(sum, 1 / math.max(1e-30, _len(sum)));
      final flat = kept.every((t) => _dot(t.u, mean) > 0.98);
      final local = <_Group>[];
      for (final t in kept) {
        final d = _dot(t.u, t.a);
        _Group? home;
        for (final g in local) {
          if (flat ||
              (_dot(g.unit, t.u) > 0.996 &&
                  (g.offset - d).abs() < 4e-3 * size)) {
            home = g;
            break;
          }
        }
        if (home == null) local.add(home = _Group(t.u, d));
        home
          ..weighted = _add(home.weighted, t.n)
          ..points.addAll([t.a, t.b, t.c]);
      }
      groups.addAll(local);
    }

    // Table up. A cut stone is thinnest along its table axis (depth is
    // less than the girdle's width), so that axis is the facet direction
    // with the smallest extent; the table is the larger of the facets on
    // that axis (the culet, if faceted, is tiny).
    final all = [for (final g in groups) ...g.points];
    double extent(_V3 d) {
      var lo = double.infinity, hi = -double.infinity;
      for (final p in all) {
        final t = _dot(p, d);
        lo = math.min(lo, t);
        hi = math.max(hi, t);
      }
      return hi - lo;
    }

    final maxArea = groups.map((g) => _len(g.weighted)).reduce(math.max);
    _Group? thinnest;
    var thinExtent = double.infinity;
    for (final g in groups) {
      // Slivers' normals are not worth trusting as an axis.
      if (_len(g.weighted) < 0.02 * maxArea) continue;
      final e = extent(g.unit);
      if (e < thinExtent - 1e-4 * size) {
        thinExtent = e;
        thinnest = g;
      }
    }
    final axis = thinnest!.unit;
    final table = groups
        .where((g) => _dot(g.unit, axis).abs() > 0.998)
        .reduce((x, y) => _len(x.weighted) >= _len(y.weighted) ? x : y);
    final rotate = _rotationTo(table.unit, const [0, 1, 0]);

    // Centre on the bounding box; girdle (x–z) half extent becomes 1.
    lo = [double.infinity, double.infinity, double.infinity];
    hi = [-double.infinity, -double.infinity, -double.infinity];
    for (final g in groups) {
      for (var i = 0; i < g.points.length; i++) {
        final p = g.points[i] = rotate(g.points[i]);
        for (var c = 0; c < 3; c++) {
          lo[c] = math.min(lo[c], p[c]);
          hi[c] = math.max(hi[c], p[c]);
        }
      }
    }
    final centre = [for (var c = 0; c < 3; c++) (lo[c] + hi[c]) / 2];
    final k = 2 / math.max(hi[0] - lo[0], hi[2] - lo[2]);
    for (final g in groups) {
      g.weighted = rotate(g.weighted);
    }

    // The girdle is exported as hundreds of curved micro-strips, about a
    // pixel tall on screen. It is rebuilt below as one band of chord quads.
    bool isGirdle(_Group g) => (g.weighted[1] / _len(g.weighted)).abs() < 0.2;
    final girdle = [
      for (final g in groups.where(isGirdle))
        for (final p in g.points) _scale(_sub(p, centre), k),
    ];
    groups.removeWhere(isGirdle);

    final rng = math.Random(97);
    final facets = <_Facet>[];
    for (final g in groups) {
      final points = [for (final p in g.points) _scale(_sub(p, centre), k)];
      final n = _scale(g.weighted, 1 / _len(g.weighted));
      // Area the triangles cover, projected on the facet plane.
      final covered = _len(g.weighted) / 2 * k * k;
      final kind = n[1] > 0.985
          ? GemFacetKind.table
          : n[1].abs() < 0.2
          ? GemFacetKind.girdle
          : n[1] > 0
          ? GemFacetKind.crown
          : GemFacetKind.pavilion;
      final seed = rng.nextDouble();
      final ring = _hull(points, n);
      // The outline stands in for the triangles only if it covers the same
      // area: then the facet is convex and in one piece.
      if (ring.length >= 3 && _ringArea(ring) <= covered * 1.02) {
        facets.add(_Facet.convex(ring, covered, n, kind, seed));
      } else {
        facets.add(_Facet.triangles(points, covered, n, kind, seed));
      }
    }
    return facets..addAll(_band(girdle, rng));
  }

  /// Girdle band through [points]: around the outline in up to 64 azimuth
  /// steps, the band's top and bottom edge at the outermost points of each
  /// step, joined by flat quads. Works for any outline that is star-shaped
  /// about the centre, which every cut is (a heart's cleft included).
  static List<_Facet> _band(List<_V3> points, math.Random rng) {
    if (points.isEmpty) return const [];
    const steps = 64;
    final bins = List<List<_V3>>.generate(steps, (_) => []);
    for (final p in points) {
      final a = math.atan2(p[2], p[0]);
      bins[((a + math.pi) / (2 * math.pi) * steps).floor() % steps].add(p);
    }
    final edges = <({_V3 top, _V3 bottom})>[];
    for (final bin in bins) {
      if (bin.isEmpty) continue;
      var reach = 0.0;
      for (final p in bin) {
        reach = math.max(reach, p[0] * p[0] + p[2] * p[2]);
      }
      final outer = [
        for (final p in bin)
          if (p[0] * p[0] + p[2] * p[2] >= reach * 0.96) p,
      ];
      edges.add((
        top: outer.reduce((a, b) => a[1] >= b[1] ? a : b),
        bottom: outer.reduce((a, b) => a[1] <= b[1] ? a : b),
      ));
    }
    final facets = <_Facet>[];
    for (var i = 0; i < edges.length; i++) {
      final e0 = edges[i], e1 = edges[(i + 1) % edges.length];
      var ring = [e0.top, e0.bottom, e1.bottom, e1.top];
      var n = _cross(_sub(ring[1], ring[0]), _sub(ring[2], ring[0]));
      n = _add(n, _cross(_sub(ring[2], ring[0]), _sub(ring[3], ring[0])));
      final area = _len(n) / 2;
      if (area < 1e-9) continue;
      // Face outward.
      final mid = _scale(
        _add(_add(ring[0], ring[1]), _add(ring[2], ring[3])),
        0.25,
      );
      if (n[0] * mid[0] + n[2] * mid[2] < 0) {
        ring = ring.reversed.toList();
        n = _scale(n, -1);
      }
      facets.add(
        _Facet.convex(
          ring,
          area,
          _scale(n, 1 / _len(n)),
          GemFacetKind.girdle,
          rng.nextDouble(),
        ),
      );
    }
    return facets;
  }

  static double _ringArea(List<_V3> ring) {
    var area = 0.0;
    for (var i = 1; i < ring.length - 1; i++) {
      area += _triArea(ring[0], ring[i], ring[i + 1]);
    }
    return area;
  }

  /// Convex outline of coplanar [points] around normal [n], counter-
  /// clockwise seen from the side [n] points to (monotone chain).
  static List<_V3> _hull(List<_V3> points, _V3 n) {
    final ref = n[0].abs() < 0.9
        ? const [1.0, 0.0, 0.0]
        : const [0.0, 1.0, 0.0];
    final ax = _cross(n, ref);
    final a = _scale(ax, 1 / _len(ax));
    final b = _cross(n, a);
    final uv = [for (final p in points) (u: _dot(p, a), v: _dot(p, b), p: p)]
      ..sort((p, q) => p.u != q.u ? p.u.compareTo(q.u) : p.v.compareTo(q.v));
    double turn(
      ({double u, double v, _V3 p}) o,
      ({double u, double v, _V3 p}) p,
      ({double u, double v, _V3 p}) q,
    ) => (p.u - o.u) * (q.v - o.v) - (p.v - o.v) * (q.u - o.u);
    const eps = 1e-9;
    final lower = <({double u, double v, _V3 p})>[];
    for (final p in uv) {
      while (lower.length >= 2 &&
          turn(lower[lower.length - 2], lower.last, p) <= eps) {
        lower.removeLast();
      }
      lower.add(p);
    }
    final upper = <({double u, double v, _V3 p})>[];
    for (final p in uv.reversed) {
      while (upper.length >= 2 &&
          turn(upper[upper.length - 2], upper.last, p) <= eps) {
        upper.removeLast();
      }
      upper.add(p);
    }
    return [
      for (final p in lower.sublist(0, lower.length - 1)) p.p,
      for (final p in upper.sublist(0, upper.length - 1)) p.p,
    ];
  }
}

class _Group {
  _Group(this.unit, this.offset);

  final _V3 unit;
  final double offset;
  _V3 weighted = const [0, 0, 0];
  final List<_V3> points = [];
}

/// Minimal reader for the triangle geometry of a binary glTF 2.0 file.
class _Glb {
  _Glb(Uint8List bytes) : _data = ByteData.sublistView(bytes) {
    if (_data.lengthInBytes < 20 ||
        _data.getUint32(0, Endian.little) != 0x46546C67 ||
        _data.getUint32(4, Endian.little) != 2) {
      throw const FormatException('Not a glTF 2.0 binary');
    }
    var at = 12;
    while (at + 8 <= _data.lengthInBytes) {
      final length = _data.getUint32(at, Endian.little);
      final type = _data.getUint32(at + 4, Endian.little);
      final body = Uint8List.sublistView(bytes, at + 8, at + 8 + length);
      if (type == 0x4E4F534A) {
        _json = jsonDecode(utf8.decode(body)) as Map<String, dynamic>;
      } else if (type == 0x004E4942) {
        _bin = ByteData.sublistView(body);
      }
      at += 8 + length;
    }
    if (_json == null || _bin == null) {
      throw const FormatException('GLB is missing its JSON or BIN chunk');
    }
  }

  final ByteData _data;
  Map<String, dynamic>? _json;
  ByteData? _bin;

  /// Triangle corners of every triangle-list primitive, 9 floats per
  /// triangle, one list per primitive.
  List<List<double>> primitives() {
    final all = <List<double>>[];
    final meshes = (_json!['meshes'] as List?) ?? const [];
    for (final mesh in meshes) {
      for (final prim in (mesh as Map)['primitives'] as List) {
        final p = prim as Map;
        if ((p['mode'] as int? ?? 4) != 4) continue;
        final position = (p['attributes'] as Map)['POSITION'] as int?;
        if (position == null) continue;
        final pos = _read(position);
        final indices = p['indices'] as int?;
        final idx = indices == null
            ? List<double>.generate(pos.length ~/ 3, (i) => i.toDouble())
            : _read(indices);
        final out = <double>[];
        all.add(out);
        for (final i in idx) {
          final v = i.toInt() * 3;
          out
            ..add(pos[v])
            ..add(pos[v + 1])
            ..add(pos[v + 2]);
        }
      }
    }
    return all;
  }

  List<double> _read(int index) {
    final acc = (_json!['accessors'] as List)[index] as Map;
    final view =
        (_json!['bufferViews'] as List)[acc['bufferView'] as int] as Map;
    final width = const {
      'SCALAR': 1,
      'VEC2': 2,
      'VEC3': 3,
      'VEC4': 4,
    }[acc['type']]!;
    final type = acc['componentType'] as int;
    final bytes = const {5121: 1, 5123: 2, 5125: 4, 5126: 4}[type];
    if (bytes == null) throw FormatException('Unsupported component $type');
    final stride = view['byteStride'] as int? ?? width * bytes;
    final start =
        (view['byteOffset'] as int? ?? 0) + (acc['byteOffset'] as int? ?? 0);
    final count = acc['count'] as int;
    final bin = _bin!;
    return [
      for (var i = 0; i < count; i++)
        for (var c = 0; c < width; c++)
          switch (type) {
            5126 => bin.getFloat32(start + i * stride + c * 4, Endian.little),
            5125 =>
              bin
                  .getUint32(start + i * stride + c * 4, Endian.little)
                  .toDouble(),
            5123 =>
              bin
                  .getUint16(start + i * stride + c * 2, Endian.little)
                  .toDouble(),
            _ => bin.getUint8(start + i * stride + c).toDouble(),
          },
    ];
  }
}

_V3 _sub(_V3 a, _V3 b) => [a[0] - b[0], a[1] - b[1], a[2] - b[2]];
_V3 _add(_V3 a, _V3 b) => [a[0] + b[0], a[1] + b[1], a[2] + b[2]];
_V3 _scale(_V3 a, double k) => [a[0] * k, a[1] * k, a[2] * k];
double _dot(_V3 a, _V3 b) => a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
double _len(_V3 a) => math.sqrt(_dot(a, a));
_V3 _cross(_V3 a, _V3 b) => [
  a[1] * b[2] - a[2] * b[1],
  a[2] * b[0] - a[0] * b[2],
  a[0] * b[1] - a[1] * b[0],
];
double _triArea(_V3 a, _V3 b, _V3 c) =>
    _len(_cross(_sub(b, a), _sub(c, a))) / 2;

/// Rotation taking unit [from] onto unit [to] (Rodrigues).
_V3 Function(_V3) _rotationTo(_V3 from, _V3 to) {
  final axis = _cross(from, to);
  final s = _len(axis);
  final c = _dot(from, to);
  if (s < 1e-9) {
    // Parallel: identity, or a half turn about x when opposite.
    return c > 0 ? (p) => p : (p) => [p[0], -p[1], -p[2]];
  }
  final k = _scale(axis, 1 / s);
  return (p) {
    final kxp = _cross(k, p);
    final kdp = _dot(k, p) * (1 - c);
    return [
      p[0] * c + kxp[0] * s + k[0] * kdp,
      p[1] * c + kxp[1] * s + k[1] * kdp,
      p[2] * c + kxp[2] * s + k[2] * kdp,
    ];
  };
}
