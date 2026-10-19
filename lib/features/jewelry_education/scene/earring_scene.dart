import 'dart:math' as math;

import '../domain/jewelry_design.dart';
import '../domain/jewelry_metal.dart';
import '../geometry/jewelry_stone.dart';
import '../geometry/jmath.dart';
import '../geometry/jmesh.dart';
import '../physics/jewelry_physics.dart';
import 'jewelry_scene.dart';
import 'pendant_builder.dart';
import 'scene_kit.dart';
import 'setting_builder.dart';

/// A pair of earrings on a velvet display bar, through holes 26 mm
/// apart, as on a jeweller's stand.
///
/// Studs are held by the bar like a stiff spring and only shiver when
/// tapped. A drop hangs from a small top stone by two linked jump rings:
/// a real double pendulum that swings, twists and settles. A hoop hangs
/// from its hole and swings both ways like a physical pendulum.
abstract final class EarringScene {
  static const _barHalf = V3(32, 4.5, 5);
  static const _holeX = 13.0;

  static JScene build(JewelryDesign d) {
    final tally = JTally();
    final density = d.metal.density(d.purity);
    final parts = <JPart>[];
    final stones = <JTracedStone>[];
    final rigids = <JRigid>[];
    final ropes = <JRope>[];
    final frames = <JRopeFrame>[];
    final skins = <JChainSkin>[];
    final bar = JBoxCollider(V3.zero, _barHalf, 3.2);
    var lowest = 0.0;
    var centreCt = 0.0;

    final stone = d.earringStyle == EarringStyle.hoop
        ? null
        : JewelryStone.of(d.stone);

    for (final side in const [-1.0, 1.0]) {
      final x = side * _holeX;
      switch (d.earringStyle) {
        case EarringStyle.stud:
          final s = stone!;
          final v0 = tally.metalVolume;
          final zc = _barHalf.z + 0.2 + s.depthMm / 2 + 0.6;
          final face = SceneKit.facingFront(d.stone.shape, V3(x, 0, zc));
          final mb = MeshBuilder();
          final headMb = MeshBuilder();
          SettingBuilder.build(
            headMb,
            s,
            tally,
            head: d.head,
            halo: d.halo,
            baseY: _barHalf.z + 0.2 - zc,
            seed: side > 0 ? 3 : 7,
          );
          mb.addMesh(headMb.build(), face);
          _postAndBack(mb, tally, V3(x, 0, 0));
          final mesh = mb.build();
          final node = JNode();
          parts.add(JPart(mesh, node));
          stones.add(JTracedStone(s, node, face));
          centreCt += s.spec.carat;
          final grams = (tally.metalVolume - v0) * density / 1000;
          rigids.add(
            JRigid.tuned(
              node: node,
              pivot: V3(x, 0, 0),
              masses: [
                ...SceneKit.massOf(mesh, grams),
                (face.t, SceneKit.stoneGrams(s.spec.carat)),
              ],
              hz: const V3(5.5, 6.5, 5.5),
              zeta: const V3(0.1, 0.1, 0.1),
              touchPoints: SceneKit.touchOf(mesh, samples: 60),
            ),
          );
          lowest = math.min(lowest, -SceneKit.reachUp(s, face) - 2);
        case EarringStyle.drop:
          final s = stone!;
          // The top: a small bezel-set stone on the post, a ring below.
          final topZ = _barHalf.z + 1.6;
          final top = MeshBuilder();
          const topStone = 2.6;
          top.brilliant(
            V3(x, 0, topZ + 0.25),
            V3.unitZ,
            topStone,
            side * 5.1,
            around: V3.unitX,
          );
          tally.accent(topStone);
          final rim = <V3>[
            for (var i = 0; i < 24; i++)
              V3(
                x + (topStone / 2 + 0.25) * math.cos(2 * math.pi * i / 24),
                (topStone / 2 + 0.25) * math.sin(2 * math.pi * i / 24),
                topZ,
              ),
          ];
          top.tube(rim, 0.35, JTag.metal(1), sides: 6, closed: true);
          const loopY = -(topStone / 2 + 1.1);
          top.tube(
            [
              for (var i = 0; i <= 16; i++)
                V3(
                  x,
                  loopY + 0.75 * math.cos(2 * math.pi * i / 16),
                  topZ + 0.75 * math.sin(2 * math.pi * i / 16),
                ),
            ],
            0.28,
            JTag.metal(1),
            sides: 6,
            closed: true,
          );
          tally.metalVolume += top.solidVolume;
          _postAndBack(top, tally, V3(x, 0, 0));
          parts.add(JPart(top.build(), JNode()));

          // Two jump rings, then the drop.
          const linkW = 1.3;
          final pitch = SceneKit.linkPitch(ChainStyle.cable, linkW);
          final pendant = PendantBuilder.build(
            s,
            d.head,
            d.halo,
            tally,
            bail: 0.9,
            seed: side > 0 ? 11 : 17,
          );
          final rope = JRope(4, friction: 0.6, passes: 8);
          final anchor = V3(x, loopY - 0.75, topZ);
          rope.place(0, anchor);
          // Jump rings weigh a few hundredths of a gram.
          rope.place(
            1,
            anchor - V3(0, pitch, 0),
            mass: 0.03,
            r: 0.4,
            drag: 0.6,
          );
          rope.place(
            2,
            anchor - V3(0, pitch * 2, 0),
            mass: 0.03,
            r: 0.4,
            drag: 0.6,
          );
          final pm = pendant.grams(density) + SceneKit.stoneGrams(s.spec.carat);
          rope.place(
            3,
            anchor - V3(0, pitch * 2 + pendant.comDrop, 0),
            mass: pm,
            r: s.depthMm * 0.45,
            drag: 0.35,
          );
          rope
            ..link(0, 1, pitch)
            ..link(1, 2, pitch)
            ..link(2, 3, pendant.comDrop)
            ..colliders.add(bar);
          ropes.add(rope);
          final linkMesh = SceneKit.link(ChainStyle.cable, linkW);
          final linkNodes = [JNode(), JNode()];
          for (final n in linkNodes) {
            parts.add(JPart(linkMesh, n));
          }
          skins.add(
            JChainSkin(
              rope: rope,
              nodes: linkNodes,
              pitch: pitch,
              from: 0,
              to: 2,
              front: (_) => V3.unitZ,
            ),
          );
          final node = JNode();
          parts.add(JPart(pendant.mesh, node));
          stones.add(JTracedStone(s, node, pendant.stoneAt));
          frames.add(
            JRopeFrame(
              node: node,
              rope: rope,
              bail: 2,
              com: 3,
              front: (_) => V3.unitZ,
            ),
          );
          centreCt += s.spec.carat;
          lowest = math.min(lowest, anchor.y - pitch * 2 - pendant.length);
        case EarringStyle.hoop:
          final r = d.hoopDiameterMm / 2;
          final wire = 0.75 + d.hoopDiameterMm * 0.012;
          final centre = V3(x, -r, 0);
          final mb = MeshBuilder();
          final pts = <V3>[
            for (var i = 0; i < 72; i++)
              centre +
                  V3(
                    0,
                    r * math.cos(2 * math.pi * i / 72),
                    r * math.sin(2 * math.pi * i / 72),
                  ),
          ];
          mb.tube(pts, wire, JTag.metal(1), sides: 10, closed: true);
          tally.metalVolume += mb.solidVolume;
          if (d.bandAccent != BandAccent.plain) {
            final hs = (wire * 1.5).clamp(1.0, 2.2);
            const from = 0.45;
            final to = d.bandAccent == BandAccent.eternity
                ? 2 * math.pi - 0.45
                : 2.5;
            final step = hs * 1.12 / (r + wire);
            var k = 0;
            for (var a = from; a <= to; a += step) {
              final radial = V3(0, math.cos(a), math.sin(a));
              final tangent = V3(0, -math.sin(a), math.cos(a));
              mb.brilliant(
                centre + radial * (r + wire * 0.75),
                radial,
                hs,
                side * 7 + k * 0.37,
                around: tangent,
              );
              k++;
            }
            tally.accent(hs, k);
          }
          final mesh = mb.build();
          final node = JNode();
          parts.add(JPart(mesh, node));
          final grams = mb.solidVolume * density / 1000;
          rigids.add(
            JRigid.tuned(
              node: node,
              pivot: V3(x, 0, 0),
              masses: SceneKit.massOf(mesh, grams),
              // Free to swing sideways and fore–aft; the hole stops it
              // twisting round.
              hz: const V3(0, 4.0, 0),
              zeta: const V3(0.05, 0.2, 0.06),
              touchPoints: SceneKit.touchOf(mesh, samples: 60),
            ),
          );
          lowest = math.min(lowest, -2 * r - wire);
      }
    }

    final barMesh = MeshBuilder()
      ..roundedBox(V3.zero, _barHalf, JTag.velvet(1), roundness: 0.22, res: 22);
    parts.add(JPart(barMesh.build(), JNode()));

    final physics = JPhysics(
      rigids: rigids,
      ropes: ropes,
      frames: frames,
      skins: skins,
    );
    physics.settle(seconds: ropes.isEmpty ? 0.1 : 1.5);
    final grams = tally.metalVolume * density / 1000;
    final height = -lowest + _barHalf.y;
    return JScene(
      design: d,
      parts: parts,
      stones: stones,
      physics: physics,
      framing: JFraming(
        focus: V3(0, lowest / 2 + 2, 3),
        radius: math.max(_holeX + 9, height * 0.62),
        yaw: 0.38,
        pitch: 0.12,
        yawLimit: 1.35,
      ),
      facts: JFacts(
        metalGrams: grams,
        centreCarats: centreCt,
        accentCarats: tally.accentCarats,
        accentCount: tally.accentCount,
      ),
    );
  }

  /// A post through the bar and a butterfly back behind it.
  static void _postAndBack(MeshBuilder mb, JTally tally, V3 hole) {
    final before = mb.solidVolume;
    mb.tube(
      [hole + V3(0, 0, _barHalf.z + 0.6), hole - V3(0, 0, _barHalf.z + 2.6)],
      0.42,
      JTag.metal(0.8),
      sides: 6,
    );
    mb.roundedBox(
      hole - V3(0, 0, _barHalf.z + 1.4),
      const V3(2.7, 2.4, 0.9),
      JTag.metal(0.85),
      roundness: 0.6,
      res: 8,
    );
    tally.metalVolume += mb.solidVolume - before;
  }
}
