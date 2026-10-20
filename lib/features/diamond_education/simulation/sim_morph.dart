import 'dart:math' as math;
import 'dart:typed_data';

import 'sim_hull.dart';
import 'sim_mesh.dart';

/// One stone turning from one cut into another, as a jeweller would see
/// it on a wheel: never two stones blended, but a single solid whose
/// facets tilt, slide and give way until the new cut stands.
///
/// Every facet of either stone gets a slot (a facet of the other stone
/// with the nearest normal, every facet of both used at least once). At
/// time t a slot's normal swings between its two facets' normals, and
/// the slot's plane sits where both stones reach in that direction,
/// weighted by t: `(1 − t)·hA(n) + t·hB(n)`, h being how far a stone
/// reaches along n. The morphing stone is whatever those planes leave
/// standing, so at every t it is a true convex polyhedron of flat facets
/// that the ray tracer follows exactly, it always holds the blend of the
/// two stones, and it is exactly the first stone at t = 0 and the second
/// at t = 1. Facets are born and retire at zero size, so nothing ever
/// pops.
///
/// Only as many plane slots as the larger stone has per facet tier
/// (crown, pavilion, girdle), so the morph fits the shader's plane budget.
///
/// A heart is traced as its +x half with a mirror at x = 0, a star or a
/// lily as one wedge between mirrors ([SimMesh.fold]); a morph with one
/// works on that part of both stones the same way, which holds because
/// the shapes beside it share its symmetry.
class SimShapeMorph {
  SimShapeMorph._(
    this.a,
    this.b,
    this.fold,
    this._nA,
    this._nB,
    this._kindA,
    this._kindB,
    this._vA,
    this._vB,
  );

  /// Pairs [a] with [b]; costs a few milliseconds, so build it ahead.
  factory SimShapeMorph(SimMesh a, SimMesh b) {
    assert(
      a.fold == 0 || b.fold == 0 || a.fold == b.fold,
      'a morph folds both stones alike',
    );
    final fold = math.max(a.fold, b.fold);
    final sa = _Solid.of(a, fold), sb = _Solid.of(b, fold);
    final nA = <double>[], nB = <double>[];
    final kA = <int>[], kB = <int>[];
    for (var g = 0; g < 3; g++) {
      final ia = [
        for (var i = 0; i < sa.kinds.length; i++)
          if (_tier(sa.kinds[i]) == g) i,
      ];
      final ib = [
        for (var i = 0; i < sb.kinds.length; i++)
          if (_tier(sb.kinds[i]) == g) i,
      ];
      for (final (i, j) in _cover(ia, ib, sa.normals, sb.normals)) {
        // A facet with no partner on the other stone keeps its normal and
        // simply settles onto that stone's surface.
        final na = i ?? j!, nb = j ?? i!;
        final fa = i == null ? sb : sa, fb = j == null ? sa : sb;
        for (var k = 0; k < 3; k++) {
          nA.add(fa.normals[na * 3 + k]);
        }
        for (var k = 0; k < 3; k++) {
          nB.add(fb.normals[nb * 3 + k]);
        }
        kA.add(fa.kinds[na]);
        kB.add(fb.kinds[nb]);
      }
    }
    return SimShapeMorph._(
      a,
      b,
      fold,
      Float64List.fromList(nA),
      Float64List.fromList(nB),
      Uint8List.fromList(kA),
      Uint8List.fromList(kB),
      sa.vertices,
      sb.vertices,
    );
  }

  final SimMesh a, b;

  /// How both stones are traced through the morph ([SimMesh.fold]).
  final int fold;

  bool get mirrorX => fold == 1;
  final Float64List _nA, _nB;
  final Uint8List _kindA, _kindB;

  /// Corners of either solid (its traced part when folded), xyz: where
  /// each stone reaches in any direction.
  final Float64List _vA, _vB;

  int get slots => _kindA.length;

  /// The stone at [t], 0..1. The ends are the stones themselves.
  SimMesh at(double t) {
    if (t <= 1e-6) return a;
    if (t >= 1 - 1e-6) return b;
    final n = slots;
    final mirrors = SimMesh.mirrorPlanes(fold);
    final planes = Float64List(n * 4 + mirrors.length);
    for (var k = 0; k < n; k++) {
      var x = _nA[k * 3] * (1 - t) + _nB[k * 3] * t;
      var y = _nA[k * 3 + 1] * (1 - t) + _nB[k * 3 + 1] * t;
      var z = _nA[k * 3 + 2] * (1 - t) + _nB[k * 3 + 2] * t;
      final l = math.sqrt(x * x + y * y + z * z);
      if (l < 1e-6) {
        final src = t < 0.5 ? _nA : _nB;
        x = src[k * 3];
        y = src[k * 3 + 1];
        z = src[k * 3 + 2];
      } else {
        x /= l;
        y /= l;
        z /= l;
      }
      planes
        ..[k * 4] = x
        ..[k * 4 + 1] = y
        ..[k * 4 + 2] = z
        ..[k * 4 + 3] =
            (1 - t) * _reach(_vA, x, y, z) + t * _reach(_vB, x, y, z);
    }
    planes.setRange(n * 4, planes.length, mirrors);
    final hull = SimHull.cut(planes, planes.length ~/ 4);
    final kinds = t < 0.5 ? _kindA : _kindB;
    final facets = <(List<int>, SimFacetKind)>[
      for (final f in hull.faces)
        if (f.plane >= 0 && f.plane < n)
          (f.verts, SimFacetKind.values[kinds[f.plane]]),
    ];
    double lerp(double p, double q) => p + (q - p) * t;
    return SimMesh.fromFacets(
      t < 0.5 ? a.shape : b.shape,
      hull.vertices,
      facets,
      fold: fold,
      crownHeight: lerp(a.crownHeight, b.crownHeight),
      pavilionDepth: lerp(a.pavilionDepth, b.pavilionDepth),
      girdleThickness: lerp(a.girdleThickness, b.girdleThickness),
    );
  }

