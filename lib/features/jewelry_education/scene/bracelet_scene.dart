import 'dart:math' as math;

import '../domain/jewelry_design.dart';
import '../domain/jewelry_metal.dart';
import '../geometry/jewelry_stone.dart';
import '../geometry/jmath.dart';
import '../geometry/jmesh.dart';
import '../physics/jewelry_physics.dart';
import 'band_kit.dart';
import 'jewelry_scene.dart';
import 'scene_kit.dart';

/// A bracelet hanging over a velvet display rod.
///
/// A tennis bracelet is a closed loop of hinged stone boxes and a chain
/// bracelet a loop of links: both drape over the rod and swing as real
/// flexible chains (point masses, inextensible hinges, limited bending
/// for the boxes), their hinge pins and links rubbing with dry friction.
/// The clasp is the heaviest part and settles at the bottom; charms hang
/// from the chain as pendulums of their own. A bangle or cuff is rigid
/// and swings from where it rests, rubbing on the velvet.
abstract final class BraceletScene {
  static const _rodR = 15.0, _rodHalf = 40.0;

  static JScene build(JewelryDesign d) {
    final tally = JTally();
    final density = d.metal.density(d.purity);
    final parts = <JPart>[];
    final lengthMm = d.braceletLengthIn * 25.4;
    final rod = JRodCollider(0, 0, _rodR);
    late final JPhysics physics;
    var height = 60.0;

    switch (d.braceletStyle) {
      case BraceletStyle.tennis:
        final ds = d.accentStoneMm;
        final pitch = ds * 1.12 + 0.2;
        final count = math.max(24, (lengthMm / pitch).round());
        final loopR = count * pitch / (2 * math.pi);
        final h = ds * 0.6;
        final seg = _tennisSegment(d.tennisSetting, ds, pitch, h);
        final segGrams =
            seg.$2 * density / 1000 +
            SceneKit.stoneGrams(JewelryStone.roundCarat(ds));
        final clasp = _boxClasp(pitch, h, ds, d.safetyLatch);
        final claspAt = count ~/ 2;
        tally
          ..accent(ds, count - 1)
          ..metalVolume += seg.$2 * (count - 1) + clasp.$2;
        final rope = JRope(count, friction: 0.3, rocking: 0.12);
        final cy = _rodR + h / 2 + 0.1 - loopR;
        for (var i = 0; i < count; i++) {
          final a = math.pi / 2 + 2 * math.pi * i / count;
          final extra = i == claspAt || i == claspAt + 1
              ? clasp.$2 * density / 1000 / 2 - segGrams / 2
              : 0.0;
          rope.place(
            i,
            V3(loopR * math.cos(a), cy + loopR * math.sin(a), 0),
            mass: segGrams + extra,
            r: h / 2 + 0.1,
            drag: 0.1,
          );
        }
        final chord = 2 * loopR * math.sin(math.pi / count);
        // Neighbouring boxes meet edge to edge once a hinge bends about
        // 35°: a hard stop on how close every second link may come. Short
        // of it the hinge turns freely (with its pin's friction), and the
        // bracelet can lie straight.
        const maxBend = 35 * math.pi / 180;
        final stop = 2 * chord * math.cos(maxBend / 2);
        for (var i = 0; i < count; i++) {
          rope.link(i, (i + 1) % count, chord);
          rope.link(i, (i + 2) % count, stop, minOnly: true);
        }
        // Hinge pins h/5 in radius, metal on metal.
        rope
          ..chainJoints(0, count - 1, 0.35 * h, closed: true)
          ..colliders.add(rod);
        final nodes = [for (var i = 0; i < count; i++) JNode()];
        for (var i = 0; i < count; i++) {
          parts.add(JPart(i == claspAt ? clasp.$1 : seg.$1, nodes[i]));
        }
        physics = JPhysics(
          ropes: [rope],
          skins: [
            JChainSkin(
              rope: rope,
              nodes: nodes,
              pitch: pitch,
              from: 0,
              to: count - 1,
              front: (_) => V3.unitZ,
              closed: true,
              segments: true,
            ),
          ],
        );
        physics.settle(seconds: 2.5);
        height = _lowest(rope);
      case BraceletStyle.chain:
        final cw = d.chainWidthMm + 0.6;
        final style = d.chainStyle;
        final (linkMeshes, offsets, chainVolume) = SceneKit.chain(
          style,
          cw,
          lengthMm,
        );
        final count = math.max(24, (lengthMm / 4).round());
        final seg = lengthMm / count;
        final loopR = lengthMm / (2 * math.pi);
        final linkGrams = chainVolume * density / 1000 / lengthMm;
        final (claspMesh, claspVolume) = SceneKit.clasp(d.clasp, cw);
        final claspGrams = claspVolume * density / 1000;
        final claspAt = count ~/ 2;
        final charmCount = d.charms;
        final rope = JRope(
          count + charmCount,
          friction: 0.3,
          passes: 4,
          rocking: 0.12,
        );
        final cy = _rodR + cw / 2 - loopR;
        for (var i = 0; i < count; i++) {
          final a = math.pi / 2 + 2 * math.pi * i / count;
          rope.place(
            i,
            V3(loopR * math.cos(a), cy + loopR * math.sin(a), 0),
            mass: linkGrams * seg + (i == claspAt ? claspGrams : 0),
            r: cw * 0.45,
            drag: 0.1,
          );
        }
        for (var i = 0; i < count; i++) {
          rope.link(
            i,
            (i + 1) % count,
            2 * loopR * math.sin(math.pi / count),
            maxOnly: true,
          );
        }
        rope
          ..chainJoints(0, count - 1, 0.45 * cw * 0.3, closed: true)
          ..colliders.add(rod);
        // Links, with the clasp in place of one at the bottom.
        final nodes = [for (var i = 0; i < linkMeshes.length; i++) JNode()];
        final claspLink = linkMeshes.length ~/ 2;
        for (var i = 0; i < nodes.length; i++) {
          parts.add(
            JPart(i == claspLink ? claspMesh : linkMeshes[i], nodes[i]),
          );
        }
        tally.metalVolume += chainVolume + claspVolume;
        // Charms on jump rings, about the clasp.
        final frames = <JRopeFrame>[];
        if (charmCount > 0) {
          final (charmMesh, charmVolume) = SceneKit.charm(9);
          final drop = -charmMesh.centroid.y;
          final grams = charmVolume * density / 1000;
          final spread = math.max(2, count ~/ 10);
          for (var c = 0; c < charmCount; c++) {
            // Evenly either side of the clasp, so the loop hangs level.
            final at = (claspAt + (2 * c - (charmCount - 1)) * spread ~/ 2) % count;
            final p = count + c;
            rope
              ..place(
                p,
                rope.at(at) - V3(0, drop, -1),
                mass: grams,
                r: 3,
                drag: 0.1,
              )
              ..link(at, p, drop)
              ..joint(at, at, p, arm: 0.12);
            tally.metalVolume += charmVolume;
            final node = JNode();
            parts.add(JPart(charmMesh, node));
            frames.add(
              JRopeFrame(
                node: node,
                rope: rope,
                bail: at,
                com: p,
                front: (_) => V3.unitZ,
              ),
            );
          }
        }
        physics = JPhysics(
          ropes: [rope],
          frames: frames,
          skins: [
            JChainSkin(
              rope: rope,
              nodes: nodes,
              pitch: lengthMm / nodes.length,
              from: 0,
              to: count - 1,
              front: (_) => V3.unitZ,
              twist: SceneKit.twistOf(style),
              closed: true,
              offsets: offsets,
            ),
          ],
        );
        physics.settle(seconds: 6);
        height = _lowest(rope);
      case BraceletStyle.bangle:
        // Bangles slip over the hand: about a tenth larger than a chain;
        // hinged bangles and cuffs open, so they fit closer.
        final slip = d.bangleStyle == BangleStyle.slipOn ? 1.1 : 1.0;
        final r = lengthMm * slip / (2 * math.pi);
        final oval = d.bangleShape == BangleShape.oval;
        final a = r * (oval ? 1.12 : 1.0), b = r * (oval ? 0.86 : 1.0);
        final w = d.bangleWidthMm;
        final t = (1.6 + w * 0.12).clamp(1.8, 2.8);
        final cuff = d.bangleStyle == BangleStyle.cuff;
        final centre = V3(0, _rodR - b + t / 2, 0);
        final shank = Shank(
          style: ShankStyle.straight,
          profile: d.bandProfile,
          rMid: a,
          b: b,
          thickness: t,
          width: w,
          centre: centre,
          hasHead: false,
          gapAt: -math.pi / 2,
          gapHalf: cuff ? 0.42 : 0,
        );
        final mb = MeshBuilder();
        shank.build(mb, milgrain: d.milgrain);
        if (d.bangleStyle == BangleStyle.hinged) _hingeAndClasp(mb, shank);
        tally.metalVolume += mb.solidVolume;
        if (d.bandAccent != BandAccent.plain) {
          BandStones.place(
            mb,
            tally,
            shank,
            coverage: d.bandAccent,
            setting: d.accentSetting,
            centreAt: -math.pi / 2,
            clear: cuff ? 0.5 : 0,
          );
        }
        final mesh = mb.build();
        final node = JNode();
        parts.add(JPart(mesh, node));
        physics = JPhysics(
          rigids: [
            JRigid.tuned(
              node: node,
              pivot: const V3(0, _rodR, 0),
              masses: SceneKit.massOf(mesh, tally.metalVolume * density / 1000),
              // Swings freely in its plane and fore–aft, rubbing on the
              // velvet rod; the rod stops it turning flat.
              hz: const V3(0, 1.6, 0),
              zeta: const V3(0.01, 0.25, 0.01),
              mu: 0.25,
              arm: V3(w / 2, 0, 1.2),
              stick: const V3(0, 0.01, 0),
              touchPoints: SceneKit.touchOf(mesh),
              touchNormals: SceneKit.touchNormalsOf(mesh),
            ),
          ],
        );
        physics.writeNodes();
        height = _rodR - (centre.y - b - t);
    }

    final rodMesh = MeshBuilder();
    SceneKit.rod(rodMesh, _rodR, _rodHalf);
    parts.add(JPart(rodMesh.build(), JNode()));

    return JScene(
      design: d,
      parts: parts,
      stones: const [],
      physics: physics,
      framing: JFraming(
        focus: V3(0, _rodR - height / 2 - 2, 0),
        radius: math.max(46, height * 0.62),
        yaw: 0.55,
        pitch: 0.18,
      ),
      facts: JFacts(
        metalGrams: tally.metalVolume * density / 1000,
        centreCarats: 0,
        accentCarats: tally.accentCarats,
        accentCount: tally.accentCount,
      ),
    );
  }

