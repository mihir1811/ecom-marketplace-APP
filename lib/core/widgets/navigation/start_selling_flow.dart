import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/auth_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../router/app_navigation.dart';
import '../../router/route_names.dart';
import '../app_dialog.dart';

/// Takes a non-seller to business registration.
///
/// Guests go straight to registration; signed-in individual accounts are told
/// that selling needs a separate business account and are signed out only
/// after they confirm. Router and auth are captured up front so the flow
/// completes even when the caller (e.g. a drawer) is torn down by sign-out.
Future<void> startSellingFlow(BuildContext context, WidgetRef ref) async {
  final router = GoRouter.of(context);
  final auth = ref.read(authProvider.notifier);
  final isAuthenticated = ref.read(authProvider).isAuthenticated;
  if (!isAuthenticated) {
    context.openRoute('${AppRouteNames.register}?type=business');
    return;
  }

  final goRegister = await showAppDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.tr(RemainingL10n.sellerAccountRequired)),
      content: Text(context.tr(RemainingL10n.sellerAccountRequiredBody)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.tr(RemainingL10n.notNow)),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(context.tr(RemainingL10n.createSellerAccount)),
        ),
      ],
    ),
  );
  if (goRegister != true) return;
  await auth.logout();
  router.go('${AppRouteNames.register}?type=business');
}
