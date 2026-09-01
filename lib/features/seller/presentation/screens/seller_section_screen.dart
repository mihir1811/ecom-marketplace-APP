import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';

/// Placeholder for seller sections that are not yet fully implemented.
class SellerSectionScreen extends StatelessWidget {
  const SellerSectionScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Text(
            context.tr(RemainingL10n.comingSoon),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}
