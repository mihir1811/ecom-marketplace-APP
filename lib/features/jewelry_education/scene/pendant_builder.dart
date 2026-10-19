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
    HeadStyle head,
    HaloStyle halo,
    JTally tally, {
    double bail = 1.6,
    int seed = 1,
  }) {
    final mb = MeshBuilder();
    final before = tally.metalVolume;
    // The bail: a loop at right angles to the face, so the chain runs
    // through it from side to side.
    final rb = (bail * 0.3).clamp(0.3, 0.6);
    final loop = [
      for (var i = 0; i < 20; i++)
        V3(
          0,
          -bail + bail * math.cos(2 * math.pi * i / 20),
          bail * math.sin(2 * math.pi * i / 20),
        ),
    ];
    mb.tube(loop, rb, JTag.metal(1), sides: 8, closed: true);

    final probe = SceneKit.facingFront(s.spec.shape, V3.zero);
    final up = SceneKit.reachUp(s, probe);
    var down = 0.0;
    for (var i = 0; i < 64; i++) {
      down = math.min(down, probe.rotate(s.outline(i / 64)).y);
    }
    final reach = SettingBuilder.totalReach(s, head, halo);
    final cy = -(2 * bail + 0.4 + up + reach * 0.6);
    final at = SceneKit.facingFront(s.spec.shape, V3(0, cy, 0));
    final headMb = MeshBuilder();
    SettingBuilder.build(
      headMb,
      s,
      tally,
      head: head,
      halo: halo,
      baseY: s.culetY - 0.5,
      seed: seed,
    );
    mb.addMesh(headMb.build(), at);
    // A short neck from the bail down to the top of the head.
    final topY = cy + up + reach * 0.6;
    mb.tube(
      [V3(0, -2 * bail + rb * 0.5, 0), V3(0, topY, s.girdleY * 0.6)],
      rb * 0.95,
      JTag.metal(0.95),
      sides: 8,
    );
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