  static double _lowest(JRope rope) {
    var low = double.infinity;
    for (var i = 0; i < rope.n; i++) {
      low = math.min(low, rope.at(i).y);
    }
    return _rodR - low;
  }

  /// A hinged bangle's hinge barrel at one side and box clasp at the
  /// other.
  static void _hingeAndClasp(MeshBuilder mb, Shank s) {
    final hinge = s.point(0) + s.outward(0) * (s.thickness * 0.35);
    mb.tube(
      [hinge - V3(0, 0, s.width * 0.55), hinge + V3(0, 0, s.width * 0.55)],
      s.thickness * 0.45,
      JTag.metal(0.9),
      sides: 8,
    );
    for (final z in const [-0.18, 0.18]) {
      mb.tube(
        [
          for (var i = 0; i < 10; i++)
            hinge +
                V3(
                  s.thickness * 0.47 * math.cos(2 * math.pi * i / 10),
                  s.thickness * 0.47 * math.sin(2 * math.pi * i / 10),
                  z * s.width,
                ),
        ],
        0.12,
        JTag.metal(0.75),
        sides: 4,
        closed: true,
      );
    }
    final clasp = s.point(math.pi) + s.outward(math.pi) * (s.thickness * 0.3);
    mb.roundedBox(
      clasp,
      V3(s.thickness * 0.75, s.thickness * 1.6, s.width * 0.52),
      JTag.metal(1),
      roundness: 0.35,
      res: 8,
    );
    // The push-piece of the box clasp.
    mb.roundedBox(
      clasp + s.outward(math.pi) * (s.thickness * 0.8),
      V3(s.thickness * 0.25, s.thickness * 0.5, s.width * 0.2),
      JTag.metal(0.9),
      roundness: 0.6,
      res: 6,
    );
  }

