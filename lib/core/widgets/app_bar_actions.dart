import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'app_drawer_button.dart';
import 'language_menu_button.dart';

/// Trailing actions that must stay at the far right after the section
/// shortcuts.
///
/// Order contribution: optional drawer (rare) → language (guests only).
List<Widget> buildAppBarActions({
  List<Widget> actions = const [],
  bool showDrawerButton = false,
}) {
  final result = <Widget>[...actions];
  if (showDrawerButton) {
    result.add(const AppDrawerButton());
  }
  result.add(const LanguageMenuButton(unauthenticatedOnly: true));
  result.add(const SizedBox(width: AppSpacing.s8));
  return result;
}
