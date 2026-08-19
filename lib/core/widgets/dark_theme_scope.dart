import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../theme/theme_preference_provider.dart';

/// Applies the dark theme to its subtree when dark mode is enabled.
///
/// Light-themed screens (home, detail, auth, etc.) stay on the light theme;
/// only listing and filter screens opt in by being wrapped in this scope.
class DarkThemeScope extends ConsumerWidget {
  const DarkThemeScope({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark =
        ref.watch(themePreferenceProvider);
    return Theme(
      data: dark ? AppTheme.dark : AppTheme.light,
      child: child,
    );
  }
}