  /// A tennis bracelet's box clasp, the size of a link: local x along
  /// the bracelet, y out. Returns the mesh and its metal mm³.
  static (JMesh, double) _boxClasp(
    double pitch,
    double h,
    double ds,
    bool safety,
  ) {
    final mb = MeshBuilder();
    mb.roundedBox(
      V3(0, h * 0.05, 0),
      V3(pitch * 0.55, h * 0.55, ds * 0.55),
      JTag.metal(1),
      roundness: 0.3,
      res: 6,
    );
    // The tongue's push-piece on top.
    mb.roundedBox(
      V3(pitch * 0.15, h * 0.62, 0),
      V3(pitch * 0.18, h * 0.12, ds * 0.3),
      JTag.metal(0.9),
      roundness: 0.5,
      res: 4,
    );
    if (safety) {
      // A figure-eight on the side, over two small pegs.
      final c = V3(0, 0, ds * 0.6);
      final pts = <V3>[];
      for (var i = 0; i < 24; i++) {
        final t = 2 * math.pi * i / 24;
        pts.add(
          c + V3(pitch * 0.5 * math.sin(t), h * 0.35 * math.sin(2 * t), 0),
        );
      }
      mb.tube(pts, 0.18, JTag.metal(1), sides: 5, closed: true);
    }
    for (final sx in const [-1.0, 1.0]) {
      mb.tube(
        [
          V3(sx * pitch * 0.5, -h * 0.25, -ds * 0.3),
          V3(sx * pitch * 0.5, -h * 0.25, ds * 0.3),
        ],
        h * 0.2,
        JTag.metal(0.8),
        sides: 4,
        roundEnds: false,
      );
    }
    return (mb.build(), mb.solidVolume);
  }

