import 'dart:math' as math;

import '../domain/jewelry_design.dart';
import '../geometry/jewelry_stone.dart';
import '../geometry/jmath.dart';
import '../geometry/jmesh.dart';
import 'jewelry_scene.dart';

/// The metal that holds a centre stone, and its halo, built in the stone
/// frame (mm, table up, girdle outline from [JewelryStone.outline]).
///
/// Prongs rise from [baseY] (where the head meets the band, post or
/// plate), hug the pavilion, pass the girdle just outside it and fold
/// over the crown edge: as a round bead, a tapering claw, a flat tab, or
/// a V guarding a pointed tip. A basket gallery ties them with rails, a
/// trellis crosses them in X's, an open (peg) head has neither. A bezel
/// is a collar round the whole girdle whose lip just covers the crown's
/// edge, on a cup that narrows to the base; a half bezel only collars
/// the long sides. A halo is a row of melee round the head on a shared
/// rail with beads between stones; a double halo adds a second row; a
/// hidden halo rings the pavilion under the girdle, seen from the side.
///
/// All of it is tagged as the setting's metal ([JTag.head]), so a
/// two-tone piece can show it in a second metal.
abstract final class SettingBuilder {
  /// Prong wire radius for [s].
  static double prongRadius(JewelryStone s) =>
      (0.06 * math.min(s.widthMm, s.lengthMm) + 0.12).clamp(0.32, 0.8);

  static double bezelWall(JewelryStone s) =>
      (0.07 * math.min(s.widthMm, s.lengthMm) + 0.25).clamp(0.5, 1.1);

  /// How far outside the girdle the head's metal reaches.
  static double headReach(JewelryStone s, HeadStyle head) => switch (head) {
    HeadStyle.bezel || HeadStyle.halfBezel => bezelWall(s),
    _ => prongRadius(s) * 1.8,
  };

  /// Melee size for a halo round [s].
  static double haloStone(JewelryStone s) =>
      (0.115 * math.min(s.widthMm, s.lengthMm) + 0.3).clamp(0.9, 1.7);

  /// Outermost reach of head and halo past the girdle, mm.
  static double totalReach(JewelryStone s, HeadSpec h) {
    final rows = h.haloRows;
    if (rows == 0) return headReach(s, h.style);
    final hs = haloStone(s);
    return headReach(s, h.style) + 0.12 + rows * (hs * 1.08 + 0.05) + 0.3;
  }

  static void build(
    MeshBuilder mb,
    JewelryStone s,
    JTally tally, {
    required HeadSpec head,
    required double baseY,
    int seed = 1,
  }) {
    final before = mb.solidVolume;
    switch (head.style) {
      case HeadStyle.bezel:
        _bezel(mb, s, baseY, head.milgrain, null);
      case HeadStyle.halfBezel:
        _bezel(mb, s, baseY, head.milgrain, _longSides(s));
      default:
        _prongs(mb, s, baseY, head);
    }
    if (head.hiddenHalo) _hiddenHalo(mb, s, tally, head, seed + 57);
    for (var r = 0; r < head.haloRows; r++) {
      _halo(
        mb,
        s,
        tally,
        head,
        r,
        baseY,
        seed + r * 31,
        outermost: r == head.haloRows - 1,
      );
    }
    tally.metalVolume += mb.solidVolume - before;
  }

  static V3 _flat(V3 p) => V3(p.x, 0, p.z);

  /// How sharply the outline turns at [u], radians: a point or a corner
  /// turns far more than a curve.
  static double sharpness(JewelryStone s, double u) {
    const e = 1 / 48;
    final a = s.outline(u - e), b = s.outline(u), c = s.outline(u + e);
    final t0 = (b - a).normalized, t1 = (c - b).normalized;
    return math.acos(t0.dot(t1).clamp(-1.0, 1.0));
  }

  static bool _roundish(JewelryStone s) {
    for (var i = 0; i < 48; i++) {
      if (sharpness(s, i / 48) > 0.5) return false;
    }
    return true;
  }

