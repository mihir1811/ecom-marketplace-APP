import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'app_drawer_button.dart';
import 'theme_toggle_button.dart';

/// Trailing actions that must stay at the far right after Cart/Wallet/Messages.
///
/// Order contribution: optional drawer (rare) → theme toggle.
List<Widget> buildAppBarActions({
  List<Widget> actions = const [],
  bool showDrawerButton = false,
  bool showThemeToggle = true,
}) {
  final result = <Widget>[...actions];
  if (showDrawerButton) {
    result.add(const AppDrawerButton());
  }
  if (showThemeToggle) {
    result.add(const ThemeToggleButton());
    result.add(const SizedBox(width: AppSpacing.s8));
  }
  return result;
}
