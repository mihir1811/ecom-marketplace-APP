import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../seller/presentation/widgets/seller_layout.dart';
import 'reference_hub_screen.dart';

class SellerReferencesScreen extends StatelessWidget {
  const SellerReferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: AppSpacing.s8, top: AppSpacing.s8),
            child: IconButton(
              onPressed: () => openSellerDrawer(context),
              icon: const Icon(Icons.menu),
              tooltip: 'Open menu',
            ),
          ),
        ),
        const Expanded(child: ReferenceHubScreen()),
      ],
    );
  }
}
