import 'package:flutter/material.dart';

import '../../../buyer/presentation/widgets/buyer_layout.dart';
import '../../../../core/auth/verified_account_gate.dart';
import '../widgets/wallet_panel.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/translations/remaining_messages.dart';

/// Buyer account wallet (balance, history, Razorpay top-up).
class BuyerWalletScreen extends StatelessWidget {
  const BuyerWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BuyerLayout(
      title: context.tr(RemainingL10n.wallet),
      child: const VerifiedAccountGate(child: WalletPanel()),
    );
  }
}
