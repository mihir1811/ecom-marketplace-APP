import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../widgets/wallet_panel.dart';

/// Seller workspace wallet (balance, history, Razorpay top-up).
class SellerWalletScreen extends StatelessWidget {
  const SellerWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: AppSpacing.s8),
        Expanded(child: WalletPanel()),
      ],
    );
  }
}
