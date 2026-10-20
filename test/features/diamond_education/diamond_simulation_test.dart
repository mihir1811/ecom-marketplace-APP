import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/features/diamond_education/application/diamond_simulator_controller.dart';
import 'package:gemstone/features/diamond_education/domain/average_hand.dart';
import 'package:gemstone/features/diamond_education/domain/cut_grade_estimator.dart';
import 'package:gemstone/features/diamond_education/domain/diamond_grades.dart';
import 'package:gemstone/features/diamond_education/domain/diamond_proportions.dart';
import 'package:gemstone/features/diamond_education/domain/diamond_shape.dart';
import 'package:gemstone/features/diamond_education/domain/diamond_spec.dart';
import 'package:gemstone/features/diamond_education/simulation/sim_inclusions.dart';
import 'package:gemstone/features/diamond_education/simulation/sim_mesh.dart';
import 'package:gemstone/features/diamond_education/simulation/sim_optics.dart';
import 'package:gemstone/features/diamond_education/simulation/sim_tracer.dart';

void main() {
  group('SimMesh', () {
    for (final shape in SimShape.values) {
      for (final grade in CutGrade.values) {
        test(
          '${shape.name} ${grade.name} is a closed, outward-facing solid',
          () {
            final p = DiamondProportions.forGrade(shape, grade);
            final mesh = SimMesh.build(shape, p);
            expect(mesh.facetCount, greaterThan(40));
            expect(mesh.volume, greaterThan(0.5));
            expect(mesh.width, closeTo(2, 0.02));
            expect(mesh.length / mesh.width, closeTo(shape.ratio, 0.1));

            for (var f = 0; f < mesh.facetCount; f++) {
              final nx = mesh.planes[f * 4], ny = mesh.planes[f * 4 + 1];
              final nz = mesh.planes[f * 4 + 2];
              expect(math.sqrt(nx * nx + ny * ny + nz * nz), closeTo(1, 1e-9));
              // The centre lies inside every facet plane.
              expect(mesh.planes[f * 4 + 3], greaterThan(0));
            }
            // Crown and pavilion match the proportions they were cut to.
            // (Curved outlines measure a hair under 2 wide, hence 0.1.)
            expect(mesh.crownHeightPct, closeTo(p.crownHeightPct, 0.1));
            expect(
              mesh.pavilionDepthPct,
              closeTo(p.pavilionDepthPct(shape.family), 0.1),
            );
            expect(
              mesh.totalDepthPct,
              greaterThan(p.approxDepthPct(shape.family) - 0.1),
            );
          },
        );
      }
    }

    test('a heart is traced as a convex half and its mirror image', () {
      final mesh = SimMesh.build(
        SimShape.heart,
        DiamondProportions.ideal(SimShape.heart),
      );
      expect(mesh.mirrorX, isTrue);
      expect(mesh.tracedFacets, lessThan(mesh.facetCount));
      // Every traced facet faces +x or straddles the axis, and the half
      // is convex: no corner of it lies outside any traced plane.
      for (var i = 0; i < mesh.vertexCount; i++) {
        final x = mesh.positions[i * 3];
        if (x < -1e-9) continue;
        expect(
          mesh.inset(x, mesh.positions[i * 3 + 1], mesh.positions[i * 3 + 2]),
          greaterThan(-1e-6),
        );
      }
      final round = SimMesh.build(
        SimShape.round,
        DiamondProportions.ideal(SimShape.round),
      );
      expect(round.mirrorX, isFalse);
      expect(round.tracedFacets, round.facetCount);
    });

    test('ideal shapes have realistic total depth', () {
      for (final shape in SimShape.values) {
        final mesh = SimMesh.build(shape, DiamondProportions.ideal(shape));
        expect(
          mesh.totalDepthPct,
          inInclusiveRange(58, 70),
          reason: shape.name,
        );
      }
    });

    test('table faces up and the culet down', () {
      final mesh = SimMesh.build(
        SimShape.round,
        DiamondProportions.ideal(SimShape.round),
      );
      final table = mesh.kinds.indexOf(SimFacetKind.table.index);
      expect(mesh.planes[table * 4 + 1], closeTo(1, 1e-9));
      final withCulet = SimMesh.build(
        SimShape.round,
        DiamondProportions.ideal(
          SimShape.round,
        ).copyWith(culet: CuletSize.medium),
      );
      final culet = withCulet.kinds.indexOf(SimFacetKind.culet.index);
      expect(withCulet.planes[culet * 4 + 1], closeTo(-1, 1e-9));
    });
  });

  group('SimTracer', () {
    for (final shape in [SimShape.oval, SimShape.heart]) {
      test('returns finite, non-negative light for every view ray '
          '(${shape.name})', () {
        final mesh = SimMesh.build(shape, DiamondProportions.ideal(shape));
        final tracer = SimTracer()..mesh = mesh;
        final rng = math.Random(4);
        for (var i = 0; i < 400; i++) {
          final f = rng.nextInt(mesh.facetCount);
          final s = mesh.facetStart[f];
          final v = mesh.facetVerts[s] * 3;
          final nx = mesh.planes[f * 4], ny = mesh.planes[f * 4 + 1];
          final nz = mesh.planes[f * 4 + 2];
          // A ray striking the facet from outside.
          var dx = -nx + (rng.nextDouble() - 0.5);
          var dy = -ny + (rng.nextDouble() - 0.5);
          var dz = -nz + (rng.nextDouble() - 0.5);
          final l = math.sqrt(dx * dx + dy * dy + dz * dz);
          dx /= l;
          dy /= l;
          dz /= l;
          if (dx * nx + dy * ny + dz * nz >= -0.05) continue;
          tracer.trace(
            f,
            mesh.positions[v],
            mesh.positions[v + 1],
            mesh.positions[v + 2],
            dx,
            dy,
            dz,
          );
          for (final c in [tracer.outR, tracer.outG, tracer.outB]) {
            expect(c.isFinite, isTrue);
            expect(c, greaterThanOrEqualTo(0));
          }
        }
      });
    }
  });

  group('CutGradeEstimator', () {
    test('every grade preset is graded as that grade', () {
      for (final shape in SimShape.values) {
        for (final grade in CutGrade.values) {
          expect(
            CutGradeEstimator.estimate(
              shape,
              DiamondProportions.forGrade(shape, grade),
            ),
            grade,
            reason: '${shape.name} ${grade.name}',
          );
        }
      }
    });
  });

  group('SimInclusions', () {
    test(
      'cleaner grades carry fewer characteristics, all inside the stone',
      () {
        final mesh = SimMesh.build(
          SimShape.round,
          DiamondProportions.ideal(SimShape.round),
        );
        var previous = -1;
        for (final grade in ClarityGrade.values) {
          final list = SimInclusions.generate(mesh, grade);
          expect(
            list.length,
            greaterThanOrEqualTo(previous == -1 ? 0 : previous - 1),
          );
          previous = list.length;
          for (final inc in list) {
            for (var f = 0; f < mesh.facetCount; f++) {
              final p = mesh.planes;
              final d =
                  p[f * 4] * inc.x +
                  p[f * 4 + 1] * inc.y +
                  p[f * 4 + 2] * inc.z;
              expect(d, lessThan(p[f * 4 + 3]));
            }
          }
        }
        expect(SimInclusions.generate(mesh, ClarityGrade.fl), isEmpty);
        final i3 = SimInclusions.generate(mesh, ClarityGrade.i3);
        expect(i3.length, greaterThan(10));
        expect(i3.length, lessThanOrEqualTo(SimInclusions.maxCount));
        // Packed for the shader: kind in the whole part, seed in the
        // fraction, unit axes.
        final packed = SimInclusions.pack(i3);
        expect(packed.length, SimInclusions.maxCount * 8);
        for (var i = 0; i < i3.length; i++) {
          expect(packed[i * 8 + 7].floor(), i3[i].kind.code);
          final ax = packed[i * 8 + 4], ay = packed[i * 8 + 5];
          final az = packed[i * 8 + 6];
          expect(math.sqrt(ax * ax + ay * ay + az * az), closeTo(1, 1e-5));
        }
      },
    );
  });

  group('DiamondSimulatorController', () {
    late ProviderContainer container;
    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    DiamondSimulatorController notifier() =>
        container.read(diamondSimulatorProvider.notifier);
    DiamondSimulatorState state() => container.read(diamondSimulatorProvider);

    test('round sizes match trade size charts', () {
      final sub = container.listen(diamondSimulatorProvider, (_, _) {});
      addTearDown(sub.close);
      // Carat → diameter, as size charts list them.
      for (final (ct, mm) in const [
        (0.5, 5.2),
        (1.0, 6.5),
        (1.5, 7.4),
        (2.0, 8.1),
        (3.0, 9.4),
        (5.0, 11.0),
      ]) {
        notifier().setCarat(ct);
        expect(state().widthMm, closeTo(mm, 0.15), reason: '$ct ct');
      }
    });

    test('derived proportions solve back to their inputs', () {
      final sub = container.listen(diamondSimulatorProvider, (_, _) {});
      addTearDown(sub.close);
      notifier().setCrownHeight(12.5);
      expect(state().mesh.crownHeightPct, closeTo(12.5, 0.05));
      notifier().setPavilionDepth(45);
      expect(state().mesh.pavilionDepthPct, closeTo(45, 0.05));
      notifier().setTotalDepth(64);
      expect(state().mesh.totalDepthPct, closeTo(64, 0.3));
    });

    test('changing shape keeps cut quality; options apply', () {
      final sub = container.listen(diamondSimulatorProvider, (_, _) {});
      addTearDown(sub.close);
      notifier().applyCutGrade(CutGrade.good);
      notifier().setShape(SimShape.emerald);
      expect(state().spec.shape, SimShape.emerald);
      expect(state().estimatedCut, CutGrade.good);
      notifier().setFancyColor(FancyColor.pink);
      expect(state().spec.isFancy, isTrue);
      notifier().setColorGrade(ColorGrade.h);
      expect(state().spec.isFancy, isFalse);
      notifier().setLighting(SimLighting.ultraviolet);
      expect(state().lighting, SimLighting.ultraviolet);
    });

    test('hearts & arrows scope is for well cut rounds only', () {
      final sub = container.listen(diamondSimulatorProvider, (_, _) {});
      addTearDown(sub.close);
      notifier().applyCutGrade(CutGrade.fair);
      notifier().setHeartsArrows(true);
      expect(state().lighting, SimLighting.heartsArrows);
      // Recut precisely, or the pattern could not form.
      expect(state().estimatedCut, CutGrade.excellent);
      notifier().setShape(SimShape.princess);
      expect(state().lighting, SimLighting.daylight);
      notifier().setHeartsArrows(true);
      expect(state().lighting, SimLighting.daylight);
      notifier().setShape(SimShape.round);
      notifier().setHeartsArrows(true);
      notifier().setHeartsArrows(false);
      expect(state().lighting, SimLighting.daylight);
    });

    test('start shape can be scoped per route', () {
      final scoped = ProviderContainer(
        overrides: [
          simulatorStartShapeProvider.overrideWithValue(SimShape.heart),
        ],
      );
      addTearDown(scoped.dispose);
      expect(scoped.read(diamondSimulatorProvider).spec.shape, SimShape.heart);
    });
  });

  group('Inclusions, BGM and treatment', () {
    final mesh = SimMesh.build(
      SimShape.round,
      DiamondProportions.ideal(SimShape.round),
    );

    test('chosen inclusion kinds are the only ones placed', () {
      final only = SimInclusions.generate(
        mesh,
        ClarityGrade.vs1,
        only: {InclusionType.carbon, InclusionType.needle},
      );
      expect(only, isNotEmpty);
      expect(only.map((i) => i.kind).toSet(), {
        SimInclusionKind.darkCrystal,
        SimInclusionKind.needle,
      });
      expect(
        SimInclusions.generate(
          mesh,
          ClarityGrade.fl,
          only: {InclusionType.cloud},
        ),
        isEmpty,
      );
    });

    test('laser drilling bleaches dark crystals and bores channels', () {
      final plain = SimInclusions.generate(mesh, ClarityGrade.si2);
      final drilled = SimInclusions.generate(
        mesh,
        ClarityGrade.si2,
        enhancement: Enhancement.laserDrilling,
      );
      expect(
        drilled.where((i) => i.kind == SimInclusionKind.darkCrystal),
        isEmpty,
      );
      expect(
        drilled.where((i) => i.kind == SimInclusionKind.laserDrillHole).length,
        greaterThan(
          plain.where((i) => i.kind == SimInclusionKind.laserDrillHole).length,
        ),
      );
      // Each tunnel opens on a facet.
      for (final h in drilled.where(
        (i) => i.kind == SimInclusionKind.laserDrillHole,
      )) {
        expect(h.open, isTrue);
      }
    });

    test('brown warms the stone, milky veils it, HPHT clears brown', () {
      final base = DiamondSpec.initial();
      final brown = base.copyWith(brown: TingeLevel.medium);
      expect(brown.absorption.b, greaterThan(base.absorption.b));
      expect(
        brown.copyWith(enhancement: Enhancement.hpht).absorption.b,
        lessThan(base.absorption.b),
      );
      final milky = SimOptics.of(
        base.copyWith(milky: MilkyLevel.strongly),
        SimLighting.daylight,
      );
      expect(milky.milk, greaterThan(0.05));
    });
  });

  group('SimHandController', () {
    late ProviderContainer container;
    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('each finger keeps its own stone', () {
      final sub = container.listen(simHandProvider, (_, _) {});
      addTearDown(sub.close);
      final stone = container.read(diamondSimulatorProvider.notifier);
      final hand = container.read(simHandProvider.notifier);
      hand.show(true);
      stone.setColorGrade(ColorGrade.f);
      stone.setCarat(1.5);

      hand.select(HandFinger.forefinger);
      final second = container.read(diamondSimulatorProvider);
      expect(second.spec.shape, isNot(SimShape.round));
      stone
        ..setCarat(0.5)
        ..setColorGrade(ColorGrade.j);

      final h = container.read(simHandProvider);
      expect(h.active, HandFinger.forefinger);
      final ring = h.parked[HandFinger.ring]!.spec;
      expect(ring.carat, 1.5);
      expect(ring.colorGrade, ColorGrade.f);

      hand.select(HandFinger.ring);
      expect(container.read(diamondSimulatorProvider).spec.carat, 1.5);
      expect(
        container
            .read(simHandProvider)
            .parked[HandFinger.forefinger]!
            .spec
            .colorGrade,
        ColorGrade.j,
      );

      hand.remove(HandFinger.ring);
      expect(container.read(simHandProvider).count, 1);
      expect(container.read(diamondSimulatorProvider).spec.carat, 0.5);
      hand.remove(HandFinger.forefinger);
      expect(container.read(simHandProvider).count, 1);
    });

    test('fingers match average ring sizes, stones sit mid-finger', () {
      expect(AverageHand.ring.seatWidth, closeTo(16.5, 0.2));
      expect(AverageHand.ring.usRingSize, closeTo(6, 0.3));
      expect(AverageHand.middle.usRingSize, closeTo(7, 0.4));
      expect(AverageHand.index.usRingSize, closeTo(6.5, 0.4));
      expect(AverageHand.little.usRingSize, closeTo(4, 0.4));
      // The ring seat is the origin.
      expect(AverageHand.ring.seatPoint.x, closeTo(0, 1e-9));
      expect(AverageHand.ring.seatPoint.y, closeTo(0, 1e-9));
    });
  });
}
