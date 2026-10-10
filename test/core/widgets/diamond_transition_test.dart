import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/core/router/route_names.dart';
import 'package:gemstone/core/widgets/navigation/bottom_nav/diamond_transition/diamond_cut.dart';
import 'package:gemstone/core/widgets/navigation/bottom_nav/diamond_transition/diamond_mesh.dart';
import 'package:gemstone/core/widgets/navigation/bottom_nav/diamond_transition/diamond_transition_controller.dart';

const _routes = [
  AppRouteNames.home,
  AppRouteNames.buyerWishlist,
  AppRouteNames.cart,
  AppRouteNames.buyerProfile,
];

DiamondSnapshot _snap(double scale) {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    const Rect.fromLTWH(0, 0, 40, 80),
    Paint()..color = const Color(0xFF884422),
  );
  final image = recorder.endRecording().toImageSync(40, 80);
  return DiamondSnapshot(image, 1, const Size(40, 80));
}

class _Harness {
  _Harness() {
    controller = DiamondTransitionController(
      vsync: const TestVSync(),
      routes: _routes,
      cuts: [
        DiamondCut.brilliant,
        DiamondCut.marquise,
        DiamondCut.emerald,
        DiamondCut.brilliant,
      ],
      navigate: (route) {
        navigations.add(route);
        path = route;
      },
      currentPath: () => path,
      currentTab: () => _routes.indexOf(path),
    )..capture = _snap;
    controller.addListener(() => phases.add(controller.phase));
  }

  late final DiamondTransitionController controller;
  final navigations = <String>[];
  final phases = <DiamondTransitionPhase>[];
  String path = AppRouteNames.home;

  /// Pumps [frames] 16 ms frames.
  Future<void> run(WidgetTester tester, int frames) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  Future<void> settle(WidgetTester tester) => run(tester, 160);
}

