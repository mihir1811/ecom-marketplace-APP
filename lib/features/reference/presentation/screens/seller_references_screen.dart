import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../seller/presentation/widgets/seller_layout.dart';
import 'reference_hub_screen.dart';

class SellerReferencesScreen extends StatelessWidget {
  const SellerReferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: () => openSellerDrawer(context),
                icon: const Icon(Icons.menu),
                tooltip: 'Open menu',
              ),
              Text(
                'References',
                style: AppTypography.title.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        const Expanded(child: ReferenceHubScreen()),
      ],
    );
  }
}
