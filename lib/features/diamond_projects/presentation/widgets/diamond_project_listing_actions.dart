import 'package:flutter/material.dart';
import '../../../../core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../diamonds/application/diamond_list_provider.dart';
import '../../../diamonds/application/diamond_search_provider.dart';
import '../../../diamonds/domain/models/diamond_catalog_type.dart';
import '../../application/diamond_project_selection_provider.dart';

/// Seller-only listing actions: select loaded stones or open saved projects.
class DiamondProjectListingActions extends ConsumerWidget {
  const DiamondProjectListingActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canUse = ref.watch(
      authProvider.select((s) => s.isSeller || s.sellerId != null),
    );
    if (!canUse) return const SizedBox.shrink();

    final loadedCount = ref.watch(
      diamondListProvider.select(
        (async) => async.valueOrNull?.diamonds.length ?? 0,
      ),
    );

    final selectLabel =
        loadedCount == 0 ? 'Select page' : 'Select page ($loadedCount)';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s8,
        AppSpacing.s16,
        AppSpacing.s8,
      ),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: loadedCount == 0
                  ? null
                  : () {
                      final diamonds =
                          ref.read(diamondListProvider).valueOrNull?.diamonds ??
                          const [];
                      if (diamonds.isEmpty) return;
                      ref
                          .read(diamondProjectSelectionProvider.notifier)
                          .selectLoadedPage(
                            diamonds: diamonds,
                            filters: ref.read(diamondSearchProvider),
                            catalog: ref.read(diamondCatalogTypeProvider),
                          );
                      context.push(AppRouteNames.diamondProject);
                    },
              icon: const Icon(Icons.analytics_outlined, size: 14),
              label: Text(
                selectLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSelected(context),
                  fontSize: 12,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.selectedFill(context),
                foregroundColor: AppColors.onSelected(context),
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s8,
                  vertical: AppSpacing.s8,
                ),
                minimumSize: const Size(0, 36),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () =>
                  context.push(AppRouteNames.savedDiamondProjects),
              icon: const Icon(Icons.folder_outlined, size: 14),
              label: Text(
                context.tr(CatalogL10n.savedStatistics),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary(context),
                  fontSize: 12,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary(context),
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s8,
                  vertical: AppSpacing.s8,
                ),
                minimumSize: const Size(0, 36),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact helper text shown under listing actions.
class DiamondProjectListingHint extends StatelessWidget {
  const DiamondProjectListingHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.s16,
        right: AppSpacing.s16,
        bottom: AppSpacing.s8,
      ),
      child: Text(
        'Statistics use diamonds already loaded on this screen.',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.caption.copyWith(
          color: AppColors.textMuted(context),
        ),
      ),
    );
  }
}
