import 'package:flutter/material.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/chart_value_tooltip.dart';
import '../../domain/models/diamond_project_stats.dart';
import 'diamond_project_panel.dart';

/// Horizontal bar mix (shape / color / clarity) with share of stones.
class DiamondProjectMixCard extends StatefulWidget {
  const DiamondProjectMixCard({
    required this.title,
    required this.entries,
    super.key,
  });

  final String title;
  final List<NamedCount> entries;

  @override
  State<DiamondProjectMixCard> createState() => _DiamondProjectMixCardState();
}

class _DiamondProjectMixCardState extends State<DiamondProjectMixCard> {
  int? _selectedIndex;

  @override
  void didUpdateWidget(covariant DiamondProjectMixCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entries != widget.entries) {
      _selectedIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final max = widget.entries.fold<int>(
      0,
      (m, e) => e.count > m ? e.count : m,
    );
    final total = widget.entries.fold<int>(0, (s, e) => s + e.count);
    return DiamondProjectPanel(
      title: widget.title,
      child: widget.entries.isEmpty
          ? Text(
              context.tr(CatalogL10n.projectNoData),
              style: LuxeType.label(p.inkFaint, size: 12.5),
            )
          : Column(
              children: [
                for (var i = 0; i < widget.entries.length; i++) ...[
                  _MixRow(
                    entry: widget.entries[i],
                    max: max == 0 ? 1 : max,
                    total: total == 0 ? 1 : total,
                    index: i,
                    selected: _selectedIndex == i,
                    onTap: () {
                      AppHaptics.selection();
                      setState(() {
                        _selectedIndex = _selectedIndex == i ? null : i;
                      });
                    },
                  ),
                  if (i < widget.entries.length - 1) const SizedBox(height: 8),
                ],
              ],
            ),
    );
  }
}

class _MixRow extends StatelessWidget {
  const _MixRow({
    required this.entry,
    required this.max,
    required this.total,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  final NamedCount entry;
  final int max;
  final int total;
  final int index;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final share = entry.count / total * 100;
    final still = MediaQuery.disableAnimationsOf(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            children: [
              SizedBox(
                width: 62,
                child: Text(
                  entry.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LuxeType.label(
                    selected ? p.accent : p.ink,
                    size: 12.5,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 10,
                  decoration: ShapeDecoration(
                    color: p.surfaceRaised,
                    shape: const StadiumBorder(),
                  ),
                  alignment: Alignment.centerLeft,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: still ? 1 : 0, end: 1),
                    duration: Duration(milliseconds: 700 + 60 * index),
                    curve: LuxeMotion.settle,
                    builder: (context, t, _) => FractionallySizedBox(
                      widthFactor: (entry.count / max * t).clamp(0.02, 1.0),
                      child: AnimatedContainer(
                        duration: LuxeMotion.fast,
                        decoration: ShapeDecoration(
                          shape: const StadiumBorder(),
                          gradient: LinearGradient(
                            colors: selected
                                ? [p.accent, p.accent]
                                : [p.ink.withValues(alpha: 0.75), p.ink],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 64,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${entry.count}',
                        style: LuxeType.figure(p.ink, size: 12.5),
                      ),
                      TextSpan(
                        text: '  ${share.toStringAsFixed(share < 10 ? 1 : 0)}%',
                        style: LuxeType.figure(p.inkFaint, size: 11),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          if (selected)
            Positioned(
              top: -42,
              left: 62,
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
