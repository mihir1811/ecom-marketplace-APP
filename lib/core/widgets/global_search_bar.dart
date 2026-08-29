import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

import '../l10n/app_localizations.dart';
import '../l10n/translations/remaining_messages.dart';

class GlobalSearchBar extends StatelessWidget {
  const GlobalSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    final textColor = AppColors.textPrimary(context);
    final fieldColor = AppColors.field(context);
    final borderColor = AppColors.border(context);
    final mutedColor = AppColors.textMuted(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: Container(
        decoration: BoxDecoration(
          color: fieldColor,
          borderRadius: BorderRadius.circular(AppSpacing.r20),
          border: Border.all(color: borderColor),
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: context.tr(RemainingL10n.searchCatalogHint),
            hintStyle: AppTypography.body.copyWith(color: mutedColor),
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s12,
              vertical: AppSpacing.s8,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.s12,
                right: AppSpacing.s8,
              ),
              child: Icon(Icons.search, color: mutedColor, size: 20),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
          ),
          style: AppTypography.body.copyWith(color: textColor),
          textInputAction: TextInputAction.search,
          scrollPadding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
          onSubmitted: (value) {},
        ),
      ),
    );
  }
}
