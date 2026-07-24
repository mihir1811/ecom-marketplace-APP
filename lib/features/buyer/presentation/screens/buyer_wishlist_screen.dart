import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/buyer_layout.dart';

class BuyerWishlistScreen extends StatelessWidget {
  const BuyerWishlistScreen({super.key});

  static const _items = <_WishlistItem>[
    _WishlistItem(
      title: '1.02ct Round D VVS1',
      subtitle: 'Natural diamond · GIA',
      priceLabel: '₹4,85,000',
    ),
    _WishlistItem(
      title: 'Burmese Ruby 2.14ct',
      subtitle: 'Gemstone · Unheated',
      priceLabel: '₹2,10,000',
    ),
    _WishlistItem(
      title: '18K Gold Solitaire Ring',
      subtitle: 'Jewelry · Size 14',
      priceLabel: '₹1,25,000',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return BuyerLayout(
      title: 'My Wishlist',
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.s16),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s12),
        itemBuilder: (context, index) {
          final item = _items[index];
          return Container(
            padding: const EdgeInsets.all(AppSpacing.s16),
            decoration: BoxDecoration(
              color: AppColors.warmWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.warmBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.sandSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.diamond_outlined,
                    color: AppColors.bronze,
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.title.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.priceLabel,
                        style: AppTypography.label.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.favorite, color: AppColors.error),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WishlistItem {
  const _WishlistItem({
    required this.title,
    required this.subtitle,
    required this.priceLabel,
  });

  final String title;
  final String subtitle;
  final String priceLabel;
}
