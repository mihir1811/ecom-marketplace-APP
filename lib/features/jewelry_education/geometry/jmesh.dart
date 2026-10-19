import 'dart:math' as math;
import 'dart:typed_data';

import 'jmath.dart';

/// What a surface is made of, packed with its shading detail into one
/// 0..1 value: the blue channel of the renderer's G-buffer (see
/// `shaders/jewelry_shade.frag`, which decodes the same bands).
abstract final class JTag {
  /// Metal with ambient occlusion [ao] (1 open, 0 fully hidden).
  static double metal(double ao) => 0.21 + 0.19 * ao.clamp(0.0, 1.0);

  /// The setting's metal (head, prongs, bezel, halo) with ambient
  /// occlusion [ao]: the same as [metal] unless the piece is two-tone.
  static double head(double ao) => 0.19 * ao.clamp(0.0, 1.0);

  /// Metal's ambient occlusion from either metal's tag.
  static double metalAo(double t) => t < 0.20 ? t / 0.19 : (t - 0.21) / 0.19;

  static bool isHeadMetal(double t) => t < 0.20;

  /// Display velvet with ambient occlusion [ao].
  static double velvet(double ao) => 0.45 + 0.20 * ao.clamp(0.0, 1.0);

  /// A small diamond facet; [seed] varies how each facet catches light.
  static double gem(double seed) => 0.70 + 0.30 * seed.clamp(0.0, 1.0);

  static bool isMetal(double t) => t < 0.425;
  static bool isGem(double t) => t >= 0.675;
}

/// An indexed triangle mesh in millimetres, with a smooth (or, for gem
/// facets, flat) normal and a [JTag] per vertex. Triangles wind
/// counter-clockwise seen from outside.
class JMesh {
  JMesh(this.pos, this.nrm, this.tag, this.idx);

  static final empty = JMesh(
    Float32List(0),
    Float32List(0),
    Float32List(0),
    Int32List(0),
  );

  final Float32List pos, nrm, tag;
  final Int32List idx;

  int get vertexCount => tag.length;
  int get triangleCount => idx.length ~/ 3;

  /// Enclosed volume, mm³, for meshes that close up (divergence theorem).
  double get volume {
    var v = 0.0;
    for (var i = 0; i < idx.length; i += 3) {
      final a = idx[i] * 3, b = idx[i + 1] * 3, c = idx[i + 2] * 3;
      final ax = pos[a], ay = pos[a + 1], az = pos[a + 2];
      final bx = pos[b], by = pos[b + 1], bz = pos[b + 2];
      final cx = pos[c], cy = pos[c + 1], cz = pos[c + 2];
      v +=
          ax * (by * cz - bz * cy) -
          ay * (bx * cz - bz * cx) +
          az * (bx * cy - by * cx);
    }
    return v.abs() / 6;
  }

  /// Mean of the vertices.
  V3 get centroid {
    if (vertexCount == 0) return V3.zero;
    var x = 0.0, y = 0.0, z = 0.0;
    for (var i = 0; i < vertexCount; i++) {
      x += pos[i * 3];
      y += pos[i * 3 + 1];
      z += pos[i * 3 + 2];
    }
    return V3(x / vertexCount, y / vertexCount, z / vertexCount);
  }

  /// Bounding radius around [c].
  double radiusAbout(V3 c) {
    var r = 0.0;
    for (var i = 0; i < vertexCount; i++) {
      final dx = pos[i * 3] - c.x,
          dy = pos[i * 3 + 1] - c.y,
          dz = pos[i * 3 + 2] - c.z;
      r = math.max(r, dx * dx + dy * dy + dz * dz);
    }
    return math.sqrt(r);
  }
}

/// Accumulates geometry and builds a [JMesh]. Every primitive takes a
/// [JTag] value for its vertices.
class MeshBuilder {
  final List<double> _p = [], _n = [], _t = [];
  final List<int> _i = [];

  /// Volume of solids added since construction, mm³, counted per
  /// primitive so overlapping parts (a prong sinking into the band) do
  /// not need a closed union.
  double solidVolume = 0;

  int get vertexCount => _t.length;

  int vertex(V3 p, V3 n, double tag) {
    final u = n.normalized;
    _p
      ..add(p.x)
      ..add(p.y)
      ..add(p.z);
    _n
      ..add(u.x)
      ..add(u.y)
      ..add(u.z);
    _t.add(tag);
    return _t.length - 1;
  }

  V3 _pos(int i) => V3(_p[i * 3], _p[i * 3 + 1], _p[i * 3 + 2]);
  V3 _nrm(int i) => V3(_n[i * 3], _n[i * 3 + 1], _n[i * 3 + 2]);

