import 'package:flutter/material.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/utils/app_currency.dart';
import '../../domain/models/diamond_project_item.dart';

/// Virtualized selected-diamonds table with a sticky per-row remove control.
class DiamondProjectSelectedTable extends StatelessWidget {
  const DiamondProjectSelectedTable({
    required this.items,
    required this.onRemove,
    super.key,
  });

  final List<DiamondProjectItem> items;
  final ValueChanged<String> onRemove;

  static const _rowHeight = 44.0;
  static const _dataWidth = 640.0;
  static const _removeWidth = 40.0;

  @override
  Widget build(BuildContext context) {
    final listHeight = items.length > 8
        ? 360.0
        : (items.length * _rowHeight).clamp(88.0, 360.0);
    final p = LuxePalette.of(context);
    final muted = LuxeType.eyebrow(
      p.inkMuted,
    ).copyWith(fontSize: 9.5, letterSpacing: 1.4);

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(LuxeSpace.radius),
        border: Border.all(color: p.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr(CatalogL10n.selectedDiamonds),
                    style: LuxeType.display(21, p.ink),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: ShapeDecoration(
                    color: p.accentSoft,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    '${items.length}',
                    style: LuxeType.figure(p.accent, size: 12),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: p.hairline),
          ColoredBox(
            color: p.surfaceRaised.withValues(alpha: 0.5),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: _dataWidth,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s16,
                          vertical: AppSpacing.s8,
                        ),
                        child: _HeaderCells(style: muted),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: _removeWidth,
                  height: _rowHeight,
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: p.inkMuted.withValues(alpha: 0),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: p.hairline),
          SizedBox(
            height: listHeight,
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => Divider(height: 1, color: p.hairline),
              itemBuilder: (context, index) {
                final item = items[index];
                return SizedBox(
                  height: _rowHeight,
                  child: Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: _dataWidth,
                            child: _DataCells(
                              key: ValueKey('data-${item.diamondId}'),
                              item: item,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: _removeWidth,
                        child: IconButton(
                          key: ValueKey('remove-${item.diamondId}'),
                          tooltip: context.tr(CatalogL10n.removeSelection),
                          onPressed: () {
                            AppHaptics.light();
                            onRemove(item.diamondId);
                          },
                          icon: Icon(
                            Icons.remove_circle_outline_rounded,
                            size: 18,
                            color: p.caution,
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCells extends StatelessWidget {
  const _HeaderCells({required this.style});

  final TextStyle style;

  @override
  Widget build(BuildContext context) {
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
      ],
    );
  }
}

class _DataCells extends StatelessWidget {
  const _DataCells({required this.item, super.key});

  final DiamondProjectItem item;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final style = LuxeType.figure(p.ink, size: 12.5);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
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
        ],
      ),
    );
  }
}
