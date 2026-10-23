import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/features/diamond_education/domain/diamond_proportions.dart';
import 'package:gemstone/features/diamond_education/domain/diamond_shape.dart';
import 'package:gemstone/features/diamond_education/simulation/sim_mesh.dart';
import 'package:gemstone/features/diamond_education/simulation/sim_quality.dart';

/// A batch of frames whose raster takes [ms].
List<FrameTiming> batch(double ms, {int frames = 20}) {
  final us = (ms * 1000).round();
  return [
    for (var i = 0; i < frames; i++)
      FrameTiming(
        vsyncStart: 0,
        buildStart: 0,
        buildFinish: 1000,
        rasterStart: 1000,
        rasterFinish: 1000 + us,
        rasterFinishWallTime: 1000 + us,
      ),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final q = SimQuality.instance;

  setUp(q.debugReset);

  test('a stone at rest is traced at full resolution, whatever the device', () {
    for (var i = 0; i < 12; i++) {
      q.debugJudge(batch(60));
    }
    expect(q.debugMotion, lessThan(1));
    expect(q.traceScale(3, moving: false), 3);
    expect(q.draft(moving: false), isFalse);
  });

  test('a device that keeps up keeps full quality in motion', () {
    for (var i = 0; i < 10; i++) {
      q.debugJudge(batch(6));
    }
    expect(q.debugMotion, 1);
    expect(q.pace, 0);
    expect(q.traceScale(2.75, moving: true), 2.75);
    expect(q.draft(moving: true), isFalse);
  });

  test(
    'a slow device trades pixels first, then pace, never below the floor',
    () {
      final seen = <double>[1];
      for (var i = 0; i < 30; i++) {
        q.debugJudge(batch(40));
        if (q.debugMotion != seen.last) seen.add(q.debugMotion);
      }
      // Bounded steps down, never past half the resolution per axis.
      for (var i = 1; i < seen.length; i++) {
        expect(seen[i] / seen[i - 1], greaterThanOrEqualTo(0.59));
      }
      expect(q.debugMotion, 0.5);
      expect(q.pace, greaterThan(0));
      expect(q.traceScale(3, moving: true), 1.5);
      // Never fewer traced pixels than logical ones.
      expect(q.traceScale(1.5, moving: true), 1);
      expect(q.draft(moving: true), isTrue);
    },
  );

  test('once fast again, pace returns before pixels, without oscillating', () {
    for (var i = 0; i < 30; i++) {
      q.debugJudge(batch(40));
    }
    final pace = q.pace;
    final motion = q.debugMotion;
    // Smoothed: a couple of batches pass before it trusts the change.
    for (var i = 0; i < 8; i++) {
      q.debugJudge(batch(4));
    }
    expect(q.pace, lessThan(pace));
    expect(q.debugMotion, motion);
    for (var i = 0; i < 200; i++) {
      q.debugJudge(batch(4));
    }
    expect(q.pace, 0);
    expect(q.debugMotion, 1);
  });

  test('frame times inside the dead band change nothing', () {
    for (var i = 0; i < 20; i++) {
      q.debugJudge(batch(12));
    }
    expect(q.debugMotion, 1);
    expect(q.pace, 0);
  });

  test('the memory budget follows what the OS grants this app', () {
    expect(q.pixelBudget, isNull);
    q.debugSetDevice(const SimDeviceState(appMemoryBytes: 256 << 20));
    final roomy = q.pixelBudget!;
    q.debugSetDevice(const SimDeviceState(appMemoryBytes: 128 << 20));
    final tight = q.pixelBudget!;
    expect(tight * 2, closeTo(roomy, 2));
    q.debugSetDevice(
      const SimDeviceState(appMemoryBytes: 128 << 20, lowMemory: true),
    );
    expect(q.pixelBudget! * 2, closeTo(tight, 2));
    // Free memory caps it too.
    q.debugSetDevice(
      const SimDeviceState(
        appMemoryBytes: 512 << 20,
        availableBytes: 200 << 20,
      ),
    );
    expect(q.pixelBudget, lessThan((512 << 20) * 0.1 / 4));
  });

  test('heat tightens quality before the device throttles', () {
    expect(SimDeviceState.parse({'thermalHeadroom': 0.5}).thermal, 0);
    expect(SimDeviceState.parse({'thermalHeadroom': 1.0}).thermal, 1);
    expect(
      SimDeviceState.parse({'thermalStatus': 3}).thermal,
      closeTo(0.67, 0.01),
    );
    expect(SimDeviceState.parse({'thermalState': 2}).thermal, 0.7);
    expect(SimDeviceState.parse(const {}).thermal, 0);

    q.debugSetDevice(const SimDeviceState(thermal: 1));
    expect(q.pace, 1);
    expect(q.traceScale(3, moving: false), lessThan(3));
    // A frame time that passes when cool is too slow when hot.
    q.debugReset();
    q.debugSetDevice(const SimDeviceState(thermal: 0.9));
    for (var i = 0; i < 6; i++) {
      q.debugJudge(batch(11.5));
    }
    expect(q.debugMotion, lessThan(1));
  });

  test('meshes are built once per cut and shared', () {
    final p = DiamondProportions.ideal(SimShape.princess);
    final a = SimMesh.build(SimShape.princess, p);
    expect(identical(SimMesh.build(SimShape.princess, p), a), isTrue);
    SimMesh.trimCache();
    final b = SimMesh.build(SimShape.princess, p);
    expect(identical(b, a), isFalse);
    expect(b.positions, a.positions);
  });
}
