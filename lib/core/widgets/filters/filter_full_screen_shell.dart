import 'package:flutter/material.dart';

import '../../haptics/app_haptics.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../app_scaffold.dart';
import '../app_top_bar.dart';

/// Full-screen catalog filter chrome matching jewelry filters:
/// title app bar (no header Reset) + sticky bottom Reset | Show Results.
class FilterFullScreenShell extends StatelessWidget {
  const FilterFullScreenShell({
    required this.body,
    required this.onReset,
    required this.onShowResults,
    this.title,
    this.resetLabel,
    this.showResultsLabel,
    super.key,
  });

  final Widget body;
  final VoidCallback onReset;
  final VoidCallback onShowResults;
  final String? title;
  final String? resetLabel;
  final String? showResultsLabel;

  @override
  Widget build(BuildContext context) {
    final resolvedTitle = title ?? context.tr(CatalogL10n.filters);
    final resolvedReset = resetLabel ?? context.tr(CatalogL10n.resetFilters);
    final resolvedShow =
        showResultsLabel ?? context.tr(CatalogL10n.showResults);

    return AppScaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppTopBar(title: resolvedTitle),
      body: Column(
        children: [
          Expanded(child: body),
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s16,
              AppSpacing.s12,
              AppSpacing.s16,
              AppSpacing.s16,
            ),
            decoration: BoxDecoration(
              color: AppColors.bg(context),
              border: Border(top: BorderSide(color: AppColors.border(context))),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        AppHaptics.selection();
                        onReset();
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.r8),
                        ),
                      ),
                      child: Text(resolvedReset),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.isDark(context)
                            ? AppColors.bronze
                            : AppColors.charcoal,
                        foregroundColor: AppColors.warmWhite,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.r8),
                        ),
                      ),
                      onPressed: () {
                        AppHaptics.medium();
                        onShowResults();
                      },
                      child: Text(
                        resolvedShow,
                        style: AppTypography.label.copyWith(
                          color: AppColors.warmWhite,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
