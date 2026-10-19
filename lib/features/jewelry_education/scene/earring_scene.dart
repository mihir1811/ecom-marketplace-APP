import 'dart:math' as math;

import '../domain/jewelry_design.dart';
import '../domain/jewelry_metal.dart';
import '../geometry/jewelry_stone.dart';
import '../geometry/jmath.dart';
import '../geometry/jmesh.dart';
import '../physics/jewelry_physics.dart';
import 'band_kit.dart';
import 'jewelry_scene.dart';
import 'pendant_builder.dart';
import 'scene_kit.dart';
import 'setting_builder.dart';

/// A pair of earrings on a velvet display bar, through holes 26 mm
/// apart, as on a jeweller's stand.
///
/// A stud is clamped by its back against the bar: the foam behind gives
/// a little, stiffer for a screw back, and carries the weight. A drop
/// hangs from its fitting by jump rings: a post top is fixed, a French
/// hook or lever back pivots in the hole, so the whole is a real double
/// or triple pendulum, its joints rubbing with dry friction so it swings
/// a few times and stops. A hoop or huggie hangs from its hole and swings
/// both ways like a physical pendulum, the wire rubbing in the hole.
abstract final class EarringScene {
  static const _holeX = 13.0;

  static V3 _barHalf(JewelryDesign d) => switch (d.earringStyle) {
    // Hoops and huggies hang from a slimmer earring card.
    EarringStyle.hoop || EarringStyle.huggie => const V3(32, 4.5, 2.0),
    _ => const V3(32, 4.5, 5),
  };

