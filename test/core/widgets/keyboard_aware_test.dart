import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/core/widgets/keyboard_aware.dart';

void main() {
  test('overlayBottomGap includes keyboard inset and FAB gap', () {
    expect(AppKeyboard.overlayBottomGap(keyboardInset: 0, safeBottom: 34), 122);
    expect(
      AppKeyboard.overlayBottomGap(keyboardInset: 300, safeBottom: 0),
      388,
    );
  });

  testWidgets('AppKeyboardInset pads by viewInsets.bottom', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(
          size: Size(400, 800),
          viewInsets: EdgeInsets.only(bottom: 320),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: AppKeyboardInset(child: SizedBox.expand()),
        ),
      ),
    );
    await tester.pump();

    final padding = tester.widget<AnimatedPadding>(
      find.byType(AnimatedPadding),
    );
    expect((padding.padding as EdgeInsets).bottom, 320);
  });
}
