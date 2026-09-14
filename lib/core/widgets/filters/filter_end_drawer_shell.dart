import 'package:flutter/material.dart';

import '../../haptics/app_haptics.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../keyboard_aware.dart';

/// Shared end-drawer chrome: width, header (Reset/Clear), sticky SHOW RESULTS.
class FilterEndDrawerShell extends StatelessWidget {
  const FilterEndDrawerShell({
    required this.body,
    required this.onReset,
    required this.onShowResults,
    this.title = 'Filters',
    this.resetLabel = 'Reset',
    this.showResultsLabel = 'SHOW RESULTS',
    super.key,
  });

  final Widget body;
  final VoidCallback onReset;
  final VoidCallback onShowResults;
  final String title;
  final String resetLabel;
  final String showResultsLabel;

  static double drawerWidthFor(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width > 480 ? 360.0 : width * 0.88;
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: drawerWidthFor(context),
      backgroundColor: AppColors.card(context),
      child: AppKeyboardInset(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s20,
                  AppSpacing.s12,
                  AppSpacing.s8,
                  AppSpacing.s12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.title.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        AppHaptics.selection();
                        onReset();
                      },
                      child: Text(
                        resetLabel,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.bronze,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: context.tr(CatalogL10n.close),
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(child: body),
              Container(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s16,
                  AppSpacing.s12,
                  AppSpacing.s16,
                  AppSpacing.s16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.card(context),
                  border: Border(
                    top: BorderSide(color: AppColors.border(context)),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.selectedFill(context),
                      foregroundColor: AppColors.onSelected(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.r8),
                      ),
                    ),
                    onPressed: () {
                      AppHaptics.medium();
                      onShowResults();
                    },
                    child: Text(
                      showResultsLabel,
                      style: AppTypography.label.copyWith(
                        color: AppColors.onSelected(context),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