  /// Where on the outline (0..1) each prong stands.
  static List<double> prongStops(JewelryStone s, HeadStyle h) {
    final per = s.perimeterMm;
    final pair = (prongRadius(s) * 1.25) / per;
    List<double> doubled(List<double> us) => [
      for (final u in us) ...[u - pair, u + pair],
    ];
    switch (h) {
      case HeadStyle.prong4:
        return s.prongStops(4);
      case HeadStyle.prong6:
        return s.prongStops(6);
      case HeadStyle.prong3:
        // One prong guards the sharpest point, two hold the far side.
        var best = 1 / 12, sharp = 0.0;
        for (var i = 0; i < 96; i++) {
          final k = sharpness(s, i / 96);
          if (k > sharp) {
            sharp = k;
            best = i / 96;
          }
        }
        if (sharp < 0.5) return const [1 / 12, 5 / 12, 9 / 12];
        return [best, best + 0.37, best + 0.63];
      case HeadStyle.prong8:
        return _roundish(s)
            ? [for (var k = 0; k < 8; k++) k / 8 + 1 / 16]
            : doubled(s.prongStops(4));
      case HeadStyle.compass:
        return const [0, 0.25, 0.5, 0.75];
      case HeadStyle.doubleClaw:
        return doubled(s.prongStops(4));
      case HeadStyle.bezel:
      case HeadStyle.halfBezel:
        return const [];
    }
  }

  static void _prongs(
    MeshBuilder mb,
    JewelryStone s,
    double baseY,
    HeadSpec head,
  ) {
    final style = head.style;
    final slim = style == HeadStyle.doubleClaw || style == HeadStyle.prong8;
    final pr = prongRadius(s) * (slim ? 0.72 : 1.0);
    final g = s.girdleY, pav = s.pavilionMm, crown = s.crownMm;
    final stops = prongStops(s, style);
    final gallery = head.gallery;
    for (var k = 0; k < stops.length; k++) {
      final u = stops[k];
      final p = _flat(s.outline(u)), n = s.outlineNormal(u);
      // Trellis prongs start half a gap round, alternately, and cross
      // their neighbours on the way up; an open head gathers into a post.
      V3 base;
      switch (gallery) {
        case GalleryStyle.trellis:
          final next = stops[(k + 1) % stops.length];
          final prev = stops[(k - 1 + stops.length) % stops.length];
          final gap = ((k.isEven ? next - u : u - prev) % 1 + 1) % 1;
          final q = _flat(s.outline(u + (k.isEven ? 1 : -1) * gap * 0.5));
          base = V3(q.x * 0.36, baseY, q.z * 0.36);
        case GalleryStyle.open:
          base = V3(p.x * 0.14, baseY, p.z * 0.14);
        case GalleryStyle.basket:
          base = V3(p.x * 0.3, baseY, p.z * 0.3);
      }
      final pointed = sharpness(s, u) > 0.5;
      final tip = head.tip == ProngTip.vTip && !pointed
          ? ProngTip.round
          : head.tip;
      final ao = JTag.head(0.85);
      final lower = [
        base,
        V3(p.x * 0.78, g - pav * 0.55, p.z * 0.78) + n * pr,
        V3(p.x, g, p.z) + n * (pr * 0.85),
      ];
      mb.sphere(base, pr, JTag.head(0.7), segments: 8, rings: 4);
      switch (tip) {
        case ProngTip.round:
          final path = smoothPath([
            ...lower,
            V3(p.x * 0.97, g + crown * 0.5, p.z * 0.97) + n * (pr * 0.3),
          ], steps: 5);
          mb.tube(path, pr, ao, sides: 8, roundEnds: false);
          mb.sphere(path.last, pr * 1.04, JTag.head(1), segments: 10, rings: 6);
        case ProngTip.claw:
          final path = smoothPath([
            ...lower,
            V3(p.x * 0.97, g + crown * 0.42, p.z * 0.97) + n * (pr * 0.25),
            V3(p.x * 0.9, g + crown * 0.62, p.z * 0.9),
          ], steps: 5);
          final m = path.length;
          final taper = [
            for (var i = 0; i < m; i++)
              1 - 0.7 * smoothstep(m * 0.55, m - 1.0, i.toDouble()),
          ];
          mb.tube(path, pr, ao, sides: 8, roundEnds: true, scales: taper);
        case ProngTip.tab:
          final path = smoothPath(lower, steps: 5);
          mb.tube(path, pr, ao, sides: 8, roundEnds: false);
          _tab(mb, s, u, pr);
        case ProngTip.vTip:
          final path = smoothPath(lower, steps: 5);
          mb.tube(path, pr, ao, sides: 8, roundEnds: false);
          _chevron(mb, s, u, pr);
      }
    }
    if (gallery != GalleryStyle.basket) return;
    // Gallery rails tie the prongs together under the girdle.
    final upper = <V3>[], lowerRail = <V3>[];
    for (var i = 0; i < 64; i++) {
      final u = i / 64;
      final p = _flat(s.outline(u)), n = s.outlineNormal(u);
      upper.add(V3(p.x * 0.78, g - pav * 0.55, p.z * 0.78) + n * pr);
      lowerRail.add(V3(p.x * 0.42, g - pav * 0.88, p.z * 0.42));
    }
    mb.tube(upper, pr * 0.55, JTag.head(0.8), sides: 6, closed: true);
    mb.tube(lowerRail, pr * 0.5, JTag.head(0.65), sides: 6, closed: true);
  }

