import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../application/gem_agent_controller.dart';
import '../../domain/agent_card.dart';

/// Answer cards under an agent line: KPI tiles, short lists, bar charts.
class GemAgentCards extends StatelessWidget {
  const GemAgentCards({super.key, required this.cards});

  final List<AgentCard> cards;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final card in cards)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: _CardFrame(card: card),
          ),
      ],
    );
  }
}

class _CardFrame extends ConsumerWidget {
  const _CardFrame({required this.card});

  final AgentCard card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(gemAgentControllerProvider.notifier);
    final title = card.title;
    final action = card.action;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      decoration: BoxDecoration(
        color: LuxeStage.glass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LuxeStage.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(
              title.toUpperCase(),
              style: LuxeType.eyebrow(LuxeStage.inkMuted),
            ),
            const SizedBox(height: 6),
          ],
          switch (card) {
            AgentStatsCard(:final stats) => _Stats(stats: stats),
            AgentListCard(:final rows, :final moreCount) => _Rows(
              rows: rows,
              moreCount: moreCount,
              onOpen: controller.openFromCard,
            ),
            final AgentChartCard chart => _Bars(chart: chart),
          },
          if (action != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => controller.openFromCard(action.route),
                style: TextButton.styleFrom(
                  foregroundColor: LuxeStage.goldLight,
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: Text(
                  action.label,
                  style: LuxeType.label(LuxeStage.goldLight),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.stats});

  final List<AgentStat> stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 360 ? 3 : 2;
        final width = (constraints.maxWidth - 8 * (columns - 1)) / columns;
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final stat in stats)
              SizedBox(
                width: width,
                child: _Tile(stat: stat),
              ),
          ],
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.stat});

  final AgentStat stat;

  @override
  Widget build(BuildContext context) {
    final trend = stat.trend;
    final up = (trend ?? 0) >= 0;
    final hint = stat.hint;
    return Semantics(
      label: '${stat.label}: ${stat.value}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stat.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: LuxeType.label(LuxeStage.inkMuted, size: 12),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              stat.value,
              style: LuxeType.figure(LuxeStage.ink, size: 17),
            ),
          ),
          if (trend != null)
            Text(
              '${up ? '▲' : '▼'} ${trend.abs().toStringAsFixed(0)}%',
              style: LuxeType.label(
                up ? LuxeStage.goldLight : LuxeStage.inkMuted,
                size: 11,
              ),
            )
          else if (hint != null)
            Text(hint, style: LuxeType.label(LuxeStage.inkMuted, size: 11)),
        ],
      ),
    );
  }
}

class _Rows extends StatelessWidget {
  const _Rows({
    required this.rows,
    required this.moreCount,
    required this.onOpen,
  });

  final List<AgentListRow> rows;
  final int moreCount;
  final void Function(String route) onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in rows) _RowTile(row: row, onOpen: onOpen),
        if (moreCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '+$moreCount more',
              style: LuxeType.label(LuxeStage.inkMuted, size: 12),
            ),
          ),
      ],
    );
  }
}

class _RowTile extends StatelessWidget {
  const _RowTile({required this.row, required this.onOpen});

  final AgentListRow row;
  final void Function(String route) onOpen;

  @override
  Widget build(BuildContext context) {
    final route = row.route;
    final image = row.imageUrl?.trim();
    final subtitle = row.subtitle;
    final trailing = row.trailing;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: route == null ? null : () => onOpen(route),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox.square(
                dimension: 36,
                child: image == null || image.isEmpty
                    ? _thumbFallback()
                    : AppNetworkImage(
                        url: image,
                        width: 36,
                        height: 36,
                        memCacheWidth: 108,
                        error: _thumbFallback(),
                      ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LuxeType.body(LuxeStage.ink, size: 13),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LuxeType.label(LuxeStage.inkMuted, size: 11),
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 6),
              Text(trailing, style: LuxeType.figure(LuxeStage.ink, size: 13)),
            ],
          ],
        ),
      ),
    );
  }

  static Widget _thumbFallback() => ColoredBox(
    color: LuxeStage.glass,
    child: Icon(Icons.diamond_outlined, size: 16, color: LuxeStage.gold),
  );
}

/// Compact bar chart: one bar per bucket, the highest labelled.
class _Bars extends StatelessWidget {
  const _Bars({required this.chart});

  final AgentChartCard chart;

  static const _height = 96.0;

  String _format(double v) => switch (chart.format) {
    AgentValueFormat.usd => AppCurrency.usd(v, decimals: 0),
    AgentValueFormat.inr => AppCurrency.inr(v, decimals: 0),
    AgentValueFormat.count => v.round().toString(),
  };

  @override
  Widget build(BuildContext context) {
    final values = chart.values;
    final peak = values.fold<double>(0, (m, v) => v > m ? v : m);
    final peakIndex = peak <= 0 ? -1 : values.indexOf(peak);
    final caption = chart.caption;
    return Semantics(
      label: [
        for (var i = 0; i < values.length; i++)
          '${chart.labels[i]}: ${_format(values[i])}',
      ].join(', '),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (peak > 0)
            Text(
              'Peak ${_format(peak)} · ${chart.labels[peakIndex]}',
              style: LuxeType.label(LuxeStage.inkMuted, size: 11),
            ),
          const SizedBox(height: 5),
          SizedBox(
            height: _height,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < values.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Tooltip(
                        message: '${chart.labels[i]}: ${_format(values[i])}',
                        child: Container(
                          height: peak <= 0
                              ? 2
                              : (values[i] / peak * _height).clamp(2, _height),
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                            color: i == peakIndex
                                ? LuxeStage.gold
                                : LuxeStage.gold.withValues(alpha: 0.45),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (final label in chart.labels)
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: LuxeType.label(LuxeStage.inkMuted, size: 10),
                  ),
                ),
            ],
          ),
          if (caption != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                caption,
                style: LuxeType.label(LuxeStage.inkMuted, size: 11),
              ),
            ),
        ],
      ),
    );
  }
}
