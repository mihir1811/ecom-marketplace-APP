import 'package:flutter/material.dart';

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
              title: const Text('Delete account?'),
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
                      labelText: 'Current password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: obscure ? 'Show password' : 'Hide password',
                        onPressed: () => setLocal(() => obscure = !obscure),
                        icon: Icon(
                          obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    onSubmitted: (_) {
                      if (passwordController.text.trim().isEmpty) return;
                      Navigator.pop(context, true);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (passwordController.text.trim().isEmpty) return;
                    Navigator.pop(context, true);
                  },
                  child: const Text('Delete account'),
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
