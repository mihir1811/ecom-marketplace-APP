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
/// plate), hug the pavilion, pass the girdle just outside it and curl
/// over the crown edge as rounded claws, joined by a gallery rail under
/// the girdle. A bezel is a collar round the whole girdle whose lip just
/// covers the crown's edge, on a cup that narrows to the base. A halo is
/// a row of melee round the head on a shared rail with beads between
/// stones; a double halo adds a second row outside the first.
abstract final class SettingBuilder {
  /// Prong wire radius for [s].
  static double prongRadius(JewelryStone s) =>
      (0.06 * math.min(s.widthMm, s.lengthMm) + 0.12).clamp(0.32, 0.8);

  static double bezelWall(JewelryStone s) =>
      (0.07 * math.min(s.widthMm, s.lengthMm) + 0.25).clamp(0.5, 1.1);

  /// How far outside the girdle the head's metal reaches.
  static double headReach(JewelryStone s, HeadStyle head) =>
      head == HeadStyle.bezel ? bezelWall(s) : prongRadius(s) * 1.8;

  /// Melee size for a halo round [s].
  static double haloStone(JewelryStone s) =>
      (0.115 * math.min(s.widthMm, s.lengthMm) + 0.3).clamp(0.9, 1.7);

  /// Outermost reach of head and halo past the girdle, mm.
  static double totalReach(JewelryStone s, HeadStyle head, HaloStyle halo) {
    final hs = haloStone(s);
    final rows = switch (halo) {
      HaloStyle.none => 0,
      HaloStyle.single => 1,
      HaloStyle.double => 2,
    };
    if (rows == 0) return headReach(s, head);
    return headReach(s, head) + 0.12 + rows * (hs * 1.08 + 0.05) + 0.3;
  }

  static void build(
    MeshBuilder mb,
    JewelryStone s,
    JTally tally, {
    required HeadStyle head,
    HaloStyle halo = HaloStyle.none,
    required double baseY,
    int seed = 1,
  }) {
    final before = mb.solidVolume;
    if (head == HeadStyle.bezel) {
      _bezel(mb, s, baseY);
    } else {
      _prongs(mb, s, baseY, head == HeadStyle.prong6 ? 6 : 4);
    }
    final rows = switch (halo) {
      HaloStyle.none => 0,
      HaloStyle.single => 1,
      HaloStyle.double => 2,
    };
    for (var r = 0; r < rows; r++) {
      _halo(mb, s, tally, head, r, baseY, seed + r * 31);
    }
    tally.metalVolume += mb.solidVolume - before;
  }

  static V3 _flat(V3 p) => V3(p.x, 0, p.z);

  static void _prongs(MeshBuilder mb, JewelryStone s, double baseY, int count) {
    final pr = prongRadius(s);
    final g = s.girdleY, pav = s.pavilionMm, crown = s.crownMm;
    for (final u in s.prongStops(count)) {
      final p = _flat(s.outline(u)), n = s.outlineNormal(u);
      final path = smoothPath([
        V3(p.x * 0.3, baseY, p.z * 0.3),
        V3(p.x * 0.78, g - pav * 0.55, p.z * 0.78) + n * pr,
        V3(p.x, g, p.z) + n * (pr * 0.85),
        V3(p.x * 0.97, g + crown * 0.5, p.z * 0.97) + n * (pr * 0.3),
      ], steps: 5);
      final ao = JTag.metal(0.85);
      mb.tube(path, pr, ao, sides: 8, roundEnds: false);
      mb.sphere(path.first, pr, JTag.metal(0.7), segments: 8, rings: 4);
      // The claw's rounded tip.
      mb.sphere(path.last, pr * 1.04, JTag.metal(1), segments: 10, rings: 6);
    }
    // Gallery rails tie the prongs together under the girdle.
    final upper = <V3>[], lower = <V3>[];
    for (var i = 0; i < 64; i++) {
      final u = i / 64;
      final p = _flat(s.outline(u)), n = s.outlineNormal(u);
      upper.add(V3(p.x * 0.78, g - pav * 0.55, p.z * 0.78) + n * pr);
      lower.add(V3(p.x * 0.42, g - pav * 0.88, p.z * 0.42));
    }
    mb.tube(upper, pr * 0.55, JTag.metal(0.8), sides: 6, closed: true);
    mb.tube(lower, pr * 0.5, JTag.metal(0.65), sides: 6, closed: true);
  }

