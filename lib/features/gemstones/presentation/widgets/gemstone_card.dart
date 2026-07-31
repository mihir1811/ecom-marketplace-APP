import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/marketplace_product_card_shell.dart';
import '../../../buyer/domain/models/wishlist_item.dart';
import '../../../buyer/presentation/widgets/wishlist_toggle_button.dart';
import '../../../comparison/application/comparison_provider.dart';
import '../../../comparison/domain/models/compare_item.dart';
import '../../../comparison/presentation/widgets/compare_add_button.dart';
import '../../../comparison/presentation/widgets/compare_toggle_helper.dart';
import '../../../product_detail/product_detail_navigation.dart';
import '../../domain/gemstone_assets.dart';
import '../../domain/models/gemstone.dart';

class GemstoneCardGrid extends ConsumerWidget {
  const GemstoneCardGrid({
    required this.gemstone,
    this.onTap,
    super.key,
  });

  final Gemstone gemstone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const textColor = AppColors.textPrimaryLight;
    const mutedColor = AppColors.textMutedLight;
    final inCompare = ref.watch(isInComparisonProvider(gemstone.id));

    return MarketplaceProductCardShell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: _GemstoneThumb(
                    gemstone: gemstone,
                    padding: AppSpacing.s24,
                  ),
                ),
                if (gemstone.discount != null && gemstone.discount! > 0)
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
                        '-${gemstone.discount!.round()}%',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.warmWhite,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: AppSpacing.s8,
                  left: AppSpacing.s4,
                  child: WishlistToggleButton(
                    item: WishlistItem.fromGemstone(gemstone),
                    size: 18,
                  ),
                ),
                Positioned(
                  bottom: AppSpacing.s8,
                  right: AppSpacing.s8,
                  child: CompareAddButton(
                    isSelected: inCompare,
                    onPressed: () => handleCompareToggle(
                      context,
                      ref,
                      CompareItem.fromGemstone(gemstone),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s12,
              AppSpacing.s8,
              AppSpacing.s12,
              AppSpacing.s8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppCurrency.format(formatCatalogPrice(gemstone.price)),
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ).copyWith(color: textColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${gemstone.carat.toStringAsFixed(2)}ct · ${gemstone.type}',
                  style: AppTypography.caption.copyWith(
                    color: mutedColor,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (gemstone.shape.isNotEmpty) gemstone.shape,
                    if (gemstone.origin.isNotEmpty) gemstone.origin,
                  ].join(' · '),
                  style: AppTypography.caption.copyWith(
                    color: mutedColor,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal list card matching [DiamondCardList] structure with gemstone data.
class GemstoneCardList extends ConsumerWidget {
  const GemstoneCardList({
    required this.gemstone,
    this.onTap,
    super.key,
  });

  final Gemstone gemstone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title =
        '${gemstone.carat.toStringAsFixed(2)}ct ${_display(gemstone.type)}';
    final price = AppCurrency.format(formatCatalogPrice(gemstone.price));
    final inCompare = ref.watch(isInComparisonProvider(gemstone.id));

    return MarketplaceProductCardShell(
      borderRadius: AppSpacing.r12,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16,
          AppSpacing.s20,
          AppSpacing.s16,
          AppSpacing.s20,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ListMedia(
                gemstone: gemstone,
                inCompare: inCompare,
                onCompare: () => handleCompareToggle(
                  context,
                  ref,
                  CompareItem.fromGemstone(gemstone),
                ),
              ),
              const SizedBox(width: AppSpacing.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: AppTypography.title.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              height: 1.3,
                              color: AppColors.textPrimaryLight,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s12),
                        Text(
                          price,
                          style: AppTypography.title.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            height: 1.3,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s20),
                    _SpecGrid(gemstone: gemstone),
                    const SizedBox(height: AppSpacing.s16),
                    _MetaRow(gemstone: gemstone),
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

class GemstoneListView extends StatelessWidget {
  const GemstoneListView({
    required this.gemstones,
    required this.scrollController,
    this.isLoadingMore = false,
    super.key,
  });

  final List<Gemstone> gemstones;
  final ScrollController scrollController;
  final bool isLoadingMore;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      cacheExtent: 600,
      addAutomaticKeepAlives: false,
      padding: const EdgeInsets.only(
        left: AppSpacing.s16,
        right: AppSpacing.s16,
        top: AppSpacing.s8,
        bottom: AppSpacing.s24,
      ),
      itemCount: gemstones.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= gemstones.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Text(
                  'Loading more...',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMutedLight,
                  ),
                ),
              ],
            ),
          );
        }
        final gemstone = gemstones[index];
        return RepaintBoundary(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s12),
            child: GemstoneCardList(
              key: ValueKey(gemstone.id),
              gemstone: gemstone,
              onTap: () => openGemstoneDetail(context, gemstone),
            ),
          ),
        );
      },
    );
  }
}

class GemstoneGridView extends StatelessWidget {
  const GemstoneGridView({
    required this.gemstones,
    required this.scrollController,
    this.isLoadingMore = false,
    super.key,
  });

  final List<Gemstone> gemstones;
  final ScrollController scrollController;
  final bool isLoadingMore;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: scrollController,
      cacheExtent: 600,
      addAutomaticKeepAlives: false,
      padding: const EdgeInsets.only(
        left: AppSpacing.s16,
        right: AppSpacing.s16,
        top: AppSpacing.s8,
        bottom: AppSpacing.s24,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.s12,
        mainAxisSpacing: AppSpacing.s12,
        childAspectRatio: 0.72,
      ),
      itemCount: gemstones.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= gemstones.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.s16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final gemstone = gemstones[index];
        return RepaintBoundary(
          child: GemstoneCardGrid(
            key: ValueKey(gemstone.id),
            gemstone: gemstone,
            onTap: () => openGemstoneDetail(context, gemstone),
          ),
        );
      },
    );
  }
}

