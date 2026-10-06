import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../diamond_projects/domain/models/diamond_project_stats.dart';
import '../../../diamond_projects/presentation/widgets/diamond_project_histogram_card.dart';
import '../../../diamond_projects/presentation/widgets/diamond_project_kpi_grid.dart';
import '../../../diamond_projects/presentation/widgets/diamond_project_mix_card.dart';
import '../../../diamond_projects/presentation/widgets/diamond_project_price_stats_card.dart';
import '../../../diamond_projects/presentation/widgets/diamond_project_scatter_card.dart';
import '../../../diamond_projects/presentation/widgets/diamond_project_selected_table.dart';
import '../../../diamonds/domain/models/diamond_filter_state.dart';
import '../../../diamonds/presentation/widgets/diamond_svg_data.dart';
import '../../application/seller_diamond_project_provider.dart';
import '../atelier/atelier_components.dart';
import '../atelier/atelier_feedback.dart';
import '../atelier/atelier_motion.dart';
import '../atelier/atelier_theme.dart';

const _dashboardCutGrades = ['Excellent', 'Very Good', 'Good', 'Fair', 'Poor'];

const _dashboardCutGradeKeys = <String, String>{
  'Excellent': RemainingL10n.cutGradeExcellent,
  'Very Good': RemainingL10n.cutGradeVeryGood,
  'Good': RemainingL10n.cutGradeGood,
  'Fair': RemainingL10n.cutGradeFair,
  'Poor': CatalogL10n.cutGradePoor,
};

String _cutGradeLabel(BuildContext context, String grade) {
  final key = _dashboardCutGradeKeys[grade];
  return key == null ? grade : context.tr(key);
}

const _dashboardCertLabs = ['GIA', 'IGI', 'AGS', 'HRD'];

/// Seller dashboard diamond-projects panel: filter dialog, inventory, analytics.
class SellerDashboardDiamondProjectsSection extends ConsumerStatefulWidget {
  const SellerDashboardDiamondProjectsSection({super.key});

  @override
  ConsumerState<SellerDashboardDiamondProjectsSection> createState() =>
      _SellerDashboardDiamondProjectsSectionState();
}