  static double _reach(Float64List v, double x, double y, double z) {
    var best = -double.infinity;
    for (var i = 0; i < v.length; i += 3) {
      final d = v[i] * x + v[i + 1] * y + v[i + 2] * z;
      if (d > best) best = d;
    }
    return best;
  }

  /// Facet tier: crown and table, pavilion and culet, girdle. Facets only
  /// pair within a tier, so a crown facet never swings down the pavilion.
  static int _tier(int kind) {
    final k = SimFacetKind.values[kind];
    return switch (k) {
      SimFacetKind.table || SimFacetKind.crown => 0,
      SimFacetKind.pavilion || SimFacetKind.culet => 1,
      SimFacetKind.girdle => 2,
    };
  }

  /// Pairs facets [ia] of one stone with [ib] of the other so that every
  /// facet is in at least one pair and the normals turn as little as
  /// possible in all: each facet of the smaller set gets its own partner
  /// (an optimal assignment), the rest of the larger set their nearest.
  /// A null side means the tier is missing from that stone.
  static List<(int?, int?)> _cover(
    List<int> ia,
    List<int> ib,
    Float64List na,
    Float64List nb,
  ) {
    if (ia.isEmpty) return [for (final j in ib) (null, j)];
    if (ib.isEmpty) return [for (final i in ia) (i, null)];
    final swap = ia.length < ib.length;
    final small = swap ? ia : ib, large = swap ? ib : ia;
    final ns = swap ? na : nb, nl = swap ? nb : na;
    double cost(int s, int l) =>
        1 -
        (ns[small[s] * 3] * nl[large[l] * 3] +
            ns[small[s] * 3 + 1] * nl[large[l] * 3 + 1] +
            ns[small[s] * 3 + 2] * nl[large[l] * 3 + 2]);
    final match = _assign(small.length, large.length, cost);
    final partner = List<int>.filled(large.length, -1);
    for (var s = 0; s < small.length; s++) {
      partner[match[s]] = s;
    }
    final out = <(int?, int?)>[];
    for (var l = 0; l < large.length; l++) {
      var s = partner[l];
      if (s < 0) {
        var best = double.infinity;
        for (var q = 0; q < small.length; q++) {
          final c = cost(q, l);
          if (c < best) {
            best = c;
            s = q;
          }
        }
      }
      out.add(swap ? (small[s], large[l]) : (large[l], small[s]));
    }
    return out;
  }

  /// Minimum cost assignment of [n] rows to distinct columns of [m]
  /// (n <= m), Hungarian method; returns each row's column.
  static List<int> _assign(int n, int m, double Function(int, int) cost) {
    final u = Float64List(n + 1), v = Float64List(m + 1);
    final p = Int32List(m + 1), way = Int32List(m + 1);
    final minv = Float64List(m + 1);
    final used = List<bool>.filled(m + 1, false);
    for (var i = 1; i <= n; i++) {
      p[0] = i;
      var j0 = 0;
      minv.fillRange(0, m + 1, double.infinity);
      used.fillRange(0, m + 1, false);
      do {
        used[j0] = true;
        final i0 = p[j0];
        var delta = double.infinity;
        var j1 = 0;
        for (var j = 1; j <= m; j++) {
          if (used[j]) continue;
          final cur = cost(i0 - 1, j - 1) - u[i0] - v[j];
          if (cur < minv[j]) {
            minv[j] = cur;
            way[j] = j0;
          }
          if (minv[j] < delta) {
            delta = minv[j];
            j1 = j;
          }
        }
        for (var j = 0; j <= m; j++) {
          if (used[j]) {
            u[p[j]] += delta;
            v[j] -= delta;
          } else {
            minv[j] -= delta;
          }
        }
        j0 = j1;
      } while (p[j0] != 0);
      do {
        final j1 = way[j0];
        p[j0] = p[j1];
        j0 = j1;
      } while (j0 != 0);
    }
    final out = List<int>.filled(n, 0);
    for (var j = 1; j <= m; j++) {
      if (p[j] > 0) out[p[j] - 1] = j - 1;
    }
    return out;
  }
}

/// A stone as the solid its traced planes enclose (only its traced part,
/// between mirrors, when folded): its facet normals and kinds, and its
/// corners.
class _Solid {
  _Solid(this.normals, this.kinds, this.vertices);

  final Float64List normals;
  final Uint8List kinds;
  final Float64List vertices;

  static _Solid of(SimMesh mesh, int fold) {
    final n = mesh.tracedFacets;
    final mirrors = SimMesh.mirrorPlanes(fold);
    final planes = Float64List(n * 4 + mirrors.length)
      ..setRange(0, n * 4, mesh.planes)
      ..setRange(n * 4, n * 4 + mirrors.length, mirrors);
    final hull = SimHull.cut(planes, planes.length ~/ 4);
    // Only facets that bound the solid: a stone's own planes, or for a
    // folded part, those reaching into it.
    final normals = <double>[];
    final kinds = <int>[];
    for (final f in hull.faces) {
      if (f.plane < 0 || f.plane >= n) continue;
      normals.addAll(mesh.planes.sublist(f.plane * 4, f.plane * 4 + 3));
      kinds.add(mesh.kinds[f.plane]);
    }
    return _Solid(
      Float64List.fromList(normals),
      Uint8List.fromList(kinds),
      Float64List.fromList(hull.vertices),
    );
  }
}
