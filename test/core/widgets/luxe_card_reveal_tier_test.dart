import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemworld/core/device/device_tier.dart';
import 'package:gemworld/core/widgets/luxe/luxe_card_reveal.dart';

void main() {
  tearDown(() => DeviceTier.reduceEffects.value = false);

  Future<LuxeRevealClock?> clockIn(WidgetTester tester) async {
    LuxeRevealClock? clock;
    await tester.pumpWidget(
      MaterialApp(
        home: ListView(
          children: [
            LuxeCardReveal(
              index: 0,
              child: Builder(
                builder: (context) {
                  clock = LuxeCardReveal.clockOf(context);
                  return const SizedBox(height: 100);
                },
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    return clock;
  }

  testWidgets('full phones get the entrance', (tester) async {
    expect(await clockIn(tester), isNotNull);
  });

  testWidgets('budget phones show the card plainly', (tester) async {
    DeviceTier.reduceEffects.value = true;
    expect(await clockIn(tester), isNull);
  });

  testWidgets('switching to budget mode drops the entrance', (tester) async {
    expect(await clockIn(tester), isNotNull);
    LuxeRevealClock? after;
    DeviceTier.reduceEffects.value = true;
    await tester.pumpWidget(
      MaterialApp(
        home: ListView(
          children: [
            LuxeCardReveal(
              index: 0,
              child: Builder(
                builder: (context) {
                  after = LuxeCardReveal.clockOf(context);
                  return const SizedBox(height: 100);
                },
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(after, isNull);
  });
}
