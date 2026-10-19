import 'dart:math' as math;

import '../domain/jewelry_design.dart';
import '../geometry/jewelry_stone.dart';
import '../geometry/jmath.dart';
import '../geometry/jmesh.dart';
import 'jewelry_scene.dart';
import 'scene_kit.dart';
import 'setting_builder.dart';

/// A stone hung from a bail: a necklace pendant or an earring drop.
///
/// Pendant frame: the bail's top (where the chain or jump ring bears) at
/// the origin, hanging down −y, face toward +z.
class JPendant {
  JPendant(
    this.mesh,
    this.stoneAt,
    this.length,
    this.metalVolume,
    this._stoneY,
    this._carat,
  );

  final JMesh mesh;

  /// Stone frame → pendant frame.
  final Xf stoneAt;

  /// Bail top to the lowest point, mm.
  final double length;
  final double metalVolume;
  final double _stoneY, _carat;

  double grams(double density) => metalVolume * density / 1000;

  /// How far below the bail the centre of mass hangs: the metal's own
  /// centroid weighed with the stone.
  double get comDrop {
    final c = mesh.centroid;
    final metal = math.max(metalVolume * 0.015, 0.05);
    final stone = SceneKit.stoneGrams(_carat);
    return -(c.y * metal + _stoneY * stone) / (metal + stone);
  }
}

abstract final class PendantBuilder {
  static JPendant build(
    JewelryStone s,
    HeadSpec head,
    JTally tally, {
    BailStyle bailStyle = BailStyle.loop,
    double bail = 1.6,
    double chainWidth = 1.6,
    int seed = 1,
  }) {
    final mb = MeshBuilder();
    final before = tally.metalVolume;
    final rb = (bail * 0.3).clamp(0.3, 0.6);
    final probe = SceneKit.facingFront(s.spec.shape, V3.zero);
    final up = SceneKit.reachUp(s, probe);
    var down = 0.0;
    for (var i = 0; i < 64; i++) {
      down = math.min(down, probe.rotate(s.outline(i / 64)).y);
    }
    final reach = SettingBuilder.totalReach(s, head);
    // Where the head's top sits below the bail's bearing point.
    final hang = switch (bailStyle) {
      BailStyle.loop || BailStyle.pave => 2 * bail + 0.4,
      BailStyle.hidden => bail * 0.6,
      BailStyle.slide => chainWidth * 0.5 + 0.3,
    };
    final cy = -(hang + up + reach * 0.6);
    final at = SceneKit.facingFront(s.spec.shape, V3(0, cy, 0));
    final headMb = MeshBuilder();
    SettingBuilder.build(
      headMb,
      s,
      tally,
      head: head,
      baseY: s.culetY - 0.5,
      seed: seed,
    );
    mb.addMesh(headMb.build(), at);
    final topY = cy + up + reach * 0.6;
    final backZ = s.culetY - 0.2;
    switch (bailStyle) {
      case BailStyle.loop:
      case BailStyle.pave:
        // A loop at right angles to the face, so the chain runs through
        // it from side to side.
        final wide = bailStyle == BailStyle.pave;
        final r = wide ? bail * 1.25 : bail;
        final wr = wide ? rb * 1.5 : rb;
        final loop = [
          for (var i = 0; i < 20; i++)
            V3(
              0,
              -r + r * math.cos(2 * math.pi * i / 20),
              r * math.sin(2 * math.pi * i / 20),
            ),
        ];
        mb.tube(loop, wr, JTag.head(1), sides: 8, closed: true);
        if (wide) {
          // Melee down the bail's front.
          final hs = (wr * 1.4).clamp(0.8, 1.3);
          var k = 0;
          for (var a = -1.2; a <= 1.2; a += hs * 1.1 / r) {
            final n = V3(0, math.sin(a), math.cos(a));
            mb.brilliant(
              V3(0, -r, 0) + n * (r + wr * 0.6),
              n,
              hs,
              k * 0.7,
              around: V3.unitX,
            );
            k++;
          }
          tally.accent(hs, k);
        }
        // A short neck from the bail down to the top of the head.
        mb.tube(
          [V3(0, -2 * r + wr * 0.5, 0), V3(0, topY, s.girdleY * 0.6)],
          rb * 0.95,
          JTag.head(0.95),
          sides: 8,
        );
      case BailStyle.hidden:
        // The loop stands behind the head, out of sight from the front.
        final loop = [
          for (var i = 0; i < 20; i++)
            V3(
              0,
              -bail + bail * math.cos(2 * math.pi * i / 20),
              backZ - bail + bail * math.sin(2 * math.pi * i / 20),
            ),
        ];
        mb.tube(loop, rb, JTag.head(0.85), sides: 8, closed: true);
        mb.tube(
          [V3(0, -bail * 1.6, backZ - bail * 0.4), V3(0, cy, backZ * 0.6)],
          rb,
          JTag.head(0.8),
          sides: 8,
        );
      case BailStyle.slide:
        // A tube across the back of the head: the chain runs through it
        // and the pendant floats on the chain.
        final tr = chainWidth * 0.5 + 0.35;
        final half = math.max(chainWidth * 1.6, s.widthMm * 0.3);
        mb.surface(
          12,
          2,
          (u, v) {
            final a = 2 * math.pi * u;
            return V3(
              -half + 2 * half * v,
              -tr * 0.2 + tr * math.cos(a),
              backZ - tr + tr * math.sin(a),
            );
          },
          (_, _) => JTag.head(0.85),
          closedU: true,
          outward: (p) => V3(0, p.y + tr * 0.2, p.z - (backZ - tr)),
        );
        mb.solidVolume += 2 * half * math.pi * tr * 0.4 * 2;
        mb.tube(
          [V3(0, -tr, backZ - tr), V3(0, cy, backZ * 0.6)],
          rb,
          JTag.head(0.8),
          sides: 8,
        );
    }
    tally.metalVolume += mb.solidVolume;
    return JPendant(
      mb.build(),
      at,
      -cy - down + reach,
      tally.metalVolume - before,
      cy,
      s.spec.carat,
    );
  }
}
