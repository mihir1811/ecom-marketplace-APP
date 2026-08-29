import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/filters/filter_accordion_section.dart';
import '../../../../core/widgets/filters/filter_end_drawer_shell.dart';
import '../../application/bullions_filter_provider.dart';
import '../../application/bullions_list_provider.dart';
import '../../domain/models/bullions_filter_state.dart';

class BullionsFilterDrawer extends ConsumerStatefulWidget {
  const BullionsFilterDrawer({super.key});

  @override
  ConsumerState<BullionsFilterDrawer> createState() =>
      _BullionsFilterDrawerState();
}

class _BullionsFilterDrawerState extends ConsumerState<BullionsFilterDrawer> {
  final Map<String, bool> _expanded = {
    'shape': true,
    'price': true,
    'weight': true,
    'quantity': true,
    'condition': true,
    'certification': true,
    'mint': true,
    'dimensions': true,
  };

  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(bullionsFilterDraftProvider);
    _controllers = {
      'priceMin': TextEditingController(text: _text(draft.priceMin)),
      'priceMax': TextEditingController(text: _text(draft.priceMax)),
      'weightMin': TextEditingController(text: _text(draft.weightMin)),
      'weightMax': TextEditingController(text: _text(draft.weightMax)),
      'quantityMin': TextEditingController(text: _text(draft.quantityMin)),
      'quantityMax': TextEditingController(text: _text(draft.quantityMax)),
      'lengthMin': TextEditingController(text: _text(draft.lengthMin)),
      'lengthMax': TextEditingController(text: _text(draft.lengthMax)),
      'widthMin': TextEditingController(text: _text(draft.widthMin)),
      'widthMax': TextEditingController(text: _text(draft.widthMax)),
      'heightMin': TextEditingController(text: _text(draft.heightMin)),
      'heightMax': TextEditingController(text: _text(draft.heightMax)),
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bullionsFilterDraftProvider.notifier).syncFromApplied();
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _text(double value) => value > 0 ? value.toStringAsFixed(0) : '';

  double _parse(String key) => double.tryParse(_controllers[key]!.text) ?? 0;