  /// Adds a triangle, wound so its face looks the way its normals do.
  void tri(int a, int b, int c) {
    final pa = _pos(a), pb = _pos(b), pc = _pos(c);
    final face = (pb - pa).cross(pc - pa);
    final n = _nrm(a) + _nrm(b) + _nrm(c);
    if (face.dot(n) < 0) {
      _i
        ..add(a)
        ..add(c)
        ..add(b);
    } else {
      _i
        ..add(a)
        ..add(b)
        ..add(c);
    }
  }

  void quad(int a, int b, int c, int d) {
    tri(a, b, c);
    tri(a, c, d);
  }

  /// Adds every triangle of [m], moved by [xf].
  void addMesh(JMesh m, [Xf? xf]) {
    final base = vertexCount;
    for (var i = 0; i < m.vertexCount; i++) {
      var p = V3(m.pos[i * 3], m.pos[i * 3 + 1], m.pos[i * 3 + 2]);
      var n = V3(m.nrm[i * 3], m.nrm[i * 3 + 1], m.nrm[i * 3 + 2]);
      if (xf != null) {
        p = xf.apply(p);
        n = xf.rotate(n);
      }
      vertex(p, n, m.tag[i]);
    }
    for (final i in m.idx) {
      _i.add(base + i);
    }
  }

  JMesh build() => JMesh(
    Float32List.fromList(_p),
    Float32List.fromList(_n),
    Float32List.fromList(_t),
    Int32List.fromList(_i),
  );

  // ---- Primitives ------------------------------------------------------

  /// Sweeps closed 2D [profile] (u, v) along a path: at step i the
  /// profile point lands at `origins[i] + us[i]·u + vs[i]·v`. Normals come
  /// from the profile's own outward normals. [tagAt] may vary the tag per
  /// path step and profile point.
  void sweep({
    required List<V3> origins,
    required List<V3> us,
    required List<V3> vs,
    required List<(double, double)> profile,
    required double Function(int step, int corner) tagAt,
    bool closedPath = false,
    bool capEnds = true,
    List<double>? scales,
  }) {
    final m = profile.length, n = origins.length;
    // Outward 2D normals of the profile, whichever way it winds.
    var area = 0.0;
    for (var j = 0; j < m; j++) {
      final a = profile[j], b = profile[(j + 1) % m];
      area += a.$1 * b.$2 - b.$1 * a.$2;
    }
    final sign = area >= 0 ? 1.0 : -1.0;
    final nu = Float64List(m), nv = Float64List(m);
    for (var j = 0; j < m; j++) {
      final a = profile[(j - 1 + m) % m], b = profile[(j + 1) % m];
      final du = b.$1 - a.$1, dv = b.$2 - a.$2;
      final l = math.sqrt(du * du + dv * dv);
      nu[j] = sign * dv / l;
      nv[j] = -sign * du / l;
    }
    final rows = <int>[];
    for (var i = 0; i < n; i++) {
      final s = scales?[i] ?? 1.0;
      rows.add(vertexCount);
      for (var j = 0; j < m; j++) {
        final (pu, pv) = profile[j];
        vertex(
          origins[i] + us[i] * (pu * s) + vs[i] * (pv * s),
          us[i] * nu[j] + vs[i] * nv[j],
          tagAt(i, j),
        );
      }
    }
    final spans = closedPath ? n : n - 1;
    for (var i = 0; i < spans; i++) {
      final r0 = rows[i], r1 = rows[(i + 1) % n];
      for (var j = 0; j < m; j++) {
        final j1 = (j + 1) % m;
        quad(r0 + j, r0 + j1, r1 + j1, r1 + j);
      }
    }
    if (!closedPath && capEnds) {
      for (final end in [0, n - 1]) {
        final along = end == 0
            ? origins[0] - origins[1]
            : origins[n - 1] - origins[n - 2];
        final out = along.normalized;
        final c = vertex(origins[end], out, tagAt(end, 0));
        final ring = <int>[];
        final s = scales?[end] ?? 1.0;
        for (var j = 0; j < m; j++) {
          final (pu, pv) = profile[j];
          ring.add(
            vertex(
              origins[end] + us[end] * (pu * s) + vs[end] * (pv * s),
              out,
              tagAt(end, j),
            ),
          );
        }
        for (var j = 0; j < m; j++) {
          tri(c, ring[j], ring[(j + 1) % m]);
        }
      }
    }
    // Profile area × path length (Pappus), for the metal weight.
    var len = 0.0;
    for (var i = 0; i < spans; i++) {
      len += (origins[(i + 1) % n] - origins[i]).length;
    }
    final s = scales == null
        ? 1.0
        : scales.reduce((a, b) => a + b) / scales.length;
    solidVolume += area.abs() / 2 * s * s * len;
  }