  static void _bezel(MeshBuilder mb, JewelryStone s, double baseY) {
    final tb = bezelWall(s);
    final g = s.girdleY;
    final yt = g + s.crownMm * 0.32, yb = g - s.pavilionMm * 0.62;
    final profile = roundedRect(-0.22, tb, yb, yt, math.min(tb * 0.45, 0.4));
    final origins = <V3>[], us = <V3>[], vs = <V3>[];
    for (var i = 0; i < 96; i++) {
      final u = i / 96;
      origins.add(_flat(s.outline(u)));
      us.add(s.outlineNormal(u));
      vs.add(V3.unitY);
    }
    mb.sweep(
      origins: origins,
      us: us,
      vs: vs,
      profile: profile,
      closedPath: true,
      // The inner lip sits in the stone's shadow.
      tagAt: (_, j) => JTag.metal(profile[j].$1 < 0 ? 0.7 : 1.0),
    );
    // The cup below the collar narrows to the base.
    mb.surface(
      48,
      6,
      (u, v) {
        final p = _flat(s.outline(u)) + s.outlineNormal(u) * (tb * 0.6);
        final k = 1 - 0.7 * v;
        return V3(p.x * k, yb + (baseY - yb) * v, p.z * k);
      },
      (_, v) => JTag.metal(1 - 0.35 * v),
      closedU: true,
      outward: (p) => V3(p.x, 0, p.z),
    );
    mb.solidVolume += s.perimeterMm * tb * (yb - baseY).abs() * 0.5;
  }

  static void _halo(
    MeshBuilder mb,
    JewelryStone s,
    JTally tally,
    HeadStyle head,
    int row,
    double baseY,
    int seed,
  ) {
    final hs = haloStone(s);
    final off = headReach(s, head) + 0.12 + hs / 2 + row * (hs * 1.08 + 0.05);
    final yh = s.girdleY + s.crownMm * 0.05 - row * 0.15;
    // The offset outline, finely, with its running length.
    const fine = 192;
    final pts = <V3>[], nrm = <V3>[];
    for (var i = 0; i < fine; i++) {
      final u = i / fine;
      final n = s.outlineNormal(u);
      pts.add(_flat(s.outline(u)) + n * off);
      nrm.add(n);
    }
    final cum = <double>[0];
    for (var i = 0; i < fine; i++) {
      cum.add(cum.last + (pts[(i + 1) % fine] - pts[i]).length);
    }
    final total = cum.last;
    final count = math.max(6, (total / (hs * 1.1)).floor());
    (V3, V3, V3) at(double d) {
      d %= total;
      var i = 0;
      while (i < fine - 1 && cum[i + 1] < d) {
        i++;
      }
      final f = (d - cum[i]) / (cum[i + 1] - cum[i]);
      final a = pts[i], b = pts[(i + 1) % fine];
      final n = nrm[i].lerp(nrm[(i + 1) % fine], f).normalized;
      return (a.lerp(b, f), n, (b - a).normalized);
    }

    for (var k = 0; k < count; k++) {
      final (p, n, t) = at(total * k / count);
      mb.brilliant(V3(p.x, yh, p.z), V3.unitY, hs, seed + k * 0.731, around: t);
      final (q, m, _) = at(total * (k + 0.5) / count);
      for (final side in const [-1.0, 1.0]) {
        mb.sphere(
          V3(q.x, yh + hs * 0.1, q.z) + m * (side * hs * 0.4),
          hs * 0.16,
          JTag.metal(1),
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
      vs: List.filled(fine, V3.unitY),
      profile: profile,
      closedPath: true,
      tagAt: (_, j) => JTag.metal(profile[j].$2 < yh - hs * 0.3 ? 0.75 : 1),
    );
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
          JTag.metal(0.8),
          sides: 6,
        );
      }
    }
  }
}
