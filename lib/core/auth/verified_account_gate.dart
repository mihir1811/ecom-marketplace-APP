import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../router/app_navigation.dart';
import '../router/route_names.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'account_access.dart';
import 'auth_providers.dart';

/// Blocks buying/selling surfaces until admin KYC is complete.
class VerifiedAccountGate extends ConsumerWidget {
  const VerifiedAccountGate({
    super.key,
    required this.child,
    this.fallbackRoute = AppRouteNames.home,
  });

  final Widget child;
  final String fallbackRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(
      authProvider.select((s) => s.isVerificationPending),
    );
    if (!pending) return child;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      context.resetTo(fallbackRoute);
    });

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Text(
          AccountAccess.pendingMessage,
          textAlign: TextAlign.center,
          style: AppTypography.body,
        ),
      ),
    );
  }
}
