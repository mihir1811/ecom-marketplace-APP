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
/// lowest point. Longer chains fall lower: 16" sits at the base of the
/// neck, 18" on the collarbone, 20" below it, 24" toward the bust.
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
    final linkMesh = SceneKit.link(style, cw);
    final twist = style == ChainStyle.cable || style == ChainStyle.box
        ? JLinkTwist.alternate
        : JLinkTwist.none;
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
    final frontLen = d.chainLength.mm - backLen;

    // The hanging part as particles about 5 mm apart.
    final n = math.max(9, (frontLen / 5).round() | 1);
    final seg = frontLen / (n - 1);
    final pendant = PendantBuilder.build(
      stone,
      d.head,
      d.halo,
      tally,
      bail: 1.2 + cw * 0.5,
      seed: 5,
    );
    final rope = JRope(n + 1, friction: 0.25, passes: 4);
    final linkGrams = linkMesh.volume * density / 1000;
    final perParticle = linkGrams * seg / pitch;
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
        drag: 1.4,
      );
      if (i > 0) rope.link(i - 1, i, seg, maxOnly: true);
    }
    final mid = n ~/ 2;
    final bailAt = rope.at(mid);
    final pm = pendant.grams(density) + SceneKit.stoneGrams(stone.spec.carat);
    rope.place(
      n,
      bailAt - V3(0, pendant.comDrop, 0) + const V3(0, 0, 3),
      mass: pm,
      r: stone.depthMm * 0.5 + 0.6,
      drag: 0.5,
    );
    rope
      ..link(mid, n, pendant.comDrop)
      ..colliders.add(JFieldCollider(bustDistance));

    final links = JChainSkin.linksFor(frontLen, pitch);
    final linkNodes = [for (var i = 0; i < links; i++) JNode()];
    for (final node in linkNodes) {
      parts.add(JPart(linkMesh, node));
    }
    final skin = JChainSkin(
      rope: rope,
      nodes: linkNodes,
      pitch: pitch,
      from: 0,
      to: n - 1,
      front: _chestNormal,
      twist: twist,
    );
    final pendantNode = JNode();
    parts.add(JPart(pendant.mesh, pendantNode));
    final frame = JRopeFrame(
      node: pendantNode,
      rope: rope,
      bail: mid,
      com: n,
      front: _chestNormal,
    );

    // The still chain round the back of the neck: seen only edge-on
    // past the neck's sides, so a plain cord of the chain's width.
    final still = MeshBuilder()
      ..tube(smoothPath(back, steps: 3), cw * 0.42, JTag.metal(0.8), sides: 5);
    parts.add(JPart(still.build(), JNode()));
    parts.add(JPart(_bust(), JNode()));

    final physics = JPhysics(ropes: [rope], frames: [frame], skins: [skin]);
    physics.settle(seconds: 3);

    final low = rope.at(n);
    final chainGrams = linkGrams * (d.chainLength.mm / pitch);
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
        final y = top - (top + 240) * v;
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
