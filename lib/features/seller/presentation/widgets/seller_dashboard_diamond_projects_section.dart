import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_scope.dart';
import '../../../diamond_projects/presentation/widgets/diamond_project_overview.dart';
import '../../../diamond_projects/presentation/widgets/diamond_project_panel.dart';
import '../../../diamond_projects/domain/models/diamond_project_stats.dart';
import '../../../diamonds/domain/models/diamond_filter_state.dart';
import '../../../diamonds/presentation/widgets/diamond_svg_data.dart';
import '../../application/seller_diamond_project_provider.dart';
import '../atelier/atelier_components.dart';
import '../atelier/atelier_feedback.dart';
import '../atelier/atelier_motion.dart';
import '../atelier/atelier_studio.dart';
import '../atelier/atelier_theme.dart';

const _dashboardCutGrades = [
  'Ideal',
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

const _dashboardCertLabs = ['GIA', 'IGI', 'AGS', 'HRD', 'EGL', 'Others'];

/// Seller dashboard diamond-projects panel: filter dialog, inventory, analytics.
class SellerDashboardDiamondProjectsSection extends ConsumerStatefulWidget {
  const SellerDashboardDiamondProjectsSection({super.key});

  @override
  ConsumerState<SellerDashboardDiamondProjectsSection> createState() =>
      _SellerDashboardDiamondProjectsSectionState();
}

class _SellerDashboardDiamondProjectsSectionState
    extends ConsumerState<SellerDashboardDiamondProjectsSection> {
  DiamondProjectTab _tab = DiamondProjectTab.overview;

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
    final inventoryAsync = ref.watch(sellerDiamondProjectInventoryProvider);
    final inventory = inventoryAsync.value;
    final stats = ref.watch(sellerDiamondProjectStatsProvider);
    final isLoading = inventoryAsync.isLoading;
    final hasData = inventory?.hasApplied == true;

    return AtelierCard(
      // Tighter than the default card: the hero inside is already a framed
      // surface, so a wide gutter only wastes width on phones.
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
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
                  const SizedBox(height: AtelierSpace.s16),
                  const Row(
                    children: [
                      Expanded(child: SkeletonBox(height: 72)),
                      SizedBox(width: 8),
                      Expanded(child: SkeletonBox(height: 72)),
                      SizedBox(width: 8),
                      Expanded(child: SkeletonBox(height: 72)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const SkeletonBox(height: 160),
                ] else if (hasData) ...[
                  const SizedBox(height: AtelierSpace.s16),
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
                  else
                    // One compact summary, then the Overview · Mix · Spread ·
                    // Stones tabs shared with the diamond project screen.
                    LuxeScope(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ProjectSummary(stats: stats),
                          const SizedBox(height: AtelierSpace.s12),
                          Center(
                            child: DiamondProjectTabBar(
                              selected: _tab,
                              onChanged: (t) => setState(() => _tab = t),
                            ),
                          ),
                          const SizedBox(height: AtelierSpace.s10),
                          // Already inside this card: draw the analytics
                          // panels without their own frame and inset.
                          DiamondProjectPanelFlush(
                            child: DiamondProjectTabView(
                              tab: _tab,
                              stats: stats,
                              items: inventory.items,
                              onRemove: (id) => ref
                                  .read(
                                    sellerDiamondProjectInventoryProvider
                                        .notifier,
                                  )
                                  .removeItem(id),
                            ),
                          ),
                        ],
                      ),
                    ),
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
    final p = context.atelier;
    return Row(
      children: [
        Expanded(
          child: Text(
            context.tr(CatalogL10n.sellerDiamondProjectsTitle),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AtelierType.title(p.ink, size: 17),
          ),
        ),
        AtelierIconButton(
          icon: Icons.tune_rounded,
          tooltip: context.tr(CatalogL10n.filters),
          filled: true,
          size: 38,
          onPressed: onFilter,
        ),
        const SizedBox(width: AtelierSpace.s8),
        AtelierIconButton(
          icon: Icons.refresh_rounded,
          tooltip: context.tr(RemainingL10n.refresh),
          filled: true,
          size: 38,
          onPressed: onRefresh,
        ),
      ],
    );
  }
}

/// Key figures of the live selection in one light strip: carats, value and
/// price per carat, with averages underneath. The stone count lives on the
/// Stones tab, so it is not repeated here.
class _ProjectSummary extends StatelessWidget {
  const _ProjectSummary({required this.stats});

  final DiamondProjectStats stats;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    String money(double v) => atelierMoney(v.round(), symbol: r'$');
    Widget figure(String value, String label) => Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: AtelierType.title(p.ink, size: 16)),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AtelierType.caption(p.muted, size: 11),
          ),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: p.sunken,
        borderRadius: BorderRadius.circular(AtelierRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              figure(
                '${stats.totalCarat.toStringAsFixed(2)} ct',
                context.tr(CatalogL10n.projectTotalCaratKpi),
              ),
              figure(money(stats.totalPrice), 'Value'),
              figure(money(stats.avgPpc), r'Avg $/ct'),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            'Avg ${stats.avgCarat.toStringAsFixed(2)} ct · '
            'Avg ${money(stats.avgPrice)}',
            textAlign: TextAlign.center,
            style: AtelierType.caption(p.muted, size: 11.5),
          ),
        ],
      ),
    );
  }
}

