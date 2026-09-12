import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/diamond_project_listing_pick_provider.dart';

/// Sticky bottom tray when ≥1 diamond is picked for project analysis.
class DiamondProjectPickBottomBar extends ConsumerWidget {
  const DiamondProjectPickBottomBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canUse = ref.watch(
      authProvider.select((s) => s.isSeller || s.sellerId != null),
    );
    if (!canUse) return const SizedBox.shrink();

    final count = ref.watch(
      diamondProjectListingPickProvider.select((s) => s.length),
    );
    if (count == 0) return const SizedBox.shrink();

    final label = count == 1 ? 'diamond' : 'diamonds';

    return Material(
      elevation: 8,
      color: AppColors.card(context),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border(context))),
            boxShadow: AppShadows.modalLight,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s12,
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, size: 18, color: AppColors.bronze),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: Text(
                  '$count $label selected',
                  style: AppTypography.label.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () =>
                    ref.read(diamondProjectListingPickProvider.notifier).clear(),
                child: Text(
                  context.tr(CatalogL10n.clearAll),
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
