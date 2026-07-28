import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_swatches.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/seller_product.dart';
import '../../../../core/utils/app_currency.dart';

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
        return GridView.builder(
          padding: const EdgeInsets.all(AppSpacing.s16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppSpacing.s16,
            mainAxisSpacing: AppSpacing.s16,
            // Fixed height avoids bottom RenderFlex overflow on narrow cards.
            mainAxisExtent: 440,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final p = products[index];
            return _ProductCard(
              product: p,
              selected: selectedIds.contains(p.id),
              onSelected: (v) => onToggleSelection(p.id, v),
              onEdit: onEdit == null ? null : () => onEdit!(p),
              onDelete: onDelete == null ? null : () => onDelete!(p),
            );
          },
        );
      },
    );
  }
}

class _ProductCard extends StatefulWidget {
  const _ProductCard({
    required this.product,
    required this.selected,
    required this.onSelected,
    this.onEdit,
    this.onDelete,
  });

  final SellerProduct product;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  late final PageController _pageController;
  int _page = 0;

  static const _imageCount = 3;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final shape = p.field('shape') ?? '—';
    final carat = p.field('carat_weight') ?? '—';
    final price = p.field('total_price') ?? '0.00';
    final updated = p.field('updated_at') ?? '—';
    final catalogLabel = p.isNatural ? 'Natural Diamond' : 'Melee Diamond';

    return Material(
      color: AppColors.warmWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.warmBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 168,
            child: Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: _imageCount,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, index) {
                    return Container(
                      color: AppColors.sandSurface,
                      child: const Center(
                        child: Icon(
                          Icons.diamond_outlined,
                          size: 48,
                          color: AppColors.textMutedLight,
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  left: 8,
                  top: 8,
                  child: Material(
                    color: AppColors.warmWhite,
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: Checkbox(
                        value: widget.selected,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        onChanged: (v) => widget.onSelected(v ?? false),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 4,
                  top: 4,
                  child: PopupMenuButton<_CardAction>(
                    tooltip: 'Actions',
                    padding: EdgeInsets.zero,
                    icon: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.warmWhite.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.more_vert, size: 18),
                    ),
                    onSelected: (action) {
                      switch (action) {
                        case _CardAction.quickView:
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Quick view for ${widget.product.stockNumber}',
                              ),
                            ),
                          );
                        case _CardAction.edit:
                          widget.onEdit?.call();
                        case _CardAction.delete:
                          widget.onDelete?.call();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: _CardAction.quickView,
                        child: _MenuRow(
                          icon: Icons.visibility_outlined,
                          label: 'Quick View',
                        ),
                      ),
                      PopupMenuItem(
                        value: _CardAction.edit,
                        child: _MenuRow(
                          icon: Icons.edit_outlined,
                          label: 'Edit Product',
                        ),
                      ),
                      PopupMenuItem(
                        value: _CardAction.delete,
                        child: _MenuRow(
                          icon: Icons.delete_outline,
                          label: 'Delete Product',
                          danger: true,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_page > 0)
                  Positioned(
                    left: 4,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _NavChip(
                        icon: Icons.chevron_left,
                        onTap: () => _pageController.previousPage(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                        ),
                      ),
                    ),
                  ),
                if (_page < _imageCount - 1)
                  Positioned(
                    right: 4,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _NavChip(
                        icon: Icons.chevron_right,
                        onTap: () => _pageController.nextPage(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 10,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_imageCount, (i) {
                      final active = i == _page;
                      return Container(
                        width: active ? 8 : 6,
                        height: active ? 8 : 6,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: active
                              ? AppColors.charcoal
                              : AppColors.textMutedLight,
                        ),
                      );
                    }),
                  ),
                ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.warmWhite.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.collections_outlined,
                      size: 16,
                      color: AppColors.charcoal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$shape ${carat}ct',
                          style: AppTypography.label.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (p.isOnAuction)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppSwatches.sellerCardSurface,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'ON AUCTION',
                            style: AppTypography.caption.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.bronzeDark,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _TagChip(label: catalogLabel),
                      _TagChip(label: shape),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppCurrency.format(price),
                    style: AppTypography.title.copyWith(
                      color: AppColors.info,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _SpecTile(label: 'Shape', value: shape),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SpecTile(
                          label: 'Color',
                          value: p.field('color') ?? '—',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _SpecTile(
                          label: 'Clarity',
                          value: p.field('clarity') ?? '—',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SpecTile(
                          label: 'Cut',
                          value: p.field('cut') ?? '—',
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Updated: $updated',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textMutedLight,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (p.isSold)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppColors.error),
                          ),
                          child: Text(
                            'SOLD',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
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
    final color = danger ? AppColors.error : AppColors.charcoal;
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _NavChip extends StatelessWidget {
  const _NavChip({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.warmWhite.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 20, color: AppColors.charcoal),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.sandSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.warmBorder),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          fontSize: 11,
          color: AppColors.textSecondaryLight,
        ),
      ),
    );
  }
}

class _SpecTile extends StatelessWidget {
  const _SpecTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.sandSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              fontSize: 10,
              color: AppColors.textMutedLight,
            ),
          ),
          Text(
            value,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
