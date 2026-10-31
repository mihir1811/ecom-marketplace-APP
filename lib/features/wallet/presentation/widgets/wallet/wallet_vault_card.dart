import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/theme/luxe_tokens.dart';
import '../../../../buyer/presentation/maison/maison_kit.dart';
import '../../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../../seller/presentation/atelier/atelier_theme.dart';
import '../../../domain/models/wallet.dart';

/// One action button inside [WalletVaultCard].
class WalletCardAction {
  const WalletCardAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool primary;
}

/// Compact wallet summary: balance, account tail and currency, with the
/// wallet's actions (e.g. Add funds, Refunds) in the same dark card.
class WalletVaultCard extends StatelessWidget {
  const WalletVaultCard({
    required this.wallet,
    this.label = 'Private wallet',
    this.actions = const [],
    super.key,
  });

  final Wallet wallet;

  /// Shown beside the balance caption ("Private wallet", "Business wallet").
  final String label;

  final List<WalletCardAction> actions;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final soft = p.onOnyx.withValues(alpha: 0.6);
    final id = wallet.id.replaceAll('-', '');
    final tail = id.length >= 4 ? id.substring(id.length - 4) : id;

    return Semantics(
      label: context.tr(RemainingL10n.walletBalanceAmount, {
        'amount': maisonInr(wallet.balance),
      }),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AtelierRadius.lg),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [LuxeStage.vault, LuxeStage.vaultBottom],
          ),
          border: Border.all(color: p.gold.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${context.tr(RemainingL10n.availableBalance)} · $label'
                        .toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AtelierType.overline(soft),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '•••• ${tail.toUpperCase()}  ·  ${wallet.currency}',
                  style: AtelierType.figure(soft, size: 11.5),
                ),
              ],
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: CountUpText(
                maisonInr(wallet.balance),
                duration: const Duration(milliseconds: 1200),
                style: AtelierType.display(
                  p.onOnyx,
                  size: 34,
                  weight: FontWeight.w500,
                ),
              ),
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  for (var i = 0; i < actions.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(child: _ActionButton(action: actions[i])),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action});

  final WalletCardAction action;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final primary = action.primary;
    final fg = primary ? p.onGold : p.onOnyx;
    return Pressable(
      onTap: action.onTap,
      semanticLabel: action.label,
      borderRadius: BorderRadius.circular(AtelierRadius.pill),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AtelierRadius.pill),
          gradient: primary ? p.goldGradient : null,
          border: primary
              ? null
              : Border.all(color: p.onOnyx.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(action.icon, size: 17, color: fg),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                action.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AtelierType.label(fg, size: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