  /// A round wire of radius [r] along [pts], with rounded ends; [scales]
  /// thins it along the way (a claw tapering to its point).
  void tube(
    List<V3> pts,
    double r,
    double tag, {
    int sides = 8,
    bool closed = false,
    bool roundEnds = true,
    List<double>? scales,
  }) {
    final n = pts.length;
    if (n < 2) return;
    final us = <V3>[], vs = <V3>[];
    V3 tangent(int i) {
      if (closed) return (pts[(i + 1) % n] - pts[(i - 1 + n) % n]).normalized;
      if (i == 0) return (pts[1] - pts[0]).normalized;
      if (i == n - 1) return (pts[n - 1] - pts[n - 2]).normalized;
      return (pts[i + 1] - pts[i - 1]).normalized;
    }

    // Rotation-minimising frames, so the wire does not twist.
    var u = tangent(0).anyPerpendicular;
    for (var i = 0; i < n; i++) {
      final t = tangent(i);
      u = (u - t * u.dot(t)).normalized;
      us.add(u);
      vs.add(t.cross(u));
    }
    final profile = [
      for (var k = 0; k < sides; k++)
        (
          r * math.cos(2 * math.pi * k / sides),
          r * math.sin(2 * math.pi * k / sides),
        ),
    ];
    sweep(
      origins: pts,
      us: us,
      vs: vs,
      profile: profile,
      tagAt: (_, _) => tag,
      closedPath: closed,
      capEnds: !roundEnds,
      scales: scales,
    );
    if (!closed && roundEnds) {
      final r0 = r * (scales?.first ?? 1), r1 = r * (scales?.last ?? 1);
      sphere(pts.first, r0, tag, segments: sides, rings: 4, count: false);
      sphere(pts.last, r1, tag, segments: sides, rings: 4, count: false);
    }
  }

  /// Milgrain: a row of tiny beads [r] in radius along [pts], about
  /// 2.4 radii apart.
  void beads(List<V3> pts, double r, double tag, {bool closed = false}) {
    if (pts.length < 2) return;
    var carry = 0.0;
    final step = r * 2.4;
    final n = closed ? pts.length : pts.length - 1;
    for (var i = 0; i < n; i++) {
      final a = pts[i], b = pts[(i + 1) % pts.length];
      final len = (b - a).length;
      var s = carry;
      while (s < len) {
        sphere(a.lerp(b, s / len), r, tag, segments: 4, rings: 3);
        s += step;
      }
      carry = s - len;
    }
  }

  /// A sphere; [tagAt] may shade it by its outward normal.
  void sphere(
    V3 c,
    double r,
    double tag, {
    int segments = 10,
    int rings = 6,
    bool count = true,
    double Function(V3 normal)? tagAt,
  }) {
    final rows = <int>[];
    for (var i = 0; i <= rings; i++) {
      final phi = math.pi * i / rings;
      rows.add(vertexCount);
      for (var j = 0; j < segments; j++) {
        final th = 2 * math.pi * j / segments;
        final n = V3(
          math.sin(phi) * math.cos(th),
          math.cos(phi),
          math.sin(phi) * math.sin(th),
        );
        vertex(c + n * r, n, tagAt?.call(n) ?? tag);
      }
    }
    for (var i = 0; i < rings; i++) {
      for (var j = 0; j < segments; j++) {
        final j1 = (j + 1) % segments;
        if (i == 0) {
          tri(rows[0] + j, rows[1] + j, rows[1] + j1);
        } else if (i == rings - 1) {
          tri(rows[i] + j, rows[i + 1] + j, rows[i] + j1);
        } else {
          quad(rows[i] + j, rows[i + 1] + j, rows[i + 1] + j1, rows[i] + j1);
        }
      }
    }
    if (count) solidVolume += 4 / 3 * math.pi * r * r * r;
  }