  /// A flat tab folded over the crown edge at outline position [u]: wide
  /// along the girdle, thin across it.
  static void _tab(MeshBuilder mb, JewelryStone s, double u, double pr) {
    final g = s.girdleY, crown = s.crownMm;
    final p = _flat(s.outline(u)), n = s.outlineNormal(u);
    final t = V3(-n.z, 0, n.x);
    final pts = smoothPath([
      V3(p.x, g - crown * 0.3, p.z) + n * (pr * 0.6),
      V3(p.x, g + crown * 0.2, p.z) + n * (pr * 0.5),
      V3(p.x * 0.95, g + crown * 0.52, p.z * 0.95) + n * (pr * 0.1),
    ], steps: 4);
    final us = <V3>[], vs = <V3>[];
    for (var i = 0; i < pts.length; i++) {
      final d = (pts[math.min(i + 1, pts.length - 1)] - pts[math.max(i - 1, 0)])
          .normalized;
      us.add((n - d * n.dot(d)).normalized);
      vs.add((t - d * t.dot(d)).normalized);
    }
    final profile = roundedRect(
      -pr * 0.42,
      pr * 0.42,
      -pr * 1.35,
      pr * 1.35,
      pr * 0.35,
    );
    mb.sweep(
      origins: pts,
      us: us,
      vs: vs,
      profile: profile,
      tagAt: (_, _) => JTag.head(1),
    );
  }

  /// A V-prong: a short collar folded round a pointed tip at [u].
  static void _chevron(MeshBuilder mb, JewelryStone s, double u, double pr) {
    final g = s.girdleY, crown = s.crownMm;
    final half = (pr * 2.6) / s.perimeterMm;
    final origins = <V3>[], us = <V3>[], vs = <V3>[];
    const steps = 9;
    for (var i = 0; i <= steps; i++) {
      final v = u - half + 2 * half * i / steps;
      origins.add(_flat(s.outline(v)) + V3(0, g, 0));
      us.add(s.outlineNormal(v));
      vs.add(V3.unitY);
    }
    final profile = roundedRect(
      -0.18,
      pr * 0.95,
      -crown * 0.35,
      crown * 0.42,
      pr * 0.3,
    );
    mb.sweep(
      origins: origins,
      us: us,
      vs: vs,
      profile: profile,
      tagAt: (_, j) => JTag.head(profile[j].$1 < 0 ? 0.75 : 1.0),
    );
  }

  /// The two arcs (outline ranges) along a stone's long sides.
  static List<(double, double)> _longSides(JewelryStone s) {
    var a = 0.0, b = 0.5, hi = -2.0, lo = 2.0;
    for (var i = 0; i < 96; i++) {
      final n = s.outlineNormal(i / 96);
      if (n.z > hi) {
        hi = n.z;
        a = i / 96;
      }
      if (n.z < lo) {
        lo = n.z;
        b = i / 96;
      }
    }
    const span = 0.15;
    return [(a - span, a + span), (b - span, b + span)];
  }

