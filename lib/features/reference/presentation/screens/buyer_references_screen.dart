import 'package:flutter/material.dart';

import '../../../buyer/presentation/widgets/buyer_layout.dart';
import '../../../../core/widgets/dark_theme_scope.dart';
import 'reference_hub_screen.dart';

class BuyerReferencesScreen extends StatelessWidget {
  const BuyerReferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DarkThemeScope(
      child: Builder(
        builder: (context) =>
            const BuyerLayout(title: 'References', child: ReferenceHubScreen()),
      ),
    );
  }
}
