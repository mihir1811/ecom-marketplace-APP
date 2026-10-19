import 'dart:math' as math;

import '../../diamond_education/domain/diamond_shape.dart';
import '../domain/jewelry_design.dart';
import '../domain/jewelry_metal.dart';
import '../geometry/jewelry_stone.dart';
import '../geometry/jmath.dart';
import '../geometry/jmesh.dart';
import '../physics/jewelry_physics.dart';
import 'jewelry_scene.dart';
import 'scene_kit.dart';
import 'setting_builder.dart';

/// A ring standing in the slot of a velvet display cushion.
///
/// Ring frame: the finger runs along z, the band circles in the x–y
/// plane, the centre stone on top. The cushion holds the bottom of the
/// band like a soft torsion spring: a tap rocks the ring, the cushion
/// brings it back, and gravity on the raised head makes it rock slower.
abstract final class RingScene {
  static JScene build(JewelryDesign d) {
    final tally = JTally();
    final stone = JewelryStone.of(d.stone);
    final rIn = RingSizes.diameterMm(d.ringSize) / 2;
    final t = (1.25 + d.bandWidthMm * 0.2).clamp(1.5, 2.1);
    final rOut = rIn + t, rMid = rIn + t / 2;
    final yc = rOut + 0.35 + stone.depthMm / 2;
    final seat = SceneKit.ringSeat(d.stone.shape, V3(0, yc, 0));

    final mb = MeshBuilder();
    final head = MeshBuilder();
    SettingBuilder.build(
      head,
      stone,
      tally,
      head: d.head,
      halo: d.halo,
      baseY: (rOut - 0.3) - yc,
    );
    mb.addMesh(head.build(), seat);

    final node = JNode();
    final traced = [JTracedStone(stone, node, seat)];
    var centreCt = d.stone.carat;
    // Extent of the head(s) along the band, for where the band's own
    // stones may start.
    final across = d.stone.shape == SimShape.heart
        ? stone.lengthMm
        : stone.widthMm;
    var reachX = across / 2 + SettingBuilder.totalReach(stone, d.head, d.halo);

    if (d.threeStone) {
      final side = JewelryStone.side(
        d.stone,
        (d.stone.carat * 0.3).clamp(0.1, 1.5),
      );
      final sideHead = d.head == HeadStyle.bezel
          ? HeadStyle.bezel
          : HeadStyle.prong4;
      final sideReach = SettingBuilder.headReach(side, sideHead);
      for (final s in const [-1.0, 1.0]) {
        final xs = s * (reachX + sideReach + side.widthMm / 2 + 0.15);
        final lift = rOut + 0.35 + side.depthMm / 2;
        final ang = math.asin((xs / lift).clamp(-0.9, 0.9));
        final tilt = Xf.rotation(V3.unitZ, -ang);
        final xf =
            Xf.rotation(V3.unitZ, -ang, tilt.rotate(V3(0, lift, 0))) *
            SceneKit.ringSeat(side.spec.shape, V3.zero);
        final sb = MeshBuilder();
        SettingBuilder.build(
          sb,
          side,
          tally,
          head: sideHead,
          baseY: -0.65 - side.depthMm / 2,
        );
        mb.addMesh(sb.build(), xf);
        traced.add(JTracedStone(side, node, xf));
        centreCt += side.spec.carat;
      }
      reachX = reachX + 2 * (sideReach + side.widthMm / 2) + 0.3;
    }

    // The band, swept round the finger; a cathedral lifts its shoulders
    // up into the head.
    final catH = d.cathedral
        ? math.max(0.0, (yc + stone.girdleY - stone.pavilionMm * 0.5) - rOut) *
              0.8
        : 0.0;
    final profile = bandProfile(d.bandProfile, t, d.bandWidthMm);
    const steps = 144;
    final origins = <V3>[], us = <V3>[], vs = <V3>[], scales = <double>[];
    for (var i = 0; i < steps; i++) {
      final th = 2 * math.pi * i / steps;
      var dTop = (th - math.pi / 2).abs();
      if (dTop > math.pi) dTop = 2 * math.pi - dTop;
      final shoulder = smoothstep(0.8, 0.0, dTop);
      final radial = V3(math.cos(th), math.sin(th), 0);
      origins.add(radial * (rMid + catH * shoulder));
      us.add(radial);
      vs.add(V3.unitZ);
      scales.add(1 - (d.cathedral ? 0.18 : 0.06) * shoulder);
    }
    final band = MeshBuilder();
    band.sweep(
      origins: origins,
      us: us,
      vs: vs,
      profile: profile,
      scales: scales,
      closedPath: true,
      // The inside of the band and its underside near the head are shaded.
      tagAt: (i, j) => JTag.metal(profile[j].$1 < 0 ? 0.68 : 1.0),
    );
    tally.metalVolume += band.solidVolume;
    mb.addMesh(band.build());

    _bandStones(mb, tally, d, rOut, reachX);

    final mesh = mb.build();
    final density = d.metal.density(d.purity);
    final grams = tally.metalVolume * density / 1000;

    // The display cushion; the band's foot sinks into its slot.
    final pivot = V3(0, -rOut + 2.0, 0);
    final cushionHalf = V3(rOut + 10, 9, rOut * 0.55 + 7);
    final cushionCentre = V3(0, pivot.y - 9 + 0.8, 0);
    final cushion = MeshBuilder()
      ..surface(
        68,
        34,
        (u, v) {
          // A pillow: a rounded box, its top pinched into the slot.
          final th = 2 * math.pi * u, ph = math.pi * v - math.pi / 2;
          double sp(double a, double e) =>
              a.sign * math.pow(a.abs(), e).toDouble();
          const e = 0.55;
          final x = cushionHalf.x * sp(math.cos(ph), e) * sp(math.cos(th), e);
          final z = cushionHalf.z * sp(math.cos(ph), e) * sp(math.sin(th), e);
          var y = cushionHalf.y * sp(math.sin(ph), e);
          if (y > 0) {
            // The slot: a soft crease along the top, across the ring.
            final along = smoothstep(
              cushionHalf.x,
              cushionHalf.x * 0.6,
              x.abs(),
            );
            y -= 2.2 * math.exp(-(z * z) / 3.0) * along;
          }
          return cushionCentre + V3(x, y, z);
        },
        (u, v) {
          final th = 2 * math.pi * u, ph = math.pi * v - math.pi / 2;
          final z = cushionHalf.z * math.cos(ph) * math.sin(th);
          final top = math.sin(ph) > 0.3 ? 1.0 : 0.0;
          // The slot reads as a dark crease.
          return JTag.velvet(1 - 0.75 * top * math.exp(-(z * z) / 2.0));
        },
        closedU: true,
        outward: (p) => p - cushionCentre,
      );

    final masses = [
      ...SceneKit.massOf(mesh, grams),
      for (final s in traced)
        (s.local.t, SceneKit.stoneGrams(s.stone.spec.carat)),
    ];
    final body = JRigid.tuned(
      node: node,
      pivot: pivot,
      masses: masses,
      hz: const V3(1.8, 2.6, 2.2),
      zeta: const V3(0.09, 0.12, 0.09),
      touchPoints: SceneKit.touchOf(mesh),
    );
    final top = yc + stone.tableY;
    return JScene(
      design: d,
      parts: [JPart(mesh, node), JPart(cushion.build(), JNode())],
      stones: traced,
      physics: JPhysics(rigids: [body]),
      framing: JFraming(
        focus: V3(0, (top - rOut) / 2, 0),
        radius: math.max(rOut * 1.2, (top + rOut) / 2 * 1.08),
        yaw: 0.62,
        pitch: 0.3,
      ),
      facts: JFacts(
        metalGrams: grams,
        centreCarats: centreCt,
        accentCarats: tally.accentCarats,
        accentCount: tally.accentCount,
      ),
    );
  }

