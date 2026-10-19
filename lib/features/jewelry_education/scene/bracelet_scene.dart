import 'dart:math' as math;

import '../domain/jewelry_design.dart';
import '../domain/jewelry_metal.dart';
import '../geometry/jewelry_stone.dart';
import '../geometry/jmath.dart';
import '../geometry/jmesh.dart';
import '../physics/jewelry_physics.dart';
import 'jewelry_scene.dart';
import 'scene_kit.dart';

/// A bracelet hanging over a velvet display rod.
///
/// A tennis bracelet is a closed loop of hinged stone boxes and a chain
/// bracelet a loop of links: both drape over the rod and swing as real
/// flexible chains (point masses, inextensible hinges, limited bending
/// for the boxes). A bangle is rigid and swings from where it rests.
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
        final seg = _tennisSegment(ds, pitch, h);
        final segGrams =
            seg.$2 * density / 1000 +
            SceneKit.stoneGrams(JewelryStone.roundCarat(ds));
        tally
          ..accent(ds, count)
          ..metalVolume += seg.$2 * count;
        final rope = JRope(count, friction: 0.3);
        final cy = _rodR + h / 2 + 0.1 - loopR;
        for (var i = 0; i < count; i++) {
          final a = math.pi / 2 + 2 * math.pi * i / count;
          rope.place(
            i,
            V3(loopR * math.cos(a), cy + loopR * math.sin(a), 0),
            mass: segGrams,
            r: h / 2 + 0.1,
            drag: 0.8,
          );
        }
        final chord = 2 * loopR * math.sin(math.pi / count);
        final chord2 = 2 * loopR * math.sin(2 * math.pi / count);
        for (var i = 0; i < count; i++) {
          rope.link(i, (i + 1) % count, chord);
          // The boxes stop each hinge bending far: a soft limit on every
          // second neighbour.
          rope.link(i, (i + 2) % count, chord2, compliance: 2e-5);
        }
        rope.colliders.add(rod);
        final nodes = [for (var i = 0; i < count; i++) JNode()];
        for (final n in nodes) {
          parts.add(JPart(seg.$1, n));
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
        final pitch = SceneKit.linkPitch(style, cw);
        final linkMesh = SceneKit.link(style, cw);
        final count = math.max(24, (lengthMm / 4).round());
        final seg = lengthMm / count;
        final loopR = lengthMm / (2 * math.pi);
        final linkGrams = linkMesh.volume * density / 1000;
        final rope = JRope(count, friction: 0.3);
        final cy = _rodR + cw / 2 - loopR;
        for (var i = 0; i < count; i++) {
          final a = math.pi / 2 + 2 * math.pi * i / count;
          rope.place(
            i,
            V3(loopR * math.cos(a), cy + loopR * math.sin(a), 0),
            mass: linkGrams * seg / pitch,
            r: cw * 0.45,
            drag: 1.0,
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
        rope.colliders.add(rod);
        final links = JChainSkin.linksFor(lengthMm, pitch);
        final nodes = [for (var i = 0; i < links; i++) JNode()];
        for (final n in nodes) {
          parts.add(JPart(linkMesh, n));
        }
        tally.metalVolume += linkMesh.volume * links;
        physics = JPhysics(
          ropes: [rope],
          skins: [
            JChainSkin(
              rope: rope,
              nodes: nodes,
              pitch: lengthMm / links,
              from: 0,
              to: count - 1,
              front: (_) => V3.unitZ,
              twist: style == ChainStyle.cable || style == ChainStyle.box
                  ? JLinkTwist.alternate
                  : JLinkTwist.none,
              closed: true,
            ),
          ],
        );
        physics.settle(seconds: 2.5);
        height = _lowest(rope);
      case BraceletStyle.bangle:
        // Bangles slip over the hand: about a tenth larger than a chain.
        final r = lengthMm * 1.1 / (2 * math.pi);
        final a = r * 1.06, b = r * 0.94;
        const t = 2.2, w = 4.5;
        final centre = V3(0, _rodR - b + t / 2, 0);
        final profile = bandProfile(BandProfile.comfort, t, w);
        final origins = <V3>[], us = <V3>[], vs = <V3>[];
        const steps = 120;
        for (var i = 0; i < steps; i++) {
          final th = 2 * math.pi * i / steps;
          origins.add(centre + V3(a * math.cos(th), b * math.sin(th), 0));
          us.add(V3(b * math.cos(th), a * math.sin(th), 0).normalized);
          vs.add(V3.unitZ);
        }
        final mb = MeshBuilder()
          ..sweep(
            origins: origins,
            us: us,
            vs: vs,
            profile: profile,
            closedPath: true,
            tagAt: (_, j) => JTag.metal(profile[j].$1 < 0 ? 0.7 : 1),
          );
        tally.metalVolume += mb.solidVolume;
        if (d.bandAccent != BandAccent.plain) {
          final hs = (w * 0.48).clamp(1.2, 2.2);
          final from = d.bandAccent == BandAccent.eternity
              ? 0.0
              : math.pi * 1.1;
          final to = d.bandAccent == BandAccent.eternity
              ? 2 * math.pi
              : math.pi * 1.9;
          final step = hs * 1.12 / r;
          var k = 0;
          for (var th = from; th < to - step * 0.5; th += step) {
            final out = V3(b * math.cos(th), a * math.sin(th), 0).normalized;
            final tangent = V3(
              -a * math.sin(th),
              b * math.cos(th),
              0,
            ).normalized;
            final p =
                centre +
                V3(a * math.cos(th), b * math.sin(th), 0) +
                out * (t / 2 - hs * 0.05);
            mb.brilliant(p, out, hs, k * 0.73, around: tangent);
            k++;
          }
          tally.accent(hs, k);
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
              hz: const V3(0, 1.6, 0),
              zeta: const V3(0.06, 0.2, 0.04),
              touchPoints: SceneKit.touchOf(mesh),
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

  /// One tennis link: a four-prong box with its stone, hinged at each
  /// end. Local x along the bracelet, y out of the stone's table, the
  /// hinge line through the origin. Returns the mesh and its metal mm³.
  static (JMesh, double) _tennisSegment(double ds, double pitch, double h) {
    final mb = MeshBuilder();
    mb.roundedBox(
      V3(0, -h * 0.05, 0),
      V3(pitch * 0.45, h * 0.45, ds * 0.55),
      JTag.metal(0.9),
      roundness: 0.35,
      res: 5,
    );
    final girdle = h * 0.4 + ds * 0.02;
    mb.brilliant(V3(0, girdle, 0), V3.unitY, ds, 0.37, around: V3.unitX);
    final pr = ds * 0.1;
    for (final sx in const [-1.0, 1.0]) {
      for (final sz in const [-1.0, 1.0]) {
        final base = V3(sx * ds * 0.36, h * 0.2, sz * ds * 0.36);
        final tip = V3(sx * ds * 0.36, girdle + ds * 0.09, sz * ds * 0.36);
        mb
          ..tube([base, tip], pr, JTag.metal(1), sides: 4, roundEnds: false)
          ..sphere(tip, pr * 1.1, JTag.metal(1), segments: 5, rings: 3);
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
