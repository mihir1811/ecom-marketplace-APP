import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_swatches.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../domain/models/jewelry.dart';

Color jewelryMetalSwatch(String label) => AppSwatches.jewelryMetal(label);

class JewelryProductCard extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.warmWhite;
    final border = AppColors.warmBorder;
    final text = AppColors.textPrimaryLight;
    final muted = AppColors.textMutedLight;
    final variants = item.colorVariants.take(4).toList();
    final extra = item.colorVariants.length - variants.length;

    if (compact) {
      return _compactCard(
        bg: bg,
        border: border,
        text: text,
        muted: muted,
        variants: variants,
      );
    }

    return _fullCard(
      bg: bg,
      border: border,
      text: text,
      muted: muted,
      variants: variants,
      extra: extra,
    );
  }

  Widget _compactCard({
    required Color bg,
    required Color border,
    required Color text,
    required Color muted,
    required List<String> variants,
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
          children: [
            Expanded(
              flex: 55,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _image(),
                  if (item.badge != null) _badge(),
                  Positioned(
                    top: AppSpacing.s8,
                    right: AppSpacing.s8,
                    child: Icon(
                      item.wishlisted
                          ? Icons.favorite
                          : Icons.favorite_border,
                      size: 18,
                      color: item.wishlisted
                          ? AppColors.terracotta
                          : muted,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 45,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        for (var i = 0; i < variants.length; i++) ...[
                          if (i > 0) const SizedBox(width: 4),
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: jewelryMetalSwatch(variants[i]),
                              border: Border.all(
                                color: i == 0 ? AppColors.bronze : border,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.name,
                      style: AppTypography.label.copyWith(
                        color: text,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${formatInrPrice(item.price)}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ).copyWith(color: text),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.metalPurity,
                      style: AppTypography.caption.copyWith(
                        fontSize: 10,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fullCard({
    required Color bg,
    required Color border,
    required Color text,
    required Color muted,
    required List<String> variants,
    required int extra,
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
                      onTap: onWishlist,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: bg.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item.wishlisted
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 18,
                          color: item.wishlisted
                              ? AppColors.terracotta
                              : muted,
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
                    '₹${formatInrPrice(item.price)}',
                    style: GoogleFonts.inter(
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
                        icon: Icons.favorite_border,
                        label: 'Wishlist',
                        onTap: onWishlist,
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
    final asset = item.imageAsset;
    if (asset == null) return _placeholder();
    return Image.asset(
      asset,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholder(),
    );
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

  Widget _placeholder() {
    return ColoredBox(
      color: AppColors.sandSurface,
      child: const Center(
        child: Icon(Icons.diamond_outlined, size: 40, color: AppColors.bronze),
      ),
    );
  }
}

class JewelryProductListCard extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.warmWhite;
    final border = AppColors.warmBorder;
    final text = AppColors.textPrimaryLight;
    final muted = AppColors.textMutedLight;
    final variants = item.colorVariants.take(3).toList();
    final purityLabel = item.metalPurity.replaceAll(' ', '').toLowerCase();

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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 112,
              height: 132,
              child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (item.imageAsset != null)
                      Image.asset(
                        item.imageAsset!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _listImagePlaceholder(),
                      )
                    else
                      _listImagePlaceholder(),
                    Positioned(
                      top: AppSpacing.s8,
                      right: AppSpacing.s8,
                      child: InkWell(
                        onTap: onWishlist,
                        child: Icon(
                          item.wishlisted
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 18,
                          color: item.wishlisted
                              ? AppColors.terracotta
                              : muted,
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
                    AppSpacing.s8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _displayTitle(item),
                        style: AppTypography.label.copyWith(
                          color: text,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.sku,
                        style: AppTypography.caption.copyWith(
                          color: muted,
                          fontSize: 11,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s8),
                      Wrap(
                        spacing: AppSpacing.s8,
                        runSpacing: AppSpacing.s4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '₹${formatInrPrice(item.price)}',
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ).copyWith(color: text),
                          ),
                          _OutlineBadge(
                            label: item.metalType,
                            borderColor: AppColors.bronze.withValues(alpha: 0.45),
                            textColor: AppColors.bronze,
                          ),
                          if (item.stoneCount > 0)
                            _StoneCountBadge(count: item.stoneCount),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'COLOR',
                                style: AppTypography.caption.copyWith(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: muted,
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
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'PURITY',
                                style: AppTypography.caption.copyWith(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: muted,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 4),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 56),
                                child: Text(
                                  purityLabel,
                                  style: AppTypography.caption.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: text,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _listImagePlaceholder() {
    return ColoredBox(
      color: AppColors.sandSurface,
      child: const Icon(
        Icons.diamond_outlined,
        color: AppColors.bronze,
      ),
    );
  }
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
    final muted = AppColors.textMutedLight;
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
    final muted = AppColors.textMutedLight;
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