class _ListMedia extends StatelessWidget {
  const _ListMedia({
    required this.gemstone,
    required this.inCompare,
    required this.onCompare,
  });

  final Gemstone gemstone;
  final bool inCompare;
  final VoidCallback onCompare;

  static const double _width = 116;
  static const double _minHeight = 132;

  @override
  Widget build(BuildContext context) {
    final certLab = _labBadge(gemstone.lab);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _minHeight),
      child: SizedBox(
        width: _width,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.sandSurface,
                  borderRadius: BorderRadius.circular(AppSpacing.r8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.r8),
                  child: _GemstoneThumb(
                    gemstone: gemstone,
                    padding: AppSpacing.s12,
                    cover: true,
                  ),
                ),
              ),
            ),
            if (certLab != null)
              Positioned(
                top: AppSpacing.s8,
                left: AppSpacing.s8,
                child: _CertificateLabBadge(label: certLab),
              ),
            Positioned(
              top: AppSpacing.s4,
              right: AppSpacing.s4,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.warmWhite,
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                    BorderSide(color: AppColors.warmBorder),
                  ),
                ),
                child: WishlistToggleButton(
                  item: WishlistItem.fromGemstone(gemstone),
                  size: 13,
                  padded: true,
                ),
              ),
            ),
            Positioned(
              bottom: AppSpacing.s4,
              right: AppSpacing.s4,
              child: CompareAddButton(
                size: 30,
                isSelected: inCompare,
                onPressed: onCompare,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CertificateLabBadge extends StatelessWidget {
  const _CertificateLabBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s8,
        vertical: AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: AppColors.bronze,
        borderRadius: BorderRadius.circular(AppSpacing.r4),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: AppColors.warmWhite,
          fontWeight: FontWeight.w700,
          fontSize: 9,
          height: 1.1,
          letterSpacing: 0.2,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _SpecGrid extends StatelessWidget {
  const _SpecGrid({required this.gemstone});

  final Gemstone gemstone;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SpecItem(
                label: 'Shape',
                value: _display(gemstone.shape),
              ),
            ),
            const SizedBox(width: AppSpacing.s16),
            Expanded(
              child: _SpecItem(
                label: 'Color',
                value: _display(gemstone.color),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s16),
        Row(
          children: [
            Expanded(
              child: _SpecItem(
                label: 'Clarity',
                value: _display(gemstone.clarity),
              ),
            ),
            const SizedBox(width: AppSpacing.s16),
            Expanded(
              child: _SpecItem(
                label: 'Cut',
                value: _display(gemstone.cut),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.gemstone});

  final Gemstone gemstone;

  @override
  Widget build(BuildContext context) {
    final ppc = gemstone.pricePerCarat;
    final ppcLabel = ppc == null
        ? 'N/A'
        : AppCurrency.format(formatCatalogPrice(ppc));
    final hasOrigin = gemstone.origin.trim().isNotEmpty;
    final secondValue = _display(
      hasOrigin ? gemstone.origin : gemstone.treatment,
    );

    return Row(
      children: [
        Expanded(child: _SpecItem(label: '\$/ct', value: ppcLabel)),
        const SizedBox(width: AppSpacing.s16),
        Expanded(
          child: _SpecItem(
            label: hasOrigin ? 'Origin' : 'Treatment',
            value: secondValue,
          ),
        ),
      ],
    );
  }
}

class _SpecItem extends StatelessWidget {
  const _SpecItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isMissing = value == 'N/A';
    return Row(
      children: [
        Text(
          '$label: ',
          style: AppTypography.body.copyWith(
            fontSize: 12,
            height: 1.35,
            color: AppColors.textSecondaryLight,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body.copyWith(
              fontSize: 12,
              height: 1.35,
              color: isMissing
                  ? AppColors.textMutedLight
                  : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _GemstoneThumb extends StatelessWidget {
  const _GemstoneThumb({
    required this.gemstone,
    required this.padding,
    this.cover = false,
  });

  final Gemstone gemstone;
  final double padding;
  final bool cover;

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(
      Icons.diamond_outlined,
      size: 40,
      color: gemstoneHue(gemstone.type),
    );

    if (gemstone.hasNetworkImage) {
      return ColoredBox(
        color: AppColors.sandSurface,
        child: AppNetworkImage(
          url: gemstone.imageUrl!,
          fit: cover ? BoxFit.cover : BoxFit.contain,
          memCacheWidth: cover ? 280 : 400,
          error: Center(child: fallback),
        ),
      );
    }

    final assetPath = gemstoneImagePath(gemstone.type);
    return ColoredBox(
      color: AppColors.sandSurface,
      child: assetPath != null
          ? Padding(
              padding: EdgeInsets.all(padding),
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => fallback,
              ),
            )
          : Center(child: fallback),
    );
  }
}

String _display(String? value) {
  if (value == null) return 'N/A';
  final t = value.trim();
  if (t.isEmpty || t == '-' || t == '—' || t == '–' || t.toLowerCase() == 'n/a') {
    return 'N/A';
  }
  return t;
}

String? _labBadge(String? value) {
  final label = _display(value);
  if (label == 'N/A') return null;
  const none = {'NC', 'NONE', 'NIL', 'NON', 'NO', 'NULL', 'UNKNOWN'};
  if (none.contains(label.toUpperCase())) return null;
  return label.toUpperCase();
}
