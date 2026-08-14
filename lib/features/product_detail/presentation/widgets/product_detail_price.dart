import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../buyer/application/wishlist_provider.dart';
import '../../../buyer/presentation/widgets/wishlist_toggle_button.dart';
import '../../../chat/presentation/open_product_seller_chat.dart';
import '../../domain/models/product_detail.dart';

/// Price block — the highest-priority number on the page.
class ProductDetailPrice extends ConsumerStatefulWidget {
  const ProductDetailPrice({required this.detail, super.key});

  final ProductDetail detail;

  @override
  ConsumerState<ProductDetailPrice> createState() => _ProductDetailPriceState();
}

class _ProductDetailPriceState extends ConsumerState<ProductDetailPrice> {
  bool _openingChat = false;

  Future<void> _openChat() async {
    if (_openingChat) return;
    setState(() => _openingChat = true);
    try {
      await openProductSellerChat(
        context,
        ref,
        productId: widget.detail.id,
        apiProductType: widget.detail.apiProductType,
      );
    } finally {
      if (mounted) setState(() => _openingChat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final price = detail.price;
    final unit = price.unitDisplay;
    final discount = price.discountPercent;
    final hasDiscount = price.hasDiscount;
    final formatAmount = price.displayAmountIsListPrice
        ? formatGroupedWhole
        : formatCatalogPrice;

    late final String saleLabel;
    late final String? listLabel;
    if (!hasDiscount) {
      saleLabel = price.display;
      listLabel = null;
    } else if (price.displayAmountIsListPrice) {
      // List in amountLabel → discounted = list × (1 − %/100).
      final sale = price.displayAmount * (1 - discount! / 100);
      listLabel = price.display;
      saleLabel = '${price.currencySymbol}${formatAmount(sale)}';
    } else {
      // Net already in amountLabel → list inferred from %.
      saleLabel = price.display;
      final list = price.displayAmount / (1 - discount! / 100);
      listLabel = '${price.currencySymbol}${formatAmount(list)}';
    }

    final wishlisted = ref.watch(isInWishlistProvider(detail.id));
    final canChat = ref.watch(authProvider.select((s) => s.isSeller));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (listLabel != null) ...[
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: AppSpacing.s12,
                      runSpacing: AppSpacing.s8,
                      children: [
                        Text(
                          listLabel,
                          style: AppTypography.body.copyWith(
                            color: AppColors.textMutedLight,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: AppColors.textMutedLight,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.terracotta,
                            borderRadius: BorderRadius.circular(AppSpacing.r8),
                          ),
                          child: Text(
                            '${formatDiscountPercent(discount!)}% off',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.warmWhite,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s4),
                  ],
                  Text(
                    saleLabel,
                    style: AppTypography.label.copyWith(
                      color: AppColors.textPrimaryLight,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (canChat) ...[
                  _ActionIcon(
                    icon: Icons.chat_bubble_outline,
                    tooltip: 'Chat with seller',
                    loading: _openingChat,
                    onTap: _openChat,
                  ),
                  const SizedBox(width: AppSpacing.s8),
                ],
                _ActionIcon(
                  icon: wishlisted ? Icons.favorite : Icons.favorite_border,
                  tooltip:
                      wishlisted ? 'Remove from wishlist' : 'Save to wishlist',
                  tint: wishlisted ? AppColors.terracotta : AppColors.charcoal,
                  onTap: () {
                    toggleWishlistItem(
                      context,
                      ref,
                      detail.toWishlistItem(),
                      addedMessage: 'Saved to wishlist',
                      removedMessage: 'Removed from wishlist',
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        if (unit != null) ...[
          const SizedBox(height: AppSpacing.s8),
          Text(
            unit,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondaryLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.tint = AppColors.charcoal,
    this.loading = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color tint;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(AppSpacing.r8),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.warmWhite,
            borderRadius: BorderRadius.circular(AppSpacing.r8),
            border: Border.all(color: AppColors.warmBorder),
          ),
          child: loading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(icon, size: 18, color: tint),
        ),
      ),
    );
  }
}
