import 'dart:math' as math;

/// Minimal immutable 3-vector used by the hero diamond renderer.
class Vec3 {
  const Vec3(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;

  Vec3 operator +(Vec3 o) => Vec3(x + o.x, y + o.y, z + o.z);
  Vec3 operator -(Vec3 o) => Vec3(x - o.x, y - o.y, z - o.z);
  Vec3 operator *(double s) => Vec3(x * s, y * s, z * s);

  double dot(Vec3 o) => x * o.x + y * o.y + z * o.z;

  double get length => math.sqrt(dot(this));

  Vec3 normalized() {
    final l = length;
    return l == 0 ? this : this * (1 / l);
  }
}

/// Region of the stone a facet belongs to; drives its optical response.
enum FacetKind { table, crown, girdle, pavilion }

/// One planar-ish facet of the stone, as a polygon of vertex indices.
class DiamondFacet {
  const DiamondFacet({
    required this.indices,
    required this.normal,
    required this.kind,
    required this.seed,
  });

  /// Polygon winding, counter-clockwise when seen from outside the stone.
  final List<int> indices;

  /// Outward unit normal in model space.
  final Vec3 normal;
  final FacetKind kind;

  /// Stable 0..1 value that varies sparkle per facet.
  final double seed;
}

/// Round brilliant cut (57 facets) with ideal-ish proportions.
///
/// Model space: girdle radius 1, y up, centred on the stone's bounding box.
class DiamondMesh {
  DiamondMesh._(this.vertices, this.facets)
    : triangleCount = facets.fold(0, (n, f) => n + f.indices.length - 2);

  final List<Vec3> vertices;
  final List<DiamondFacet> facets;
  final int triangleCount;

  static final DiamondMesh roundBrilliant = _buildRoundBrilliant();

  static DiamondMesh _buildRoundBrilliant() {
    const tableY = 0.30;
    const starY = 0.155;
    const girdleTop = 0.0;
    const girdleBottom = -0.05;
    const lowerY = -0.70;
    const culetY = -0.91;
    const centreY = (tableY + culetY) / 2;
    const step = math.pi / 4;
    const half = math.pi / 8;

    final v = <Vec3>[];
    int add(double r, double a, double y) {
      v.add(Vec3(r * math.cos(a), y - centreY, r * math.sin(a)));
      return v.length - 1;
    }

    final table = [for (var i = 0; i < 8; i++) add(0.56, i * step, tableY)];
    final star = [
      for (var i = 0; i < 8; i++) add(0.79, i * step + half, starY),
    ];
    final gTop = [for (var j = 0; j < 16; j++) add(1, j * half, girdleTop)];
    final gBot = [for (var j = 0; j < 16; j++) add(1, j * half, girdleBottom)];
    final lower = [
      for (var i = 0; i < 8; i++) add(0.24, i * step + half, lowerY),
    ];
    v.add(const Vec3(0, culetY - centreY, 0));
    final culet = v.length - 1;

    final raw = <(List<int>, FacetKind)>[];
    raw.add((table, FacetKind.table));
    for (var i = 0; i < 8; i++) {
      final n = (i + 1) % 8;
      final p = (i + 7) % 8;
      raw
        ..add(([table[i], table[n], star[i]], FacetKind.crown))
        ..add(([table[i], star[i], gTop[2 * i], star[p]], FacetKind.crown))
        ..add(([star[i], gTop[2 * i], gTop[2 * i + 1]], FacetKind.crown))
        ..add((
          [star[i], gTop[2 * i + 1], gTop[(2 * i + 2) % 16]],
          FacetKind.crown,
        ))
        ..add(([gBot[2 * i], lower[i], culet, lower[p]], FacetKind.pavilion))
        ..add(([gBot[2 * i], gBot[2 * i + 1], lower[i]], FacetKind.pavilion))
        ..add((
          [gBot[2 * i + 1], gBot[(2 * i + 2) % 16], lower[i]],
          FacetKind.pavilion,
        ));
    }
    for (var j = 0; j < 16; j++) {
      final n = (j + 1) % 16;
      raw.add(([gTop[j], gTop[n], gBot[n], gBot[j]], FacetKind.girdle));
    }

    final rng = math.Random(57);
    final facets = <DiamondFacet>[];
    for (final (indices, kind) in raw) {
      var normal = _newellNormal(indices, v);
      var centroid = const Vec3(0, 0, 0);
      for (final i in indices) {
        centroid = centroid + v[i];
      }
      centroid = centroid * (1 / indices.length);
      var ordered = indices;
      if (normal.dot(centroid) < 0) {
        normal = normal * -1;
        ordered = indices.reversed.toList(growable: false);
      }
      facets.add(
        DiamondFacet(
          indices: ordered,
          normal: normal,
          kind: kind,
          seed: rng.nextDouble(),
        ),
      );
    }
    return DiamondMesh._(List.unmodifiable(v), List.unmodifiable(facets));
  }

  static Vec3 _newellNormal(List<int> indices, List<Vec3> v) {
    var x = 0.0, y = 0.0, z = 0.0;
    for (var k = 0; k < indices.length; k++) {
      final a = v[indices[k]];
      final b = v[indices[(k + 1) % indices.length]];
      x += (a.y - b.y) * (a.z + b.z);
      y += (a.z - b.z) * (a.x + b.x);
      z += (a.x - b.x) * (a.y + b.y);
    }
    return Vec3(x, y, z).normalized();
  }
}
