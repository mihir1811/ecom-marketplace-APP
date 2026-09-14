import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../haptics/app_haptics.dart';
import '../l10n/app_localizations.dart';
import '../widgets/app_dialog.dart';

/// Asks the user to confirm leaving the app when the navigation stack is empty.
Future<bool> confirmAppExit(BuildContext context) async {
  final confirmed = await showAppDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.tr(CoreL10n.exitAppTitle)),
      content: Text(context.tr(CoreL10n.exitAppBody)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.tr(CoreL10n.cancel)),
        ),
        FilledButton(
          onPressed: () {
            AppHaptics.medium();
            Navigator.pop(context, true);
          },
          child: Text(context.tr(CoreL10n.exitAppConfirm)),
        ),
      ],
    ),
  );
  return confirmed == true;
}

/// Shows the exit confirmation and closes the app when the user agrees.
Future<void> requestAppExit(BuildContext context) async {
  final shouldExit = await confirmAppExit(context);
  if (!shouldExit || !context.mounted) return;
  await SystemNavigator.pop();
}
