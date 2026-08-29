import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/translations/remaining_messages.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_currency.dart';
import '../../domain/models/wallet.dart';

/// One wallet ledger row.
class WalletTransactionTile extends StatelessWidget {
  const WalletTransactionTile({required this.transaction, super.key});

  final WalletTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final credit = transaction.isCredit;
    final accent = credit ? AppColors.success : AppColors.error;
    final date = transaction.createdAt;
    final dateLabel = date == null
        ? null
        : '${date.day}/${date.month}/${date.year}';
    final amountPrefix = credit ? '+' : '−';

    return Container(
      key: ValueKey(transaction.id),
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppSpacing.r16),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: AppColors.isDark(context) ? [] : AppShadows.cardLight,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: accent.withValues(alpha: 0.12),
            child: Icon(
              credit ? Icons.south_west : Icons.north_east,
              size: 18,
              color: accent,
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.typeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.label.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (transaction.note != null) ...[
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    transaction.note!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
                if (dateLabel != null) ...[
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    dateLabel,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$amountPrefix${AppCurrency.inr(transaction.amount.abs())}',
                style: AppTypography.label.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                context.tr(RemainingL10n.balanceAfterAmount, {
                  'amount': AppCurrency.inr(transaction.balanceAfter),
                }),
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
