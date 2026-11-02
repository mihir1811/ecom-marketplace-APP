import 'package:flutter/material.dart';

import '../../../buyer/presentation/maison/maison_layout.dart';
import '../widgets/reference_compact.dart';

/// Buyer references: compact shared [ReferencesView] under the buyer bar.
class BuyerReferencesScreen extends StatelessWidget {
  const BuyerReferencesScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const MaisonLayout(detail: true, child: ReferencesView());
}
