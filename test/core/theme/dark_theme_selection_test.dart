import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/core/theme/app_colors.dart';
import 'package:gemstone/core/theme/app_theme.dart';
import 'package:gemstone/core/theme/theme_preference_provider.dart';
import 'package:gemstone/core/widgets/dark_theme_scope.dart';
import 'package:gemstone/core/widgets/filters/filter_chip.dart';
import 'package:gemstone/core/widgets/filters/filter_text_segmented_control.dart';
import 'package:gemstone/core/widgets/filters/filter_quick_range_chip.dart';

Widget _harness({required bool dark, required Widget child}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: ProviderScope(
      overrides: [
        themePreferenceProvider
            .overrideWith((ref) => ThemePreference()..state = dark),
      ],
      child: DarkThemeScope(child: Scaffold(body: child)),
    ),
  );
}

BoxDecoration _decorationOf(WidgetTester tester, Finder finder) {
  final container = tester.widget<AnimatedContainer>(finder);
  return container.decoration as BoxDecoration;
}

void main() {
  testWidgets('isDark resolves true inside DarkThemeScope when enabled',
      (tester) async {
    Color? resolved;
    await tester.pumpWidget(
      _harness(
        dark: true,
        child: Builder(
          builder: (context) {
            resolved = AppColors.bg(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(resolved, AppColors.obsidianBg);
  });

  testWidgets('selected chip is warmWhite bg with charcoal text in dark mode',
      (tester) async {
    await tester.pumpWidget(
      _harness(
        dark: true,
        child: Column(
          children: [
            FilterChipWidget(
              label: 'Selected',
              isSelected: true,
              onTap: () {},
            ),
            FilterChipWidget(
              label: 'Unselected',
              isSelected: false,
              onTap: () {},
            ),
          ],
        ),
      ),
    );

    final selectedDeco = _decorationOf(tester, find.ancestor(
      of: find.text('Selected'),
      matching: find.byType(AnimatedContainer),
    ));
    final unselectedDeco = _decorationOf(tester, find.ancestor(
      of: find.text('Unselected'),
      matching: find.byType(AnimatedContainer),
    ));

    expect(selectedDeco.color, AppColors.warmWhite);
    expect(unselectedDeco.color, AppColors.slateSurface);

    final selectedText = tester.widget<Text>(find.text('Selected'));
    final unselectedText = tester.widget<Text>(find.text('Unselected'));
    expect(selectedText.style!.color, AppColors.charcoal);
    expect(unselectedText.style!.color, AppColors.textPrimaryDark);
  });

  testWidgets('selected chip is charcoal bg with warmWhite text in light mode',
      (tester) async {
    await tester.pumpWidget(
      _harness(
        dark: false,
        child: Column(
          children: [
            FilterChipWidget(
              label: 'Selected',
              isSelected: true,
              onTap: () {},
            ),
            FilterChipWidget(
              label: 'Unselected',
              isSelected: false,
              onTap: () {},
            ),
          ],
        ),
      ),
    );

    final selectedDeco = _decorationOf(tester, find.ancestor(
      of: find.text('Selected'),
      matching: find.byType(AnimatedContainer),
    ));
    final unselectedDeco = _decorationOf(tester, find.ancestor(
      of: find.text('Unselected'),
      matching: find.byType(AnimatedContainer),
    ));

    expect(selectedDeco.color, AppColors.charcoal);
    expect(unselectedDeco.color, AppColors.warmWhite);

    final selectedText = tester.widget<Text>(find.text('Selected'));
    expect(selectedText.style!.color, AppColors.warmWhite);
  });

  testWidgets('segmented control selected segment is warmWhite in dark mode',
      (tester) async {
    await tester.pumpWidget(
      _harness(
        dark: true,
        child: FilterTextSegmentedControl(
          options: const ['Lab Diamond', 'Lab Melee'],
          selected: 'Lab Melee',
          onSelected: (_) {},
        ),
      ),
    );

    final selectedDeco = _decorationOf(tester, find.ancestor(
      of: find.text('LAB MELEE'),
      matching: find.byType(AnimatedContainer),
    ));
    expect(selectedDeco.color, AppColors.warmWhite);

    final selectedText = tester.widget<Text>(find.text('LAB MELEE'));
    expect(selectedText.style!.color, AppColors.charcoal);
  });

  testWidgets('quick range chip selected is warmWhite in dark mode',
      (tester) async {
    await tester.pumpWidget(
      _harness(
        dark: true,
        child: FilterQuickRangeChip(
          label: '1ct',
          isSelected: true,
          onTap: () {},
        ),
      ),
    );

    final deco = _decorationOf(tester, find.ancestor(
      of: find.text('1ct'),
      matching: find.byType(AnimatedContainer),
    ));
    expect(deco.color, AppColors.warmWhite);
  });
}
