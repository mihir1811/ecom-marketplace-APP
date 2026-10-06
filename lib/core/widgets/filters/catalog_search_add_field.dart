import 'package:flutter/material.dart';

import '../../haptics/app_haptics.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'filter_section_header.dart';

/// Search text field with an Add action — used in catalog preference filters.
///
/// Pass [onAddExcluded] to turn on include / exclude: an "Exclude" checkbox
/// picks which list the next entry joins (unchecked includes), and the two lists show as
/// "Showing only" (filled) and "Hiding" (struck, terracotta) chip groups.
class CatalogSearchAddField extends StatefulWidget {
  const CatalogSearchAddField({
    required this.title,
    required this.infoText,
    required this.hintText,
    required this.onAdd,
    this.values = const [],
    this.onRemove,
    this.controller,
    this.onChanged,
    this.clearOnAdd = false,
    this.excludedValues = const [],
    this.onAddExcluded,
    this.excludeHintText,
    this.excludeMode = false,
    this.onExcludeModeChanged,
    super.key,
  });

  final String title;
  final String infoText;
  final String hintText;
  final ValueChanged<String> onAdd;
  final List<String> values;
  final ValueChanged<String>? onRemove;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool clearOnAdd;

  /// Entries to hide from results; removed through [onRemove].
  final List<String> excludedValues;
  final ValueChanged<String>? onAddExcluded;
  final String? excludeHintText;

  /// Whether the next entry is added to the exclude list. Owned by the
  /// caller so a pending entry can be committed to the right list.
  final bool excludeMode;
  final ValueChanged<bool>? onExcludeModeChanged;

  bool get supportsExclude => onAddExcluded != null;

  @override
  State<CatalogSearchAddField> createState() => _CatalogSearchAddFieldState();
}

class _CatalogSearchAddFieldState extends State<CatalogSearchAddField> {
  late TextEditingController _controller;
  late bool _ownsController;

  @override
  void initState() {
    super.initState();
    _bindController(widget.controller);
  }

  @override
  void didUpdateWidget(CatalogSearchAddField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller == oldWidget.controller) return;
    if (_ownsController) _controller.dispose();
    _bindController(widget.controller);
  }

  void _bindController(TextEditingController? controller) {
    _ownsController = controller == null;
    _controller = controller ?? TextEditingController();
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  bool get _excluding => widget.supportsExclude && widget.excludeMode;

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    if (_excluding) {
      widget.onAddExcluded!(text);
    } else {
      widget.onAdd(text);
    }
    if (widget.clearOnAdd) {
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final fill = AppColors.selectedFill(context);
    final onFill = AppColors.onSelected(context);
    final excluding = _excluding;
    final accent = excluding ? AppColors.terracotta : AppColors.charcoal;
    final showGroups =
        widget.supportsExclude && widget.excludedValues.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: FilterSectionHeader(
                title: widget.title,
                infoText: widget.infoText,
              ),
            ),
            if (widget.supportsExclude)
              _ExcludeCheckbox(
                exclude: widget.excludeMode,
                onChanged: (v) => widget.onExcludeModeChanged?.call(v),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.s4),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 38,
                child: TextField(
                  controller: _controller,
                  onChanged: widget.onChanged,
                  onSubmitted: (_) => _submit(),
                  textInputAction: TextInputAction.done,
                  style: AppTypography.caption,
                  decoration: InputDecoration(
                    hintText: excluding
                        ? (widget.excludeHintText ?? widget.hintText)
                        : widget.hintText,
                    filled: true,
                    fillColor: AppColors.field(context),
                    prefixIcon: widget.supportsExclude
                        ? Icon(
                            excluding
                                ? Icons.block_rounded
                                : Icons.add_circle_outline_rounded,
                            size: 16,
                            color: excluding
                                ? AppColors.terracotta
                                : AppColors.textMuted(context),
                          )
                        : null,
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    enabledBorder: excluding
                        ? OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide(
                              color: AppColors.terracotta.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s4),
            SizedBox(
              height: 38,
              width: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: accent,
                  foregroundColor: AppColors.warmWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                onPressed: _submit,
                child: Text(
                  context.tr(CatalogL10n.add),
                  style: AppTypography.caption.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warmWhite,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (widget.values.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s8),
          if (showGroups)
            _GroupLabel(text: context.tr(CatalogL10n.filterShowingOnly)),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              for (final value in widget.values)
                InputChip(
                  key: ValueKey(value),
                  selected: true,
                  showCheckmark: false,
                  label: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  labelStyle: AppTypography.caption.copyWith(
                    color: onFill,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: fill,
                  selectedColor: fill,
                  deleteIconColor: onFill,
                  side: BorderSide(color: fill),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: widget.onRemove == null
                      ? null
                      : () => widget.onRemove!(value),
                ),
            ],
          ),
        ],
        if (showGroups) ...[
          const SizedBox(height: AppSpacing.s8),
          _GroupLabel(
            text: context.tr(CatalogL10n.filterHiding),
            color: AppColors.terracotta,
          ),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              for (final value in widget.excludedValues)
                InputChip(
                  key: ValueKey('x-$value'),
                  avatar: const Icon(
                    Icons.block_rounded,
                    size: 14,
                    color: AppColors.terracotta,
                  ),
                  label: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  labelStyle: AppTypography.caption.copyWith(
                    color: AppColors.terracotta,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: AppColors.terracotta,
                  ),
                  backgroundColor: AppColors.terracotta.withValues(alpha: 0.08),
                  deleteIconColor: AppColors.terracotta,
                  side: BorderSide(
                    color: AppColors.terracotta.withValues(alpha: 0.45),
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: widget.onRemove == null
                      ? null
                      : () => widget.onRemove!(value),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel({required this.text, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: AppTypography.caption.copyWith(
          fontSize: 10,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w700,
          color: color ?? AppColors.textMuted(context),
        ),
      ),
    );
  }
}

/// "Exclude" checkbox: unchecked adds to the include list (default), checked
/// adds to the exclude list.
class _ExcludeCheckbox extends StatelessWidget {
  const _ExcludeCheckbox({required this.exclude, required this.onChanged});

  final bool exclude;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final label = context.tr(CatalogL10n.filterExclude);
    void toggle() {
      AppHaptics.selection();
      onChanged(!exclude);
    }

    return Semantics(
      checked: exclude,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: toggle,
        borderRadius: BorderRadius.circular(AppSpacing.r8),
        child: Padding(
          padding: const EdgeInsets.only(right: AppSpacing.s4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: Checkbox(
                  value: exclude,
                  onChanged: (_) => toggle(),
                  activeColor: AppColors.terracotta,
                  checkColor: AppColors.warmWhite,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: exclude
                      ? AppColors.terracotta
                      : AppColors.textSecondary(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
