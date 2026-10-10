import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../haptics/app_haptics.dart';
import '../l10n/app_localizations.dart';
import '../theme/theme_preference_provider.dart';

/// Global dark mode toggle button for the app bar.
///
/// Switches between light and dark themes. Persists the user's choice.
class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = ref.watch(themePreferenceProvider);

    return IconButton(
      tooltip: context.tr(
        dark ? CoreL10n.switchToLightMode : CoreL10n.switchToDarkMode,
      ),
      icon: Icon(
        dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        size: size,
      ),
      onPressed: () {
        AppHaptics.selection();
        ref.read(palettePreferenceProvider.notifier).setDarkMode(!dark);
      },
    );
  }
}