  static void _bezel(
    MeshBuilder mb,
    JewelryStone s,
    double baseY,
    bool milgrain,
    List<(double, double)>? arcs,
  ) {
    final tb = bezelWall(s);
    final g = s.girdleY;
    final yt = g + s.crownMm * 0.32, yb = g - s.pavilionMm * 0.62;
    final profile = roundedRect(-0.22, tb, yb, yt, math.min(tb * 0.45, 0.4));
    for (final (u0, u1) in arcs ?? const [(0.0, 1.0)]) {
      final closed = arcs == null;
      final steps = closed ? 96 : 30;
      final origins = <V3>[], us = <V3>[], vs = <V3>[];
      for (var i = 0; i < (closed ? steps : steps + 1); i++) {
        final u = u0 + (u1 - u0) * i / steps;
        origins.add(_flat(s.outline(u)));
        us.add(s.outlineNormal(u));
        vs.add(V3.unitY);
      }
      mb.sweep(
        origins: origins,
        us: us,
        vs: vs,
        profile: profile,
        closedPath: closed,
        // The inner lip sits in the stone's shadow.
        tagAt: (_, j) => JTag.head(profile[j].$1 < 0 ? 0.7 : 1.0),
      );
      if (milgrain) {
        mb.beads(
          [
            for (var i = 0; i < origins.length; i++)
              origins[i] + us[i] * (tb * 0.82) + V3(0, yt, 0),
          ],
          math.min(0.16, tb * 0.2),
          JTag.head(1),
          closed: closed,
        );
      }
      // The cup below the collar narrows to the base.
      mb.surface(
        closed ? 48 : 16,
        6,
        (u, v) {
          final w = u0 + (u1 - u0) * u;
          final p = _flat(s.outline(w)) + s.outlineNormal(w) * (tb * 0.6);
          final k = 1 - 0.7 * v;
          return V3(p.x * k, yb + (baseY - yb) * v, p.z * k);
        },
        (_, v) => JTag.head(1 - 0.35 * v),
        closedU: closed,
        outward: (p) => V3(p.x, 0, p.z),
      );
      mb.solidVolume +=
          s.perimeterMm * (u1 - u0) * tb * (yb - baseY).abs() * 0.5;
    }
  }

  /// The offset outline at [off] mm outside the girdle, [fine] points,
  /// with outward normals and running length.
  static (List<V3>, List<V3>, List<double>) _offset(
    JewelryStone s,
    double off, {
    double shrink = 1,
    int fine = 192,
  }) {
    final pts = <V3>[], nrm = <V3>[];
    for (var i = 0; i < fine; i++) {
      final u = i / fine;
      final n = s.outlineNormal(u);
      pts.add(_flat(s.outline(u)) * shrink + n * off);
      nrm.add(n);
    }
    final cum = <double>[0];
    for (var i = 0; i < fine; i++) {
      cum.add(cum.last + (pts[(i + 1) % fine] - pts[i]).length);
    }
    return (pts, nrm, cum);
  }

  static (V3, V3, V3) _along(
    List<V3> pts,
    List<V3> nrm,
    List<double> cum,
    double d,
  ) {
    final fine = pts.length;
    final total = cum.last;
    d = (d % total + total) % total;
    var i = 0;
    while (i < fine - 1 && cum[i + 1] < d) {
      i++;
    }
    final f = (d - cum[i]) / (cum[i + 1] - cum[i]);
    final a = pts[i], b = pts[(i + 1) % fine];
    final n = nrm[i].lerp(nrm[(i + 1) % fine], f).normalized;
    return (a.lerp(b, f), n, (b - a).normalized);
  }

