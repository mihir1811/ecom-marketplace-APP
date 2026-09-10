import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/catalog_empty_state.dart';
import '../../../../core/widgets/filters/filter_boolean_checkbox.dart';
import '../../../../core/widgets/filters/filter_chip.dart';
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

const _dashboardCutGrades = [
  'Excellent',
  'Very Good',
  'Good',
  'Fair',
  'Poor',
];

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

    await showAppDialog<void>(
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
    final inventoryAsync = ref.watch(sellerDiamondProjectInventoryProvider);
    final inventory = inventoryAsync.valueOrNull;
    final stats = ref.watch(sellerDiamondProjectStatsProvider);
    final isLoading = inventoryAsync.isLoading;
    final hasData = inventory?.hasApplied == true;

    return Column(
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
          const SizedBox(height: AppSpacing.s12),
          Text(
            inventoryAsync.error.toString(),
            style: AppTypography.body.copyWith(color: AppColors.error),
          ),
        ],
        if (isLoading && !hasData) ...[
          const SizedBox(height: AppSpacing.s24),
          const Center(child: CircularProgressIndicator()),
        ] else if (hasData) ...[
          const SizedBox(height: AppSpacing.s16),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.s24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (inventory!.isEmpty)
            CatalogEmptyState(
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
                  child: Text(
                    context.tr(CatalogL10n.matchingStonesCount, {
                      'count': '${inventory.totalCount}',
                    }),
                    style: AppTypography.title.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _showAnalytics = !_showAnalytics);
                  },
                  child: Text(
                    _showAnalytics
                        ? context.tr(CatalogL10n.hideAnalytics)
                        : context.tr(CatalogL10n.showAnalytics),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s12),
            DiamondProjectKpiGrid(stats: stats),
            if (_showAnalytics) ...[
              const SizedBox(height: AppSpacing.s16),
              DiamondProjectPriceStatsCard(stats: stats),
              const SizedBox(height: AppSpacing.s16),
              _AnalyticsChartsGrid(stats: stats),
              const SizedBox(height: AppSpacing.s16),
              DiamondProjectScatterCard(stats: stats),
            ],
            const SizedBox(height: AppSpacing.s16),
            DiamondProjectSelectedTable(
              items: inventory.items,
              onRemove: (id) {
                ref
                    .read(sellerDiamondProjectInventoryProvider.notifier)
                    .removeItem(id);
              },
            ),
          ],
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.onFilter,
    this.onRefresh,
  });

  final VoidCallback onFilter;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(CatalogL10n.sellerDiamondProjectsTitle),
                style: AppTypography.title.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: AppSpacing.s4),
              Text(
                context.tr(CatalogL10n.sellerDiamondProjectsSubtitle),
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary(context),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: onFilter,
          icon: const Icon(Icons.tune, size: 16),
          label: Text(context.tr(CatalogL10n.filters)),
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            foregroundColor: AppColors.textPrimary(context),
          ),
        ),
        if (onRefresh != null) ...[
          const SizedBox(width: AppSpacing.s8),
          OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh, size: 16),
            label: Text(context.tr(RemainingL10n.refresh)),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              foregroundColor: AppColors.textPrimary(context),
            ),
          ),
        ],
      ],
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
      child: AlertDialog(
      backgroundColor: AppColors.card(context),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s24,
      ),
      title: Text(
        context.tr(CatalogL10n.filtersToOpenDiamondProject),
        style: AppTypography.title.copyWith(fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: wide ? 760 : double.maxFinite,
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
                    const SizedBox(width: AppSpacing.s16),
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
                    const SizedBox(height: AppSpacing.s16),
                    _SellerDiamondProjectFiltersRight(
                      state: state,
                      notifier: notifier,
                    ),
                  ],
                ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onClear();
          },
          child: Text(context.tr(CatalogL10n.clearFilters)),
        ),
        TextButton(
          onPressed: () {
            widget.notifier.replaceFilters(widget.initialFilters);
            Navigator.of(context).pop();
          },
          child: Text(context.tr(CatalogL10n.cancel)),
        ),
        FilledButton(
          onPressed: () {
            _didApply = true;
            widget.onApply();
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.info,
            foregroundColor: AppColors.warmWhite,
          ),
          child: Text(context.tr(CatalogL10n.applyFilters)),
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
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final item in kAllShapes)
              FilterChipWidget(
                label: context.trCatalogValue(item['name']!),
                isSelected: state.shapes.contains(item['name']),
                onTap: () => notifier.toggleShape(item['name']!),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.s16),
        _FilterLabel(text: context.tr(CatalogL10n.color)),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: DiamondFilterState.colors.map((letter) {
            final selected = state.selectedStandardColors.contains(letter);
            return FilterChipWidget(
              label: letter,
              isSelected: selected,
              onTap: () => notifier.toggleStandardColor(letter),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.s16),
        _FilterLabel(text: context.tr(CatalogL10n.clarity)),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: DiamondFilterState.clarities.map((grade) {
            final selected = state.selectedClarityGrades.contains(grade);
            return FilterChipWidget(
              label: grade,
              isSelected: selected,
              onTap: () => notifier.toggleClarityGradeGroup(grade),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.s16),
        _FilterLabel(text: context.tr(CatalogL10n.cutGrade)),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _dashboardCutGrades.map((grade) {
            final selected = state.selectedCuts.contains(grade);
            return FilterChipWidget(
              label: _cutGradeLabel(context, grade),
              isSelected: selected,
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
          spacing: 6,
          runSpacing: 6,
          children: DiamondFilterState.fancyColors.map((color) {
            final selected = state.selectedFancyColors.contains(color);
            return FilterChipWidget(
              label: color,
              isSelected: selected,
              onTap: () => notifier.toggleFancyColor(color),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.s16),
        _FilterLabel(text: context.tr(CatalogL10n.certification)),
        Wrap(
          spacing: AppSpacing.s12,
          runSpacing: AppSpacing.s8,
          children: [
            for (final lab in _dashboardCertLabs)
              FilterBooleanCheckbox(
                label: lab,
                value: state.selectedLabs.contains(lab),
                onChanged: (_) => notifier.toggleLab(lab),
              ),
            FilterBooleanCheckbox(
              label: context.tr(CatalogL10n.certOther),
              value: state.selectedLabs.contains('Others'),
              onChanged: (_) => notifier.toggleLab('Others'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s16),
        _CompactRangeRow(
          title: context.tr(CatalogL10n.caratWeight),
          min: state.minCarat,
          max: state.maxCarat,
          minLimit: 0,
          maxLimit: 100,
          onMinChanged: (v) => notifier.updateCaratRange(v, state.maxCarat),
          onMaxChanged: (v) => notifier.updateCaratRange(state.minCarat, v),
        ),
        const SizedBox(height: AppSpacing.s12),
        _CompactRangeRow(
          title: context.tr(CatalogL10n.ratio),
          min: state.minRatio,
          max: state.maxRatio,
          minLimit: 0.5,
          maxLimit: 5,
          onMinChanged: (v) => notifier.updateRatioRange(v, state.maxRatio),
          onMaxChanged: (v) => notifier.updateRatioRange(state.minRatio, v),
        ),
        const SizedBox(height: AppSpacing.s12),
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
        const SizedBox(height: AppSpacing.s8),
        _CompactRangeRow(
          title: context.tr(CatalogL10n.width),
          min: state.minWidth,
          max: state.maxWidth,
          minLimit: 0,
          maxLimit: 100,
          onMinChanged: (v) => notifier.updateWidthRange(v, state.maxWidth),
          onMaxChanged: (v) => notifier.updateWidthRange(state.minWidth, v),
        ),
        const SizedBox(height: AppSpacing.s8),
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
      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
      child: Text(
        text.toUpperCase(),
        style: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: AppColors.textSecondary(context),
        ),
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
    _minCtrl = TextEditingController(text: _fieldText(widget.min, widget.minLimit));
    _maxCtrl = TextEditingController(text: _fieldText(widget.max, widget.maxLimit));
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
    widget.onMinChanged(
      parsed.clamp(widget.minLimit, widget.max).toDouble(),
    );
  }

  void _commitMax(String text) {
    final parsed = _parse(text, widget.maxLimit) ?? widget.maxLimit;
    widget.onMaxChanged(
      parsed.clamp(widget.min, widget.maxLimit).toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            widget.title,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(context),
            ),
          ),
        ),
        Expanded(
          child: TextField(
            controller: _minCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              isDense: true,
              hintText: context.tr(CatalogL10n.minimum),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.r8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
            ),
            onSubmitted: _commitMin,
            onEditingComplete: () => _commitMin(_minCtrl.text),
          ),
        ),
        const SizedBox(width: AppSpacing.s8),
        Expanded(
          child: TextField(
            controller: _maxCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              isDense: true,
              hintText: context.tr(CatalogL10n.maximum),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.r8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
            ),
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
              const SizedBox(height: AppSpacing.s12),
              mixes[1],
              const SizedBox(height: AppSpacing.s12),
              for (var i = 0; i < charts.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.s12),
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
                const SizedBox(width: AppSpacing.s12),
                Expanded(child: mixes[1]),
              ],
            ),
            const SizedBox(height: AppSpacing.s12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: charts[0]),
                const SizedBox(width: AppSpacing.s12),
                Expanded(child: charts[1]),
              ],
            ),
            const SizedBox(height: AppSpacing.s12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: charts[2]),
                const SizedBox(width: AppSpacing.s12),
                Expanded(child: charts[3]),
              ],
            ),
          ],
        );
      },
    );
  }
}
