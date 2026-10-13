import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/theme/app_colors.dart';
import '../../application/diamond_project_listing_pick_provider.dart';

/// Seller-only checkbox to pick a diamond for the next project selection.
class DiamondProjectPickCheckbox extends ConsumerWidget {
  const DiamondProjectPickCheckbox({
    required this.diamondId,
    this.size = listingControlSize,
    super.key,
  });

  /// Visual diameter — matches wishlist heart icon ([WishlistToggleButton.listingIconSize]).
  static const double listingControlSize = 18;

  /// Tap target — matches [WishlistToggleButton.listingHitSize].
  static const double listingHitSize = 34;

  final String diamondId;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canPick = ref.watch(
      authProvider.select((s) => s.isSeller || s.sellerId != null),
    );
    if (!canPick || diamondId.isEmpty) return const SizedBox.shrink();

    final picked = ref.watch(isDiamondProjectPickedProvider(diamondId));
    final isDark = AppColors.isDark(context);
    final fill = picked ? AppColors.bronze : AppColors.card(context);
    final borderColor = isDark
        ? AppColors.warmWhite.withValues(alpha: 0.85)
        : AppColors.charcoal;

    return SizedBox(
      width: listingHitSize,
      height: listingHitSize,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            AppHaptics.selection();
            ref
                .read(diamondProjectListingPickProvider.notifier)
                .toggle(diamondId);
          },
          customBorder: const CircleBorder(),
          child: Semantics(
            button: true,
            checked: picked,
            label: picked
                ? 'Remove from diamond project pick'
                : 'Add to diamond project pick',
            child: Center(
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: fill,
                  border: Border.all(color: borderColor, width: 1.5),
                ),
                child: picked
                    ? Icon(
                        Icons.check,
                        size: size * 0.55,
                        color: AppColors.warmWhite,
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Overlay control used beside the wishlist button on diamond listing cards.
class DiamondProjectPickBadge extends StatelessWidget {
  const DiamondProjectPickBadge({
    required this.diamondId,
    this.size = DiamondProjectPickCheckbox.listingControlSize,
    super.key,
  });

  final String diamondId;
  final double size;

  @override
  Widget build(BuildContext context) {
    return DiamondProjectPickCheckbox(diamondId: diamondId, size: size);
  }
}
