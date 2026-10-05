import 'package:flutter/material.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/chart_value_tooltip.dart';
import '../../domain/models/diamond_project_stats.dart';
import 'diamond_project_panel.dart';

/// Vertical histogram for price / $/ct / carat buckets.
class DiamondProjectHistogramCard extends StatefulWidget {
  const DiamondProjectHistogramCard({
    required this.title,
    required this.entries,
    super.key,
  });

  final String title;
  final List<NamedCount> entries;

  @override
  State<DiamondProjectHistogramCard> createState() =>
      _DiamondProjectHistogramCardState();
}

class _DiamondProjectHistogramCardState
    extends State<DiamondProjectHistogramCard> {
  int? _selectedIndex;

  @override
  void didUpdateWidget(covariant DiamondProjectHistogramCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entries != widget.entries) {
      _selectedIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final max = widget.entries.fold<int>(
      0,
      (m, e) => e.count > m ? e.count : m,
    );
    final p = LuxePalette.of(context);
    final barColor = p.ink;
    return DiamondProjectPanel(
      title: widget.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.entries.isEmpty)
            Text(
              context.tr(CatalogL10n.projectNoData),
              style: LuxeType.label(p.inkFaint, size: 12.5),
            )
          else
            Builder(
              builder: (context) {
                final slots = _HistogramSlots.of(context);
                return SizedBox(
                  height: slots.chartHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < widget.entries.length; i++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.s4,
                            ),
                            child: _Bar(
                              entry: widget.entries[i],
                              max: max == 0 ? 1 : max,
                              slots: slots,
                              barKey: ValueKey('histogram-bar-$i'),
                              barColor: barColor,
                              selected: _selectedIndex == i,
                              showTooltip: _selectedIndex == i,
                              onTap: () {
                                AppHaptics.selection();
                                setState(() {
                                  _selectedIndex = _selectedIndex == i
                                      ? null
                                      : i;
                                });
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Fixed value and label slots so every bar shares one baseline.
class _HistogramSlots {
  const _HistogramSlots({required this.valueSlot, required this.labelSlot});

  static const trackHeight = 88.0;
  static const valueFontSize = 12.0;
  static const valueHeight = 1.2;
  static const labelFontSize = 10.0;
  static const labelHeight = 1.25;
  static const labelLines = 2;

  final double valueSlot;
  final double labelSlot;

  double get chartHeight =>
      valueSlot + AppSpacing.s8 + trackHeight + AppSpacing.s12 + labelSlot;

  static _HistogramSlots of(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return _HistogramSlots(
      valueSlot: scaler.scale(valueFontSize) * valueHeight,
      labelSlot: scaler.scale(labelFontSize) * labelHeight * labelLines,
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.entry,
    required this.max,
    required this.barColor,
    required this.slots,
    required this.barKey,
    required this.selected,
    required this.showTooltip,
    required this.onTap,
  });

  final NamedCount entry;
  final int max;
  final Color barColor;
  final _HistogramSlots slots;
  final Key barKey;
  final bool selected;
  final bool showTooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final valueStyle = LuxeType.figure(
      selected ? p.accent : p.ink,
      size: _HistogramSlots.valueFontSize,
    ).copyWith(height: _HistogramSlots.valueHeight);
    final labelStyle = LuxeType.label(
      p.inkMuted,
      size: _HistogramSlots.labelFontSize,
    ).copyWith(height: _HistogramSlots.labelHeight);
    final fraction = (entry.count / max).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Column(
            children: [
              SizedBox(
                height: slots.valueSlot,
                child: Center(
                  child: Text(
                    '${entry.count}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    strutStyle: const StrutStyle(
                      fontSize: _HistogramSlots.valueFontSize,
                      height: _HistogramSlots.valueHeight,
                      forceStrutHeight: true,
                    ),
                    style: valueStyle,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final track = constraints.maxHeight;
                    final barHeight = (track * fraction).clamp(4.0, track);
                    final barWidth = constraints.maxWidth * 0.62;
                    return Align(
                      alignment: Alignment.bottomCenter,
                      child: SizedBox(
                        height: barHeight,
                        width: barWidth,
                        child: DecoratedBox(
                          key: barKey,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(7),
                              bottom: Radius.circular(2),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: selected
                                  ? [p.accent, p.accent.withValues(alpha: 0.7)]
                                  : [barColor, barColor.withValues(alpha: 0.7)],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
              SizedBox(
                height: slots.labelSlot,
                child: Text(
                  entry.label,
                  maxLines: _HistogramSlots.labelLines,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  strutStyle: const StrutStyle(
                    fontSize: _HistogramSlots.labelFontSize,
                    height: _HistogramSlots.labelHeight,
                    forceStrutHeight: true,
                    leadingDistribution: TextLeadingDistribution.even,
                  ),
                  style: labelStyle,
                ),
              ),
            ],
          ),
          if (showTooltip)
            Positioned(
              top: -36,
              child: ChartValueTooltip(
                label: entry.label,
                value: '${entry.count}',
              ),
            ),
        ],
      ),
    );
  }
}