  /// Pavé melee along the band's top, half way round or all the way
  /// (eternity), clear of the head, with beads between stones.
  static void _bandStones(
    MeshBuilder mb,
    JTally tally,
    JewelryDesign d,
    double rOut,
    double reachX,
  ) {
    if (d.bandAccent == BandAccent.plain) return;
    final hs = (d.bandWidthMm * 0.5).clamp(0.9, 1.8);
    final clear = math.asin(((reachX + 0.4) / rOut).clamp(0.0, 0.97));
    final step = hs * 1.12 / rOut;
    final span = d.bandAccent == BandAccent.eternity
        ? math.pi - clear
        : math.min(1.45, math.pi - clear);
    final count = math.max(1, (span / step).floor());
    var placed = 0;
    for (final side in const [-1.0, 1.0]) {
      for (var k = 0; k < count; k++) {
        final th = math.pi / 2 + side * (clear + step * (k + 0.5));
        final radial = V3(math.cos(th), math.sin(th), 0);
        final tangent = V3(-math.sin(th), math.cos(th), 0);
        mb.brilliant(
          radial * (rOut - hs * 0.05),
          radial,
          hs,
          side * 13.7 + k * 0.618,
          around: tangent,
        );
        placed++;
        final mid = th + side * step * 0.5;
        final mr = V3(math.cos(mid), math.sin(mid), 0);
        for (final z in const [-1.0, 1.0]) {
          mb.sphere(
            mr * (rOut + 0.08) + V3(0, 0, z * hs * 0.42),
            hs * 0.17,
            JTag.metal(1),
            segments: 5,
            rings: 3,
          );
        }
      }
    }
    tally.accent(hs, placed);
  }
}