class _SellerDashboardDiamondProjectsSectionState
    extends ConsumerState<SellerDashboardDiamondProjectsSection> {
  bool _showAnalytics = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sellerDiamondProjectInventoryProvider.notifier).loadIfNeeded();
    });
  }

  Future<void> _openFilterDialog() async {
    final notifier = ref.read(sellerDiamondProjectFiltersProvider.notifier);
    final initial = ref.read(sellerDiamondProjectFiltersProvider);

    await showAtelierDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _SellerDiamondProjectFilterDialog(
          initialFilters: initial,
          notifier: notifier,
          onApply: () async {
            Navigator.of(dialogContext).pop();
            await ref
                .read(sellerDiamondProjectInventoryProvider.notifier)
                .applyFilters();
          },
          onClear: () {
            notifier.reset();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final inventoryAsync = ref.watch(sellerDiamondProjectInventoryProvider);
    final inventory = inventoryAsync.valueOrNull;
    final stats = ref.watch(sellerDiamondProjectStatsProvider);
    final isLoading = inventoryAsync.isLoading;
    final hasData = inventory?.hasApplied == true;

    return AtelierCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            onFilter: _openFilterDialog,
            onRefresh: isLoading
                ? null
                : () => ref
                      .read(sellerDiamondProjectInventoryProvider.notifier)
                      .applyFilters(),
          ),
          if (inventoryAsync.hasError) ...[
            const SizedBox(height: AtelierSpace.s16),
            AtelierNotice(
              text: inventoryAsync.error.toString(),
              tone: AtelierTone.ruby,
              icon: Icons.error_outline_rounded,
              actionLabel: context.tr(RemainingL10n.retry),
              onAction: () => ref
                  .read(sellerDiamondProjectInventoryProvider.notifier)
                  .applyFilters(),
            ),
          ],
          AnimatedSize(
            duration: AtelierMotion.slow,
            curve: AtelierMotion.emphasized,
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isLoading) ...[
                  const SizedBox(height: AtelierSpace.s20),
                  const Row(
                    children: [
                      Expanded(child: SkeletonBox(height: 72)),
                      SizedBox(width: 10),
                      Expanded(child: SkeletonBox(height: 72)),
                      SizedBox(width: 10),
                      Expanded(child: SkeletonBox(height: 72)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const SkeletonBox(height: 160),
                ] else if (hasData) ...[
                  const SizedBox(height: AtelierSpace.s20),
                  if (inventory!.isEmpty)
                    AtelierEmptyState(
                      compact: true,
                      icon: Icons.diamond_outlined,
                      title: context.tr(CatalogL10n.noDiamonds),
                      message: context.tr(CatalogL10n.adjustSearchCriteria),
                      actionLabel: context.tr(CatalogL10n.clearFilters),
                      onAction: () => ref
                          .read(sellerDiamondProjectInventoryProvider.notifier)
                          .clearFilters(),
                    )
                  else ...[
                    Row(
                      children: [
                        Expanded(
                          child: CountUpText(
                            context.tr(CatalogL10n.matchingStonesCount, {
                              'count': '${inventory.totalCount}',
                            }),
                            style: AtelierType.title(p.ink, size: 15),
                          ),
                        ),
                        AtelierButton(
                          label: _showAnalytics
                              ? context.tr(CatalogL10n.hideAnalytics)
                              : context.tr(CatalogL10n.showAnalytics),
                          icon: _showAnalytics
                              ? Icons.visibility_off_outlined
                              : Icons.insights_outlined,
                          compact: true,
                          variant: AtelierButtonVariant.ghost,
                          onPressed: () {
                            setState(() => _showAnalytics = !_showAnalytics);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AtelierSpace.s12),
                    DiamondProjectKpiGrid(stats: stats),
                    AnimatedSize(
                      duration: AtelierMotion.slow,
                      curve: AtelierMotion.emphasized,
                      alignment: Alignment.topCenter,
                      child: _showAnalytics
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: AtelierSpace.s16),
                                DiamondProjectPriceStatsCard(stats: stats),
                                const SizedBox(height: AtelierSpace.s16),
                                _AnalyticsChartsGrid(stats: stats),
                                const SizedBox(height: AtelierSpace.s16),
                                DiamondProjectScatterCard(stats: stats),
                              ],
                            )
                          : const SizedBox(width: double.infinity),
                    ),
                    const SizedBox(height: AtelierSpace.s16),
                    DiamondProjectSelectedTable(
                      items: inventory.items,
                      onRemove: (id) {
                        ref
                            .read(
                              sellerDiamondProjectInventoryProvider.notifier,
                            )
                            .removeItem(id);
                      },
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.onFilter, this.onRefresh});

  final VoidCallback onFilter;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final actions = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AtelierButton(
              label: context.tr(CatalogL10n.filters),
              icon: Icons.tune_rounded,
              compact: true,
              variant: AtelierButtonVariant.secondary,
              onPressed: onFilter,
            ),
            const SizedBox(width: AtelierSpace.s8),
            AtelierIconButton(
              icon: Icons.refresh_rounded,
              tooltip: context.tr(RemainingL10n.refresh),
              filled: true,
              onPressed: onRefresh,
            ),
          ],
        );
        final header = AtelierSectionHeader(
          overline: 'Inventory intelligence',
          title: context.tr(CatalogL10n.sellerDiamondProjectsTitle),
          subtitle: context.tr(CatalogL10n.sellerDiamondProjectsSubtitle),
        );
        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [header, const SizedBox(height: 14), actions],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: header),
            actions,
          ],
        );
      },
    );
  }
}

class _SellerDiamondProjectFilterDialog extends ConsumerStatefulWidget {
  const _SellerDiamondProjectFilterDialog({
    required this.initialFilters,
    required this.notifier,
    required this.onApply,
    required this.onClear,
  });

  final DiamondFilterState initialFilters;
  final SellerDiamondProjectFiltersNotifier notifier;
  final VoidCallback onApply;
  final VoidCallback onClear;

  @override
  ConsumerState<_SellerDiamondProjectFilterDialog> createState() =>
      _SellerDiamondProjectFilterDialogState();
}

