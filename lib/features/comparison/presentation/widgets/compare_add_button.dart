import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';

/// Circular "add to compare" control.
class CompareAddButton extends StatelessWidget {
  const CompareAddButton({
    required this.isSelected,
    required this.onPressed,
    this.size = listingControlSize,
    super.key,
  });

  /// Matches listing wishlist / project-pick control size.
  static const double listingControlSize = 24;

  final bool isSelected;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final border = isSelected ? AppColors.bronze : (AppColors.border(context));
    final fill = isSelected
        ? AppColors.bronze.withValues(alpha: 0.12)
        : (AppColors.card(context));
    final ink = isSelected
        ? AppColors.bronze
        : (AppColors.textPrimary(context));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Semantics(
          button: true,
          label: isSelected
              ? context.tr(AccountCommerceL10n.removeComparison)
              : context.tr(AccountCommerceL10n.addComparison),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: fill,
              border: Border.all(color: border),
            ),
            child: Icon(Icons.add, size: size * 0.55, color: ink),
          ),
        ),
      ),
    );
  }
}

/// Shows a snackbar for comparison add/toggle outcomes.
void showCompareFeedback(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        // Floating snack bars already sit above the bottom dock (pages report
        // its clearance as view padding), so only a small gap is added here.
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        duration: const Duration(seconds: 2),
      ),
    );
}
