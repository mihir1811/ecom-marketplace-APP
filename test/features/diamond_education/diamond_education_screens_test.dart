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
import 'package:gemstone/features/diamond_education/domain/diamond_shape.dart';
import 'package:gemstone/features/diamond_education/presentation/screens/diamond_education_screen.dart';
import 'package:gemstone/features/diamond_education/presentation/screens/diamond_simulator_screen.dart';

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
          'Enhancement',
          'Fluorescence',
          'Proportions',
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

        // Recut and turn the stone.
        await tapText('Shape');
        await tapText('Emerald');
        await tapText('Done');
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

  testWidgets('simulator opens on a scoped shape', (tester) async {
    await _pump(
      tester,
      const Size(360, 740),
      const DiamondSimulatorScreen(),
      overrides: [
        simulatorStartShapeProvider.overrideWithValue(SimShape.marquise),
      ],
    );
    expect(find.textContaining('Marquise'), findsWidgets);
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
