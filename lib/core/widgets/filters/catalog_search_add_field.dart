import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'filter_section_header.dart';

/// Search text field with an Add action — used in catalog preference filters.
class CatalogSearchAddField extends StatelessWidget {
  const CatalogSearchAddField({
    required this.title,
    required this.infoText,
    required this.hintText,
    required this.onAdd,
    this.controller,
    this.onChanged,
    super.key,
  });

  final String title;
  final String infoText;
  final String hintText;
  final VoidCallback onAdd;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilterSectionHeader(title: title, infoText: infoText),
        const SizedBox(height: AppSpacing.s4),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 38,
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  style: AppTypography.caption,
                  decoration: InputDecoration(
                    hintText: hintText,
                    filled: true,
                    fillColor: AppColors.warmWhite,
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                onPressed: onAdd,
                child: const Text('Add', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
