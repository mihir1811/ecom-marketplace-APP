import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'keyboard_aware.dart';

/// Dialog helper that keeps content clear of the status bar, nav bar, and IME.
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
  bool useRootNavigator = true,
}) {
  // Capture the caller's theme so dialogs opened from dark-theme screens
  // render dark instead of inheriting the app-level light theme.
  final theme = Theme.of(context);
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor,
    useRootNavigator: useRootNavigator,
    builder: (context) {
      return SafeArea(
        minimum: const EdgeInsets.all(AppSpacing.s8),
        child: AppKeyboardInset(
          child: Theme(data: theme, child: builder(context)),
        ),
      );
    },
  );
}

/// Bottom sheet helper that respects system insets on physical devices.
Future<T?> showAppModalSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool isDismissible = true,
  bool enableDrag = true,
  bool showDragHandle = false,
  Color? backgroundColor,
  ShapeBorder? shape,
}) {
  // Capture the caller's theme so sheets opened from dark-theme screens
  // render dark instead of inheriting the app-level light theme.
  final theme = Theme.of(context);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    showDragHandle: showDragHandle,
    backgroundColor: backgroundColor,
    shape: shape,
    useSafeArea: true,
    builder: (context) {
      return AppKeyboardInset(
        child: Theme(data: theme, child: builder(context)),
      );
    },
  );
}
