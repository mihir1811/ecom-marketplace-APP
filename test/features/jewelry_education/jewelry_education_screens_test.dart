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
import 'package:gemstone/features/diamond_education/domain/diamond_proportions.dart';
import 'package:gemstone/features/diamond_education/domain/diamond_shape.dart';
import 'package:gemstone/features/diamond_education/domain/diamond_spec.dart';
import 'package:gemstone/features/jewelry_education/application/jewelry_simulator_controller.dart';
import 'package:gemstone/features/jewelry_education/domain/jewelry_design.dart';
import 'package:gemstone/features/jewelry_education/domain/jewelry_metal.dart';
import 'package:gemstone/features/jewelry_education/presentation/screens/jewelry_education_screen.dart';
import 'package:gemstone/features/jewelry_education/presentation/screens/jewelry_simulator_screen.dart';

class _SignedOut extends AuthController {
  @override
  AuthState build() => const AuthState();
}

Future<ProviderContainer> _pump(
  WidgetTester tester,
  Size size,
  Widget child, {
  List<Override> overrides = const [],
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [authProvider.overrideWith(_SignedOut.new), ...overrides],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
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
  return container;
}

/// Unmounts and lets cancelled timers drain.
Future<void> _teardown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 6));
}

void main() {
  setUp(() => AppHaptics.debugDisable = true);
  tearDown(AppHaptics.debugReset);

  for (final size in const [Size(360, 740), Size(1280, 800)]) {
    testWidgets(
      'simulator builds every piece and opens every tool at ${size.width.toInt()}px',
      (tester) async {
        await _pump(tester, size, const JewelrySimulatorScreen());
        expect(tester.takeException(), isNull);

        Future<void> tap(String text) async {
          final target = find.text(text).first;
          await tester.ensureVisible(target);
          await tester.pump();
          await tester.tap(target);
          await tester.pump(const Duration(milliseconds: 200));
          expect(tester.takeException(), isNull, reason: text);
        }

        for (final piece in const [
          'Earrings',
          'Necklace',
          'Bracelet',
          'Ring',
        ]) {
          await tap(piece);
          await tester.pump(const Duration(milliseconds: 200));
          for (final tool in const [
            'Metal',
            'Stone',
            'Setting',
            'Band',
            'Style',
            'Chain',
          ]) {
            if (find.text(tool).evaluate().isEmpty) continue;
            await tap(tool);
            await tap('Done');
          }
        }

        // Touching the piece runs its physics without error.
        await tester.tapAt(Offset(size.width / 2, size.height / 2));
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
        expect(tester.takeException(), isNull);
        await _teardown(tester);
      },
    );
  }

  testWidgets('a diamond handed over from the diamond simulator is set', (
    tester,
  ) async {
    final spec = DiamondSpec(
      shape: SimShape.pear,
      proportions: DiamondProportions.ideal(SimShape.pear),
      carat: 2.0,
    );
    final container = await _pump(
      tester,
      const Size(390, 800),
      const JewelrySimulatorScreen(),
      overrides: [jewelryStoneHandoffProvider.overrideWith((ref) => spec)],
    );
    final design = container.read(jewelrySimulatorProvider).design;
    expect(design.stone, spec);
    expect(design.type, JewelryType.ring);
    expect(find.textContaining('2.00 ct'), findsWidgets);
    await _teardown(tester);
  });

  testWidgets('a metal change restyles at once; a shape change rebuilds', (
    tester,
  ) async {
    final container = await _pump(
      tester,
      const Size(390, 800),
      const JewelrySimulatorScreen(),
    );
    final c = container.read(jewelrySimulatorProvider.notifier);
    final before = container.read(jewelrySimulatorProvider).scene;
    c.update((d) => d.copyWith(metal: JewelryMetal.roseGold));
    c.update(
      (d) => d.copyWith(purity: MetalPurity.k14, finish: MetalFinish.satin),
    );
    final restyled = container.read(jewelrySimulatorProvider).scene;
    expect(identical(restyled.parts, before.parts), isTrue);
    c.update((d) => d.copyWith(halo: HaloStyle.single));
    await tester.pump(const Duration(milliseconds: 200));
    final rebuilt = container.read(jewelrySimulatorProvider).scene;
    expect(identical(rebuilt.parts, before.parts), isFalse);
    expect(rebuilt.design.halo, HaloStyle.single);
    await _teardown(tester);
  });

  testWidgets('education page renders and scrolls without errors', (
    tester,
  ) async {
    await _pump(tester, const Size(390, 844), const JewelryEducationScreen());
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -6000));
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
    await _teardown(tester);
  });
}
