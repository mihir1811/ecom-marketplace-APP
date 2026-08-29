import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/translations/account_commerce_messages.dart';

import '../widgets/app_dialog.dart';

/// Asks the user to confirm signing out of the current account.
Future<bool> confirmSignOut(BuildContext context) async {
  final confirmed = await showAppDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.tr(AccountCommerceL10n.signOutTitle)),
      content: Text(context.tr(AccountCommerceL10n.signOutBody)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.tr(CoreL10n.cancel)),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(context.tr(AccountCommerceL10n.signOut)),
        ),
      ],
    ),
  );
  return confirmed == true;
}