  /// One tennis link: a stone held by four or three prongs, a bezel or a
  /// channel, hinged at each end. Local x along the bracelet, y out of
  /// the stone's table, the hinge line through the origin. Returns the
  /// mesh and its metal mm³.
  static (JMesh, double) _tennisSegment(
    TennisSetting setting,
    double ds,
    double pitch,
    double h,
  ) {
    final mb = MeshBuilder();
    mb.roundedBox(
      V3(0, -h * 0.05, 0),
      V3(pitch * 0.45, h * 0.45, ds * 0.55),
      JTag.metal(0.9),
      roundness: 0.35,
      res: 5,
    );
    final girdle = h * 0.4 + ds * 0.02;
    final sink = setting == TennisSetting.channel ? ds * 0.06 : 0.0;
    mb.brilliant(V3(0, girdle - sink, 0), V3.unitY, ds, 0.37, around: V3.unitX);
    final pr = ds * 0.1;
    void prong(double ang) {
      final dx = math.cos(ang) * ds * 0.36, dz = math.sin(ang) * ds * 0.36;
      final base = V3(dx * 1.1, h * 0.2, dz * 1.1);
      final tip = V3(dx, girdle + ds * 0.09, dz);
      mb
        ..tube([base, tip], pr, JTag.metal(1), sides: 4, roundEnds: false)
        ..sphere(tip, pr * 1.1, JTag.metal(1), segments: 5, rings: 3);
    }

    switch (setting) {
      case TennisSetting.prong4:
        for (final a in const [0.785, 2.356, 3.927, 5.498]) {
          prong(a);
        }
      case TennisSetting.prong3:
        // Alternating three-prong ("martini") heads: two on one side,
        // one on the other.
        for (final a in const [
          math.pi / 2,
          math.pi * 7 / 6,
          math.pi * 11 / 6,
        ]) {
          prong(a);
        }
      case TennisSetting.bezel:
        final r = ds / 2 + pr * 0.6;
        mb.tube(
          [
            for (var i = 0; i < 16; i++)
              V3(
                r * math.cos(2 * math.pi * i / 16),
                girdle + ds * 0.03,
                r * math.sin(2 * math.pi * i / 16),
              ),
          ],
          pr * 1.1,
          JTag.metal(1),
          sides: 5,
          closed: true,
        );
      case TennisSetting.channel:
        // Walls along both sides, end to end so they read as one rail.
        for (final sz in const [-1.0, 1.0]) {
          mb.roundedBox(
            V3(0, girdle - ds * 0.02, sz * (ds / 2 + pr * 0.6)),
            V3(pitch * 0.52, ds * 0.1, pr * 0.9),
            JTag.metal(1),
            roundness: 0.25,
            res: 4,
          );
        }
    }
    // Hinge knuckles.
    for (final sx in const [-1.0, 1.0]) {
      mb.tube(
        [
          V3(sx * pitch * 0.47, -h * 0.25, -ds * 0.3),
          V3(sx * pitch * 0.47, -h * 0.25, ds * 0.3),
        ],
        h * 0.2,
        JTag.metal(0.8),
        sides: 4,
        roundEnds: false,
      );
    }
    return (mb.build(), mb.solidVolume);
  }
}
