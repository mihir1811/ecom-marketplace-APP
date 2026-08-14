import 'package:flutter/material.dart';

import '../../../buyer/presentation/widgets/buyer_layout.dart';
import '../../../../core/auth/verified_account_gate.dart';
import '../widgets/wallet_panel.dart';

/// Buyer account wallet (balance, history, Razorpay top-up).
class BuyerWalletScreen extends StatelessWidget {
  const BuyerWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BuyerLayout(
      title: 'Wallet',
      child: VerifiedAccountGate(
        child: WalletPanel(),
      ),
    );
  }
}