class _SellerDiamondProjectFilterDialogState
    extends ConsumerState<_SellerDiamondProjectFilterDialog> {
  var _didApply = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sellerDiamondProjectFiltersProvider);
    final notifier = widget.notifier;
    final wide = MediaQuery.sizeOf(context).width >= 720;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && !_didApply) {
          widget.notifier.replaceFilters(widget.initialFilters);
        }
      },
      child: AtelierDialogFrame(
        maxWidth: wide ? 820 : 520,
        title: context.tr(CatalogL10n.filtersToOpenDiamondProject),
        icon: Icons.tune_rounded,
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.55,
          ),
          child: SingleChildScrollView(
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _SellerDiamondProjectFiltersLeft(
                          state: state,
                          notifier: notifier,
                        ),
                      ),
                      const SizedBox(width: AtelierSpace.s24),
                      Expanded(
                        child: _SellerDiamondProjectFiltersRight(
                          state: state,
                          notifier: notifier,
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SellerDiamondProjectFiltersLeft(
                        state: state,
                        notifier: notifier,
                      ),
                      const SizedBox(height: AtelierSpace.s16),
                      _SellerDiamondProjectFiltersRight(
                        state: state,
                        notifier: notifier,
                      ),
                    ],
                  ),
          ),
        ),
        actions: [
          AtelierButton(
            label: context.tr(CatalogL10n.clearFilters),
            variant: AtelierButtonVariant.ghost,
            onPressed: widget.onClear,
          ),
          AtelierButton(
            label: context.tr(CatalogL10n.cancel),
            variant: AtelierButtonVariant.secondary,
            onPressed: () {
              widget.notifier.replaceFilters(widget.initialFilters);
              Navigator.of(context).pop();
            },
          ),
          AtelierButton(
            label: context.tr(CatalogL10n.applyFilters),
            onPressed: () {
              _didApply = true;
              widget.onApply();
            },
          ),
        ],
      ),
    );
  }
}

class _SellerDiamondProjectFiltersLeft extends StatelessWidget {
  const _SellerDiamondProjectFiltersLeft({
    required this.state,
    required this.notifier,
  });

