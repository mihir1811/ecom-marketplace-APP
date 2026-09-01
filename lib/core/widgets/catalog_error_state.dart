import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../l10n/app_localizations.dart';

/// Parameterized error + retry state for catalog listing screens.
class CatalogErrorState extends StatelessWidget {
  const CatalogErrorState({
    required this.message,
    required this.onRetry,
    this.retryLabel,
    this.padding = const EdgeInsets.all(AppSpacing.s32),
    super.key,
  });

  final String message;
  final VoidCallback onRetry;
  final String? retryLabel;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.s16),
            Text(
              message,
              style: AppTypography.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s20),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(retryLabel ?? context.tr(RemainingL10n.retry)),
            ),
          ],
        ),
      ),
    );
  }
}
