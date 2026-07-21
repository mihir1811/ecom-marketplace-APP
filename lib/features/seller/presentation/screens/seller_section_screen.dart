import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../widgets/seller_layout.dart';

/// Placeholder for seller sections that are not yet fully implemented.
class SellerSectionScreen extends StatelessWidget {
  const SellerSectionScreen({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => openSellerDrawer(context),
                icon: const Icon(Icons.menu),
                tooltip: 'Open menu',
              ),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Coming soon.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
          ),
        ],
      ),
    );
  }
}