  final DiamondFilterState state;
  final SellerDiamondProjectFiltersNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FilterLabel(text: context.tr(CatalogL10n.shape)),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in kAllShapes)
              AtelierChoiceChip(
                label: context.trCatalogValue(item['name']!),
                selected: state.shapes.contains(item['name']),
                onTap: () => notifier.toggleShape(item['name']!),
              ),
          ],
        ),
        const SizedBox(height: AtelierSpace.s16),
        _FilterLabel(text: context.tr(CatalogL10n.color)),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: DiamondFilterState.colors.map((letter) {
            final selected = state.selectedStandardColors.contains(letter);
            return AtelierChoiceChip(
              label: letter,
              selected: selected,
              onTap: () => notifier.toggleStandardColor(letter),
            );
          }).toList(),
        ),
        const SizedBox(height: AtelierSpace.s16),
        _FilterLabel(text: context.tr(CatalogL10n.clarity)),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: DiamondFilterState.clarities.map((grade) {
            final selected = state.selectedClarityGrades.contains(grade);
            return AtelierChoiceChip(
              label: grade,
              selected: selected,
              onTap: () => notifier.toggleClarityGradeGroup(grade),
            );
          }).toList(),
        ),
        const SizedBox(height: AtelierSpace.s16),
        _FilterLabel(text: context.tr(CatalogL10n.cutGrade)),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _dashboardCutGrades.map((grade) {
            final selected = state.selectedCuts.contains(grade);
            return AtelierChoiceChip(
              label: _cutGradeLabel(context, grade),
              selected: selected,
              onTap: () => notifier.toggleCut(grade),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _SellerDiamondProjectFiltersRight extends StatelessWidget {
  const _SellerDiamondProjectFiltersRight({
    required this.state,
    required this.notifier,
  });

  final DiamondFilterState state;
  final SellerDiamondProjectFiltersNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FilterLabel(text: context.tr(CatalogL10n.fancyColors)),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: DiamondFilterState.fancyColors.map((color) {
            final selected = state.selectedFancyColors.contains(color);
            return AtelierChoiceChip(
              label: color,
              selected: selected,
              onTap: () => notifier.toggleFancyColor(color),
            );
          }).toList(),
        ),
        const SizedBox(height: AtelierSpace.s16),
        _FilterLabel(text: context.tr(CatalogL10n.certification)),
        Wrap(
          spacing: AtelierSpace.s8,
          runSpacing: AtelierSpace.s8,
          children: [
            for (final lab in _dashboardCertLabs)
              AtelierChoiceChip(
                label: lab,
                selected: state.selectedLabs.contains(lab),
                onTap: () => notifier.toggleLab(lab),
              ),
            AtelierChoiceChip(
              label: context.tr(CatalogL10n.certOther),
              selected: state.selectedLabs.contains('Others'),
              onTap: () => notifier.toggleLab('Others'),
            ),
          ],
        ),
        const SizedBox(height: AtelierSpace.s16),
        _CompactRangeRow(
          title: context.tr(CatalogL10n.caratWeight),
          min: state.minCarat,
          max: state.maxCarat,
          minLimit: 0,
          maxLimit: 100,
          onMinChanged: (v) => notifier.updateCaratRange(v, state.maxCarat),
          onMaxChanged: (v) => notifier.updateCaratRange(state.minCarat, v),
        ),
        const SizedBox(height: AtelierSpace.s12),
        _CompactRangeRow(
          title: context.tr(CatalogL10n.ratio),
          min: state.minRatio,
          max: state.maxRatio,
          minLimit: 0.5,
          maxLimit: 5,
          onMinChanged: (v) => notifier.updateRatioRange(v, state.maxRatio),
          onMaxChanged: (v) => notifier.updateRatioRange(state.minRatio, v),
        ),
        const SizedBox(height: AtelierSpace.s12),
        _FilterLabel(text: context.tr(CatalogL10n.measurements)),
        _CompactRangeRow(
          title: context.tr(CatalogL10n.length),
          min: state.minLength,
          max: state.maxLength,
          minLimit: 0,
          maxLimit: 100,
          onMinChanged: (v) => notifier.updateLengthRange(v, state.maxLength),
          onMaxChanged: (v) => notifier.updateLengthRange(state.minLength, v),
        ),
        const SizedBox(height: AtelierSpace.s8),
        _CompactRangeRow(
          title: context.tr(CatalogL10n.width),
          min: state.minWidth,
          max: state.maxWidth,
          minLimit: 0,
          maxLimit: 100,
          onMinChanged: (v) => notifier.updateWidthRange(v, state.maxWidth),
          onMaxChanged: (v) => notifier.updateWidthRange(state.minWidth, v),
        ),
        const SizedBox(height: AtelierSpace.s8),
        _CompactRangeRow(
          title: context.tr(CatalogL10n.height),
          min: state.minHeight,
          max: state.maxHeight,
          minLimit: 0,
          maxLimit: 100,
          onMinChanged: (v) => notifier.updateHeightRange(v, state.maxHeight),
          onMaxChanged: (v) => notifier.updateHeightRange(state.minHeight, v),
        ),
      ],
    );
  }
}

class _FilterLabel extends StatelessWidget {
  const _FilterLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AtelierSpace.s10),
      child: Text(
        text.toUpperCase(),
        style: AtelierType.overline(context.atelier.muted),
      ),
    );
  }
}

class _CompactRangeRow extends StatefulWidget {
  const _CompactRangeRow({
    required this.title,
    required this.min,
    required this.max,
    required this.minLimit,
    required this.maxLimit,
    required this.onMinChanged,
    required this.onMaxChanged,
  });

  final String title;
  final double min;
  final double max;
  final double minLimit;
  final double maxLimit;
  final ValueChanged<double> onMinChanged;
  final ValueChanged<double> onMaxChanged;

  @override
  State<_CompactRangeRow> createState() => _CompactRangeRowState();
}

class _CompactRangeRowState extends State<_CompactRangeRow> {
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;

  @override
  void initState() {
    super.initState();
    _minCtrl = TextEditingController(
      text: _fieldText(widget.min, widget.minLimit),
    );
    _maxCtrl = TextEditingController(
      text: _fieldText(widget.max, widget.maxLimit),
    );
  }

