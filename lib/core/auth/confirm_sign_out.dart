import 'package:flutter/material.dart';

import '../widgets/app_dialog.dart';

/// Asks the user to confirm signing out of the current account.
Future<bool> confirmSignOut(BuildContext context) async {
  final confirmed = await showAppDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Sign out?'),
      content: const Text(
        'Are you sure you want to sign out from this account?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Sign out'),
        ),
      ],
    ),
  );
  return confirmed == true;
}
