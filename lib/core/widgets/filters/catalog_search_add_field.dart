import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'filter_section_header.dart';

/// Search text field with an Add action — used in catalog preference filters.
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

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onAdd(text);
    if (widget.clearOnAdd) {
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final fill = AppColors.selectedFill(context);
    final onFill = AppColors.onSelected(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilterSectionHeader(title: widget.title, infoText: widget.infoText),
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
                    hintText: widget.hintText,
                    filled: true,
                    fillColor: AppColors.field(context),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
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
                  backgroundColor: AppColors.charcoal,
                  foregroundColor: AppColors.warmWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                onPressed: _submit,
                child: Text(
                  'Add',
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
      ],
    );
  }
}
