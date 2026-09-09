import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Shared PDP tab + key/value table chrome (diamond / jewelry / bullion).
class ProductDetailSpecTabBar extends StatelessWidget {
  const ProductDetailSpecTabBar({
    required this.titles,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final List<String> titles;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < titles.length; i++)
          Expanded(
            child: InkWell(
              onTap: () => onSelected(i),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.s12,
                    ),
                    child: Text(
                      titles[i].toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTypography.label.copyWith(
                        color: i == selectedIndex
                            ? AppColors.textPrimary(context)
                            : AppColors.textMuted(context),
                        fontSize: 12,
                        fontWeight: i == selectedIndex
                            ? FontWeight.w800
                            : FontWeight.w600,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  ColoredBox(
                    color: i == selectedIndex
                        ? AppColors.bronze
                        : AppColors.border(context),
                    child: SizedBox(
                      height: i == selectedIndex ? 2 : 1,
                      width: double.infinity,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Bordered card of divider-separated label/value rows.
class ProductDetailSpecTable extends StatelessWidget {
  const ProductDetailSpecTable({required this.rows, super.key});

  final List<ProductDetailSpecKv> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppSpacing.r20),
        border: Border.all(color: AppColors.border(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, color: AppColors.border(context)),
            ProductDetailSpecRow(row: rows[i]),
          ],
        ],
      ),
    );
  }
}

/// Section title above a [ProductDetailSpecTable] (diamond ADVANCE pattern).
class ProductDetailSpecSection extends StatelessWidget {
  const ProductDetailSpecSection({
    required this.title,
    required this.rows,
    super.key,
  });

  final String title;
  final List<ProductDetailSpecKv> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.s4,
            bottom: AppSpacing.s12,
          ),
          child: Text(
            _catalogText(context, title),
            style: AppTypography.label.copyWith(
              color: AppColors.textPrimary(context),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        ProductDetailSpecTable(rows: rows),
      ],
    );
  }
}

class ProductDetailSpecKv {
  const ProductDetailSpecKv(
    this.label,
    this.value, {
    this.valueColor,
    this.bold = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;
}

class ProductDetailSpecRow extends StatelessWidget {
  const ProductDetailSpecRow({required this.row, super.key});

  final ProductDetailSpecKv row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              _catalogText(context, row.label),
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted(context),
                fontSize: 13,
                fontWeight: row.bold ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s16),
          Expanded(
            flex: 5,
            child: Text(
              row.value.isEmpty ? '—' : row.value,
              textAlign: TextAlign.right,
              style: AppTypography.label.copyWith(
                color: row.valueColor ?? AppColors.textPrimary(context),
                fontSize: 13,
                fontWeight: row.bold ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty / prose content inside the same bordered card frame.
class ProductDetailSpecPanel extends StatelessWidget {
  const ProductDetailSpecPanel({
    required this.child,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.s16,
      vertical: AppSpacing.s24,
    ),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppSpacing.r20),
        border: Border.all(color: AppColors.border(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );
  }
}

String productDetailSpecDash(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? '—' : trimmed;
}

String _catalogText(BuildContext context, String value) {
  final key = catalogDisplayMessageKeys[value];
  return key == null ? value : context.tr(key);
}
