import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/features/diamond_education/domain/diamond_grades.dart';
import 'package:gemstone/features/diamond_education/domain/diamond_proportions.dart';
import 'package:gemstone/features/diamond_education/domain/diamond_shape.dart';
import 'package:gemstone/features/diamond_education/simulation/sim_inclusions.dart';
import 'package:gemstone/features/diamond_education/simulation/sim_mesh.dart';

void main() {
  group('Inclusion types', () {
    test('every kind is classed open or closed as GIA practice has it', () {
      for (final t in InclusionType.values) {
        final open = t.isOpen;
        switch (t) {
          case InclusionType.pinpoint ||
              InclusionType.cloud ||
              InclusionType.needle ||
              InclusionType.crystal ||
              InclusionType.carbon ||
              InclusionType.feather ||
              InclusionType.graining ||
              InclusionType.twinningWisp ||
              InclusionType.cleavage ||
              InclusionType.grainCenter:
            expect(open, isFalse, reason: '$t stays inside');
          default:
            expect(open, isTrue, reason: '$t reaches the surface');
        }
      }
    });

    for (final shape in SimShape.values) {
      test('${shape.name}: chosen kinds sit inside, open ones on a facet', () {
        final mesh = SimMesh.build(shape, DiamondProportions.ideal(shape));
        final all = SimInclusions.generate(
          mesh,
          ClarityGrade.si1,
          only: InclusionType.values.toSet(),
        );
        expect(all.length, lessThanOrEqualTo(SimInclusions.maxShown));
        final shown = {
          for (final c in all)
            if (c.kind.labelled) c.kind.type,
        };
        expect(shown, InclusionType.values.toSet());
        for (final c in all) {
          expect(
            mesh.inset(c.x, c.y, c.z),
            greaterThan(0),
            reason: '${c.kind} inside',
          );
          final ax = math.sqrt(c.ax * c.ax + c.ay * c.ay + c.az * c.az);
          expect(ax, closeTo(1, 1e-6));
          if (c.kind.type.isOpen &&
              c.kind != SimInclusionKind.bleachedCrystal) {
            expect(c.open, isTrue, reason: '${c.kind} opens');
            final n = math.sqrt(c.sx * c.sx + c.sy * c.sy + c.sz * c.sz);
            expect(n, closeTo(1, 1e-6));
            // The facet it breaks lies right by it.
            final gap = c.sd - (c.sx * c.x + c.sy * c.y + c.sz * c.z);
            expect(gap, greaterThan(0));
            expect(gap, lessThan(c.size * 1.2 + 0.01), reason: '${c.kind}');
          } else {
            expect(c.open, isFalse, reason: '${c.kind} closed');
          }
        }
      });
    }

    test('picking another kind never moves those already shown', () {
      final mesh = SimMesh.build(
        SimShape.oval,
        DiamondProportions.ideal(SimShape.oval),
      );
      final some = {
        InclusionType.feather,
        InclusionType.knot,
        InclusionType.cloud,
        InclusionType.chip,
      };
      final a = SimInclusions.generate(mesh, ClarityGrade.si1, only: some);
      final b = SimInclusions.generate(
        mesh,
        ClarityGrade.si1,
        only: {...some, InclusionType.needle},
      );
      for (final c in a) {
        expect(
          b.any((d) => d.kind == c.kind && d.x == c.x && d.y == c.y),
          isTrue,
        );
      }
    });

    test('fracture filling opens every feather to the surface', () {
      final mesh = SimMesh.build(
        SimShape.round,
        DiamondProportions.ideal(SimShape.round),
      );
      final filled = SimInclusions.generate(
        mesh,
        ClarityGrade.si2,
        enhancement: Enhancement.fractureFilling,
      );
      final feathers = filled.where(
        (c) => c.kind == SimInclusionKind.filledFeather,
      );
      expect(feathers, isNotEmpty);
      expect(feathers.every((c) => c.open), isTrue);
      expect(filled.where((c) => c.kind == SimInclusionKind.feather), isEmpty);
    });

    test('the picker follows the GIA key to symbols', () {
      expect(giaInternalKey, hasLength(15));
      expect(giaExternalKey, hasLength(9));
      expect(giaInternalKey.any((t) => t.isExternal), isFalse);
      expect(giaExternalKey.every((t) => t.isExternal), isTrue);
      final key = {...giaInternalKey, ...giaExternalKey};
      final codes = {for (final t in key) t.giaCode};
      expect(codes, hasLength(key.length), reason: 'one code per symbol');
      // Kinds outside the key are plotted as one on it.
      for (final t in InclusionType.values) {
        expect(key, contains(t.plotAs), reason: '$t');
      }
    });
  });
}
