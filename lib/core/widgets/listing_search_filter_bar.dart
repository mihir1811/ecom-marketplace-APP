import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Listing search field + filter (tune) button with optional active-filter badge.
class ListingSearchFilterBar extends StatelessWidget {
  const ListingSearchFilterBar({
    required this.controller,
    required this.hintText,
    required this.onFilterTap,
    this.onChanged,
    this.onSubmitted,
    this.activeFilterCount = 0,
    this.mutedColor,
    super.key,
  });

  final TextEditingController controller;
  final String hintText;
  final VoidCallback onFilterTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final int activeFilterCount;
  final Color? mutedColor;

  @override
  Widget build(BuildContext context) {
    final muted = mutedColor ?? AppColors.textMutedLight;

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.warmWhite,
              borderRadius: BorderRadius.circular(AppSpacing.r12),
              border: Border.all(color: AppColors.warmBorder),
            ),
            child: TextField(
              controller: controller,
              textAlignVertical: TextAlignVertical.center,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              decoration: InputDecoration(
                isDense: true,
                hintText: hintText,
                prefixIcon: Icon(Icons.search, color: muted, size: 22),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 48,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s8,
                  vertical: 0,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s8),
        Material(
          color: AppColors.charcoal,
          borderRadius: BorderRadius.circular(AppSpacing.r12),
          child: InkWell(
            onTap: onFilterTap,
            borderRadius: BorderRadius.circular(AppSpacing.r12),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.tune,
                    color: AppColors.warmWhite,
                    size: 22,
                  ),
                  if (activeFilterCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.bronze,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