  @override
  void didUpdateWidget(covariant _CompactRangeRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.min != widget.min) {
      _minCtrl.text = _fieldText(widget.min, widget.minLimit);
    }
    if (oldWidget.max != widget.max) {
      _maxCtrl.text = _fieldText(widget.max, widget.maxLimit);
    }
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  String _fieldText(double value, double defaultLimit) {
    if ((value - defaultLimit).abs() <= 1e-6) return '';
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
  }

  double? _parse(String text, double fallback) {
    if (text.trim().isEmpty) return fallback;
    return double.tryParse(text.trim());
  }

  void _commitMin(String text) {
    final parsed = _parse(text, widget.minLimit) ?? widget.minLimit;
    widget.onMinChanged(parsed.clamp(widget.minLimit, widget.max).toDouble());
  }

  void _commitMax(String text) {
    final parsed = _parse(text, widget.maxLimit) ?? widget.maxLimit;
    widget.onMaxChanged(parsed.clamp(widget.min, widget.maxLimit).toDouble());
  }

  InputDecoration _decoration(BuildContext context, String hint) {
    final p = context.atelier;
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: p.sunken,
      hintText: hint,
      hintStyle: AtelierType.caption(p.muted, size: 12.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AtelierRadius.sm),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AtelierRadius.sm),
        borderSide: BorderSide(color: p.gold),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Row(
      children: [
        SizedBox(
          width: 76,
          child: Text(
            widget.title,
            style: AtelierType.label(p.inkSoft, size: 12.5),
          ),
        ),
        Expanded(
          child: TextField(
            controller: _minCtrl,
            style: AtelierType.figure(p.ink, size: 13.5),
            cursorColor: p.gold,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _decoration(context, context.tr(CatalogL10n.minimum)),
            onSubmitted: _commitMin,
            onEditingComplete: () => _commitMin(_minCtrl.text),
          ),
        ),
        const SizedBox(width: AtelierSpace.s8),
        Expanded(
          child: TextField(
            controller: _maxCtrl,
            style: AtelierType.figure(p.ink, size: 13.5),
            cursorColor: p.gold,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _decoration(context, context.tr(CatalogL10n.maximum)),
            onSubmitted: _commitMax,
            onEditingComplete: () => _commitMax(_maxCtrl.text),
          ),
        ),
      ],
    );
  }
}

class _AnalyticsChartsGrid extends StatelessWidget {
  const _AnalyticsChartsGrid({required this.stats});

  final DiamondProjectStats stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        final mixes = [
          DiamondProjectMixCard(
            title: context.tr(CatalogL10n.shapeMix),
            entries: stats.shapeMix,
          ),
          DiamondProjectMixCard(
            title: context.tr(CatalogL10n.colorMix),
            entries: stats.colorMix,
          ),
        ];
        final charts = [
          DiamondProjectMixCard(
            title: context.tr(CatalogL10n.clarityMix),
            entries: stats.clarityMix,
          ),
          DiamondProjectHistogramCard(
            title: context.tr(CatalogL10n.priceDistribution),
            entries: stats.priceBuckets,
          ),
          DiamondProjectHistogramCard(
            title: context.tr(CatalogL10n.pricePerCaratDistribution),
            entries: stats.ppcBuckets,
          ),
          DiamondProjectHistogramCard(
            title: context.tr(CatalogL10n.caratDistribution),
            entries: stats.caratBuckets,
          ),
        ];

        if (!wide) {
          return Column(
            children: [
              mixes[0],
              const SizedBox(height: AtelierSpace.s12),
              mixes[1],
              const SizedBox(height: AtelierSpace.s12),
              for (var i = 0; i < charts.length; i++) ...[
                if (i > 0) const SizedBox(height: AtelierSpace.s12),
                charts[i],
              ],
            ],
          );
        }

        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: mixes[0]),
                const SizedBox(width: AtelierSpace.s12),
                Expanded(child: mixes[1]),
              ],
            ),
            const SizedBox(height: AtelierSpace.s12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: charts[0]),
                const SizedBox(width: AtelierSpace.s12),
                Expanded(child: charts[1]),
              ],
            ),
            const SizedBox(height: AtelierSpace.s12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: charts[2]),
                const SizedBox(width: AtelierSpace.s12),
                Expanded(child: charts[3]),
              ],
            ),
          ],
        );
      },
    );
  }
}
