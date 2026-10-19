import 'dart:math' as math;

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

JTouch _highest(JScene s) =>
    s.physics.touchables().reduce((a, b) => a.world.y >= b.world.y ? a : b);

/// Runs [s] for [seconds] at 60 fps.
void _run(JScene s, double seconds) {
  for (var i = 0; i < (seconds * 60).round(); i++) {
    s.physics.advance(1 / 60);
  }
}

int _triangles(JScene s) => s.parts.fold(0, (n, p) => n + p.mesh.triangleCount);

void main() {
  final ring = _design(JewelryType.ring);
  final earrings = _design(JewelryType.earrings);
  final necklace = _design(JewelryType.necklace);
  final bracelet = _design(JewelryType.bracelet);

  test('every type and option builds finite, settled geometry', () {
    final variants = <JewelryDesign>[
      for (final t in JewelryType.values) _design(t),
      for (final shape in SimShape.values)
        _design(JewelryType.ring, shape: shape).copyWith(
          halo: HaloStyle.single,
          hiddenHalo: true,
          bandAccent: BandAccent.half,
          prongTip: ProngTip.vTip,
        ),
      for (final head in HeadStyle.values)
        for (final shape in const [SimShape.round, SimShape.pear])
          ring.copyWith(
            head: head,
            stone: DiamondSpec(
              shape: shape,
              proportions: DiamondProportions.ideal(shape),
            ),
            milgrain: true,
          ),
      for (final tip in ProngTip.values)
        for (final gallery in GalleryStyle.values)
          ring.copyWith(prongTip: tip, gallery: gallery),
      for (final shank in ShankStyle.values)
        for (final height in SettingHeight.values)
          ring.copyWith(
            shank: shank,
            settingHeight: height,
            cathedral: shank == ShankStyle.split,
            eastWest: height == SettingHeight.high,
            bandAccent: BandAccent.threeQuarter,
          ),
      for (final a in AccentSetting.values)
        ring.copyWith(bandAccent: BandAccent.eternity, accentSetting: a),
      ring.copyWith(
        threeStone: true,
        cathedral: true,
        head: HeadStyle.bezel,
        halo: HaloStyle.double,
        bandAccent: BandAccent.eternity,
        bandProfile: BandProfile.knifeEdge,
        headMetal: JewelryMetal.platinum,
      ),
      for (final style in EarringStyle.values)
        for (final a in AccentSetting.values)
          earrings.copyWith(
            earringStyle: style,
            bandAccent: BandAccent.half,
            accentSetting: a,
          ),
      for (final back in EarringBack.values)
        earrings.copyWith(earringBack: back),
      for (final fitting in DropFitting.values)
        earrings.copyWith(
          earringStyle: EarringStyle.drop,
          dropFitting: fitting,
          dropLinks: 4,
        ),
      for (final closure in HoopClosure.values)
        earrings.copyWith(
          earringStyle: EarringStyle.hoop,
          hoopClosure: closure,
          hoopShape: HoopShape.oval,
          hoopWireMm: 3,
        ),
      for (final style in ChainStyle.values)
        necklace.copyWith(chainStyle: style, halo: HaloStyle.single),
      for (final len in ChainLength.values) necklace.copyWith(chainLength: len),
      for (final bail in BailStyle.values)
        necklace.copyWith(bail: bail, yDropMm: 30, stations: 4),
      for (final style in BraceletStyle.values)
        bracelet.copyWith(braceletStyle: style, bandAccent: BandAccent.half),
      for (final t in TennisSetting.values)
        bracelet.copyWith(tennisSetting: t, safetyLatch: t.index.isEven),
      for (final b in BangleStyle.values)
        bracelet.copyWith(
          braceletStyle: BraceletStyle.bangle,
          bangleStyle: b,
          bangleShape: BangleShape.oval,
          bangleWidthMm: 8,
          bandAccent: BandAccent.eternity,
          accentSetting: AccentSetting.channel,
        ),
      for (final clasp in ClaspStyle.values)
        bracelet.copyWith(
          braceletStyle: BraceletStyle.chain,
          clasp: clasp,
          charms: 3,
          chainStyle: ChainStyle.figaro,
        ),
    ];
    for (final (i, d) in variants.indexed) {
      final s = JewelrySceneFactory.build(d);
      expect(s.parts, isNotEmpty, reason: '$d');
      _expectFinite(s);
      expect(s.physics.moving, isFalse, reason: 'variant $i (${d.type}) settles at rest');
      expect(s.facts.metalGrams, greaterThan(0.2), reason: '${d.type}');
      // Phones draw about 50k triangles a frame at most.
      expect(_triangles(s), lessThan(60000), reason: '$d');
    }
  });

  test('a solitaire ring weighs what a real one does', () {
    final s = JewelrySceneFactory.build(ring);
    // An 18K, 2.2 mm comfort band with a six-prong head: about 3–6 g.
    expect(s.facts.metalGrams, inInclusiveRange(2.0, 7.0));
    expect(s.stones, hasLength(1));
  });

  test('options change what is built', () {
    int count(JewelryDesign d) =>
        JewelrySceneFactory.build(d).facts.accentCount;
    expect(
      count(ring.copyWith(bandAccent: BandAccent.eternity)),
      greaterThan(count(ring.copyWith(bandAccent: BandAccent.half))),
    );
    expect(count(ring.copyWith(hiddenHalo: true)), greaterThan(count(ring)));
    final stations = JewelrySceneFactory.build(necklace.copyWith(stations: 4));
    expect(stations.facts.accentCount, 4);
    double grams(JewelryDesign d) =>
        JewelrySceneFactory.build(d).facts.metalGrams;
    expect(grams(ring.copyWith(bandWidthMm: 4)), greaterThan(grams(ring)));
    expect(
      grams(
        bracelet.copyWith(
          braceletStyle: BraceletStyle.bangle,
          bangleWidthMm: 9,
        ),
      ),
      greaterThan(
        grams(
          bracelet.copyWith(
            braceletStyle: BraceletStyle.bangle,
            bangleWidthMm: 3,
          ),
        ),
      ),
    );
  });

  test('longer chains hang lower, a Y drop lower still', () {
    double low(JewelryDesign d) {
      final s = JewelrySceneFactory.build(d);
      final rope = s.physics.ropes.first;
      return rope.at(rope.n - 1).y;
    }

    final drops = [
      for (final l in ChainLength.values)
        low(necklace.copyWith(chainLength: l)),
    ];
    for (var i = 1; i < drops.length; i++) {
      expect(drops[i], lessThan(drops[i - 1] - 8));
    }
    expect(low(necklace.copyWith(yDropMm: 40)), lessThan(drops[2] - 25));
  });

  test('a tap sets each piece moving, and it comes back to rest', () {
    for (final d in [
      ring,
      earrings,
      earrings.copyWith(earringStyle: EarringStyle.drop),
      earrings.copyWith(
        earringStyle: EarringStyle.drop,
        dropFitting: DropFitting.frenchHook,
      ),
      earrings.copyWith(earringStyle: EarringStyle.hoop),
      necklace,
      bracelet,
      bracelet.copyWith(braceletStyle: BraceletStyle.chain, charms: 1),
      bracelet.copyWith(braceletStyle: BraceletStyle.bangle),
    ]) {
      final s = JewelrySceneFactory.build(d);
      final touch = d.type == JewelryType.ring ? _highest(s) : _lowest(s);
      final before = touch.world;
      // A fingertip sideways across the piece.
      s.physics.poke(touch, const V3(1, 0.2, -0.2), 150);
      _run(s, 0.1);
      expect(s.physics.moving, isTrue, reason: '${d.type} moves after a tap');
      expect((touch.world - before).length, greaterThan(0.05), reason: '$d');
      _run(s, 10);
      expect(s.physics.moving, isFalse, reason: '$d settles again');
      expect((touch.world - before).length, lessThan(3), reason: '$d returns');
    }
  });

  test('a held stud carries its own weight: tapped, it does not sag', () {
    final s = JewelrySceneFactory.build(earrings);
    final touch = _highest(s);
    final before = touch.world;
    _run(s, 1);
    expect((touch.world - before).length, lessThan(0.05));
    s.physics.poke(touch, const V3(0, 0, -1), 150);
    _run(s, 3);
    expect((touch.world - before).length, lessThan(0.3));
  });

  test('a ring nudged in its slot settles within a couple of rocks', () {
    final s = JewelrySceneFactory.build(ring);
    final touch = _highest(s);
    final before = touch.world;
    s.physics.poke(touch, const V3(0, 0, -1), 140);
    var crossings = 0;
    double? last;
    for (var i = 0; i < 180; i++) {
      s.physics.advance(1 / 60);
      final z = (touch.world - before).z;
      if (last != null && (last < 0) != (z < 0) && z.abs() > 0.05) {
        crossings++;
      }
      last = z;
    }
    // Velvet foam is heavily damped: no jelly wobble.
    expect(crossings, lessThanOrEqualTo(2));
    expect(s.physics.moving, isFalse);
  });

  test('a pendulum swings at its natural period', () {
    // A 1 g mass on a 20 mm link: T = 2π√(L/g) ≈ 0.284 s.
    final rope = JRope(2, pile: 0, roll: 0)
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

  test('joint friction stops a swing dead, as Coulomb friction does', () {
    // Two 1 g links hanging from a pin. Dry friction at each joint takes
    // a fixed bite out of every swing, so it stops within seconds; with
    // no friction (and no air) it would swing on.
    // Fastest speed (mm/s) in the third second after a push.
    double late(double arm) {
      final rope = JRope(3, pile: 0, roll: 0)
        ..place(0, V3.zero)
        ..place(1, const V3(0, -10, 0), mass: 1, drag: 0)
        ..place(2, const V3(0, -20, 0), mass: 1, drag: 0);
      rope
        ..link(0, 1, 10)
        ..link(1, 2, 10)
        ..chainJoints(0, 2, arm);
      final world = JPhysics(ropes: [rope]);
      rope.poke(2, const V3(1, 0, 0), 100);
      var fastest = 0.0;
      for (var i = 0; i < 180; i++) {
        world.advance(1 / 60);
        if (i >= 120) fastest = math.max(fastest, math.sqrt(rope.kinetic));
      }
      return fastest;
    }

    expect(late(0), greaterThan(20));
    expect(late(0.1), lessThan(1.5));
  });

  test('a chain carries its weight in tension', () {
    // 5 g hanging on a light link: tension ≈ m·g = 49 050 µN.
    final rope = JRope(2, pile: 0, roll: 0)
      ..place(0, V3.zero)
      ..place(1, const V3(0, -10, 0), mass: 5, drag: 0)
      ..link(0, 1, 10);
    final world = JPhysics(ropes: [rope]);
    for (var i = 0; i < 60; i++) {
      world.advance(1 / 60);
    }
    expect(rope.tension(0), closeTo(5 * jGravity, 5 * jGravity * 0.02));
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

  test('two-tone keeps one metal unless a second is chosen', () {
    final d = ring.copyWith(headMetal: JewelryMetal.yellowGold);
    expect(d.headMetal, isNull);
    final t = ring.copyWith(headMetal: JewelryMetal.platinum);
    expect(t.settingMetal, JewelryMetal.platinum);
    expect(t.settingPurity, MetalPurity.pt950);
    expect(t.copyWith(clearHeadMetal: true).headMetal, isNull);
  });
}