  void _syncControllers(BullionsFilterState draft) {
    final next = {
      'priceMin': draft.priceMin,
      'priceMax': draft.priceMax,
      'weightMin': draft.weightMin,
      'weightMax': draft.weightMax,
      'quantityMin': draft.quantityMin,
      'quantityMax': draft.quantityMax,
      'lengthMin': draft.lengthMin,
      'lengthMax': draft.lengthMax,
      'widthMin': draft.widthMin,
      'widthMax': draft.widthMax,
      'heightMin': draft.heightMin,
      'heightMax': draft.heightMax,
    };
    next.forEach((key, value) {
      final newText = _text(value);
      if (_controllers[key]!.text != newText) {
        _controllers[key]!.text = newText;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(bullionsFilterDraftProvider);
    _syncControllers(draft);

    final notifier = ref.read(bullionsFilterDraftProvider.notifier);

    return FilterEndDrawerShell(
      onReset: () {
        notifier.reset();
        _syncControllers(ref.read(bullionsFilterDraftProvider));
      },
      onShowResults: () {
        notifier.apply();
        ref.read(bullionsListProvider.notifier).refresh();
        Navigator.of(context).maybePop();
      },
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.s24),
        children: [
          _section(
            'shape',
            context.tr(CatalogL10n.shape),
            _chipGrid(
              BullionsFilterState.shapeOptions,
              draft.shapes,
              notifier.toggleShape,
            ),
          ),
          _section(
            'price',
            context.tr(CatalogL10n.priceRange),
            _rangeInputs(
              label: context.tr(CatalogL10n.currentRange),
              minKey: 'priceMin',
              maxKey: 'priceMax',
              minLabel: 'Min (\$)',
              maxLabel: 'Max (\$)',
              onChanged: () => notifier.setPriceRange(
                min: _parse('priceMin'),
                max: _parse('priceMax'),
              ),
            ),
          ),
          _section(
            'weight',
            context.tr(CatalogL10n.weight),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s20,
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.start,
                      crossAxisAlignment: WrapCrossAlignment.start,
                      spacing: AppSpacing.s8,
                      runSpacing: AppSpacing.s8,
                      children: [
                        for (final item
                            in BullionsFilterState.weightChipOptions)
                          _MiniChip(
                            label: item,
                            selected: draft.weightChips.contains(item),
                            onTap: () => notifier.toggleWeightChip(item),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s12),
                _rangeInputs(
                  label: context.tr(CatalogL10n.currentRange),
                  minKey: 'weightMin',
                  maxKey: 'weightMax',
                  minLabel: 'Min',
                  maxLabel: 'Max',
                  onChanged: () => notifier.setWeightRange(
                    min: _parse('weightMin'),
                    max: _parse('weightMax'),
                  ),
                ),
              ],
            ),
          ),
          _section(
            'quantity',
            context.tr(CatalogL10n.quantity),
            _rangeInputs(
              label: context.tr(CatalogL10n.currentRange),
              minKey: 'quantityMin',
              maxKey: 'quantityMax',
              minLabel: 'Min',
              maxLabel: 'Max',
              onChanged: () => notifier.setQuantityRange(
                min: _parse('quantityMin'),
                max: _parse('quantityMax'),
              ),
            ),
          ),
          _section(
            'condition',
            context.tr(CatalogL10n.condition),
            _chipGrid(
              BullionsFilterState.conditionOptions,
              draft.conditions,
              notifier.toggleCondition,
            ),
          ),
          _section(
            'certification',
            'Certification',
            _chipGrid(
              BullionsFilterState.certificationOptions,
              draft.certifications,
              notifier.toggleCertification,
            ),
          ),
          _section(
            'mint',
            context.tr(CatalogL10n.mintMark),
            _chipGrid(
              BullionsFilterState.mintMarkOptions,
              draft.mintMarks,
              notifier.toggleMintMark,
            ),
          ),
          _section(
            'dimensions',
            context.tr(CatalogL10n.dimensions),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _rangeInputs(
                  label: context.tr(CatalogL10n.length),
                  minKey: 'lengthMin',
                  maxKey: 'lengthMax',
                  minLabel: 'Min',
                  maxLabel: 'Max',
                  onChanged: () => notifier.setLengthRange(
                    min: _parse('lengthMin'),
                    max: _parse('lengthMax'),
                  ),
                ),
                _rangeInputs(
                  label: context.tr(CatalogL10n.width),
                  minKey: 'widthMin',
                  maxKey: 'widthMax',
                  minLabel: 'Min',
                  maxLabel: 'Max',
                  onChanged: () => notifier.setWidthRange(
                    min: _parse('widthMin'),
                    max: _parse('widthMax'),
                  ),
                ),
                _rangeInputs(
                  label: context.tr(CatalogL10n.height),
                  minKey: 'heightMin',
                  maxKey: 'heightMax',
                  minLabel: 'Min',
                  maxLabel: 'Max',
                  onChanged: () => notifier.setHeightRange(
                    min: _parse('heightMin'),
                    max: _parse('heightMax'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String key, String title, Widget child) {
    final open = _expanded[key] ?? false;
    return FilterAccordionSection(
      title: title,
      expanded: open,
      onToggle: () => setState(() => _expanded[key] = !open),
      child: child,
    );
  }

  Widget _chipGrid(
    List<String> values,
    Set<String> selected,
    void Function(String) onToggle,
  ) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
        child: Wrap(
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.start,
          runAlignment: WrapAlignment.start,
          spacing: AppSpacing.s8,
          runSpacing: AppSpacing.s8,
          children: [
            for (final value in values)
              _SelectableChip(
                label: value,
                selected: selected.contains(value),
                onTap: () => onToggle(value),
              ),
          ],
        ),
      ),
    );
  }

  Widget _rangeInputs({
    required String label,
    required String minKey,
    required String maxKey,
    required String minLabel,
    required String maxLabel,
    required VoidCallback onChanged,
  }) {
    final muted = AppColors.textMuted(context);
    const placeholders = BullionsFilterState.rangePlaceholders;
    final minHint = placeholders[minKey] ?? '0';
    final maxHint = placeholders[maxKey] ?? '0';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s20,
        0,
        AppSpacing.s20,
        AppSpacing.s16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.s8),
          Row(
            children: [
              Expanded(
                child: _NumberField(
                  controller: _controllers[minKey]!,
                  label: minLabel,
                  hintText: minHint,
                  muted: muted,
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: _NumberField(
                  controller: _controllers[maxKey]!,
                  label: maxLabel,
                  hintText: maxHint,
                  muted: muted,
                  onChanged: (_) => onChanged(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectableChip extends StatelessWidget {
  const _SelectableChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.r8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s12,
          vertical: AppSpacing.s8,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.selectedFill(context)
              : AppColors.card(context),
          borderRadius: BorderRadius.circular(AppSpacing.r8),
          border: Border.all(
            color: selected
                ? AppColors.selectedFill(context)
                : AppColors.border(context),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: selected
                ? AppColors.onSelected(context)
                : AppColors.textPrimary(context),
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.r8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s12,
          vertical: AppSpacing.s8,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.selectedFill(context)
              : AppColors.card(context),
          borderRadius: BorderRadius.circular(AppSpacing.r8),
          border: Border.all(
            color: selected
                ? AppColors.selectedFill(context)
                : AppColors.border(context),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: selected
                ? AppColors.onSelected(context)
                : AppColors.textPrimary(context),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.muted,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final Color muted;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.caption.copyWith(color: muted)),
        const SizedBox(height: AppSpacing.s4),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: onChanged,
          scrollPadding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
          decoration: InputDecoration(
            isDense: true,
            hintText: hintText,
            hintStyle: AppTypography.caption.copyWith(color: muted),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s12,
              vertical: AppSpacing.s12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.r8),
            ),
          ),
        ),
      ],
    );
  }
}
