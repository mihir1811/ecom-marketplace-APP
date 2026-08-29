import 'package:flutter/material.dart';

import '../../../buyer/presentation/widgets/buyer_layout.dart';
import 'reference_hub_screen.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/translations/remaining_messages.dart';

class BuyerReferencesScreen extends StatelessWidget {
  const BuyerReferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BuyerLayout(
      title: context.tr(RemainingL10n.myReference),
      child: const ReferenceHubScreen(),
    );
  }
}