  static void _halo(
    MeshBuilder mb,
    JewelryStone s,
    JTally tally,
    HeadSpec head,
    int row,
    double baseY,
    int seed, {
    required bool outermost,
  }) {
    final hs = haloStone(s);
    final off =
        headReach(s, head.style) + 0.12 + hs / 2 + row * (hs * 1.08 + 0.05);
    final yh = s.girdleY + s.crownMm * 0.05 - row * 0.15;
    final (pts, nrm, cum) = _offset(s, off);
    final total = cum.last;
    final count = math.max(6, (total / (hs * 1.1)).floor());
    for (var k = 0; k < count; k++) {
      final (p, _, t) = _along(pts, nrm, cum, total * k / count);
      mb.brilliant(V3(p.x, yh, p.z), V3.unitY, hs, seed + k * 0.731, around: t);
      final (q, m, _) = _along(pts, nrm, cum, total * (k + 0.5) / count);
      for (final side in const [-1.0, 1.0]) {
        mb.sphere(
          V3(q.x, yh + hs * 0.1, q.z) + m * (side * hs * 0.4),
          hs * 0.16,
          JTag.head(1),
          segments: 5,
          rings: 3,
        );
      }
    }
    tally.accent(hs, count);
    // The shared rail under the melee.
    final profile = roundedRect(
      -hs * 0.55,
      hs * 0.55,
      yh - hs * 0.5,
      yh - hs * 0.04,
      hs * 0.18,
    );
    mb.sweep(
      origins: [for (final p in pts) V3(p.x, 0, p.z)],
      us: nrm,
      vs: List.filled(pts.length, V3.unitY),
      profile: profile,
      closedPath: true,
      tagAt: (_, j) => JTag.head(profile[j].$2 < yh - hs * 0.3 ? 0.75 : 1),
    );
    if (outermost && head.milgrain) {
      mb.beads(
        [
          for (var i = 0; i < pts.length; i += 2)
            pts[i] + nrm[i] * (hs * 0.55) + V3(0, yh - hs * 0.08, 0),
        ],
        hs * 0.1,
        JTag.head(1),
        closed: true,
      );
    }
    if (row == 0) {
      // Struts carry the halo down to the base.
      for (final u in const [1 / 8, 3 / 8, 5 / 8, 7 / 8]) {
        final p = _flat(s.outline(u)) + s.outlineNormal(u) * off;
        mb.tube(
          smoothPath([
            V3(p.x, yh - hs * 0.45, p.z),
            V3(p.x * 0.75, (yh + baseY) / 2, p.z * 0.75),
            V3(p.x * 0.3, baseY, p.z * 0.3),
          ], steps: 4),
          hs * 0.22,
          JTag.head(0.8),
          sides: 6,
        );
      }
    }
  }

  /// Melee round the pavilion under the girdle, tables tipped outward:
  /// hidden from above, a flash of sparkle from the side.
  static void _hiddenHalo(
    MeshBuilder mb,
    JewelryStone s,
    JTally tally,
    HeadSpec head,
    int seed,
  ) {
    final hs = haloStone(s) * 0.82;
    final pr = prongRadius(s);
    final depth = s.pavilionMm * 0.3;
    final yh = s.girdleY - depth;
    final shrink = 1 - depth / s.pavilionMm;
    final (pts, nrm, cum) = _offset(s, hs * 0.55 + 0.05, shrink: shrink);
    final total = cum.last;
    final count = math.max(6, (total / (hs * 1.12)).floor());
    // Keep clear of the prongs.
    final stops = head.isBezel ? const <double>[] : prongStops(s, head.style);
    final prongAt = [for (final u in stops) _flat(s.outline(u)) * shrink];
    var placed = 0;
    for (var k = 0; k < count; k++) {
      final (p, n, t) = _along(pts, nrm, cum, total * k / count);
      if (prongAt.any((q) => (q - p).length < pr + hs * 0.55)) continue;
      final up = (n * 0.8 + V3.unitY * 0.6).normalized;
      mb.brilliant(V3(p.x, yh, p.z), up, hs, seed + k * 0.37, around: t);
      placed++;
    }
    tally.accent(hs, placed);
    final profile = roundedRect(
      -hs * 0.45,
      hs * 0.45,
      -hs * 0.55,
      -hs * 0.12,
      hs * 0.15,
    );
    mb.sweep(
      origins: [for (final p in pts) V3(p.x, yh, p.z)],
      us: nrm,
      vs: List.filled(pts.length, V3.unitY),
      profile: profile,
      closedPath: true,
      tagAt: (_, _) => JTag.head(0.8),
    );
  }
}
