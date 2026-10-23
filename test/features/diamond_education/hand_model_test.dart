import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/features/diamond_education/domain/average_hand.dart';
import 'package:gemstone/features/diamond_education/domain/diamond_proportions.dart';
import 'package:gemstone/features/diamond_education/domain/diamond_shape.dart';
import 'package:gemstone/features/diamond_education/domain/hand_model.dart';
import 'package:gemstone/features/diamond_education/domain/hand_ring.dart';
import 'package:gemstone/features/diamond_education/simulation/hand_renderer.dart';
import 'package:gemstone/features/diamond_education/simulation/hand_ring_mesh.dart';
import 'package:gemstone/features/diamond_education/simulation/sim_mesh.dart';

void main() {
  group('HandModel', () {
    test('fingers are as wide as the trade charts where a ring sits', () {
      final digits = {
        HandFinger.ring: AverageHand.ring,
        HandFinger.middle: AverageHand.middle,
        HandFinger.forefinger: AverageHand.index,
        HandFinger.little: AverageHand.little,
      };
      for (final e in digits.entries) {
        expect(
          HandModel.seat(e.key).halfWidth * 2,
          closeTo(e.value.seatWidth, 0.25),
          reason: '${e.key}',
        );
      }
    });

    test('seats face out of the back of the hand along their finger', () {
      for (final f in HandFinger.values) {
        final s = HandModel.seat(f);
        expect(s.normal.length, closeTo(1, 1e-9));
        expect(s.along.length, closeTo(1, 1e-9));
        expect(s.normal.dot(s.along), closeTo(0, 1e-9));
        expect(s.normal.z, greaterThan(0.8), reason: '$f');
        expect(s.along.y, greaterThan(0.6), reason: '$f');
      }
    });

    test('the bounding sphere holds the whole hand', () {
      final s = HandModel.bounds;
      for (final p in HandModel.outline) {
        expect((p - s.c).length, lessThanOrEqualTo(s.r));
      }
    });

    test('a seat shows from the back of the hand, not from the palm', () {
      HandCamera cam(double yaw) =>
          HandCamera(yaw: yaw, pitch: 0.1, centre: Offset.zero, pxPerMm: 3);
      for (final f in HandFinger.values) {
        final seat = HandModel.seat(f);
        expect(
          HandModel.visibility(seat, cam(-0.18).eye, 3),
          greaterThan(0.9),
          reason: '$f front',
        );
        expect(
          HandModel.visibility(seat, cam(math.pi).eye, 3),
          0,
          reason: '$f palm',
        );
      }
    });
  });

  group('HandMesh', () {
    test('parses the bundled scan and stays inside the bounds', () {
      final bytes = File('assets/models/hand.bin').readAsBytesSync();
      final mesh = HandMesh.parse(ByteData.sublistView(bytes));
      expect(mesh.vertexCount, inInclusiveRange(1000, 65535));
      expect(mesh.triangleCount, greaterThan(1000));
      for (final i in mesh.indices) {
        expect(i, lessThan(mesh.vertexCount));
      }
      final b = HandModel.bounds;
      for (var i = 0; i < mesh.vertexCount; i++) {
        final p = HandVec(
          mesh.positions[i * 3],
          mesh.positions[i * 3 + 1],
          mesh.positions[i * 3 + 2],
        );
        if (p.y < HandModel.fadeEnd) continue;
        expect((p - b.c).length, lessThanOrEqualTo(b.r + 1e-3));
      }
      for (final u in mesh.uvs) {
        expect(u, inInclusiveRange(0, 1));
      }
    });
  });

  group('buildRing', () {
    test('the band rounds the finger clear of the skin; claws hold the '
        'stone without cutting into it, its culet on the band', () {
      for (final shape in [SimShape.round, SimShape.oval]) {
        final stone = SimMesh.build(shape, DiamondProportions.ideal(shape));
        const mm = 3.25;
        var low = 0.0;
        for (var i = 1; i < stone.positions.length; i += 3) {
          low = math.min(low, stone.positions[i]);
        }
        for (final prongs in RingProngs.values) {
          for (final f in HandFinger.values) {
            final seat = HandModel.seat(f);
            final style = RingStyle(prongs: prongs, bandWidth: 3);
            final crest = ringCrest(seat, style);
            final centre = crest + seat.normal * (-low * mm - 0.08);
            final x = seat.along, y = seat.normal, z = x.cross(y);
            final hull = StoneHull.of(stone, mm, centre, x, y, z);
            final mesh = buildRing(
              seat,
              style,
              RingHead(
                centre: centre,
                x: x,
                y: y,
                z: z,
                claws: RingHead.clawsFor(stone, mm, prongs),
                hull: hull,
              ),
            );
            final why = '$shape $prongs $f';
            expect(mesh.vertexCount, lessThan(6000), reason: why);
            for (final i in mesh.indices) {
              expect(i, lessThan(mesh.vertexCount));
            }
            // The culet rests on the band's crown.
            final culet = centre - seat.normal * (-low * mm);
            expect((culet - crest).length, lessThan(0.1), reason: why);
            var touching = 0;
            for (var i = 0; i < mesh.vertexCount; i++) {
              final p = HandVec(
                mesh.positions[i * 3],
                mesh.positions[i * 3 + 1],
                mesh.positions[i * 3 + 2],
              );
              final q = p - seat.centre;
              final ax = q.dot(seat.along);
              final radial = q - seat.along * ax;
              // Band vertices: within its width, never inside the skin.
              if (ax.abs() <= style.bandWidth / 2 + 1e-6 &&
                  radial.dot(seat.normal) < seat.radiusAt(0) * 0.9) {
                final a = math.atan2(
                  radial.dot(seat.lateral),
                  radial.dot(seat.normal),
                );
                expect(
                  radial.length,
                  greaterThanOrEqualTo(seat.radiusAt(a) * 0.97),
                  reason: why,
                );
              }
              // Metal never inside the stone; claws resting on it.
              var out = -double.infinity;
              final pl = hull.planes;
              for (var k = 0; k < pl.length; k += 4) {
                out = math.max(
                  out,
                  pl[k] * p.x + pl[k + 1] * p.y + pl[k + 2] * p.z - pl[k + 3],
                );
              }
              final inBand = (p - crest).dot(seat.normal) < 0.05;
              if (!inBand) {
                expect(out, greaterThan(-0.05), reason: why);
              }
              if (out < 0.1) touching++;
            }
            expect(touching, greaterThan(prongs.count * 8), reason: why);
            // Nothing between the eye straight above and the table but
            // the claw tips.
            expect(
              hull.blocks(centre + y * 20, centre - y * 20),
              isTrue,
              reason: why,
            );
            expect(
              hull.blocks(centre + y * 20, centre + y * 10),
              isFalse,
              reason: why,
            );
          }
        }
      }
    });

    test('band width stays within what jewellers make', () {
      expect(const RingStyle().copyWith(bandWidth: 9).bandWidth, 4);
      expect(const RingStyle().copyWith(bandWidth: 0.2).bandWidth, 1.5);
    });
  });

  group('HandCamera.stoneView', () {
    test('puts the table on the finger and the length along it', () {
      final r = Float64List(9);
      for (final yaw in [-2.5, -0.18, 0.0, 0.9, 2.2]) {
        for (final pitch in [-1.1, 0.0, 0.12, 0.8]) {
          final cam = HandCamera(
            yaw: yaw,
            pitch: pitch,
            roll: 0.07,
            centre: Offset.zero,
            pxPerMm: 2,
          );
          for (final f in HandFinger.values) {
            final seat = HandModel.seat(f);
            for (final spin in [0.0, 0.7]) {
              cam.stoneView(seat.normal, seat.along, spin).rotationInto(r);
              // Model y (the table axis) is column 1.
              final n = cam.turn(seat.normal);
              expect(r[1], closeTo(n.x, 1e-9));
              expect(r[4], closeTo(n.y, 1e-9));
              expect(r[7], closeTo(n.z, 1e-9));
              // Model x is column 0: along the finger, turned by spin.
              var x = cam.turn(seat.along);
              x = (x - n * x.dot(n)).unit;
              final z = x.cross(n);
              final want = x * math.cos(spin) - z * math.sin(spin);
              expect(r[0], closeTo(want.x, 1e-9));
              expect(r[3], closeTo(want.y, 1e-9));
              expect(r[6], closeTo(want.z, 1e-9));
            }
          }
        }
      }
    });
  });
}
