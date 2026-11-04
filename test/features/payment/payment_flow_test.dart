import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/core/error/failure.dart';
import 'package:gemstone/core/error/result.dart';
import 'package:gemstone/features/payment/presentation/payment_flow.dart';

const _summary = PurchaseSummary(
  item: '1 item',
  amount: '₹1,000.00',
  method: 'Wallet',
);

/// Hosts a "Pay" button that starts [PaymentFlow.run] with [process].
class _Host extends StatelessWidget {
  const _Host({required this.process, required this.onResult});

  final Future<Result<String, Failure>> Function() process;
  final void Function(Result<String, Failure>?) onResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () async {
            final result = await PaymentFlow.run(
              context,
              summary: _summary,
              process: process,
              successMessage: (message) => message,
            );
            onResult(result);
          },
          child: const Text('Pay'),
        ),
      ),
    );
  }
}

Future<void> _pumpHost(
  WidgetTester tester, {
  required Future<Result<String, Failure>> Function() process,
  required void Function(Result<String, Failure>?) onResult,
}) {
  return tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: _Host(process: process, onResult: onResult),
      ),
    ),
  );
}

Future<void> _pressBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

void main() {

  testWidgets('confirm → progress → success stays until closed with icon', (
    tester,
  ) async {
    final pending = Completer<Result<String, Failure>>();
    var calls = 0;
    var done = false;
    Result<String, Failure>? outcome;
    await _pumpHost(
      tester,
      process: () {
        calls++;
        return pending.future;
      },
      onResult: (r) {
        done = true;
        outcome = r;
      },
    );

    await tester.tap(find.text('Pay'));
    await tester.pumpAndSettle();
    expect(find.text('Confirm purchase'), findsOneWidget);
    expect(find.text('Wallet'), findsOneWidget);
    expect(calls, 0, reason: 'nothing is charged before confirmation');

    await tester.tap(find.text('Confirm'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(PaymentProgressDialog), findsOneWidget);
    expect(calls, 1);

    // Back is ignored while the payment is processing.
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(PaymentProgressDialog), findsOneWidget);

    pending.complete(Result.success('Order placed'));
    await tester.pumpAndSettle();
    expect(find.byType(PaymentProgressDialog), findsNothing);
    expect(find.text('Payment successful'), findsOneWidget);
    expect(find.text('Order placed'), findsOneWidget);

    // Not auto-dismissed.
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('Payment successful'), findsOneWidget);
    expect(done, isFalse);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Payment successful'), findsNothing);
    expect(find.text('Pay'), findsOneWidget);
    expect(done, isTrue);
    expect(outcome, isA<Success<String, Failure>>());
  });

  testWidgets('failure shows the error and closes with system back', (
    tester,
  ) async {
    Result<String, Failure>? outcome;
    await _pumpHost(
      tester,
      process: () async =>
          Result.failure(const ValidationFailure('Payment was cancelled.')),
      onResult: (r) => outcome = r,
    );

    await tester.tap(find.text('Pay'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(find.text('Payment failed'), findsOneWidget);
    expect(find.text('Payment was cancelled.'), findsOneWidget);

    await _pressBack(tester);
    expect(find.text('Payment failed'), findsNothing);
    expect(find.text('Pay'), findsOneWidget, reason: 'screen is kept');
    expect(outcome, isA<ResultFailure<String, Failure>>());
  });

  testWidgets('failure popup closes with its Close button', (tester) async {
    await _pumpHost(
      tester,
      process: () async => Result.failure(const NetworkFailure('Offline')),
      onResult: (_) {},
    );

    await tester.tap(find.text('Pay'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Close'));
    await tester.pumpAndSettle();
    expect(find.text('Payment failed'), findsNothing);
    expect(find.text('Pay'), findsOneWidget);
  });

  testWidgets('success popup closes with system back', (tester) async {
    await _pumpHost(
      tester,
      process: () async => Result.success('Paid'),
      onResult: (_) {},
    );

    await tester.tap(find.text('Pay'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(find.text('Payment successful'), findsOneWidget);

    await _pressBack(tester);
    expect(find.text('Payment successful'), findsNothing);
    expect(find.text('Pay'), findsOneWidget);
  });

  testWidgets('cancel and back at confirmation never charge', (tester) async {
    var calls = 0;
    final results = <Result<String, Failure>?>[];
    await _pumpHost(
      tester,
      process: () async {
        calls++;
        return Result.success('Paid');
      },
      onResult: results.add,
    );

    await tester.tap(find.text('Pay'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pay'));
    await tester.pumpAndSettle();
    await _pressBack(tester);

    expect(find.text('Confirm purchase'), findsNothing);
    expect(find.text('Pay'), findsOneWidget);
    expect(calls, 0);
    expect(results, [null, null]);
  });

  testWidgets('repeat taps start a single payment', (tester) async {
    var calls = 0;
    await _pumpHost(
      tester,
      process: () async {
        calls++;
        return Result.success('Paid');
      },
      onResult: (_) {},
    );

    // Second tap lands before the confirm dialog covers the button.
    await tester.tap(find.text('Pay'));
    await tester.tap(find.text('Pay'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Confirm purchase'), findsOneWidget);

    // Double tap on confirm must not pop the screen underneath.
    await tester.tap(find.text('Confirm'));
    await tester.tap(find.text('Confirm'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(calls, 1);
    expect(find.text('Payment successful'), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Pay'), findsOneWidget);
    expect(PaymentFlow.isActive, isFalse);
  });
}
