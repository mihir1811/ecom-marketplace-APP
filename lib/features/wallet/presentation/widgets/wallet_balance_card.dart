import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_currency.dart';
import '../../domain/models/wallet.dart';

/// Balance summary for the wallet home screen.
class WalletBalanceCard extends StatelessWidget {
  const WalletBalanceCard({required this.wallet, super.key});

  final Wallet wallet;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Wallet balance ${AppCurrency.inr(wallet.balance)}',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.s24),
        decoration: BoxDecoration(
          color: AppColors.charcoal,
          borderRadius: BorderRadius.circular(AppSpacing.r24),
          boxShadow: AppColors.isDark(context) ? [] : AppShadows.cardLight,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available balance',
              style: AppTypography.caption.copyWith(
                color: AppColors.warmWhite.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              AppCurrency.inr(wallet.balance),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.headline.copyWith(
                color: AppColors.warmWhite,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              wallet.currency,
              style: AppTypography.label.copyWith(
                color: AppColors.bronzeLight,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
