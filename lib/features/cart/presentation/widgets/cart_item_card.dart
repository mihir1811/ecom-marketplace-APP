import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/error/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../diamonds/presentation/widgets/diamond_svg_data.dart';
import '../../../product_detail/product_detail_navigation.dart';
import '../../application/cart_provider.dart';
import '../../domain/models/cart_item.dart';

class CartItemCard extends ConsumerWidget {
  const CartItemCard({required this.item, super.key});

  final CartItem item;

  void _openProduct(BuildContext context) {
    if (openRememberedProductDetail(context, item.productId)) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Open this product from the catalog to see its details.',
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mutating = ref.watch(cartIsMutatingProvider);

    return Material(
      color: AppColors.warmWhite,
      borderRadius: BorderRadius.circular(AppSpacing.r16),
      child: InkWell(
        onTap: () => _openProduct(context),
        borderRadius: BorderRadius.circular(AppSpacing.r16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.r16),
            border: Border.all(color: AppColors.warmBorder),
          ),
          padding: const EdgeInsets.all(AppSpacing.s12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumb(item: item),
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
                          onPressed: mutating
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
                          color: AppColors.textMutedLight,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    if (item.seller != null && item.seller!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.s4),
                      Text(
                        item.seller!,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMutedLight,
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
                      ),
                    ),
                    if (item.quantity > 1) ...[
                      const SizedBox(height: AppSpacing.s4),
                      Text(
                        'Qty ${item.quantity}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondaryLight,
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
        color: AppColors.sandSurface,
        borderRadius: BorderRadius.circular(AppSpacing.r12),
      ),
      clipBehavior: Clip.antiAlias,
      child: item.imageUrl != null && item.imageUrl!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: item.imageUrl!,
              fit: BoxFit.cover,
              memCacheWidth: 144,
              placeholder: (_, __) => const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (_, __, ___) => _fallback(),
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
