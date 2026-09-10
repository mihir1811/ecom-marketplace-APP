import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../application/diamond_project_listing_pick_provider.dart';

/// Seller-only checkbox to pick a diamond for the next project selection.
class DiamondProjectPickCheckbox extends ConsumerWidget {
  const DiamondProjectPickCheckbox({
    required this.diamondId,
    this.size = 22,
    super.key,
  });

  final String diamondId;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canPick = ref.watch(
      authProvider.select((s) => s.isSeller || s.sellerId != null),
    );
    if (!canPick || diamondId.isEmpty) return const SizedBox.shrink();

    final picked = ref.watch(isDiamondProjectPickedProvider(diamondId));
    final border = picked ? AppColors.bronze : AppColors.border(context);
    final fill = picked
        ? AppColors.bronze
        : (AppColors.card(context).withValues(alpha: 0.92));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => ref
            .read(diamondProjectListingPickProvider.notifier)
            .toggle(diamondId),
        customBorder: const CircleBorder(),
        child: Semantics(
          button: true,
          checked: picked,
          label: picked
              ? 'Remove from diamond project pick'
              : 'Add to diamond project pick',
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: fill,
              border: Border.all(color: border, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: picked
                ? Icon(
                    Icons.check,
                    size: size * 0.6,
                    color: AppColors.warmWhite,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

/// Bottom-left overlay used on diamond listing cards.
class DiamondProjectPickBadge extends StatelessWidget {
  const DiamondProjectPickBadge({required this.diamondId, super.key});

  final String diamondId;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: AppSpacing.s8,
      left: AppSpacing.s8,
      child: DiamondProjectPickCheckbox(diamondId: diamondId),
    );
  }
}
