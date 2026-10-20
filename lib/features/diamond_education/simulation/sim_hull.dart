import 'dart:math' as math;
import 'dart:typed_data';

/// A face of a [SimHull].
class SimHullFace {
  SimHullFace(this.plane, this.verts);

  /// Index of the plane it lies in; negative for the starting box.
  final int plane;
  final List<int> verts;
}

/// The convex solid cut from a large box by planes `n · p <= d`.
class SimHull {
  SimHull(this.vertices, this.faces);

  /// Corners in use, xyz.
  final List<double> vertices;

  /// One polygon per plane that bounds the solid, counter-clockwise seen
  /// from outside.
  final List<SimHullFace> faces;

  static const _eps = 1e-9;

  /// Cuts with the first [count] planes of [planes] (nx ny nz d each).
  static SimHull cut(Float64List planes, int count) {
    const r = 8.0;
    var v = Float64List(1536);
    var nv = 8;
    for (var i = 0; i < 8; i++) {
      v
        ..[i * 3] = i & 1 == 0 ? -r : r
        ..[i * 3 + 1] = i & 2 == 0 ? -r : r
        ..[i * 3 + 2] = i & 4 == 0 ? -r : r;
    }
    var faces = <SimHullFace>[
      SimHullFace(-1, [0, 4, 6, 2]), // −x
      SimHullFace(-2, [1, 3, 7, 5]), // +x
      SimHullFace(-3, [0, 1, 5, 4]), // −y
      SimHullFace(-4, [2, 6, 7, 3]), // +y
      SimHullFace(-5, [0, 2, 3, 1]), // −z
      SimHullFace(-6, [4, 5, 7, 6]), // +z
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
      final next = <SimHullFace>[];
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
        if (out.length >= 3) next.add(SimHullFace(f.plane, out));
      }
      if (cap.length >= 3) {
        next.add(SimHullFace(p, _around(v, cap, nx, ny, nz)));
      }
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
    return SimHull(out, faces);
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