void main() {
  testWidgets('a tap plays the whole sequence and navigates once', (
    tester,
  ) async {
    final h = _Harness();
    addTearDown(h.controller.dispose);

    h.controller.requestTab(2);
    await h.run(tester, 2);
    expect(h.controller.active.value, isTrue);
    expect(h.navigations, [AppRouteNames.cart]);

    await h.settle(tester);
    expect(h.controller.isActive, isFalse);
    expect(h.controller.active.value, isFalse);
    expect(h.navigations, [AppRouteNames.cart]);
    final order = h.phases.toSet().toList();
    expect(
      order,
      containsAllInOrder([
        DiamondTransitionPhase.wrapping,
        DiamondTransitionPhase.formed,
        DiamondTransitionPhase.rotating,
        DiamondTransitionPhase.unwrapping,
        DiamondTransitionPhase.completed,
        DiamondTransitionPhase.idle,
      ]),
    );
  });

  testWidgets('tapping the current tab does nothing', (tester) async {
    final h = _Harness();
    addTearDown(h.controller.dispose);
    h.controller.requestTab(0);
    await h.run(tester, 4);
    expect(h.controller.isActive, isFalse);
    expect(h.navigations, isEmpty);
  });

  testWidgets('progress follows the finger, pauses and reverses with it', (
    tester,
  ) async {
    final h = _Harness();
    addTearDown(h.controller.dispose);
    final c = h.controller;

    c.scrubStart(0);
    await h.run(tester, 2);
    expect(c.phase, DiamondTransitionPhase.previewing);
    expect(c.progress, 0);

    c.scrubUpdate(0.25);
    await h.run(tester, 30);
    final first = c.progress;
    expect(first, greaterThan(0));
    expect(first, lessThan(DiamondTransitionController.wrapEnd));

    // Finger still: nothing moves on its own and the ticker rests.
    await h.run(tester, 30);
    expect(c.progress, first);
    expect(tester.binding.transientCallbackCount, 0);

    c.scrubUpdate(0.5);
    await h.run(tester, 30);
    final further = c.progress;
    expect(further, greaterThan(first));

    // Back towards the origin unwinds from where it is, without a jump.
    c.scrubUpdate(0.4);
    await h.run(tester, 1);
    expect(c.progress, lessThan(further));
    expect(c.progress, greaterThan(first));
    await h.run(tester, 30);
    expect(c.progress, lessThan(further));

    expect(h.navigations, isEmpty);
    c.scrubCancel();
    await h.settle(tester);
  });

  testWidgets('scrubbing across every tab previews but never navigates', (
    tester,
  ) async {
    final h = _Harness();
    addTearDown(h.controller.dispose);
    final c = h.controller;
    final previews = <int?>[];
    c.preview.addListener(() => previews.add(c.preview.value));

    c.scrubStart(0);
    await h.run(tester, 2);
    for (var x = 0.0; x <= 3; x += 0.1) {
      c.scrubUpdate(x);
      await h.run(tester, 2);
    }
    await h.run(tester, 20);
    expect(c.progress, closeTo(DiamondTransitionController.wrapEnd, 1e-6));
    expect(c.cutTo, DiamondCut.brilliant);
    expect(h.navigations, isEmpty);
    expect(previews.whereType<int>().toSet(), {0, 1, 2, 3});

    c.scrubEnd();
    await h.run(tester, 2);
    expect(h.navigations, [AppRouteNames.buyerProfile]);
    await h.settle(tester);
    expect(c.isActive, isFalse);
    expect(h.navigations, [AppRouteNames.buyerProfile]);
  });

  testWidgets('releasing over the original tab restores it', (tester) async {
    final h = _Harness();
    addTearDown(h.controller.dispose);
    final c = h.controller;

    h.path = AppRouteNames.buyerWishlist;
    c.scrubStart(1);
    await h.run(tester, 2);
    c.scrubUpdate(2.2);
    await h.run(tester, 30);
    expect(c.progress, greaterThan(0.2));
    c.scrubUpdate(1.1);
    await h.run(tester, 10);
    c.scrubEnd();
    await h.settle(tester);
    expect(c.isActive, isFalse);
    expect(c.progress, 0);
    expect(h.navigations, isEmpty);
    expect(c.preview.value, isNull);
  });

  testWidgets('a cancelled gesture unwinds without navigating', (tester) async {
    final h = _Harness();
    addTearDown(h.controller.dispose);
    final c = h.controller;
    c.scrubStart(0);
    await h.run(tester, 2);
    c.scrubUpdate(1.6);
    await h.run(tester, 40);
    c.scrubCancel();
    await h.run(tester, 2);
    expect(c.phase, DiamondTransitionPhase.wrapping);
    await h.settle(tester);
    expect(c.isActive, isFalse);
    expect(h.navigations, isEmpty);
  });

  testWidgets('a second tap mid-switch redirects to the latest tab', (
    tester,
  ) async {
    final h = _Harness();
    addTearDown(h.controller.dispose);
    final c = h.controller;

    c.requestTab(1);
    await h.run(tester, 15);
    c.requestTab(3);
    await h.run(tester, 2);
    expect(h.navigations, [
      AppRouteNames.buyerWishlist,
      AppRouteNames.buyerProfile,
    ]);

    // Redirect while the page is already unfolding: it folds back first.
    while (c.progress <= DiamondTransitionController.unwrapStart + 0.05) {
      await h.run(tester, 1);
    }
    c.requestTab(2);
    await h.run(tester, 2);
    expect(h.navigations.last, AppRouteNames.buyerProfile);
    await h.settle(tester);
    expect(h.navigations.last, AppRouteNames.cart);
    expect(h.path, AppRouteNames.cart);
    expect(c.isActive, isFalse);
  });

  testWidgets('backgrounding mid-gesture restores a consistent state', (
    tester,
  ) async {
    final h = _Harness();
    addTearDown(h.controller.dispose);
    final c = h.controller;
    c.scrubStart(0);
    await h.run(tester, 2);
    c.scrubUpdate(2);
    await h.run(tester, 20);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    expect(c.isActive, isFalse);
    expect(c.active.value, isFalse);
    expect(h.navigations, isEmpty);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  test('the sheet wraps every cut from four sides', () {
    const n = DiamondGrid.size, stride = DiamondGrid.stride;
    for (final cut in DiamondCut.all) {
      final p = cut.gem.positions;
      double at(int i, int j, int axis) => p[(j * stride + i) * 3 + axis];

      // Centre faces the viewer, top edge becomes the table, bottom the
      // culet, and all four corners meet at the back.
      expect(at(n ~/ 2, n ~/ 2, 2), greaterThan(0.25), reason: cut.name);
      expect(at(n ~/ 2, 0, 1), lessThan(0), reason: cut.name);
      expect(at(n ~/ 2, n, 1), greaterThan(0), reason: cut.name);
      for (final (i, j) in [(0, 0), (n, 0), (0, n), (n, n)]) {
        expect(at(i, j, 2), lessThan(-0.25), reason: cut.name);
        expect(at(i, j, 0).abs(), lessThan(1e-6), reason: cut.name);
      }
      for (final v in p) {
        expect(v.isFinite, isTrue, reason: cut.name);
      }
      final normals = cut.gem.normals;
      for (var t = 0; t < normals.length; t += 3) {
        final len =
            normals[t] * normals[t] +
            normals[t + 1] * normals[t + 1] +
            normals[t + 2] * normals[t + 2];
        expect(len, closeTo(1, 1e-3), reason: cut.name);
      }
    }
  });

  test('octahedron keeps the sheet edges together', () {
    final a = Float64List(3), b = Float64List(3);
    // Mirror points across an edge midpoint land on the same seam point.
    DiamondGrid.octahedron(1, 0.4, a, 0);
    DiamondGrid.octahedron(1, -0.4, b, 0);
    expect(a[0], closeTo(b[0], 1e-9));
    expect(a[2], closeTo(b[2], 1e-9));
    expect(a[1].abs(), lessThan(1e-9));
  });

  testWidgets('the mesh paints every stage of every cut', (tester) async {
    final h = _Harness();
    addTearDown(h.controller.dispose);
    h.controller.requestTab(2);
    await h.run(tester, 2);

    final mesh = DiamondMesh();
    const style = DiamondStyle(
      backdrop: Color(0xFFF6F3EE),
      sheetBack: Color(0xFFEFEAE2),
      accent: Color(0xFF9C7A45),
      isDark: false,
    );
    for (var i = 0; i < 60; i++) {
      final recorder = ui.PictureRecorder();
      mesh.paint(Canvas(recorder), const Size(390, 700), h.controller, style);
      recorder.endRecording().dispose();
      await h.run(tester, 2);
    }
    expect(tester.takeException(), isNull);
    await h.settle(tester);
  });
}
