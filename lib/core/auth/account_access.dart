import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_providers.dart';
import 'auth_state.dart';

/// Shared buy/sell gate for accounts awaiting admin verification.
abstract final class AccountAccess {
  static const pendingMessage =
      'Verification is pending. You can explore the app, but buying and '
      'selling are unavailable until an admin verifies your account.';

  static const signInMessage = 'Please sign in to continue.';

  /// Cart, checkout, seller workspace, and other buy/sell chrome.
  static bool showProtected(AuthState state) => !state.isVerificationPending;

  static String? blockReason(AuthState state) {
    if (!state.isAuthenticated) return signInMessage;
    if (state.isVerificationPending) return pendingMessage;
    return null;
  }

  /// Returns `true` when the action may proceed.
  static bool guard(BuildContext context, WidgetRef ref) {
    final reason = blockReason(ref.read(authProvider));
    if (reason == null) return true;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(content: Text(reason)));
    return false;
  }
}
