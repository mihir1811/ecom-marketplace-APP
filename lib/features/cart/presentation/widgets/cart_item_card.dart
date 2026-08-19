import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/error/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../diamonds/presentation/widgets/diamond_svg_data.dart';
import '../../../product_detail/application/catalog_product_detail_loader.dart';
import '../../../product_detail/product_detail_navigation.dart';
import '../../application/cart_provider.dart';
import '../../domain/models/cart_item.dart';

class CartItemCard extends ConsumerStatefulWidget {
  const CartItemCard({required this.item, super.key});

  final CartItem item;

  @override
  ConsumerState<CartItemCard> createState() => _CartItemCardState();
}

class _CartItemCardState extends ConsumerState<CartItemCard> {
  bool _opening = false;

  Future<void> _openProduct() async {
    if (_opening) return;
    final item = widget.item;
    if (item.productId.isEmpty) return;

    if (openRememberedProductDetail(context, item.productId)) return;

    setState(() => _opening = true);
    try {
      final detail = await CatalogProductDetailLoader.load(
        ref.read,
        productType: item.productType,
        productId: item.productId,
      );
      if (!mounted) return;
      if (detail != null) {
        openProductDetail(context, detail);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open this product right now.'),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final mutating = ref.watch(cartIsMutatingProvider);
    final available = item.isAvailable;
    final muted = AppColors.textMuted(context);

    return Opacity(
      opacity: available ? 1 : 0.72,
      child: Material(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppSpacing.r16),
        child: InkWell(
          onTap: _opening ? null : _openProduct,
          borderRadius: BorderRadius.circular(AppSpacing.r16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.r16),
              border: Border.all(
                color: available ? AppColors.border(context) : AppColors.error.withValues(alpha: 0.35),
              ),
            ),
            padding: const EdgeInsets.all(AppSpacing.s12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    _Thumb(item: item),
                    if (!available)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.charcoal.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(AppSpacing.r12),
                          ),
                          child: Center(
                            child: Text(
                              item.availabilityLabel ?? 'Unavailable',
                              textAlign: TextAlign.center,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.warmWhite,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (_opening)
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.charcoal.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(AppSpacing.r12),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.warmWhite,
                            ),
                          ),
                        ),
                      ),
                  ],
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
                                color: available
                                    ? AppColors.textPrimary(context)
                                    : muted,
                                decoration: available
                                    ? null
                                    : TextDecoration.lineThrough,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Remove',
                            onPressed: mutating || _opening
                                ? null
                                : () async {
                                    final result = await ref
                                        .read(cartProvider.notifier)
                                        .removeItem(item.cartId);
                                    if (!context.mounted) return;
                                    if (result
                                        case ResultFailure(:final failure)) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(failure.message),
                                        ),
                                      );
                                    }
                                  },
                            icon: const Icon(Icons.delete_outline, size: 20),
                          color: AppColors.textMuted(context),
                          visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      if (!available) ...[
                        const SizedBox(height: AppSpacing.s4),
                        Text(
                          item.availabilityLabel ?? 'Unavailable',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      if (item.seller != null && item.seller!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.s4),
                        Text(
                          item.seller!,
                          style: AppTypography.caption.copyWith(
                            color: muted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.s8),
                      Text(
                        AppCurrency.format(
                          item.displayPriceUsd.toStringAsFixed(2),
                        ),
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: available
                              ? AppColors.textPrimary(context)
                              : muted,
                          decoration: available
                              ? null
                              : TextDecoration.lineThrough,
                        ),
                      ),
                      if (item.quantity > 1) ...[
                        const SizedBox(height: AppSpacing.s4),
                        Text(
                          'Qty ${item.quantity}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppSpacing.r12),
      ),
      clipBehavior: Clip.antiAlias,
      child: item.imageUrl != null && item.imageUrl!.isNotEmpty
          ? AppNetworkImage(
              url: item.imageUrl!,
              fit: BoxFit.cover,
              width: 72,
              height: 72,
              memCacheWidth: 144,
              error: _fallback(),
            )
          : _fallback(),
    );
  }

  Widget _fallback() {
    return Center(
      child: item.shape != null
          ? renderShapeSvg(item.shape!, size: 36, color: AppColors.bronze)
          : const Icon(Icons.diamond_outlined, color: AppColors.bronze),
    );
  }
}
