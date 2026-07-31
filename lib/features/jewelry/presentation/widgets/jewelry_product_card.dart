import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_swatches.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/catalog_missing_image.dart';
import '../../../../core/widgets/marketplace_product_card_shell.dart';
import '../../../buyer/application/wishlist_provider.dart';
import '../../../buyer/domain/models/wishlist_item.dart';
import '../../../buyer/presentation/widgets/wishlist_toggle_button.dart';
import '../../domain/models/jewelry.dart';
import '../../../../core/utils/app_currency.dart';

Color jewelryMetalSwatch(String label) => AppSwatches.jewelryMetal(label);

class JewelryProductCard extends ConsumerWidget {
  const JewelryProductCard({
    required this.item,
    this.compact = false,
    this.onTap,
    this.onWishlist,
    super.key,
  });

  final Jewelry item;
  final bool compact;
  final VoidCallback? onTap;
  final VoidCallback? onWishlist;

  void _toggleWishlist(BuildContext context, WidgetRef ref) {
    if (onWishlist != null) {
      onWishlist!();
      return;
    }
    final added = ref
        .read(wishlistProvider.notifier)
        .toggle(WishlistItem.fromJewelry(item));
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Text(added ? 'Added to wishlist' : 'Removed from wishlist'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bg = AppColors.warmWhite;
    final border = AppColors.warmBorder;
    final text = AppColors.textPrimaryLight;
    final muted = AppColors.textSecondaryLight;
    final variants = item.colorVariants.take(4).toList();
    final extra = item.colorVariants.length - variants.length;
    final wishlisted = ref.watch(isInWishlistProvider(item.id));

    if (compact) {
      return _compactCard(
        context: context,
        ref: ref,
        bg: bg,
        border: border,
        text: text,
        muted: muted,
        variants: variants,
        wishlisted: wishlisted,
      );
    }

    return _fullCard(
      context: context,
      ref: ref,
      bg: bg,
      border: border,
      text: text,
      muted: muted,
      variants: variants,
      extra: extra,
      wishlisted: wishlisted,
    );
  }

  Widget _compactCard({
    required BuildContext context,
    required WidgetRef ref,
    required Color bg,
    required Color border,
    required Color text,
    required Color muted,
    required List<String> variants,
    required bool wishlisted,
  }) {
    final title = () {
      final dash = item.name.split(' — ');
      if (dash.length > 1) return dash.first.trim();
      return item.name;
    }();
    final specs = [
      item.metalType,
      if (item.metalPurity.trim().isNotEmpty) item.metalPurity,
      if (item.stoneWeightCt > 0)
        '${item.stoneWeightCt.toStringAsFixed(2)}ct',
    ].join(' · ');

    return MarketplaceProductCardShell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1.05,
            child: Stack(
              children: [
                Positioned.fill(child: _image()),
                if (item.badge != null) _badge(),
                Positioned(
                  top: AppSpacing.s4,
                  right: AppSpacing.s4,
                  child: WishlistToggleButton(
                    item: WishlistItem.fromJewelry(item),
                    size: 18,
                  ),
                ),
                if (item.discount != null && item.discount! > 0)
                  Positioned(
                    top: AppSpacing.s8,
                    left: AppSpacing.s8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s8,
                        vertical: AppSpacing.s4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.terracotta,
                        borderRadius: BorderRadius.circular(AppSpacing.r4),
                      ),
                      child: Text(
                        '-${item.discount!.round()}%',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.warmWhite,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s12,
                AppSpacing.s12,
                AppSpacing.s12,
                AppSpacing.s12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.category,
                    style: AppTypography.caption.copyWith(
                      color: muted,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                      height: 1.35,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.cardLineGap),
                  Text(
                    title,
                    style: AppTypography.label.copyWith(
                      color: text,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.cardLineGap),
                  Text(
                    specs,
                    style: AppTypography.caption.copyWith(
                      color: muted,
                      fontSize: 11,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  const SizedBox(height: AppSpacing.cardPriceGap),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppCurrency.format(formatInrPrice(item.price)),
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ).copyWith(color: text),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: AppColors.bronze,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fullCard({
    required BuildContext context,
    required WidgetRef ref,
    required Color bg,
    required Color border,
    required Color text,
    required Color muted,
    required List<String> variants,
    required int extra,
    required bool wishlisted,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppSpacing.r12),
          border: Border.all(color: border),
          boxShadow: AppShadows.cardLight,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 1.15,
              child: Stack(
                children: [
                  Positioned.fill(child: _image()),
                  if (item.badge != null) _badge(),
                  Positioned(
                    top: AppSpacing.s8,
                    right: AppSpacing.s8,
                    child: InkWell(
                      onTap: () => _toggleWishlist(context, ref),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: bg.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          wishlisted ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: wishlisted ? AppColors.terracotta : muted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < variants.length; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: jewelryMetalSwatch(variants[i]),
                            border: Border.all(
                              color: i == 0 ? AppColors.bronze : border,
                              width: i == 0 ? 1.5 : 1,
                            ),
                          ),
                        ),
                      ],
                      if (extra > 0) ...[
                        const SizedBox(width: 6),
                        Text(
                          '+$extra',
                          style: AppTypography.caption.copyWith(
                            color: muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    item.name,
                    style: AppTypography.label.copyWith(
                      color: text,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    AppCurrency.format(formatInrPrice(item.price)),
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ).copyWith(color: text),
                  ),
                  if (item.discount != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${item.discount!.round()}% off · EMI available',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.bronze,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.s8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.sandSurface,
                      borderRadius: BorderRadius.circular(AppSpacing.r8),
                    ),
                    child: Text(
                      item.metalPurity,
                      style: AppTypography.caption.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: text,
                      ),
                    ),
                  ),
                  if (item.rating != null) ...[
                    const SizedBox(height: AppSpacing.s8),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: AppColors.bronze,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${item.rating}',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: text,
                          ),
                        ),
                        if (item.reviewCount != null)
                          Text(
                            ' (${item.reviewCount})',
                            style:
                                AppTypography.caption.copyWith(color: muted),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.s12),
                  Row(
                    children: [
                      _QuickAction(
                        icon: wishlisted
                            ? Icons.favorite
                            : Icons.favorite_border,
                        label: 'Wishlist',
                        onTap: () => _toggleWishlist(context, ref),
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      _QuickAction(
                        icon: Icons.compare_arrows,
                        label: 'Compare',
                        onTap: () {},
                      ),
                      const Spacer(),
                      _QuickAction(
                        icon: Icons.visibility_outlined,
                        label: 'View',
                        onTap: onTap,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _image() {
    final network = item.displayImageUrl;
    if (network != null) {
      return AppNetworkImage(
        url: network,
        fit: BoxFit.cover,
        memCacheWidth: 480,
        error: const CatalogMissingImage(),
      );
    }
    return const CatalogMissingImage();
  }

  Widget _badge() {
    return Positioned(
      top: AppSpacing.s8,
      left: AppSpacing.s8,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s8,
          vertical: AppSpacing.s4,
        ),
        decoration: BoxDecoration(
          color: AppColors.charcoal,
          borderRadius: BorderRadius.circular(AppSpacing.r4),
        ),
        child: Text(
          item.badge ?? '',
          style: AppTypography.caption.copyWith(
            color: AppColors.warmWhite,
            fontWeight: FontWeight.w700,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}

class JewelryProductListCard extends ConsumerWidget {
  const JewelryProductListCard({
    required this.item,
    this.onTap,
    this.onWishlist,
    super.key,
  });

  final Jewelry item;
  final VoidCallback? onTap;
  final VoidCallback? onWishlist;

  String _displayTitle(Jewelry item) {
    final dash = item.name.split(' — ');
    if (dash.length > 1) return dash.first.trim();
    if (item.subCategory != null && item.subCategory!.isNotEmpty) {
      return '${item.subCategory} ${item.metalType} ${item.category}';
    }
    return item.name;
  }

  void _toggleWishlist(BuildContext context, WidgetRef ref) {
    if (onWishlist != null) {
      onWishlist!();
      return;
    }
    final added = ref
        .read(wishlistProvider.notifier)
        .toggle(WishlistItem.fromJewelry(item));
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Text(added ? 'Added to wishlist' : 'Removed from wishlist'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bg = AppColors.warmWhite;
    final border = AppColors.warmBorder;
    final text = AppColors.textPrimaryLight;
    final secondary = AppColors.textSecondaryLight;
    final variants = item.colorVariants.take(3).toList();
    final purityLabel = item.metalPurity.replaceAll(' ', '').toLowerCase();
    final wishlisted = ref.watch(isInWishlistProvider(item.id));
    final stoneLine = _jewelryStoneLine(item);
    final metalLine = [
      item.metalType,
      if (item.metalColor.trim().isNotEmpty) item.metalColor,
      if (item.metalWeightG > 0)
        '${item.metalWeightG.toStringAsFixed(item.metalWeightG >= 10 ? 1 : 2)}g',
    ].join(' · ');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppSpacing.r12),
          border: Border.all(color: border),
          boxShadow: AppShadows.cardLight,
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 112,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 140),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (item.displayImageUrl != null)
                        AppNetworkImage(
                          url: item.displayImageUrl!,
                          fit: BoxFit.cover,
                          memCacheWidth: 320,
                          error: const CatalogMissingImage(
                            padding: AppSpacing.s16,
                          ),
                        )
                      else
                        const CatalogMissingImage(padding: AppSpacing.s16),
                      Positioned(
                        top: AppSpacing.s8,
                        right: AppSpacing.s8,
                        child: InkWell(
                          onTap: () => _toggleWishlist(context, ref),
                          child: Icon(
                            wishlisted
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 18,
                            color: wishlisted
                                ? AppColors.terracotta
                                : secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s16,
                    AppSpacing.s16,
                    AppSpacing.s16,
                    AppSpacing.s16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.category,
                        style: AppTypography.caption.copyWith(
                          color: secondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.cardLineGap),
                      Text(
                        _displayTitle(item),
                        style: AppTypography.label.copyWith(
                          color: text,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.cardLineGap),
                      Text(
                        metalLine,
                        style: AppTypography.caption.copyWith(
                          color: secondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (stoneLine != null) ...[
                        const SizedBox(height: AppSpacing.cardLineGap),
                        Text(
                          stoneLine,
                          style: AppTypography.caption.copyWith(
                            color: secondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                          maxLines: 2,
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.cardPriceGap),
                      Wrap(
                        spacing: AppSpacing.s8,
                        runSpacing: AppSpacing.s8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            AppCurrency.format(formatInrPrice(item.price)),
                            style: GoogleFonts.manrope(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ).copyWith(color: text),
                          ),
                          _OutlineBadge(
                            label: purityLabel,
                            borderColor:
                                AppColors.bronze.withValues(alpha: 0.45),
                            textColor: AppColors.bronze,
                          ),
                          if (item.stoneCount > 0)
                            _StoneCountBadge(count: item.stoneCount),
                        ],
                      ),
                      if (variants.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.cardPriceGap),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'COLOR',
                              style: AppTypography.caption.copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: secondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 4),
                            for (var i = 0; i < variants.length; i++) ...[
                              if (i > 0) const SizedBox(width: 3),
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: jewelryMetalSwatch(variants[i]),
                                  border: Border.all(
                                    color: i == 0 ? text : border,
                                    width: i == 0 ? 1.5 : 1,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
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

String? _jewelryStoneLine(Jewelry item) {
  final parts = <String>[];
  if (item.stoneType.trim().isNotEmpty) parts.add(item.stoneType);
  if (item.stoneShape.trim().isNotEmpty) parts.add(item.stoneShape);
  if (item.stoneWeightCt > 0) {
    parts.add('${item.stoneWeightCt.toStringAsFixed(2)}ct');
  }
  if (item.certification.trim().isNotEmpty &&
      item.certification.toLowerCase() != 'n/a') {
    parts.add(item.certification);
  }
  if (parts.isEmpty) return null;
  return parts.join(' · ');
}

class _OutlineBadge extends StatelessWidget {
  const _OutlineBadge({
    required this.label,
    required this.borderColor,
    required this.textColor,
  });

  final String label;
  final Color borderColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

class _StoneCountBadge extends StatelessWidget {
  const _StoneCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.textSecondaryLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: muted.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppSwatches.jewelryAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$count Stones',
            style: AppTypography.caption.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.textSecondaryLight;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.r8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: muted),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: muted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
