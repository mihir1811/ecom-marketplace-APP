import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../diamonds/presentation/widgets/diamond_svg_data.dart';
import '../../application/cart_provider.dart';
import '../../domain/models/cart_item.dart';

class CartItemCard extends ConsumerWidget {
  const CartItemCard({required this.item, super.key});

  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final border = AppColors.warmBorder;
    final bg = AppColors.warmWhite;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.r16),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(AppSpacing.s12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.sandSurface,
              borderRadius: BorderRadius.circular(AppSpacing.r12),
            ),
            child: Center(
              child: item.shape != null
                  ? renderShapeSvg(item.shape!, size: 36, color: AppColors.bronze)
                  : const Icon(Icons.diamond_outlined, color: AppColors.bronze),
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: AppTypography.label.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove',
                      onPressed: () =>
                          ref.read(cartProvider.notifier).removeItem(item.id),
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: AppColors.textMutedLight,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.sandSurface,
                    borderRadius: BorderRadius.circular(AppSpacing.circular),
                  ),
                  child: Text(
                    item.category,
                    style: AppTypography.caption.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  '\$${item.priceUsd.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Chat about product — coming soon'),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 14,
                        color: AppColors.bronze,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Chat about product',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.bronze,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