/// Keeps the options the seller's inventory holds, plus any already picked
/// (so they can still be unpicked). Unknown inventory keeps the full list.
List<String> _available(
  List<String> options,
  Set<String>? inInventory,
  List<String> selected,
) {
  if (inInventory == null) return options;
  return [
    for (final o in options)
      if (SellerDiamondProjectFacets.has(inInventory, o) ||
          selected.contains(o))
        o,
  ];
}

String? _hint(double? v) {
  if (v == null) return null;
  return v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);
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
    final p = context.atelier;
    final state = ref.watch(sellerDiamondProjectFiltersProvider);
    final facets = ref.watch(
      sellerDiamondProjectInventoryProvider.select((s) => s.value?.facets),
    );
    final notifier = widget.notifier;
    final wide = MediaQuery.sizeOf(context).width >= 720;

    final left = _SellerDiamondProjectFiltersLeft(
      state: state,
      notifier: notifier,
      facets: facets,
    );
    final right = _SellerDiamondProjectFiltersRight(
      state: state,
      notifier: notifier,
      facets: facets,
    );

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && !_didApply) {
          widget.notifier.replaceFilters(widget.initialFilters);
        }
      },
      child: Material(
        type: MaterialType.transparency,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: wide ? 760 : 480),
          child: Container(
            decoration: BoxDecoration(
              color: p.raised,
              borderRadius: BorderRadius.circular(AtelierRadius.xl),
              border: Border.all(color: p.hairline),
              boxShadow: p.floatShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header: title left, Clear top-right so the footer only
                // carries Cancel / Apply.
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 5, 4),
                  child: Row(
                    children: [
                      Icon(Icons.tune_rounded, size: 18, color: p.gold),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          context.tr(CatalogL10n.filtersToOpenDiamondProject),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AtelierType.title(p.ink, size: 16),
                        ),
                      ),
                      TextButton(
                        onPressed: widget.onClear,
                        style: TextButton.styleFrom(
                          foregroundColor: p.gold,
                          minimumSize: const Size(0, 32),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          context.tr(CatalogL10n.clearAll),
                          style: AtelierType.label(p.gold, size: 12.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, thickness: 1, color: p.hairline),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: left),
                              const SizedBox(width: AtelierSpace.s16),
                              Expanded(child: right),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [left, right],
                          ),
                  ),
                ),
                Divider(height: 1, thickness: 1, color: p.hairline),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: AtelierButton(
                          label: context.tr(CatalogL10n.cancel),
                          variant: AtelierButtonVariant.secondary,
                          compact: true,
                          onPressed: () {
                            widget.notifier.replaceFilters(
                              widget.initialFilters,
                            );
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                      const SizedBox(width: AtelierSpace.s8),
                      Expanded(
                        child: AtelierButton(
                          label: context.tr(CatalogL10n.applyFilters),
                          compact: true,
                          onPressed: () {
                            _didApply = true;
                            widget.onApply();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Labelled chip group; draws nothing when no option is available.
class _ChipSection extends StatelessWidget {
  const _ChipSection({
    required this.title,
    required this.options,
    required this.isSelected,
    required this.onTap,
    this.labelOf,
  });

  final String title;
  final List<String> options;
  final bool Function(String) isSelected;
  final ValueChanged<String> onTap;
  final String Function(String)? labelOf;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AtelierSpace.s10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FilterLabel(text: title),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              for (final o in options)
                _MiniChip(
                  label: labelOf?.call(o) ?? o,
                  selected: isSelected(o),
                  onTap: () => onTap(o),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Dense toggle chip: colour and border mark the selection, no check icon,
/// so more chips fit on a line.
class _MiniChip extends StatelessWidget {
  const _MiniChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      borderRadius: BorderRadius.circular(AtelierRadius.pill),
      child: AnimatedContainer(
        duration: AtelierMotion.base,
        curve: AtelierMotion.emphasized,
        constraints: const BoxConstraints(minWidth: 32),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? p.goldSoft : p.surface,
          borderRadius: BorderRadius.circular(AtelierRadius.pill),
          border: Border.all(
            color: selected ? p.gold : p.hairline,
            width: selected ? 1.2 : 1,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: AtelierType.label(
            selected ? p.ink : p.inkSoft,
            size: 12,
            weight: selected ? FontWeight.w600 : null,
          ),
        ),
      ),
    );
  }
}

class _SellerDiamondProjectFiltersLeft extends StatelessWidget {
  const _SellerDiamondProjectFiltersLeft({
    required this.state,
    required this.notifier,
    required this.facets,
  });

  final DiamondFilterState state;
  final SellerDiamondProjectFiltersNotifier notifier;
  final SellerDiamondProjectFacets? facets;

  @override
  Widget build(BuildContext context) {
    final f = facets;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ChipSection(
          title: context.tr(CatalogL10n.shape),
          options: _available(
            [for (final s in kAllShapes) s['name']!],
            f?.shapes,
            state.shapes,
          ),
          labelOf: context.trCatalogValue,
          isSelected: state.shapes.contains,
          onTap: notifier.toggleShape,
        ),
        _ChipSection(
          title: context.tr(CatalogL10n.color),
          options: _available(
            DiamondFilterState.colors,
            f?.colors,
            state.selectedStandardColors,
          ),
          isSelected: state.selectedStandardColors.contains,
          onTap: notifier.toggleStandardColor,
        ),
        _ChipSection(
          title: context.tr(CatalogL10n.clarity),
          options: _available(
            DiamondFilterState.clarities,
            f?.clarities,
            state.selectedClarityGrades,
          ),
          isSelected: state.selectedClarityGrades.contains,
          onTap: notifier.toggleClarityGradeGroup,
        ),
        _ChipSection(
          title: context.tr(CatalogL10n.cutGrade),
          options: _available(_dashboardCutGrades, f?.cuts, state.selectedCuts),
          labelOf: (g) => _cutGradeLabel(context, g),
          isSelected: state.selectedCuts.contains,
          onTap: notifier.toggleCut,
        ),
      ],
    );
  }
}

class _SellerDiamondProjectFiltersRight extends StatelessWidget {
  const _SellerDiamondProjectFiltersRight({
    required this.state,
    required this.notifier,
    required this.facets,
  });

  final DiamondFilterState state;
  final SellerDiamondProjectFiltersNotifier notifier;
  final SellerDiamondProjectFacets? facets;

  @override
  Widget build(BuildContext context) {
    final f = facets;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ChipSection(
          title: context.tr(CatalogL10n.fancyColors),
          options: _available(
            DiamondFilterState.fancyColors,
            f?.fancyColors,
            state.selectedFancyColors,
          ),
          isSelected: state.selectedFancyColors.contains,
          onTap: notifier.toggleFancyColor,
        ),
        _ChipSection(
          title: context.tr(CatalogL10n.certification),
          options: _available(_dashboardCertLabs, f?.labs, state.selectedLabs),
          labelOf: (lab) =>
              lab == 'Others' ? context.tr(CatalogL10n.certOther) : lab,
          isSelected: state.selectedLabs.contains,
          onTap: notifier.toggleLab,
        ),
        _CompactRangeRow(
          title: context.tr(CatalogL10n.caratWeight),
          min: state.minCarat,
          max: state.maxCarat,
          minLimit: 0,
          maxLimit: 100,
          minHint: _hint(f?.minCarat),
          maxHint: _hint(f?.maxCarat),
          onMinChanged: (v) => notifier.updateCaratRange(v, state.maxCarat),
          onMaxChanged: (v) => notifier.updateCaratRange(state.minCarat, v),
        ),
        const SizedBox(height: 5),
        _CompactRangeRow(
          title: context.tr(CatalogL10n.ratio),
          min: state.minRatio,
          max: state.maxRatio,
          minLimit: 0.5,
          maxLimit: 5,
          minHint: _hint(f?.minRatio),
          maxHint: _hint(f?.maxRatio),
          onMinChanged: (v) => notifier.updateRatioRange(v, state.maxRatio),
          onMaxChanged: (v) => notifier.updateRatioRange(state.minRatio, v),
        ),
        const SizedBox(height: AtelierSpace.s10),
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
        const SizedBox(height: 5),
        _CompactRangeRow(
          title: context.tr(CatalogL10n.width),
          min: state.minWidth,
          max: state.maxWidth,
          minLimit: 0,
          maxLimit: 100,
          onMinChanged: (v) => notifier.updateWidthRange(v, state.maxWidth),
          onMaxChanged: (v) => notifier.updateWidthRange(state.minWidth, v),
        ),
        const SizedBox(height: 5),
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
      padding: const EdgeInsets.only(bottom: 5),
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
    this.minHint,
    this.maxHint,
  });

  final String title;
  final double min;
  final double max;
  final double minLimit;
  final double maxLimit;
  final ValueChanged<double> onMinChanged;
  final ValueChanged<double> onMaxChanged;

  /// Inventory's own low / high, shown in the empty fields.
  final String? minHint;
  final String? maxHint;

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
      hintStyle: AtelierType.caption(p.muted, size: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AtelierRadius.sm),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AtelierRadius.sm),
        borderSide: BorderSide(color: p.gold),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AtelierType.label(p.inkSoft, size: 12),
          ),
        ),
        Expanded(
          child: TextField(
            controller: _minCtrl,
            style: AtelierType.figure(p.ink, size: 13),
            cursorColor: p.gold,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _decoration(
              context,
              widget.minHint ?? context.tr(CatalogL10n.minimum),
            ),
            onSubmitted: _commitMin,
            onEditingComplete: () => _commitMin(_minCtrl.text),
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: TextField(
            controller: _maxCtrl,
            style: AtelierType.figure(p.ink, size: 13),
            cursorColor: p.gold,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _decoration(
              context,
              widget.maxHint ?? context.tr(CatalogL10n.maximum),
            ),
            onSubmitted: _commitMax,
            onEditingComplete: () => _commitMax(_maxCtrl.text),
          ),
        ),
      ],
    );
  }
}
