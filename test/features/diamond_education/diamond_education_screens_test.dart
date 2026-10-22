import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/core/auth/auth_controller.dart';
import 'package:gemstone/core/auth/auth_providers.dart';
import 'package:gemstone/core/auth/auth_state.dart';
import 'package:gemstone/core/haptics/app_haptics.dart';
import 'package:gemstone/core/l10n/app_localizations.dart';
import 'package:gemstone/core/theme/app_palette.dart';
import 'package:gemstone/core/theme/app_theme.dart';
import 'package:gemstone/features/diamond_education/application/diamond_simulator_controller.dart';
import 'package:gemstone/features/diamond_education/domain/diamond_grades.dart';
import 'package:gemstone/features/diamond_education/domain/diamond_shape.dart';
import 'package:gemstone/features/diamond_education/presentation/screens/diamond_education_screen.dart';
import 'package:gemstone/features/diamond_education/presentation/screens/diamond_simulator_screen.dart';
import 'package:gemstone/features/diamond_education/presentation/widgets/simulator/diamond_sim_viewport.dart';
import 'package:gemstone/features/diamond_education/presentation/widgets/simulator/sim_shape_dial.dart';
import 'package:gemstone/features/diamond_education/simulation/sim_fancy.dart';

class _SignedOut extends AuthController {
  @override
  AuthState build() => const AuthState();
}

Future<void> _pump(
  WidgetTester tester,
  Size size,
  Widget child, {
  List<Override> overrides = const [],
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authProvider.overrideWith(_SignedOut.new), ...overrides],
      child: MaterialApp(
        theme: AppTheme.build(AppPalette.ivory),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 16));
  await tester.pump(const Duration(milliseconds: 300));
}

/// Unmounts and lets cancelled timers drain.
Future<void> _teardown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 6));
}

