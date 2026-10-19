import 'dart:math' as math;
import 'dart:typed_data';

import '../domain/jewelry_design.dart';
import '../domain/jewelry_metal.dart';
import '../geometry/jewelry_stone.dart';
import '../geometry/jmath.dart';
import '../geometry/jmesh.dart';
import '../physics/jewelry_physics.dart';
import 'jewelry_scene.dart';
import 'pendant_builder.dart';
import 'scene_kit.dart';

/// A pendant necklace on a velvet display bust.
///
/// The chain round the back of the neck lies still; from where it leaves
/// the shoulders it hangs free as a chain of point masses, drapes over
/// the chest under gravity with friction, and carries the pendant at its
/// lowest point, or at the end of a Y drop below it. Its links rub on
/// each other under the chain's tension, so a swing dies in a few
/// passes. Longer chains fall lower: 14" is a choker, 16" sits at the
/// base of the neck, 18" on the collarbone, 20–22" below it, 24" toward
/// the bust and 30" (opera) below it.
abstract final class NecklaceScene {
  // The bust, mm: neck an ellipse rx × rz round (0, y, nz).
  static const _rx = 52.0, _rz = 46.0, _nz = -6.0;

  /// Chest surface depth at (x, y), y ≤ 0: leaning forward as it falls,
  /// curving back toward the shoulders.
  static double chestZ(double x, double y) {
    final d = math.max(0.0, -y);
    return 40 - 0.0042 * x * x + 0.18 * d - 0.0002 * d * d;
  }

  static double _shoulderY(double x) {
    final a = math.max(0.0, x.abs() - 40);
    return -4 - 0.12 * a - 0.0035 * a * a;
  }

  /// Distance to the bust (chest or neck), outward normal into [n].
  static double bustDistance(double x, double y, double z, Float64List n) {
    // Neck: an elliptical column, flaring a little into the shoulders.
    final flare = 1 + 0.12 * smoothstep(20, -10, y);
    final ex = x / (_rx * flare), ez = (z - _nz) / (_rz * flare);
    final e = math.sqrt(ex * ex + ez * ez);
    var best = (e - 1) * math.min(_rx, _rz) * flare;
    if (e > 1e-9) {
      final gx = ex / (_rx * flare), gz = ez / (_rz * flare);
      final gl = math.sqrt(gx * gx + gz * gz);
      n[0] = gx / gl;
      n[1] = 0;
      n[2] = gz / gl;
    } else {
      n[0] = 0;
      n[1] = 0;
      n[2] = 1;
    }
    if (y <= _shoulderY(x) + 2) {
      final cz = chestZ(x, y);
      final gx = -0.0084 * x;
      final d = math.max(0.0, -y);
      final gy = -(0.18 - 0.0004 * d);
      final gl = math.sqrt(gx * gx + gy * gy + 1);
      final dist = (z - cz) / gl;
      if (dist < best) {
        best = dist;
        n[0] = -gx / gl;
        n[1] = -gy / gl;
        n[2] = 1 / gl;
      }
    }
    return best;
  }

  static V3 _chestNormal(V3 p) {
    final n = Float64List(3);
    bustDistance(p.x, p.y, p.z, n);
    return V3(n[0], n[1], n[2]);
  }

