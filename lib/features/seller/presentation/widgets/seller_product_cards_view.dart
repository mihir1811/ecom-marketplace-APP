import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/catalog_missing_image.dart';
import '../../../../core/widgets/marketplace_product_card_shell.dart';
import '../../domain/models/seller_product.dart';

import '../../../../core/l10n/app_localizations.dart';

class SellerProductCardsView extends StatelessWidget {
  const SellerProductCardsView({
    required this.products,
    required this.selectedIds,
    required this.onToggleSelection,
    this.onEdit,
    this.onDelete,
    super.key,
  });

  final List<SellerProduct> products;
  final Set<String> selectedIds;
  final void Function(String id, bool selected) onToggleSelection;
  final ValueChanged<SellerProduct>? onEdit;
  final ValueChanged<SellerProduct>? onDelete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 900 ? 3 : 2;
        final rowCount =
            (products.length + crossAxisCount - 1) ~/ crossAxisCount;
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.s16),
          addAutomaticKeepAlives: false,
          itemCount: rowCount,
          itemBuilder: (context, rowIndex) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: rowIndex == rowCount - 1 ? 0 : AppSpacing.s12,
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var col = 0; col < crossAxisCount; col++) ...[
                      if (col > 0) const SizedBox(width: AppSpacing.s12),
                      Expanded(child: _cell(rowIndex * crossAxisCount + col)),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _cell(int index) {
    if (index >= products.length) return const SizedBox.shrink();
    final p = products[index];
    return RepaintBoundary(
      child: _ProductCard(
        key: ValueKey(p.id),
        product: p,
        selected: selectedIds.contains(p.id),
        onSelected: (v) => onToggleSelection(p.id, v),
        onEdit: onEdit == null ? null : () => onEdit!(p),
        onDelete: onDelete == null ? null : () => onDelete!(p),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.selected,
    required this.onSelected,
    this.onEdit,
    this.onDelete,
    super.key,
  });

  final SellerProduct product;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final textColor = AppColors.textPrimary(context);
    final mutedColor = AppColors.textSecondary(context);
    final title = _gridTitle(product);
    final gradesLine = _gridGradesLine(product);
    final metaLine = _gridMetaLine(product);
    final priceLabel = _priceLabel(product.field('total_price'));

    return MarketplaceProductCardShell(
      onTap: onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1.05,
            child: Stack(
              children: [
                Positioned.fill(child: _ProductThumb(product: product)),
                Positioned(
                  top: AppSpacing.s8,
                  left: AppSpacing.s8,
                  child: Material(
                    color: AppColors.card(context),
                    borderRadius: BorderRadius.circular(AppSpacing.r4),
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: Checkbox(
                        value: selected,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        semanticLabel: context.tr(RemainingL10n.selectProduct, {
                          'stockNumber': product.stockNumber,
                        }),
                        onChanged: (v) => onSelected(v ?? false),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: AppSpacing.s4,
                  right: AppSpacing.s4,
                  child: PopupMenuButton<_CardAction>(
                    tooltip: context.tr(RemainingL10n.actions),
                    padding: EdgeInsets.zero,
                    icon: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.card(context).withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(AppSpacing.r8),
                      ),
                      child: const Icon(Icons.more_vert, size: 18),
                    ),
                    onSelected: (action) {
                      switch (action) {
                        case _CardAction.quickView:
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Quick view for ${product.stockNumber}',
                              ),
                            ),
                          );
                        case _CardAction.edit:
                          onEdit?.call();
                        case _CardAction.delete:
                          onDelete?.call();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: _CardAction.quickView,
                        child: _MenuRow(
                          icon: Icons.visibility_outlined,
                          label: context.tr(RemainingL10n.quickView),
                        ),
                      ),
                      PopupMenuItem(
                        value: _CardAction.edit,
                        child: _MenuRow(
                          icon: Icons.edit_outlined,
                          label: context.tr(RemainingL10n.editProduct),
                        ),
                      ),
                      PopupMenuItem(
                        value: _CardAction.delete,
                        child: _MenuRow(
                          icon: Icons.delete_outline,
                          label: context.tr(RemainingL10n.deleteProduct),
                          danger: true,
                        ),
                      ),
                    ],
                  ),
                ),
                if (product.isOnAuction || product.isSold)
                  Positioned(
                    bottom: AppSpacing.s8,
                    left: AppSpacing.s8,
                    right: AppSpacing.s8,
                    child: Wrap(
                      spacing: AppSpacing.s4,
                      runSpacing: AppSpacing.s4,
                      children: [
                        if (product.isOnAuction)
                          _StatusBadge(
                            label: context.tr(RemainingL10n.onAuction),
                            color: AppColors.terracotta,
                          ),
                        if (product.isSold)
                          _StatusBadge(
                            label: context.tr(RemainingL10n.sold),
                            color: AppColors.error,
                          ),
                      ],
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
                    title,
                    style: AppTypography.label.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (gradesLine != null) ...[
                    const SizedBox(height: AppSpacing.cardLineGap),
                    Text(
                      gradesLine,
                      style: AppTypography.caption.copyWith(
                        color: mutedColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (metaLine != null) ...[
                    const SizedBox(height: AppSpacing.cardLineGap),
                    Text(
                      metaLine,
                      style: AppTypography.caption.copyWith(
                        color: mutedColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const Spacer(),
                  const SizedBox(height: AppSpacing.cardPriceGap),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          priceLabel,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ).copyWith(color: textColor),
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
}

enum _CardAction { quickView, edit, delete }

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.product});

  final SellerProduct product;

  @override
  Widget build(BuildContext context) {
    final url = _firstImageUrl(product);
    if (url != null) {
      return ColoredBox(
        color: AppColors.surface(context),
        child: AppNetworkImage(
          url: url,
          fit: BoxFit.contain,
          memCacheWidth: 400,
          error: const CatalogMissingImage(padding: AppSpacing.s24),
        ),
      );
    }
    return const CatalogMissingImage(padding: AppSpacing.s24);
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.r4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s8,
          vertical: AppSpacing.s4,
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.warmWhite,
            fontWeight: FontWeight.w700,
            fontSize: 10,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.error : AppColors.textPrimary(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.s8),
        Flexible(
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

String _gridTitle(SellerProduct product) {
  final carat = _caratLabel(product.field('carat_weight'));
  final shape = _optionalText(product.field('shape'));
  if (carat != null && shape != null) return '$carat $shape';
  if (carat != null) return carat;
  if (shape != null) return shape;
  return product.stockNumber;
}

String? _gridGradesLine(SellerProduct product) {
  final parts = <String>[
    ?_optionalText(product.field('color')),
    ?_optionalText(product.field('clarity')),
    ?_optionalText(product.field('cut')),
  ];
  if (parts.isEmpty) return null;
  return parts.join(' · ');
}

String? _gridMetaLine(SellerProduct product) {
  final parts = <String>[];
  final ppc = _parseAmount(product.field('price_per_carat'));
  if (ppc != null && ppc > 0) {
    parts.add('${AppCurrency.format(formatCatalogPrice(ppc))}/ct');
  }
  final dims = _optionalText(product.field('measurement'));
  if (dims != null) parts.add(dims);
  if (parts.isEmpty) {
    parts.add(product.isNatural ? 'Natural Diamond' : 'Melee Diamond');
  }
  return parts.join(' · ');
}

String _priceLabel(String? raw) {
  final amount = _parseAmount(raw);
  if (amount == null) return '—';
  return AppCurrency.format(formatCatalogPrice(amount));
}

String? _caratLabel(String? raw) {
  final text = _optionalText(raw);
  if (text == null) return null;
  if (text.toLowerCase().endsWith('ct')) return text;
  final amount = _parseAmount(text);
  if (amount != null) return '${amount.toStringAsFixed(2)}ct';
  return '${text}ct';
}

String? _firstImageUrl(SellerProduct product) {
  const keys = ['image1', 'image2', 'image3', 'image4', 'image5', 'image6'];
  for (final key in keys) {
    final value = product.field(key)?.trim() ?? '';
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
  }
  return null;
}

double? _parseAmount(String? raw) {
  if (raw == null) return null;
  return double.tryParse(raw.trim().replaceAll(',', ''));
}

String? _optionalText(String? value) {
  if (value == null) return null;
  final t = value.trim();
  if (t.isEmpty ||
      t == '-' ||
      t == '—' ||
      t == '–' ||
      t.toLowerCase() == 'n/a') {
    return null;
  }
  return t;
}