  /// A smooth surface over (u, v) in 0..1 with [nu]×[nv] quads; normals
  /// from the surface's own partial derivatives, flipped to agree with
  /// [outward] when given.
  void surface(
    int nu,
    int nv,
    V3 Function(double u, double v) at,
    double Function(double u, double v) tagAt, {
    bool closedU = false,
    V3 Function(V3 p)? outward,
  }) {
    final cols = closedU ? nu : nu + 1;
    final base = vertexCount;
    const e = 1e-3;
    for (var i = 0; i <= nv; i++) {
      final v = i / nv;
      for (var j = 0; j < cols; j++) {
        final u = j / nu;
        final p = at(u, v);
        final du = at(u + e, v) - at(u - e, v);
        final dv = at(u, (v + e).clamp(0, 1)) - at(u, (v - e).clamp(0, 1));
        final c = du.cross(dv);
        V3 n;
        if (c.length < 1e-9 && outward != null) {
          // A pole, where one direction collapses.
          n = outward(p).normalized;
        } else {
          n = c.normalized;
          if (outward != null && n.dot(outward(p)) < 0) n = -n;
        }
        vertex(p, n, tagAt(u, v));
      }
    }
    for (var i = 0; i < nv; i++) {
      for (var j = 0; j < nu; j++) {
        final j1 = closedU ? (j + 1) % nu : j + 1;
        quad(
          base + i * cols + j,
          base + i * cols + j1,
          base + (i + 1) * cols + j1,
          base + (i + 1) * cols + j,
        );
      }
    }
  }

  /// A rounded box (superellipsoid) centred at [c] with half sizes [h];
  /// [roundness] 0 is boxy, 1 a full ellipsoid.
  void roundedBox(
    V3 c,
    V3 h,
    double tag, {
    double roundness = 0.25,
    int res = 18,
  }) {
    final e = 0.12 + roundness * 0.88;
    double sp(double v, double x) => v.sign * math.pow(v.abs(), x).toDouble();
    surface(
      res * 2,
      res,
      (u, v) {
        final th = 2 * math.pi * u,
            ph = math.pi * v.clamp(0.0, 1.0) - math.pi / 2;
        final cp = math.cos(ph), spn = math.sin(ph);
        return V3(
          c.x + h.x * sp(cp, e) * sp(math.cos(th), e),
          c.y + h.y * sp(spn, e),
          c.z + h.z * sp(cp, e) * sp(math.sin(th), e),
        );
      },
      (_, _) => tag,
      closedU: true,
      outward: (p) => p - c,
    );
    solidVolume += 8 * h.x * h.y * h.z * (0.52 + 0.48 * (1 - roundness));
  }

  /// A small round brilliant diamond, flat-faceted (each facet its own
  /// vertices), [d] across, girdle centred on [c], table toward [up],
  /// [seed] varying its facets' sparkle. Table 56%, crown 15%, pavilion
  /// 43% of the diameter, as in a well cut melee stone.
  void brilliant(V3 c, V3 up, double d, double seed, {V3? around}) {
    final y = up.normalized;
    final x = (around ?? y.anyPerpendicular).normalized;
    final z = x.cross(y);
    V3 at(double r, double a, double h) =>
        c + x * (r * math.cos(a)) + z * (r * math.sin(a)) + y * h;
    final r = d / 2, g = d * 0.015, crown = d * 0.15, pav = d * 0.43;
    final table = [
      for (var k = 0; k < 8; k++) at(r * 0.56, k * math.pi / 4, g + crown),
    ];
    final top = [for (var j = 0; j < 16; j++) at(r, j * math.pi / 8, g)];
    final bot = [for (var j = 0; j < 16; j++) at(r, j * math.pi / 8, -g)];
    final culet = c - y * pav;
    var facet = 0;
    void face(List<V3> ps) {
      var n = (ps[1] - ps[0]).cross(ps[2] - ps[0]).normalized;
      var mid = V3.zero;
      for (final p in ps) {
        mid = mid + p;
      }
      mid = mid * (1 / ps.length);
      if (n.dot(mid - c) < 0) n = -n;
      final h =
          math.sin((seed * 97.13 + facet * 12.9898) * 43758.5453) * 0.5 + 0.5;
      final tag = JTag.gem((h * 1000) % 1);
      facet++;
      final ids = [for (final p in ps) vertex(p, n, tag)];
      for (var k = 1; k < ids.length - 1; k++) {
        tri(ids[0], ids[k], ids[k + 1]);
      }
    }

    face(table);
    for (var k = 0; k < 8; k++) {
      final t0 = table[k], t1 = table[(k + 1) % 8];
      final g0 = top[2 * k], g1 = top[2 * k + 1], g2 = top[(2 * k + 2) % 16];
      face([t0, g0, g1]);
      face([t0, g1, t1]);
      face([t1, g1, g2]);
    }
    for (var j = 0; j < 16; j++) {
      final j1 = (j + 1) % 16;
      face([top[j], bot[j], bot[j1], top[j1]]);
      face([bot[j], culet, bot[j1]]);
    }
  }
}
