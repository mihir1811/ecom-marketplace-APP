import 'dart:math' as math;

import '../../diamond_education/domain/diamond_shape.dart';
import '../domain/jewelry_design.dart';
import '../domain/jewelry_metal.dart';
import '../geometry/jewelry_stone.dart';
import '../geometry/jmath.dart';
import '../geometry/jmesh.dart';
import '../physics/jewelry_physics.dart';
import 'band_kit.dart';
import 'jewelry_scene.dart';
import 'scene_kit.dart';
import 'setting_builder.dart';

/// A ring standing in the slot of a velvet display cushion.
///
/// Ring frame: the finger runs along z, the band circles in the x–y
/// plane, the centre stone on top. The cushion's foam grips the bottom
/// of the band: a viscoelastic holder that carries the ring's weight,
/// gives a little when tapped and takes the motion out within a swing or
/// two, with a small dead band from the foam's hysteresis. A higher head
/// raises the centre of mass, so gravity makes the ring rock slower; a
/// hard twist slides the band round in its slot, where it stays.
abstract final class RingScene {
  static JScene build(JewelryDesign d) {
    final tally = JTally();
    final stone = JewelryStone.of(d.stone);
    final head = d.headSpec;
    final rIn = RingSizes.diameterMm(d.ringSize) / 2;
    final t = (1.25 + d.bandWidthMm * 0.2).clamp(1.5, 2.1);
    final rOut = rIn + t, rMid = rIn + t / 2;
    final lift = switch (d.settingHeight) {
      SettingHeight.low => -0.7,
      SettingHeight.medium => 0.35,
      SettingHeight.high => 1.8,
    };
    final yc = rOut + lift + stone.depthMm / 2;
    final seat = _seat(d, V3(0, yc, 0));

    final mb = MeshBuilder();
    final headMb = MeshBuilder();
    SettingBuilder.build(
      headMb,
      stone,
      tally,
      head: head,
      baseY: (rOut - 0.3) - yc,
    );
    mb.addMesh(headMb.build(), seat);

    final node = JNode();
    final traced = [JTracedStone(stone, node, seat)];
    var centreCt = d.stone.carat;
    // Extent of the head(s) along the band, for where the band's own
    // stones may start.
    final lengthAcross = (d.stone.shape == SimShape.heart) != d.eastWest;
    final across = lengthAcross ? stone.lengthMm : stone.widthMm;
    var reachX = across / 2 + SettingBuilder.totalReach(stone, head);

    if (d.threeStone) {
      final side = JewelryStone.side(
        d.stone,
        (d.stone.carat * 0.3).clamp(0.1, 1.5),
      );
      final sideHead = HeadSpec(
        style: head.isBezel ? HeadStyle.bezel : HeadStyle.prong4,
        tip: head.tip,
        milgrain: head.milgrain,
      );
      final sideReach = SettingBuilder.headReach(side, sideHead.style);
      for (final s in const [-1.0, 1.0]) {
        final xs = s * (reachX + sideReach + side.widthMm / 2 + 0.15);
        final up = rOut + 0.35 + side.depthMm / 2;
        final ang = math.asin((xs / up).clamp(-0.9, 0.9));
        final tilt = Xf.rotation(V3.unitZ, -ang);
        final xf =
            Xf.rotation(V3.unitZ, -ang, tilt.rotate(V3(0, up, 0))) *
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

    // The shank, swept round the finger; a cathedral lifts its shoulders
    // up into the head.
    final catH = d.cathedral
        ? math.max(0.0, (yc + stone.girdleY - stone.pavilionMm * 0.5) - rOut) *
              0.8
        : 0.0;
    final shank = Shank(
      style: d.shank,
      profile: d.bandProfile,
      rMid: rMid,
      thickness: t,
      width: d.bandWidthMm,
      cathedral: catH,
      headHalf: math.max(reachX, across / 2 + 1.0),
    );
    final band = MeshBuilder();
    shank.build(band, milgrain: d.milgrain);
    tally.metalVolume += band.solidVolume;
    mb.addMesh(band.build());

    if (d.takesBandStones && d.bandAccent != BandAccent.plain) {
      final clear = math.asin(((reachX + 0.4) / rOut).clamp(0.0, 0.97));
      BandStones.place(
        mb,
        tally,
        shank,
        coverage: d.bandAccent,
        setting: d.accentSetting,
        clear: clear,
      );
    }

    final mesh = mb.build();
    final density = d.metal.density(d.purity);
    final grams = tally.metalVolume * density / 1000;

    // The display cushion; the band's foot sinks into its slot.
    final pivot = V3(0, -rOut + 2.0, 0);
    final cushion = _cushion(rOut, pivot);

    final masses = [
      ...SceneKit.massOf(mesh, grams),
      for (final s in traced)
        (s.local.t, SceneKit.stoneGrams(s.stone.spec.carat)),
    ];
    final body = JRigid.tuned(
      node: node,
      pivot: pivot,
      masses: masses,
      hz: const V3(2.4, 2.8, 2.2),
      zeta: const V3(0.38, 0.45, 0.38),
      stick: const V3(0.006, 0.01, 0.006),
      slipAngle: const V3(0, 0.18, 0),
      touchPoints: SceneKit.touchOf(mesh),
      touchNormals: SceneKit.touchNormalsOf(mesh),
    );
    final top = yc + stone.tableY;
    return JScene(
      design: d,
      parts: [JPart(mesh, node), JPart(cushion, JNode())],
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

  /// Stone frame → ring frame: north–south (length along the finger) or
  /// turned a quarter east–west.
  static Xf _seat(JewelryDesign d, V3 at) {
    final ns = SceneKit.ringSeat(d.stone.shape, V3.zero);
    final turn = d.eastWest ? math.pi / 2 : 0.0;
    return Xf.rotation(V3.unitY, turn, at) * ns;
  }

  static JMesh _cushion(double rOut, V3 pivot) {
    final half = V3(rOut + 10, 9, rOut * 0.55 + 7);
    final centre = V3(0, pivot.y - 9 + 0.8, 0);
    final mb = MeshBuilder()
      ..surface(
        68,
        34,
        (u, v) {
          // A pillow: a rounded box, its top pinched into the slot.
          final th = 2 * math.pi * u, ph = math.pi * v - math.pi / 2;
          double sp(double a, double e) =>
              a.sign * math.pow(a.abs(), e).toDouble();
          const e = 0.55;
          final x = half.x * sp(math.cos(ph), e) * sp(math.cos(th), e);
          final z = half.z * sp(math.cos(ph), e) * sp(math.sin(th), e);
          var y = half.y * sp(math.sin(ph), e);
          if (y > 0) {
            // The slot: a soft crease along the top, across the ring.
            final along = smoothstep(half.x, half.x * 0.6, x.abs());
            y -= 2.2 * math.exp(-(z * z) / 3.0) * along;
          }
          return centre + V3(x, y, z);
        },
        (u, v) {
          final th = 2 * math.pi * u, ph = math.pi * v - math.pi / 2;
          final z = half.z * math.cos(ph) * math.sin(th);
          final top = math.sin(ph) > 0.3 ? 1.0 : 0.0;
          // The slot reads as a dark crease.
          return JTag.velvet(1 - 0.75 * top * math.exp(-(z * z) / 2.0));
        },
        closedU: true,
        outward: (p) => p - centre,
      );
    return mb.build();
  }
}
