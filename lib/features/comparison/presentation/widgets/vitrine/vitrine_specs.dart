import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/utils/app_currency.dart';
import '../../../../../core/utils/format_catalog_price.dart';
import '../../../domain/models/compare_insights.dart';
import '../../../domain/models/compare_item.dart';
import '../../../domain/models/compare_spec.dart';
import 'vitrine_rail.dart';
import 'vitrine_style.dart';

/// One titled group of spec rows. With [differencesOnly], rows where every
/// piece agrees fold away (and the group with them when none differ).
class VitrineSpecGroup extends StatelessWidget {
  const VitrineSpecGroup({
    required this.group,
    required this.items,
    required this.insights,
    required this.columns,
    required this.differencesOnly,
    super.key,
  });

  final CompareSpecGroup group;
  final List<CompareItem> items;
  final CompareInsights insights;
  final VitrineColumns columns;
  final bool differencesOnly;

  bool _shows(CompareSpecDef spec) =>
      !insights.empty.contains(spec.key) &&
      (!differencesOnly || !insights.identical.contains(spec.key));

  @override
  Widget build(BuildContext context) {
    final v = Vitrine.of(context);
    final visible = group.specs.any(_shows);

    return AnimatedSize(
      duration: VitrineMotion.settle,
      curve: VitrineMotion.ease,
      alignment: Alignment.topCenter,
      child: !visible
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.fromLTRB(
                VitrineColumns.pad,
                18,
                VitrineColumns.pad,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          context.tr(group.titleKey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: v.display(21, style: FontStyle.italic),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Container(height: 0.6, color: v.line)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  for (final spec in group.specs)
                    _SpecRow(
                      key: ValueKey(spec.key),
                      spec: spec,
                      items: items,
                      insights: insights,
                      columns: columns,
                      visible: _shows(spec),
                    ),
                ],
              ),
            ),
    );
  }
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({
    required this.spec,
    required this.items,
    required this.insights,
    required this.columns,
    required this.visible,
    super.key,
  });

  final CompareSpecDef spec;
  final List<CompareItem> items;
  final CompareInsights insights;
  final VitrineColumns columns;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final v = Vitrine.of(context);
    return AnimatedSize(
      duration: VitrineMotion.settle,
      curve: VitrineMotion.ease,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: VitrineMotion.quick,
        child: !visible
            ? const SizedBox(width: double.infinity)
            : DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: v.line, width: 0.6)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Text(
                          context.tr(spec.label).toUpperCase(),
                          style: v.eyebrow(),
                        ),
                      ),
                      const SizedBox(height: 5),
                      if (insights.identical.contains(spec.key))
                        _Shared(value: _value(context, 0))
                      else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var i = 0; i < columns.count; i++) ...[
                              if (i > 0)
                                const SizedBox(width: VitrineColumns.gap),
                              SizedBox(
                                width: columns.column,
                                child: i < items.length
                                    ? _Cell(
                                        value: _value(context, i),
                                        leads: insights.leads(spec.key, i),
                                        delta: _delta(i),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  String _value(BuildContext context, int i) =>
      items[i].displayValues[spec.key] ?? '';

  /// "+$1,204" over the lowest price.
  String? _delta(int i) {
    if (spec.key != 'price' || items.length < 2) return null;
    final prices = [
      for (final e in items)
        if (e.price > 0) e.price,
    ];
    if (prices.length < 2) return null;
    final low = prices.reduce((a, b) => a < b ? a : b);
    final diff = items[i].price - low;
    if (items[i].price <= 0 || diff < 0.5) return null;
    return '+${AppCurrency.format(formatGroupedWhole(diff.roundToDouble()))}';
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.value, required this.leads, this.delta});

  final String value;
  final bool leads;
  final String? delta;

  @override
  Widget build(BuildContext context) {
    final v = Vitrine.of(context);
    final missing = isMissingCompareValue(value);
    final text = Text(
      missing ? '—' : value,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: v.text(
        13.5,
        weight: leads ? FontWeight.w800 : FontWeight.w600,
        color: missing
            ? v.faint
            : leads
            ? v.gold
            : v.ink,
        height: 1.25,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: VitrineMotion.settle,
          curve: VitrineMotion.ease,
          // Same inset for every cell, so values line up whether they lead.
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          decoration: BoxDecoration(
            color: leads ? v.wash : v.wash.withValues(alpha: 0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: text,
        ),
        if (delta != null) ...[
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child: Text(
              delta!,
              style: v.figure(10.5, color: v.muted, weight: FontWeight.w600),
            ),
          ),
        ],
      ],
    );
  }
}

/// A value every piece shares: one quiet line across all columns.
class _Shared extends StatelessWidget {
  const _Shared({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final v = Vitrine.of(context);
    final missing = isMissingCompareValue(value);
    return Row(
      children: [
        Expanded(child: Container(height: 0.6, color: v.line)),
        Flexible(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              missing ? '—' : value,
              textAlign: TextAlign.center,
              style: v.text(
                13,
                weight: FontWeight.w600,
                color: missing ? v.faint : v.muted,
              ),
            ),
          ),
        ),
        Expanded(child: Container(height: 0.6, color: v.line)),
      ],
    );
  }
}
