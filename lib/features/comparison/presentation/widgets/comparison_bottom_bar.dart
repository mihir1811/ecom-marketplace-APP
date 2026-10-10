import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';

import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/comparison_provider.dart';

/// Sticky bottom tray shown when ≥1 item is selected for comparison.
class ComparisonBottomBar extends ConsumerWidget {
  const ComparisonBottomBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(comparisonProvider);
    if (state.isEmpty) return const SizedBox.shrink();
    final category = state.category!;
    final label = state.count == 1 ? category.label : category.labelPlural;

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
              Icon(Icons.check_circle, size: 18, color: AppColors.bronze),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: Text(
                  '${state.count} $label selected',
                  style: AppTypography.label.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () => ref.read(comparisonProvider.notifier).clear(),
                child: Text(
                  'Clear All',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s4),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.charcoal,
                  foregroundColor: AppColors.warmWhite,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s16,
                    vertical: AppSpacing.s12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.r8),
                  ),
                ),
                onPressed: state.count >= 2
                    ? () => context.openRoute(AppRouteNames.comparison)
                    : null,
                child: Text(
                  context.tr(AccountCommerceL10n.compare),
                  style: AppTypography.label.copyWith(
                    color: AppColors.warmWhite,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
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

/// Wraps a listing body with bottom padding when the comparison tray is visible.
class ComparisonTrayHost extends ConsumerWidget {
  const ComparisonTrayHost({required this.child, super.key});

  final Widget child;

  static const double barReserve = 72;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Expanded(child: child),
        const ComparisonBottomBar(),
      ],
    );
  }
}
