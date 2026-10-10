import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_palette.dart';
import '../theme/app_theme.dart';
import '../theme/theme_preference_provider.dart';

/// Applies the active palette's theme to its subtree.
///
/// Prefer [MaterialApp.themeMode] at the app root for global theming.
/// This scope remains for isolated subtrees (e.g. widget tests) that need
/// an explicit theme override.
class DarkThemeScope extends ConsumerWidget {
  const DarkThemeScope({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(palettePreferenceProvider);
    return Theme(data: AppTheme.build(AppPalette.byId(palette)), child: child);
  }
}
