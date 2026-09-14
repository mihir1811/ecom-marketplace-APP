import 'package:flutter/material.dart';

import '../haptics/app_haptics.dart';
import '../l10n/app_localizations.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/app_dialog.dart';

/// Confirms account deletion and collects the current password.
///
/// Returns the trimmed password when confirmed, or `null` when cancelled.
Future<String?> confirmDeleteAccount(BuildContext context) async {
  final passwordController = TextEditingController();
  var obscure = true;

  try {
    final confirmed = await showAppDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: Text(context.tr(AccountCommerceL10n.deleteAccountTitle)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your account will be scheduled for deletion. You have '
                    '7 days to recover it from the email link or the recover '
                    'account screen.',
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: obscure,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: context.tr(
                        AccountCommerceL10n.currentPassword,
                      ),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIconColor: AppColors.textSecondary(context),
                      suffixIcon: IconButton(
                        tooltip: obscure
                            ? context.tr(AccountCommerceL10n.showPassword)
                            : context.tr(AccountCommerceL10n.hidePassword),
                        onPressed: () => setLocal(() => obscure = !obscure),
                        icon: Icon(
                          obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ),
                    onSubmitted: (_) {
                      if (passwordController.text.trim().isEmpty) {
                        AppHaptics.error();
                        return;
                      }
                      AppHaptics.warning();
                      Navigator.pop(context, true);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(context.tr(CoreL10n.cancel)),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (passwordController.text.trim().isEmpty) {
                      AppHaptics.error();
                      return;
                    }
                    AppHaptics.warning();
                    Navigator.pop(context, true);
                  },
                  child: Text(context.tr(AccountCommerceL10n.deleteAccount)),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) return null;
    final password = passwordController.text;
    if (password.isEmpty) return null;
    return password;
  } finally {
    passwordController.dispose();
  }
}