  static JScene build(JewelryDesign d) {
    final tally = JTally();
    final density = d.metal.density(d.purity);
    final stone = JewelryStone.of(d.stone);
    final cw = d.chainWidthMm;
    final style = d.chainStyle;
    final pitch = SceneKit.linkPitch(style, cw);
    final parts = <JPart>[];

    // Where the chain leaves the shoulders, and its still part behind.
    const ax = 60.0;
    final ay = _shoulderY(ax) - 1.5;
    final az = chestZ(ax, ay) + cw * 0.6;
    final left = V3(-ax, ay, az), right = V3(ax, ay, az);
    final back = <V3>[right];
    for (var i = 0; i <= 24; i++) {
      final a = -0.25 + (math.pi + 0.5) * i / 24;
      back.add(
        V3((_rx + 3) * math.cos(a) * 1.04, -2.5, _nz - (_rz + 3) * math.sin(a)),
      );
    }
    back.add(left);
    var backLen = 0.0;
    for (var i = 0; i < back.length - 1; i++) {
      backLen += (back[i + 1] - back[i]).length;
    }
    // A choker barely clears the anchors; keep it just longer than the
    // straight line between them.
    final frontLen = math.max(d.chainLength.mm - backLen, 2 * ax + 6);

    // The hanging part as particles about 5 mm apart.
    final n = math.max(9, (frontLen / 5).round() | 1);
    final seg = frontLen / (n - 1);
    final pendant = PendantBuilder.build(
      stone,
      d.headSpec,
      tally,
      bailStyle: d.bail,
      bail: 1.2 + cw * 0.5,
      chainWidth: cw,
      seed: 5,
    );
    final yLinks = d.yDropMm <= 0 ? 0 : math.max(2, (d.yDropMm / 4).round());
    final rope = JRope(n + yLinks + 1, friction: 0.25, passes: 4);
    final (linkMeshes, offsets, chainVolume) = SceneKit.chain(
      style,
      cw,
      frontLen,
    );
    final linkGrams = chainVolume * density / 1000 / frontLen;
    final perParticle = linkGrams * seg;
    // Start as a U on the chest; settling drapes it.
    final sag =
        math.sqrt(math.max(0.0, (frontLen / 2) * (frontLen / 2) - ax * ax)) *
        0.9;
    for (var i = 0; i < n; i++) {
      final f = i / (n - 1);
      final px = -ax + 2 * ax * f;
      final py = ay - sag * math.sin(math.pi * f);
      final pz = chestZ(px, py) + cw + 2;
      final pinned = i == 0 || i == n - 1;
      rope.place(
        i,
        pinned ? (i == 0 ? left : right) : V3(px, py, pz),
        mass: pinned ? 0 : perParticle,
        r: cw * 0.5,
        drag: 0.15,
      );
      if (i > 0) rope.link(i - 1, i, seg, maxOnly: true);
    }
    final mid = n ~/ 2;

    // A Y drop: more chain from the V down to the pendant.
    final yPath = <int>[mid];
    var bail = mid;
    if (yLinks > 0) {
      final ySeg = d.yDropMm / yLinks;
      for (var k = 0; k < yLinks; k++) {
        final i = n + k;
        rope.place(
          i,
          rope.at(mid) - V3(0, ySeg * (k + 1), -1),
          mass: linkGrams * ySeg,
          r: cw * 0.5,
          drag: 0.15,
        );
        rope.link(bail, i, ySeg, maxOnly: true);
        yPath.add(i);
        bail = i;
      }
    }
    final com = n + yLinks;
    final pm = pendant.grams(density) + SceneKit.stoneGrams(stone.spec.carat);
    rope.place(
      com,
      rope.at(bail) - V3(0, pendant.comDrop, 0) + const V3(0, 0, 3),
      mass: pm,
      r: stone.depthMm * 0.5 + 0.6,
      drag: 0.15,
    );
    rope
      ..link(bail, com, pendant.comDrop)
      ..colliders.add(JFieldCollider(bustDistance));
    // Link on link: wire sliding on wire (μ ≈ 0.45) where the links
    // bear, about a third of the link's width from the joint. Snake
    // chain's close plates bend stiffly; a bead chain's wire hardly rubs.
    final arm = switch (style) {
      ChainStyle.snake => 0.4 * cw * 0.9,
      ChainStyle.box || ChainStyle.rope => 0.45 * cw * 0.45,
      ChainStyle.bead => 0.2 * cw * 0.1,
      _ => 0.45 * cw * 0.3,
    };
    rope.chainJoints(0, n - 1, arm);
    if (yLinks > 0) {
      rope.joint(mid - 1, mid, yPath[1], arm: arm);
      for (var k = 1; k < yPath.length - 1; k++) {
        rope.joint(yPath[k - 1], yPath[k], yPath[k + 1], arm: arm);
      }
    }
    rope.joint(
      yPath.length > 1 ? yPath[yPath.length - 2] : mid - 1,
      bail,
      com,
      arm: 0.15,
    );

    // Diamond stations, in pairs out from the middle of the chain.
    final linkNodes = [for (var i = 0; i < linkMeshes.length; i++) JNode()];
    final meshes = [...linkMeshes];
    if (d.stations > 0) {
      final dia = (cw * 1.6 + 1.2).clamp(2.4, 4.4);
      final (stationMesh, stationVolume) = SceneKit.station(dia);
      final k = linkMeshes.length;
      for (var j = 0; j < d.stations ~/ 2; j++) {
        for (final sgn in const [-1, 1]) {
          final at = (k / 2 + sgn * k * 0.11 * (j + 1)).round().clamp(0, k - 1);
          meshes[at] = stationMesh;
          tally
            ..accent(dia)
            ..metalVolume += stationVolume;
          // A station weighs on the chain where it sits.
          final pi = (at / k * (n - 1)).round().clamp(1, n - 2);
          final grams =
              stationVolume * density / 1000 +
              SceneKit.stoneGrams(JewelryStone.roundCarat(dia));
          rope.invMass[pi] = 1 / (1 / rope.invMass[pi] + grams);
        }
      }
    }
    for (var i = 0; i < linkNodes.length; i++) {
      parts.add(JPart(meshes[i], linkNodes[i]));
    }
    final skins = [
      JChainSkin(
        rope: rope,
        nodes: linkNodes,
        pitch: pitch,
        from: 0,
        to: n - 1,
        front: _chestNormal,
        twist: SceneKit.twistOf(style),
        offsets: offsets,
      ),
    ];
    if (yLinks > 0) {
      final yLen = d.yDropMm;
      final (yMeshes, yOffsets, yVolume) = SceneKit.chain(style, cw, yLen);
      final yNodes = [for (var i = 0; i < yMeshes.length; i++) JNode()];
      for (var i = 0; i < yNodes.length; i++) {
        parts.add(JPart(yMeshes[i], yNodes[i]));
      }
      tally.metalVolume += yVolume;
      skins.add(
        JChainSkin(
          rope: rope,
          nodes: yNodes,
          pitch: pitch,
          from: 0,
          to: 0,
          path: yPath,
          front: _chestNormal,
          twist: SceneKit.twistOf(style),
          offsets: yOffsets,
        ),
      );
    }
    final pendantNode = JNode();
    parts.add(JPart(pendant.mesh, pendantNode));
    final frame = JRopeFrame(
      node: pendantNode,
      rope: rope,
      bail: bail,
      com: com,
      front: _chestNormal,
    );

    // The still chain round the back of the neck: seen only edge-on
    // past the neck's sides, so a plain cord of the chain's width.
    final still = MeshBuilder()
      ..tube(smoothPath(back, steps: 3), cw * 0.42, JTag.metal(0.8), sides: 5);
    parts.add(JPart(still.build(), JNode()));
    parts.add(JPart(_bust(), JNode()));

    final physics = JPhysics(ropes: [rope], frames: [frame], skins: skins);
    physics.settle(seconds: 3);

    final low = rope.at(com);
    final chainGrams =
        chainVolume / frontLen * d.chainLength.mm * density / 1000;
    final grams = chainGrams + tally.metalVolume * density / 1000;
    return JScene(
      design: d,
      parts: parts,
      stones: [JTracedStone(stone, pendantNode, pendant.stoneAt)],
      physics: physics,
      framing: JFraming(
        focus: V3(0, low.y + (ay - low.y) * 0.42, (az + low.z) / 2),
        radius: math.max(45, (ay - low.y) * 0.5 + 12),
        yaw: 0.32,
        pitch: 0.16,
        yawLimit: 1.1,
        minPitch: -0.2,
        maxPitch: 0.9,
      ),
      facts: JFacts(
        metalGrams: grams,
        centreCarats: stone.spec.carat,
        accentCarats: tally.accentCarats,
        accentCount: tally.accentCount,
      ),
    );
  }