  static JScene build(JewelryDesign d) {
    final tally = JTally();
    final density = d.metal.density(d.purity);
    final parts = <JPart>[];
    final stones = <JTracedStone>[];
    final rigids = <JRigid>[];
    final ropes = <JRope>[];
    final frames = <JRopeFrame>[];
    final skins = <JChainSkin>[];
    final barHalf = _barHalf(d);
    final bar = JBoxCollider(V3.zero, barHalf, math.min(3.2, barHalf.z * 0.9));
    var lowest = 0.0;
    var centreCt = 0.0;
    final head = d.headSpec;

    final stone = d.hasCentreStone ? JewelryStone.of(d.stone) : null;

    for (final side in const [-1.0, 1.0]) {
      final x = side * _holeX;
      final hole = V3(x, 0, 0);
      switch (d.earringStyle) {
        case EarringStyle.stud:
          final s = stone!;
          final v0 = tally.metalVolume;
          final zc = barHalf.z + 0.2 + s.depthMm / 2 + 0.6;
          final face = SceneKit.facingFront(d.stone.shape, V3(x, 0, zc));
          final mb = MeshBuilder();
          final headMb = MeshBuilder();
          SettingBuilder.build(
            headMb,
            s,
            tally,
            head: head,
            baseY: barHalf.z + 0.2 - zc,
            seed: side > 0 ? 3 : 7,
          );
          mb.addMesh(headMb.build(), face);
          _postAndBack(mb, tally, hole, barHalf, d.earringBack);
          final mesh = mb.build();
          final node = JNode();
          parts.add(JPart(mesh, node));
          stones.add(JTracedStone(s, node, face));
          centreCt += s.spec.carat;
          final grams = (tally.metalVolume - v0) * density / 1000;
          // A screw back clamps hardest, a butterfly least.
          final hz = switch (d.earringBack) {
            EarringBack.butterfly => const V3(6.5, 7.5, 6.5),
            EarringBack.disc => const V3(8.0, 8.5, 8.0),
            EarringBack.screw => const V3(9.5, 10.5, 9.5),
          };
          rigids.add(
            JRigid.tuned(
              node: node,
              pivot: hole,
              masses: [
                ...SceneKit.massOf(mesh, grams),
                (face.t, SceneKit.stoneGrams(s.spec.carat)),
              ],
              hz: hz,
              zeta: const V3(0.45, 0.5, 0.45),
              stick: const V3(0.004, 0.004, 0.004),
              touchPoints: SceneKit.touchOf(mesh, samples: 60),
              touchNormals: SceneKit.touchNormalsOf(mesh, samples: 60),
            ),
          );
          lowest = math.min(lowest, -SceneKit.reachUp(s, face) - 2);
        case EarringStyle.drop:
          final s = stone!;
          final (anchor, hook) = _fitting(
            d,
            parts,
            tally,
            hole,
            barHalf,
            side,
            density,
          );
          // Jump rings, then the drop.
          const linkW = 1.3;
          final pitch = SceneKit.linkPitch(ChainStyle.cable, linkW);
          final pendant = PendantBuilder.build(
            s,
            head,
            tally,
            bail: 0.9,
            seed: side > 0 ? 11 : 17,
          );
          final rings = d.dropLinks;
          final first = hook == null ? 0 : 1;
          final rope = JRope(first + rings + 2, friction: 0.6, passes: 10);
          final top = hook == null ? anchor : hook.$1;
          if (hook == null) {
            rope.place(0, anchor);
          } else {
            // The hook pivots where it bears in the hole.
            rope
              ..place(0, anchor)
              ..place(1, hook.$1, mass: hook.$2, r: 0.6, drag: 0.05);
            rope.link(0, 1, (hook.$1 - anchor).length);
            // The hook's front wire meets the bar's face if it swings
            // back more than a little.
            final face = hook.$1.z - 1.8;
            rope.own[1] = JFieldCollider((x, y, z, n) {
              n[0] = 0;
              n[1] = 0;
              n[2] = 1;
              return z - face;
            });
          }
          for (var i = 1; i <= rings; i++) {
            // Jump rings weigh a few hundredths of a gram.
            rope.place(
              first + i,
              top - V3(0, pitch * i, 0),
              mass: 0.03,
              r: 0.4,
              drag: 0.05,
            );
            rope.link(first + i - 1, first + i, pitch, maxOnly: true);
          }
          final bailAt = first + rings;
          final com = bailAt + 1;
          final pm = pendant.grams(density) + SceneKit.stoneGrams(s.spec.carat);
          rope.place(
            com,
            top - V3(0, pitch * rings + pendant.comDrop, 0),
            mass: pm,
            r: s.depthMm * 0.45,
            drag: 0.05,
          );
          rope
            ..link(bailAt, com, pendant.comDrop)
            ..colliders.add(bar);
          // Wire on wire: μ ≈ 0.4 on a 0.3 mm jump ring wire.
          rope.chainJoints(0, bailAt, 0.12);
          rope.joint(bailAt - 1, bailAt, com, arm: 0.12);
          ropes.add(rope);
          final linkMesh = SceneKit.link(ChainStyle.cable, linkW);
          final linkNodes = [for (var i = 0; i < rings; i++) JNode()];
          for (final n in linkNodes) {
            parts.add(JPart(linkMesh, n));
          }
          skins.add(
            JChainSkin(
              rope: rope,
              nodes: linkNodes,
              pitch: pitch,
              from: first,
              to: bailAt,
              front: (_) => V3.unitZ,
            ),
          );
          if (hook != null) {
            frames.add(
              JRopeFrame(
                node: hook.$3,
                rope: rope,
                bail: 0,
                com: 1,
                front: (_) => V3.unitZ,
              ),
            );
          }
          final node = JNode();
          parts.add(JPart(pendant.mesh, node));
          stones.add(JTracedStone(s, node, pendant.stoneAt));
          frames.add(
            JRopeFrame(
              node: node,
              rope: rope,
              bail: bailAt,
              com: com,
              front: (_) => V3.unitZ,
            ),
          );
          centreCt += s.spec.carat;
          lowest = math.min(lowest, top.y - pitch * rings - pendant.length);
        case EarringStyle.hoop:
        case EarringStyle.huggie:
          final huggie = d.earringStyle == EarringStyle.huggie;
          final mb = MeshBuilder();
          final outer = d.hoopDiameterMm / 2;
          final thick = huggie ? 1.5 : d.hoopWireMm;
          final wide = huggie ? 2.6 : d.hoopWireMm;
          final a = outer - thick / 2;
          final b = !huggie && d.hoopShape == HoopShape.oval ? a * 1.35 : a;
          // The hoop circles in the y–z plane through its hole; its
          // front (+z) faces the viewer.
          final shank = Shank(
            style: ShankStyle.straight,
            profile: huggie ? BandProfile.flat : BandProfile.comfort,
            rMid: a,
            b: b,
            thickness: thick,
            width: wide,
            centre: V3(x, -b + barHalf.y * 0.2, 0),
            ex: V3.unitZ,
            ey: V3.unitY,
            ez: V3.unitX,
            hasHead: false,
            gapAt: math.pi / 2,
            gapHalf: d.hoopClosure == HoopClosure.endless ? 0.06 : 0,
          );
          final v0 = mb.solidVolume;
          shank.build(mb, milgrain: d.milgrain);
          _closure(mb, shank, d.hoopClosure, thick);
          tally.metalVolume += mb.solidVolume - v0;
          if (d.bandAccent != BandAccent.plain) {
            BandStones.place(
              mb,
              tally,
              shank,
              coverage: d.bandAccent,
              setting: d.accentSetting,
              centreAt: 0,
              seed: side * 7,
            );
          }
          final mesh = mb.build();
          final node = JNode();
          parts.add(JPart(mesh, node));
          final grams = (mb.solidVolume - v0) * density / 1000;
          rigids.add(
            JRigid.tuned(
              node: node,
              pivot: V3(x, barHalf.y * 0.2, 0),
              masses: SceneKit.massOf(mesh, grams),
              // Free to swing sideways and fore–aft; the hole stops it
              // twisting round. The wire rubs in the hole as it swings.
              hz: const V3(0, 4.0, 0),
              zeta: const V3(0.01, 0.3, 0.01),
              mu: huggie ? 0.35 : 0.25,
              arm: V3(wide / 2, 0, thick / 2),
              stick: const V3(0, 0.01, 0),
              touchPoints: SceneKit.touchOf(mesh, samples: 60),
              touchNormals: SceneKit.touchNormalsOf(mesh, samples: 60),
            ),
          );
          lowest = math.min(lowest, -2 * b - thick);
      }
    }

    final barMesh = MeshBuilder()
      ..roundedBox(V3.zero, barHalf, JTag.velvet(1), roundness: 0.22, res: 22);
    parts.add(JPart(barMesh.build(), JNode()));

    final physics = JPhysics(
      rigids: rigids,
      ropes: ropes,
      frames: frames,
      skins: skins,
    );
    physics.settle(seconds: ropes.isEmpty ? 0.1 : 1.5);
    final grams = tally.metalVolume * density / 1000;
    final height = -lowest + barHalf.y;
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

  /// A drop's fitting. Returns where its chain hangs from (pinned) and,
  /// for a hook that pivots in the hole, the hook's loop position, its
  /// grams and its node.
  static (V3, (V3, double, JNode)?) _fitting(
    JewelryDesign d,
    List<JPart> parts,
    JTally tally,
    V3 hole,
    V3 barHalf,
    double side,
    double density,
  ) {
    final x = hole.x;
    if (d.dropFitting == DropFitting.post) {
      // A small bezel-set stone on a post, a ring below.
      final topZ = barHalf.z + 1.6;
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
      top.tube(rim, 0.35, JTag.head(1), sides: 6, closed: true);
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
      _postAndBack(top, tally, hole, barHalf, d.earringBack);
      parts.add(JPart(top.build(), JNode()));
      return (V3(x, loopY - 0.75, topZ), null);
    }
    // A wire hook through the hole: it bears on the hole's top and
    // swings from there. Built in the world at rest, then moved into the
    // frame its rope pair (pivot → loop) gives it.
    final lever = d.dropFitting == DropFitting.leverBack;
    const wire = 0.42;
    final drop = lever ? 9.0 : 11.0;
    final zf = barHalf.z + 0.9, zb = -(barHalf.z + 1.0);
    // It bears on the hole's front edge, so it hangs in front of the bar.
    final pivot = V3(x, 0.6, zf);
    final loop = V3(x, -drop, zf);
    final mb = MeshBuilder();
    final path = smoothPath([
      loop + const V3(0, 0.9, 0),
      V3(x, -drop * 0.35, zf + 0.35),
      V3(x, 1.4, zf - 0.2),
      V3(x, 0.6, 0),
      V3(x, 0.8, zb + 0.4),
      V3(x, -drop * 0.25, zb - 0.6),
      V3(x, -drop * (lever ? 0.95 : 0.8), zb - 0.4),
    ], steps: 5);
    mb.tube(path, wire, JTag.metal(1), sides: 7);
    // The loop the jump ring hangs from.
    mb.tube(
      [
        for (var i = 0; i < 14; i++)
          loop +
              V3(
                0,
                0.9 * math.cos(2 * math.pi * i / 14),
                0.9 * math.sin(2 * math.pi * i / 14),
              ),
      ],
      wire * 0.8,
      JTag.metal(1),
      sides: 6,
      closed: true,
    );
    if (lever) {
      // The hinged lever closes under the bar onto the front frame.
      mb.tube(
        smoothPath([
          V3(x, -drop * 0.95, zb - 0.4),
          V3(x, -drop * 1.2, 0),
          loop + const V3(0, -0.6, -0.5),
        ], steps: 5),
        wire * 0.85,
        JTag.metal(0.9),
        sides: 6,
      );
      // A small decorative frame in front.
      mb.tube(
        smoothPath([
          loop + const V3(0, 0.9, 0.1),
          V3(x - 1.4, -drop * 0.55, zf + 0.25),
          V3(x, -drop * 0.18, zf + 0.25),
          V3(x + 1.4, -drop * 0.55, zf + 0.25),
          loop + const V3(0, 0.9, 0.1),
        ], steps: 4),
        wire * 0.75,
        JTag.metal(1),
        sides: 6,
      );
    }
    tally.metalVolume += mb.solidVolume;
    final grams = math.max(0.05, mb.solidVolume * density / 1000);
    final rest = Xf.lookUp(pivot - loop, V3.unitZ, pivot);
    final local = rest.inverse;
    final mesh = MeshBuilder()..addMesh(mb.build(), local);
    final node = JNode();
    parts.add(JPart(mesh.build(), node));
    return (pivot, (loop, grams, node));
  }

  /// A hoop's closure at its top (where it passes through the hole).
  static void _closure(
    MeshBuilder mb,
    Shank s,
    HoopClosure closure,
    double thick,
  ) {
    final topAt = s.point(math.pi / 2);
    switch (closure) {
      case HoopClosure.hinged:
        // The hinge's barrel behind the card, the snap post in front.
        final back = s.point(math.pi / 2 + 0.55);
        mb.tube(
          [back - V3(thick * 0.6, 0, 0), back + V3(thick * 0.6, 0, 0)],
          thick * 0.62,
          JTag.metal(0.9),
          sides: 8,
        );
        final front = s.point(math.pi / 2 - 0.35);
        mb.sphere(front, thick * 0.56, JTag.metal(1), segments: 8, rings: 5);
      case HoopClosure.latch:
        // A straight post through the ear and a latch wire behind.
        mb.tube(
          [topAt + V3(0, thick * 0.3, s.a * 0.35), topAt - V3(0, 0, s.a * 0.4)],
          thick * 0.28,
          JTag.metal(0.9),
          sides: 6,
        );
        mb.tube(
          smoothPath([
            s.point(math.pi / 2 + 0.3),
            s.point(math.pi / 2 + 0.8) - s.outward(math.pi / 2 + 0.8) * thick,
            s.point(math.pi / 2 + 1.2),
          ], steps: 4),
          thick * 0.22,
          JTag.metal(0.85),
          sides: 6,
        );
      case HoopClosure.endless:
        // A fine wire bridges the gap into the hollow tube.
        mb.tube(
          [s.point(math.pi / 2 - 0.12), s.point(math.pi / 2 + 0.12)],
          thick * 0.18,
          JTag.metal(0.85),
          sides: 6,
        );
    }
  }

  /// A post through the bar and the back that holds it.
  static void _postAndBack(
    MeshBuilder mb,
    JTally tally,
    V3 hole,
    V3 barHalf,
    EarringBack back,
  ) {
    final before = mb.solidVolume;
    final behind = hole - V3(0, 0, barHalf.z + 1.4);
    mb.tube(
      [hole + V3(0, 0, barHalf.z + 0.6), hole - V3(0, 0, barHalf.z + 2.6)],
      0.42,
      JTag.metal(0.8),
      sides: 6,
    );
    switch (back) {
      case EarringBack.butterfly:
        // Two scrolled wings that grip the post.
        mb.roundedBox(
          behind,
          const V3(2.7, 2.4, 0.9),
          JTag.metal(0.85),
          roundness: 0.6,
          res: 8,
        );
        for (final sx in const [-1.0, 1.0]) {
          mb.tube(
            smoothPath([
              behind + V3(sx * 0.5, 1.6, 0.3),
              behind + V3(sx * 1.6, 0.2, 0.9),
              behind + V3(sx * 0.5, -1.6, 0.3),
            ], steps: 4),
            0.35,
            JTag.metal(0.9),
            sides: 5,
          );
        }
      case EarringBack.screw:
        // A knurled nut on a threaded post.
        mb.surface(
          16,
          4,
          (u, v) {
            final a = 2 * math.pi * u;
            final r = 1.9 + 0.12 * math.cos(a * 8);
            return behind + V3(r * math.cos(a), r * math.sin(a), 1.0 - 2.2 * v);
          },
          (_, _) => JTag.metal(0.85),
          closedU: true,
          outward: (p) => V3(p.x - behind.x, p.y - behind.y, 0),
        );
        for (final z in const [0.8, 0.0, -0.8]) {
          mb.tube(
            [
              for (var i = 0; i < 10; i++)
                hole +
                    V3(
                      0.5 * math.cos(2 * math.pi * i / 10),
                      0.5 * math.sin(2 * math.pi * i / 10),
                      -(barHalf.z + 1.6) + z,
                    ),
            ],
            0.1,
            JTag.metal(0.8),
            sides: 4,
            closed: true,
          );
        }
        mb.solidVolume += math.pi * 1.9 * 1.9 * 2.2;
      case EarringBack.disc:
        // A wide, flat disc that keeps a heavy stud upright.
        mb.roundedBox(
          behind,
          const V3(4.5, 4.5, 0.55),
          JTag.metal(0.85),
          roundness: 1.0,
          res: 12,
        );
    }
    tally.metalVolume += mb.solidVolume - before;
  }
}
