import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/features/diamond_education/domain/diamond_proportions.dart';
import 'package:gemstone/features/diamond_education/domain/diamond_shape.dart';
import 'package:gemstone/features/diamond_education/domain/diamond_spec.dart';
import 'package:gemstone/features/jewelry_education/domain/jewelry_design.dart';
import 'package:gemstone/features/jewelry_education/domain/jewelry_metal.dart';
import 'package:gemstone/features/jewelry_education/geometry/jewelry_stone.dart';
import 'package:gemstone/features/jewelry_education/geometry/jmath.dart';
import 'package:gemstone/features/jewelry_education/physics/jewelry_physics.dart';
import 'package:gemstone/features/jewelry_education/scene/jewelry_scene.dart';
import 'package:gemstone/features/jewelry_education/scene/scene_factory.dart';

JewelryDesign _design(JewelryType type, {SimShape shape = SimShape.round}) =>
    JewelryDesign.initial(
      type: type,
      stone: DiamondSpec(
        shape: shape,
        proportions: DiamondProportions.ideal(shape),
      ),
    );

void _expectFinite(JScene s) {
  for (final p in s.parts) {
    for (final v in p.mesh.pos) {
      expect(v.isFinite, isTrue);
    }
    for (final v in p.node.xf) {
      expect(v.isFinite, isTrue);
    }
  }
}

/// The lowest point a finger can find: a drop's pendant rather than the
/// light jump ring above it, a bracelet's free hanging bottom rather
/// than where it rests on the rod.
JTouch _lowest(JScene s) =>
    s.physics.touchables().reduce((a, b) => a.world.y <= b.world.y ? a : b);

void main() {
  test('every type and variant builds finite, settled geometry', () {
    final variants = <JewelryDesign>[
      for (final t in JewelryType.values) _design(t),
      for (final shape in SimShape.values)
        _design(
          JewelryType.ring,
          shape: shape,
        ).copyWith(halo: HaloStyle.single, bandAccent: BandAccent.pave),
      _design(JewelryType.ring).copyWith(
        threeStone: true,
        cathedral: true,
        head: HeadStyle.bezel,
        halo: HaloStyle.double,
        bandAccent: BandAccent.eternity,
        bandProfile: BandProfile.knifeEdge,
      ),
      for (final style in EarringStyle.values)
        _design(
          JewelryType.earrings,
        ).copyWith(earringStyle: style, bandAccent: BandAccent.pave),
      for (final style in ChainStyle.values)
        _design(
          JewelryType.necklace,
        ).copyWith(chainStyle: style, halo: HaloStyle.single),
      for (final len in ChainLength.values)
        _design(JewelryType.necklace).copyWith(chainLength: len),
      for (final style in BraceletStyle.values)
        _design(
          JewelryType.bracelet,
        ).copyWith(braceletStyle: style, bandAccent: BandAccent.pave),
    ];
    for (final d in variants) {
      final s = JewelrySceneFactory.build(d);
      expect(s.parts, isNotEmpty, reason: '$d');
      _expectFinite(s);
      expect(s.physics.moving, isFalse, reason: '${d.type} settles at rest');
      expect(s.facts.metalGrams, greaterThan(0.2), reason: '${d.type}');
    }
  });

  test('a solitaire ring weighs what a real one does', () {
    final s = JewelrySceneFactory.build(_design(JewelryType.ring));
    // An 18K, 2.2 mm comfort band with a six-prong head: about 3–6 g.
    expect(s.facts.metalGrams, inInclusiveRange(2.0, 7.0));
    expect(s.stones, hasLength(1));
  });

  test('longer chains hang lower', () {
    double low(ChainLength l) {
      final s = JewelrySceneFactory.build(
        _design(JewelryType.necklace).copyWith(chainLength: l),
      );
      final rope = s.physics.ropes.first;
      return rope.at(rope.n - 1).y;
    }

    final drops = [for (final l in ChainLength.values) low(l)];
    for (var i = 1; i < drops.length; i++) {
      expect(drops[i], lessThan(drops[i - 1] - 8));
    }
  });

  test('a tap sets each piece moving, and it comes back to rest', () {
    for (final t in JewelryType.values) {
      final s = JewelrySceneFactory.build(
        _design(t).copyWith(earringStyle: EarringStyle.drop),
      );
      final touch = _lowest(s);
      final before = touch.world;
      s.physics.poke(touch, const V3(1, 0.2, -0.2), 150);
      for (var i = 0; i < 6; i++) {
        s.physics.advance(1 / 60);
      }
      expect(s.physics.moving, isTrue, reason: '$t moves after a tap');
      expect((touch.world - before).length, greaterThan(0.05), reason: '$t');
      for (var i = 0; i < 60 * 12; i++) {
        s.physics.advance(1 / 60);
      }
      expect(s.physics.moving, isFalse, reason: '$t settles again');
      expect((touch.world - before).length, lessThan(3), reason: '$t returns');
    }
  });

  test('a pendulum swings at its natural period', () {
    // A 1 g mass on a 20 mm link: T = 2π√(L/g) ≈ 0.284 s.
    final rope = JRope(2)
      ..place(0, V3.zero)
      ..place(1, const V3(2, -19.9, 0), mass: 1, drag: 0)
      ..link(0, 1, 20);
    final world = JPhysics(ropes: [rope]);
    final xs = <double>[];
    for (var i = 0; i < 480; i++) {
      world.advance(1 / 480);
      xs.add(rope.at(1).x);
    }
    final crossings = <int>[];
    for (var i = 1; i < xs.length; i++) {
      if (xs[i - 1] < 0 && xs[i] >= 0) crossings.add(i);
    }
    expect(crossings.length, greaterThanOrEqualTo(2));
    final period = (crossings[1] - crossings[0]) / 480;
    expect(period, closeTo(0.284, 0.01));
  });

  test('metal colours follow karat and the stone outline is centred', () {
    final y22 = JewelryMetal.yellowGold.f0(MetalPurity.k22);
    final y10 = JewelryMetal.yellowGold.f0(MetalPurity.k10);
    expect(y22.b, lessThan(y10.b));
    for (final shape in SimShape.values) {
      final s = JewelryStone.of(
        DiamondSpec(shape: shape, proportions: DiamondProportions.ideal(shape)),
      );
      var minX = double.infinity, maxX = -double.infinity;
      var minZ = double.infinity, maxZ = -double.infinity;
      for (var i = 0; i < 128; i++) {
        final p = s.outline(i / 128);
        minX = minX < p.x ? minX : p.x;
        maxX = maxX > p.x ? maxX : p.x;
        minZ = minZ < p.z ? minZ : p.z;
        maxZ = maxZ > p.z ? maxZ : p.z;
      }
      // Same span as the traced mesh's girdle.
      var mMinX = double.infinity, mMaxX = -double.infinity;
      final pos = s.mesh.positions;
      for (var i = 0; i < s.mesh.vertexCount; i++) {
        final x = pos[i * 3] * s.mmPerUnit;
        mMinX = mMinX < x ? mMinX : x;
        mMaxX = mMaxX > x ? mMaxX : x;
      }
      expect(minX, closeTo(mMinX, 0.1), reason: '$shape');
      expect(maxX, closeTo(mMaxX, 0.1), reason: '$shape');
      expect((minZ + maxZ).abs(), lessThan(0.1), reason: '$shape');
    }
  });
}
