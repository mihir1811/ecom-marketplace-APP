import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'gem_mesh.dart';

/// Faceted stone imported from a binary glTF (.glb) model, in two levels of
/// detail for the software renderer.
///
/// The model's triangles are grouped into planar facets (a cut stone is
/// convex, so each plane holds exactly one facet) and every facet is
/// rebuilt as a fan over its convex outline. That drops the exporter's
/// tessellation (T-junctions, collinear girdle samples) without changing
/// the silhouette or the facet pattern. The result is normalised to the
/// procedural [GemMesh] model space: table up (+y), girdle within the unit
/// circle, centred on the stone's height.
class GemModel {
  const GemModel({required this.detail, required this.coarse});

  /// Procedural stand-in, used if a model cannot be loaded.
  factory GemModel.procedural(GemCut cut) {
    final mesh = GemMesh.of(cut);
    return GemModel(detail: mesh, coarse: mesh);
  }

  /// Every facet; for stones drawn large.
  final GemMesh detail;

  /// Sub-pixel facets and the girdle band dropped, outlines simplified
  /// harder; for small or defocused stones.
  final GemMesh coarse;

  static final Map<String, Future<GemModel>> _cache = {};

  /// Loads and converts the .glb [asset] once, off the UI isolate; later
  /// calls share it.
  static Future<GemModel> load(String asset) {
    return _cache.putIfAbsent(asset, () async {
      try {
        final data = await rootBundle.load(asset);
        return await compute(
          GemModel.parse,
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        );
      } catch (_) {
        _cache.remove(asset);
        rethrow;
      }
    });
  }

  /// Converts the bytes of a binary glTF 2.0 file.
  factory GemModel.parse(Uint8List bytes) {
    final facets = _Facet.read(bytes);
    return GemModel(
      detail: _mesh(facets, simplify: 0.005, minArea: 0),
      coarse: _mesh(facets, simplify: 0.02, minArea: 1.6e-3, girdle: false),
    );
  }

  /// Fans every facet outline into triangles. Outline corners that carve
  /// off less than [simplify] of the facet area are dropped, and facets
  /// smaller than [minArea] (model units²) are skipped, as is the girdle
  /// band unless [girdle].
  static GemMesh _mesh(
    List<_Facet> facets, {
    required double simplify,
    required double minArea,
    bool girdle = true,
  }) {
    final verts = <double>[];
    final kinds = <GemFacetKind>[];
    final seeds = <double>[];
    for (final f in facets) {
      if (f.area < minArea || (!girdle && f.kind == GemFacetKind.girdle)) {
        continue;
      }
      final ring = f.simplified(simplify);
      for (var i = 1; i < ring.length - 1; i++) {
        verts
          ..addAll(ring[0])
          ..addAll(ring[i])
          ..addAll(ring[i + 1]);
        kinds.add(f.kind);
        seeds.add(f.seed);
      }
    }
    return GemMesh.fromTriangles(
      Float32List.fromList(verts),
      kinds,
      Float32List.fromList(seeds),
    );
  }
}

typedef _V3 = List<double>;

/// One planar facet: its convex outline, counter-clockwise seen from
/// outside, in normalised model space.
class _Facet {
  _Facet(this.outline, this.area, this.kind, this.seed);

  final List<_V3> outline;
  final double area;
  final GemFacetKind kind;
  final double seed;

  List<_V3> simplified(double tolerance) {
    final ring = [...outline];
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

    // Group each primitive's triangles by plane: normals within ~5° and
    // plane offsets within a small fraction of the model size. Exporters
    // usually emit one primitive per facet; the tolerance absorbs their
    // slightly warped polygons.
    final groups = <_Group>[];
    for (final tris in primitives) {
      final local = <_Group>[];
      for (var t = 0; t < tris.length; t += 9) {
        final a = [tris[t], tris[t + 1], tris[t + 2]];
        final b = [tris[t + 3], tris[t + 4], tris[t + 5]];
        final c = [tris[t + 6], tris[t + 7], tris[t + 8]];
        final n = _cross(_sub(b, a), _sub(c, a));
        final len = _len(n);
        // Fan-triangulated facets leave zero-area slivers along collinear
        // edges; their normals are noise, and their corners lie on the
        // edges of real triangles anyway.
        final edge = math.max(
          _dot(_sub(b, a), _sub(b, a)),
          math.max(_dot(_sub(c, b), _sub(c, b)), _dot(_sub(a, c), _sub(a, c))),
        );
        if (len < 4e-3 * edge || len < 1e-12 * size * size) continue;
        final u = _scale(n, 1 / len);
        final d = _dot(u, a);
        _Group? home;
        for (final g in local) {
          if (_dot(g.unit, u) > 0.996 && (g.offset - d).abs() < 4e-3 * size) {
            home = g;
            break;
          }
        }
        if (home == null) local.add(home = _Group(u, d));
        home
          ..weighted = _add(home.weighted, n)
          ..points.addAll([a, b, c]);
      }
      groups.addAll(local);
    }

    // Table up: rotate the largest facet's normal onto +y.
    final table = groups.reduce(
      (x, y) => _len(x.weighted) >= _len(y.weighted) ? x : y,
    );
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

    // The girdle is a band of hundreds of tiny vertical facets, about a
    // pixel tall on screen. Runs of them spanning up to ~12° become one
    // chord facet; the sagitta of such a run is invisible.
    bool isGirdle(_Group g) => (g.weighted[1] / _len(g.weighted)).abs() < 0.2;
    final girdle = groups.where(isGirdle).toList()
      ..sort(
        (x, y) => math
            .atan2(x.weighted[2], x.weighted[0])
            .compareTo(math.atan2(y.weighted[2], y.weighted[0])),
      );
    final merged = <_Group>[];
    for (final g in girdle) {
      final run = merged.isEmpty ? null : merged.last;
      final u = _scale(g.weighted, 1 / _len(g.weighted));
      if (run != null && _dot(run.unit, u) > 0.978) {
        run
          ..weighted = _add(run.weighted, g.weighted)
          ..points.addAll(g.points);
      } else {
        merged.add(
          _Group(u, 0)
            ..weighted = g.weighted
            ..points.addAll(g.points),
        );
      }
    }
    groups
      ..removeWhere(isGirdle)
      ..addAll(merged);

    final rng = math.Random(97);
    final facets = <_Facet>[];
    for (final g in groups) {
      final points = [for (final p in g.points) _scale(_sub(p, centre), k)];
      final n = _scale(g.weighted, 1 / _len(g.weighted));
      final ring = _hull(points, n);
      if (ring.length < 3) continue;
      var area = 0.0;
      for (var i = 1; i < ring.length - 1; i++) {
        area += _triArea(ring[0], ring[i], ring[i + 1]);
      }
      final kind = n[1] > 0.985
          ? GemFacetKind.table
          : n[1].abs() < 0.2
          ? GemFacetKind.girdle
          : n[1] > 0
          ? GemFacetKind.crown
          : GemFacetKind.pavilion;
      facets.add(_Facet(ring, area, kind, rng.nextDouble()));
    }
    return facets;
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
