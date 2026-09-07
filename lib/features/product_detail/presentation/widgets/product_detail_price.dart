import 'package:flutter/material.dart';
import '../../../../core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../buyer/application/wishlist_provider.dart';
import '../../../buyer/presentation/widgets/wishlist_toggle_button.dart';
import '../../../chat/presentation/open_product_seller_chat.dart';
import '../../../product_share/presentation/widgets/product_share_sheet.dart';
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
    // Jewelry shows wishlist/share beside badges in the header.
    if (detail.jewelryDetail != null) {
      return const SizedBox.shrink();
    }
    final price = detail.price;
    final unitKey = price.unitLabel == null
        ? null
        : catalogDisplayMessageKeys[price.unitLabel!];
    final localizedUnit = unitKey == null
        ? price.unitLabel
        : context.tr(unitKey);
    final unit = price.isOnRequest ||
            price.unitAmountLabel == null ||
            localizedUnit == null
        ? null
        : '${price.currencySymbol}${price.unitAmountLabel} $localizedUnit';
    final discount = price.discountPercent;
    final hasDiscount = price.hasDiscount;
    final formatAmount = price.displayAmountIsListPrice
        ? formatGroupedWhole
        : formatCatalogPrice;

    // Catalog lot price from API — never scale with melee pcs/carat draft.
    final amount = price.displayAmount;

    late final String saleLabel;
    late final String? listLabel;
    if (price.isOnRequest) {
      saleLabel = price.display;
      listLabel = null;
    } else if (!hasDiscount) {
      saleLabel = '${price.currencySymbol}${formatAmount(amount)}';
      listLabel = null;
    } else if (price.displayAmountIsListPrice) {
      // List in amountLabel → discounted = list × (1 − %/100).
      final list = amount;
      final sale = list * (1 - discount! / 100);
      listLabel = '${price.currencySymbol}${formatAmount(list)}';
      saleLabel = '${price.currencySymbol}${formatAmount(sale)}';
    } else {
      // Net already in amountLabel → list inferred from %.
      saleLabel = '${price.currencySymbol}${formatAmount(amount)}';
      final list = amount / (1 - discount! / 100);
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
                            color: AppColors.textMuted(context),
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: AppColors.textMuted(context),
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
                      color: hasDiscount
                          ? AppColors.success
                          : AppColors.textPrimary(context),
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
                _ActionIcon(
                  icon: wishlisted ? Icons.favorite : Icons.favorite_border,
                  tooltip: wishlisted
                      ? 'Remove from wishlist'
                      : 'Save to wishlist',
                  tint: wishlisted
                      ? AppColors.terracotta
                      : AppColors.textPrimary(context),
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
                if (canChat) ...[
                  const SizedBox(width: AppSpacing.s8),
                  _ActionIcon(
                    icon: Icons.chat_bubble_outline,
                    tooltip: context.tr(CatalogL10n.chatWithSeller),
                    loading: _openingChat,
                    onTap: _openChat,
                  ),
                ],
                const SizedBox(width: AppSpacing.s8),
                _ActionIcon(
                  icon: Icons.share_outlined,
                  tooltip: context.tr(CatalogL10n.share),
                  onTap: () => showProductShareSheet(
                    context: context,
                    ref: ref,
                    productId: detail.id,
                    productType: detail.apiProductType,
                    productTitle: detail.title,
                  ),
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
              color: AppColors.textSecondary(context),
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
    this.tint,
    this.loading = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? tint;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final iconColor = tint ?? AppColors.textPrimary(context);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(AppSpacing.r8),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(AppSpacing.r8),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: loading
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: iconColor,
                  ),
                )
              : Icon(icon, size: 18, color: iconColor),
        ),
      ),
    );
  }
}
