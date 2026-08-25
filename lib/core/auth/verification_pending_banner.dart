import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'auth_providers.dart';

/// Persistent notice while an admin review is outstanding.
class VerificationPendingBanner extends ConsumerWidget {
  const VerificationPendingBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending =
        ref.watch(authProvider.select((s) => s.isVerificationPending));
    if (!pending) return const SizedBox.shrink();

    final dark = AppColors.isDark(context);
    return Material(
      color: AppColors.warning.withValues(alpha: dark ? 0.22 : 0.12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s8,
        ),
        child: Row(
          children: [
            Icon(
              Icons.hourglass_top_rounded,
              size: 18,
              color: dark ? AppColors.bronzeLight : AppColors.warning,
            ),
            const SizedBox(width: AppSpacing.s8),
            Expanded(
              child: Text(
                'Verification is pending. You can explore the app, but buying '
                'and selling stay unavailable until an admin verifies your '
                'account.',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textPrimary(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
