import 'dart:math' as math;
import 'dart:typed_data';

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
/// A heart is traced as its +x half with a mirror at x = 0
/// ([SimMesh.mirrorX]); a morph with one works on halves the same way,
/// which holds because the shapes beside it are themselves symmetric
/// about x = 0.
class SimShapeMorph {
  SimShapeMorph._(
    this.a,
    this.b,
    this._nA,
    this._nB,
    this._kindA,
    this._kindB,
    this._vA,
    this._vB,
  ) : mirrorX = a.mirrorX || b.mirrorX;

  /// Pairs [a] with [b]; costs a few milliseconds, so build it ahead.
  factory SimShapeMorph(SimMesh a, SimMesh b) {
    final mirror = a.mirrorX || b.mirrorX;
    final sa = _Solid.of(a, mirror), sb = _Solid.of(b, mirror);
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
      Float64List.fromList(nA),
      Float64List.fromList(nB),
      Uint8List.fromList(kA),
      Uint8List.fromList(kB),
      sa.vertices,
      sb.vertices,
    );
  }

  final SimMesh a, b;
  final bool mirrorX;
  final Float64List _nA, _nB;
  final Uint8List _kindA, _kindB;

  /// Corners of either solid (traced halves when mirrored), xyz: where
  /// each stone reaches in any direction.
  final Float64List _vA, _vB;

  int get slots => _kindA.length;

  /// The stone at [t], 0..1. The ends are the stones themselves.
  SimMesh at(double t) {
    if (t <= 1e-6) return a;
    if (t >= 1 - 1e-6) return b;
    final n = slots;
    final planes = Float64List((n + 1) * 4);
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
    var count = n;
    if (mirrorX) {
      // The mirror: the traced half is x >= 0.
      planes
        ..[n * 4] = -1
        ..[n * 4 + 3] = 0;
      count++;
    }
    final hull = _Hull.cut(planes, count);
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
      mirrorX: mirrorX,
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

/// A stone as the solid its traced planes enclose (the +x half with a
/// mirror): its facet normals and kinds, and its corners.
class _Solid {
  _Solid(this.normals, this.kinds, this.vertices);

  final Float64List normals;
  final Uint8List kinds;
  final Float64List vertices;

  static _Solid of(SimMesh mesh, bool half) {
    final n = mesh.tracedFacets;
    final planes = Float64List((n + 1) * 4)..setRange(0, n * 4, mesh.planes);
    if (half) {
      planes[n * 4] = -1;
    }
    final hull = _Hull.cut(planes, half ? n + 1 : n);
    // Only facets that bound the solid: a stone's own planes, or for a
    // half, those reaching into it.
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

class _Face {
  _Face(this.plane, this.verts);

  /// Index of the plane it lies in; negative for the starting box.
  final int plane;
  final List<int> verts;
}

/// The convex solid cut from a large box by planes `n · p <= d`.
class _Hull {
  _Hull(this.vertices, this.faces);

  /// Corners in use, xyz.
  final List<double> vertices;

  /// One polygon per plane that bounds the solid, counter-clockwise seen
  /// from outside.
  final List<_Face> faces;

  static const _eps = 1e-9;

  /// Cuts with the first [count] planes of [planes] (nx ny nz d each).
  static _Hull cut(Float64List planes, int count) {
    const r = 8.0;
    var v = Float64List(1536);
    var nv = 8;
    for (var i = 0; i < 8; i++) {
      v
        ..[i * 3] = i & 1 == 0 ? -r : r
        ..[i * 3 + 1] = i & 2 == 0 ? -r : r
        ..[i * 3 + 2] = i & 4 == 0 ? -r : r;
    }
    var faces = <_Face>[
      _Face(-1, [0, 4, 6, 2]), // −x
      _Face(-2, [1, 3, 7, 5]), // +x
      _Face(-3, [0, 1, 5, 4]), // −y
      _Face(-4, [2, 6, 7, 3]), // +y
      _Face(-5, [0, 2, 3, 1]), // −z
      _Face(-6, [4, 5, 7, 6]), // +z
    ];
    var side = Float64List(512);
    var seen = Int32List(512)..fillRange(0, 512, -1);
    final cuts = <int, int>{};
    final cap = <int>[];
    final inCap = <int>{};
    for (var p = 0; p < count; p++) {
      final nx = planes[p * 4], ny = planes[p * 4 + 1];
      final nz = planes[p * 4 + 2], d = planes[p * 4 + 3];
      if (side.length < nv) {
        side = Float64List(nv * 2);
        seen = Int32List(nv * 2)..fillRange(0, nv * 2, -1);
      }
      // Signed distance of every corner still in use, once each.
      var outside = false;
      for (var fi = 0; fi < faces.length; fi++) {
        final vs = faces[fi].verts;
        for (var k = 0; k < vs.length; k++) {
          final i = vs[k];
          if (seen[i] == p) continue;
          seen[i] = p;
          final s = nx * v[i * 3] + ny * v[i * 3 + 1] + nz * v[i * 3 + 2] - d;
          side[i] = s;
          if (s > _eps) outside = true;
        }
      }
      if (!outside) continue;
      cuts.clear();
      cap.clear();
      inCap.clear();
      final next = <_Face>[];
      for (var fi = 0; fi < faces.length; fi++) {
        final f = faces[fi];
        final vs = f.verts;
        // Untouched by this plane: kept as it is, its corners lying on
        // the plane joining the new facet.
        var cut = false;
        for (var k = 0; k < vs.length; k++) {
          if (side[vs[k]] > _eps) {
            cut = true;
            break;
          }
        }
        if (!cut) {
          for (var k = 0; k < vs.length; k++) {
            final i = vs[k];
            if (side[i] >= -_eps && inCap.add(i)) cap.add(i);
          }
          next.add(f);
          continue;
        }
        final out = <int>[];
        for (var k = 0; k < vs.length; k++) {
          final i = vs[k], j = vs[(k + 1) % vs.length];
          final si = side[i], sj = side[j];
          if (si <= _eps) {
            out.add(i);
            if (si >= -_eps && inCap.add(i)) cap.add(i);
          }
          if ((si < -_eps && sj > _eps) || (si > _eps && sj < -_eps)) {
            final key = i < j ? i * 65536 + j : j * 65536 + i;
            var c = cuts[key];
            if (c == null) {
              if (v.length < (nv + 1) * 3) {
                v = Float64List(v.length * 2)..setRange(0, nv * 3, v);
              }
              final w = si / (si - sj);
              v
                ..[nv * 3] = v[i * 3] + (v[j * 3] - v[i * 3]) * w
                ..[nv * 3 + 1] =
                    v[i * 3 + 1] + (v[j * 3 + 1] - v[i * 3 + 1]) * w
                ..[nv * 3 + 2] =
                    v[i * 3 + 2] + (v[j * 3 + 2] - v[i * 3 + 2]) * w;
              c = nv++;
              cuts[key] = c;
            }
            out.add(c);
            if (inCap.add(c)) cap.add(c);
          }
        }
        if (out.length >= 3) next.add(_Face(f.plane, out));
      }
      if (cap.length >= 3) next.add(_Face(p, _around(v, cap, nx, ny, nz)));
      faces = next;
    }

    // Keep only the corners in use.
    final remap = Int32List(nv)..fillRange(0, nv, -1);
    final out = <double>[];
    for (final f in faces) {
      for (var k = 0; k < f.verts.length; k++) {
        final i = f.verts[k];
        var j = remap[i];
        if (j < 0) {
          j = remap[i] = out.length ~/ 3;
          out.addAll([v[i * 3], v[i * 3 + 1], v[i * 3 + 2]]);
        }
        f.verts[k] = j;
      }
    }
    return _Hull(out, faces);
  }

  /// [ids] in order around their centre, counter-clockwise seen along
  /// normal (nx, ny, nz) from outside.
  static List<int> _around(
    Float64List v,
    List<int> ids,
    double nx,
    double ny,
    double nz,
  ) {
    var cx = 0.0, cy = 0.0, cz = 0.0;
    for (final i in ids) {
      cx += v[i * 3];
      cy += v[i * 3 + 1];
      cz += v[i * 3 + 2];
    }
    cx /= ids.length;
    cy /= ids.length;
    cz /= ids.length;
    // u square to n, w = n × u.
    var ux = ny.abs() < 0.9 ? 0.0 : 1.0, uy = ny.abs() < 0.9 ? 1.0 : 0.0;
    var uz = 0.0;
    final dot = ux * nx + uy * ny + uz * nz;
    ux -= nx * dot;
    uy -= ny * dot;
    uz -= nz * dot;
    final ul = math.sqrt(ux * ux + uy * uy + uz * uz);
    ux /= ul;
    uy /= ul;
    uz /= ul;
    final wx = ny * uz - nz * uy, wy = nz * ux - nx * uz;
    final wz = nx * uy - ny * ux;
    final angle = <int, double>{
      for (final i in ids)
        i: math.atan2(
          (v[i * 3] - cx) * wx +
              (v[i * 3 + 1] - cy) * wy +
              (v[i * 3 + 2] - cz) * wz,
          (v[i * 3] - cx) * ux +
              (v[i * 3 + 1] - cy) * uy +
              (v[i * 3 + 2] - cz) * uz,
        ),
    };
    return [...ids]..sort((p, q) => angle[p]!.compareTo(angle[q]!));
  }
}