void main() {
  // Loaded for real once: the shape dial starts loading the fancy cuts as
  // it opens, and a load begun under a test's fake clock never finishes.
  setUpAll(SimFancyCatalog.load);
  setUp(() => AppHaptics.debugDisable = true);
  tearDown(AppHaptics.debugReset);

  for (final size in const [Size(360, 740), Size(1280, 800)]) {
    testWidgets(
      'simulator renders every panel without errors at ${size.width.toInt()}px',
      (tester) async {
        await _pump(tester, size, const DiamondSimulatorScreen());
        expect(tester.takeException(), isNull);

        Future<void> tapText(String text) async {
          final target = find.text(text).first;
          await tester.ensureVisible(target);
          await tester.pump();
          await tester.tap(target);
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull, reason: text);
        }

        // Each tool opens on its own and closes again.
        for (final tool in const [
          'Shape',
          'Cut',
          'Color',
          'Clarity',
          'Inclusions',
          'BGM',
          'Milky',
          'Fluorescence',
        ]) {
          await tapText(tool);
          expect(find.text('Done'), findsOneWidget, reason: tool);
          await tapText('Done');
        }

        // Carat brings up the hand; a second finger gets its own stone.
        await tapText('Carat');
        await tester.pump(const Duration(milliseconds: 1200));
        await tapText('Index · Add');
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.textContaining('Index · 1.00 ct'), findsOneWidget);
        await tapText('Done');
        await tester.drag(
          find.byType(DiamondSimulatorScreen),
          const Offset(80, 0),
        );
        await tester.pump(const Duration(milliseconds: 400));
        await tapText('Go back');

        // Recut on the dial: tap the place four stops clockwise from the
        // top, let the stone morph there, then turn the ring by hand.
        await tapText('Shape');
        expect(find.byType(SimShapeDial), findsOneWidget);
        final dial = tester.widget<SimShapeDial>(find.byType(SimShapeDial));
        final centre = tester.getCenter(find.byType(SimShapeDial));
        Offset onRing(double stops) {
          final a = -math.pi / 2 + stops * 2 * math.pi / SimShape.values.length;
          return centre + Offset(math.cos(a), math.sin(a)) * dial.radius;
        }

        Future<void> settle() async {
          for (var i = 0; i < 20; i++) {
            await tester.pump(const Duration(milliseconds: 60));
          }
          expect(tester.takeException(), isNull);
        }

        SimShape shown() => SimShape.values.singleWhere(
          (s) => find.text(s.catalogValue).evaluate().isNotEmpty,
        );

        final start = shown();
        await tester.tapAt(onRing(4));
        await settle();
        final tapped = shown();
        expect(tapped.index, (start.index + 4) % SimShape.values.length);
        final gesture = await tester.startGesture(onRing(0));
        for (var i = 1; i <= 12; i++) {
          await gesture.moveTo(onRing(i * 0.1));
          await tester.pump(const Duration(milliseconds: 16));
        }
        await gesture.up();
        await settle();
        expect(shown(), isNot(tapped));
        await tapText('Done');
        expect(find.byType(SimShapeDial), findsNothing);
        await tester.drag(
          find.byType(DiamondSimulatorScreen),
          const Offset(80, 30),
        );
        await tester.pump(const Duration(milliseconds: 800));
        expect(tester.takeException(), isNull);
        await _teardown(tester);
      },
    );
  }

  for (final size in const [Size(360, 740), Size(1280, 800)]) {
    testWidgets(
      'inclusion explorer picks many kinds, labelled in the line drawing '
      'at ${size.width.toInt()}px',
      (tester) async {
        await _pump(tester, size, const DiamondSimulatorScreen());
        final container = ProviderScope.containerOf(
          tester.element(find.byType(DiamondSimulatorScreen)),
        );
        final viewport = tester
            .widget<DiamondSimViewport>(find.byType(DiamondSimViewport))
            .controller;
        expect(viewport.vector, isFalse);

        Future<void> tapText(String text) async {
          final target = find.text(text).first;
          await tester.ensureVisible(target);
          await tester.pump();
          await tester.tap(target);
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull, reason: text);
        }

        await tapText('Inclusions');
        await tester.pump(const Duration(milliseconds: 600));
        // Explored in the line drawing, labelled, the stone above the
        // picker.
        expect(viewport.vector, isTrue);
        expect(viewport.labelled.value, isTrue);
        expect(viewport.stage.value, isNotNull);
        expect(find.text('Internal · inclusions'), findsOneWidget);
        expect(find.text('External · blemishes'), findsOneWidget);
        expect(viewport.inclusionView.value, isTrue);

        // Several at once, internal and external.
        await tapText('Knot');
        await tapText('Needle');
        await tapText('Scratch');
        final types = container
            .read(diamondSimulatorProvider)
            .spec
            .inclusionTypes;
        expect(types, {
          InclusionType.knot,
          InclusionType.needle,
          InclusionType.scratch,
        });
        // The card describes the one last picked.
        expect(viewport.focus.value, InclusionType.scratch);
        expect(find.text('Durability risk'), findsWidgets);
        await tester.pump(const Duration(milliseconds: 800));
        expect(tester.takeException(), isNull);

        await tapText('Done');
        expect(viewport.vector, isFalse);
        expect(viewport.labelled.value, isFalse);
        expect(viewport.inclusionView.value, isFalse);
        await tester.pump(const Duration(milliseconds: 800));
        expect(viewport.stage.value, isNull);
        await _teardown(tester);
      },
    );
  }

  testWidgets('the dial opens into a half ring of every shape and back', (
    tester,
  ) async {
    await tester.runAsync(SimFancyCatalog.load);
    await _pump(tester, const Size(390, 844), const DiamondSimulatorScreen());
    final container = ProviderScope.containerOf(
      tester.element(find.byType(DiamondSimulatorScreen)),
    );
    final viewport = tester
        .widget<DiamondSimViewport>(find.byType(DiamondSimViewport))
        .controller;
    Future<void> settle([int frames = 30]) async {
      for (var i = 0; i < frames; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }
      expect(tester.takeException(), isNull);
    }

    // After the inclusion explorer, the dial's stone is back in the middle.
    await tester.ensureVisible(find.text('Inclusions').first);
    await tester.tap(find.text('Inclusions').first);
    await settle(12);
    await tester.tap(find.text('Done').first);
    await settle(12);
    await tester.ensureVisible(find.text('Shape').first);
    await tester.tap(find.text('Shape').first);
    await settle(12);
    expect(viewport.fit.value, isNotNull);
    expect(viewport.stage.value, isNull);

    await tester.tap(find.text('Show more shapes'));
    await settle();
    // The stone above the half ring, the round at its centre.
    final stage = viewport.stage.value!;
    final top = SimShapeDial.halfRingTop(const Size(390, 844), 0);
    expect(stage.bottom, top);
    expect(find.text('Round'), findsOneWidget);
    expect(find.text('Show fewer shapes'), findsOneWidget);

    // Along the half ring by hand, past the classic shapes into the
    // fancy cuts: shown, never made the stone's.
    // On the band at its apex, below the search and the name.
    final gesture = await tester.startGesture(Offset(195, top + 125));
    for (var i = 0; i < 24; i++) {
      await gesture.moveBy(const Offset(18, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await settle();
    expect(find.text('Round'), findsNothing);
    expect(container.read(diamondSimulatorProvider).spec.shape, SimShape.round);
    expect(viewport.morph.value, isNotNull);

    // Searched by name: a moment after typing, the half ring turns
    // there step by step, never jumping.
    await tester.enterText(find.byType(TextField), 'hea');
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Heart'), findsNothing);
    await tester.pump(const Duration(milliseconds: 250));
    var steps = 0;
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 60));
      final t = viewport.morph.value?.t ?? 0;
      if (t > 0 && t < 1) steps++;
    }
    expect(steps, greaterThan(5));
    expect(find.text('Heart'), findsOneWidget);
    expect(container.read(diamondSimulatorProvider).spec.shape, SimShape.heart);
    await tester.enterText(find.byType(TextField), 'zzz');
    await settle(10);
    expect(find.text('No match'), findsOneWidget);
    expect(find.text('Heart'), findsOneWidget);

    await tester.tap(find.text('Show fewer shapes'));
    await settle();
    expect(viewport.stage.value, isNull);
    expect(find.text('Show more shapes'), findsOneWidget);
    expect(find.text('Heart'), findsOneWidget);
    expect(container.read(diamondSimulatorProvider).spec.shape, SimShape.heart);
    expect(viewport.morph.value, isNull);
    await tester.tap(find.text('Done'));
    await settle(8);
    expect(find.byType(SimShapeDial), findsNothing);
    await _teardown(tester);
  });

  testWidgets('simulator opens on a scoped shape', (tester) async {
    await _pump(
      tester,
      const Size(360, 740),
      const DiamondSimulatorScreen(),
      overrides: [
        simulatorStartShapeProvider.overrideWithValue(SimShape.marquise),
      ],
    );
    // The shape is named only inside the shape tool.
    expect(find.textContaining('Marquise'), findsNothing);
    await tester.tap(find.text('Shape').first);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Marquise'), findsOneWidget);
    await _teardown(tester);
  });

  for (final width in const [320.0, 1100.0]) {
    testWidgets('education page lays out at ${width.toInt()}px', (
      tester,
    ) async {
      await _pump(tester, Size(width, 900), const DiamondEducationScreen());
      final scrollable = find.byType(Scrollable).first;
      // Scroll the whole page, checking every section as it builds.
      for (
        var i = 0;
        i < 40 && find.text('Browse diamonds').evaluate().isEmpty;
        i++
      ) {
        await tester.drag(scrollable, const Offset(0, -600));
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull);
      }
      expect(find.text('Browse diamonds'), findsOneWidget);
      await _teardown(tester);
    });
  }
}
