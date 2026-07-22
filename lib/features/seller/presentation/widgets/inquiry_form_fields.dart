import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

InputDecoration inquiryInputDecoration([String? hint]) {
  return InputDecoration(
    hintText: hint,
    isDense: true,
    filled: true,
    fillColor: AppColors.warmWhite,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.warmBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.warmBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.info),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );
}

class InquirySectionCard extends StatelessWidget {
  const InquirySectionCard({
    required this.child,
    this.title,
    super.key,
  });

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.warmWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warmBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: AppTypography.label.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

class InquiryLabeledField extends StatelessWidget {
  const InquiryLabeledField({
    required this.label,
    required this.child,
    super.key,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class InquiryTextField extends StatelessWidget {
  const InquiryTextField({
    required this.label,
    required this.controller,
    this.hint,
    this.maxLines = 1,
    this.onChanged,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final placeholder = hint ?? 'Enter $label';
    return InquiryLabeledField(
      label: label,
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        onChanged: onChanged,
        decoration: inquiryInputDecoration(placeholder),
      ),
    );
  }
}

class InquiryPairFields extends StatelessWidget {
  const InquiryPairFields({
    required this.left,
    required this.right,
    super.key,
  });

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 10),
        Expanded(child: right),
      ],
    );
  }
}

class InquiryDropdownField extends StatelessWidget {
  const InquiryDropdownField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.hint,
    super.key,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final placeholder = hint ?? 'Select $label';
    return InquiryLabeledField(
      label: label,
      child: DropdownButtonFormField<String>(
        key: ValueKey('$label-$value'),
        initialValue: options.contains(value) ? value : options.first,
        hint: Text(placeholder),
        items: [
          for (final o in options) DropdownMenuItem(value: o, child: Text(o)),
        ],
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
        decoration: inquiryInputDecoration(placeholder),
      ),
    );
  }
}

class InquiryCheckboxField extends StatelessWidget {
  const InquiryCheckboxField({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: (v) => onChanged(v ?? false),
          ),
          Expanded(
            child: Text(
              label,
              style: AppTypography.body.copyWith(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class InquiryDateField extends StatelessWidget {
  const InquiryDateField({
    required this.label,
    required this.value,
    required this.onPick,
    super.key,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    String text = 'mm/dd/yyyy';
    if (value != null) {
      String two(int v) => v.toString().padLeft(2, '0');
      text = '${two(value!.month)}/${two(value!.day)}/${value!.year}';
    }
    return InquiryLabeledField(
      label: label,
      child: InkWell(
        onTap: onPick,
        child: InputDecorator(
          decoration: inquiryInputDecoration('mm/dd/yyyy').copyWith(
            suffixIcon: const Icon(Icons.calendar_today, size: 18),
          ),
          child: Text(text),
        ),
      ),
    );
  }
}