  /// The display bust in velvet: neck, shoulders and upper chest.
  static JMesh _bust() {
    final mb = MeshBuilder();
    final tag = JTag.velvet(1);
    // Neck, the front three quarters (the back stays out of view).
    mb.surface(
      36,
      14,
      (u, v) {
        final a = -0.35 + (math.pi + 0.7) * u;
        final y = -6 + 134 * v;
        final flare = 1 + 0.12 * smoothstep(20, -10, y);
        return V3(
          _rx * flare * math.cos(a),
          y,
          _nz + _rz * flare * math.sin(a),
        );
      },
      (u, v) => JTag.velvet(0.75 + 0.25 * v),
      outward: (p) => V3(p.x, 0, p.z - _nz),
    );
    // Shoulders and chest.
    mb.surface(
      40,
      30,
      (u, v) {
        final x = -150 + 300 * u;
        final top = _shoulderY(x);
        final y = top - (top + 330) * v;
        return V3(x, y, chestZ(x, y));
      },
      (u, v) {
        final x = -150 + 300 * u;
        // A soft shadow where the neck meets the chest.
        final nearNeck = smoothstep(70, 30, x.abs()) * smoothstep(0.12, 0, v);
        return JTag.velvet(1 - 0.35 * nearNeck);
      },
      outward: (_) => V3.unitZ,
    );
    // Cap the neck so it reads as a solid form from above.
    mb.surface(
      36,
      4,
      (u, v) {
        final a = 2 * math.pi * u;
        final r = 1 - v;
        return V3(
          _rx * r * math.cos(a),
          128 + 2 * v,
          _nz + _rz * r * math.sin(a),
        );
      },
      (_, _) => tag,
      closedU: true,
      outward: (_) => V3.unitY,
    );
    return mb.build();
  }
}
