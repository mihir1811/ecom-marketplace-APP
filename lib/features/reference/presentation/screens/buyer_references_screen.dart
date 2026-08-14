import 'package:flutter/material.dart';

import '../../../buyer/presentation/widgets/buyer_layout.dart';
import 'reference_hub_screen.dart';

class BuyerReferencesScreen extends StatelessWidget {
  const BuyerReferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BuyerLayout(
      title: 'References',
      child: ReferenceHubScreen(),
    );
  }
}
