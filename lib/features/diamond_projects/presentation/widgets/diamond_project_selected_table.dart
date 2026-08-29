import 'package:flutter/material.dart';
import '../../../../core/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_currency.dart';
import '../../domain/models/diamond_project_item.dart';

/// Virtualized selected-diamonds table with per-row remove.
class DiamondProjectSelectedTable extends StatelessWidget {
  const DiamondProjectSelectedTable({
    required this.items,
    required this.onRemove,
    super.key,
  });

  final List<DiamondProjectItem> items;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppSpacing.r12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Text(
              context.tr(CatalogL10n.selectedDiamonds),
              style: AppTypography.label.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary(context),
              ),
            ),
          ),
          const Divider(height: 1),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 720,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.s16,
                      vertical: AppSpacing.s8,
                    ),
                    child: _HeaderRow(),
                  ),
                  const Divider(height: 1),
                  SizedBox(
                    height: items.length > 8
                        ? 360
                        : (items.length * 44.0).clamp(88, 360),
                    child: ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _ItemRow(
                          key: ValueKey(item.diamondId),
                          item: item,
                          onRemove: () => onRemove(item.diamondId),
                        );
                      },
                    ),
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

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.caption.copyWith(
      fontWeight: FontWeight.w700,
      color: AppColors.textMuted(context),
    );
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(context.tr(CatalogL10n.stock), style: style),
        ),
        Expanded(child: Text(context.tr(CatalogL10n.shape), style: style)),
        Expanded(child: Text(context.tr(CatalogL10n.carat), style: style)),
        Expanded(child: Text(context.tr(CatalogL10n.color), style: style)),
        Expanded(child: Text(context.tr(CatalogL10n.clarity), style: style)),
        Expanded(child: Text(context.tr(CatalogL10n.price), style: style)),
        Expanded(
          child: Text(context.tr(CatalogL10n.pricePerCtShort), style: style),
        ),
        const SizedBox(width: 36),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.onRemove, super.key});

  final DiamondProjectItem item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.caption.copyWith(
      color: AppColors.textPrimary(context),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s8,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              item.stockLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
          Expanded(
            child: Text(
              item.shape ?? '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
          Expanded(
            child: Text(
              item.carat.toStringAsFixed(2),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
          Expanded(
            child: Text(
              item.color ?? '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
          Expanded(
            child: Text(
              item.clarity ?? '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
          Expanded(
            child: Text(
              AppCurrency.usd(item.price, decimals: 0),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
          Expanded(
            child: Text(
              AppCurrency.usd(item.ppc, decimals: 0),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
          SizedBox(
            width: 36,
            height: 36,
            child: IconButton(
              tooltip: context.tr(CatalogL10n.removeSelection),
              onPressed: onRemove,
              icon: Icon(
                Icons.close,
                size: 16,
                color: AppColors.textMuted(context),
              ),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}
