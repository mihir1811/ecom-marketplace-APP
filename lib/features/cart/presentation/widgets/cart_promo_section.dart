import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/translations/account_commerce_messages.dart';

import '../../../../core/error/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/cart_provider.dart';
import 'cart_section_card.dart';

/// Promo code field wired to POST/DELETE promo APIs.
class CartPromoSection extends ConsumerStatefulWidget {
  const CartPromoSection({super.key});

  @override
  ConsumerState<CartPromoSection> createState() => _CartPromoSectionState();
}

class _CartPromoSectionState extends ConsumerState<CartPromoSection> {
  final _promoController = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _promoController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final next = _promoController.text.trim().isNotEmpty;
    if (next != _hasText) setState(() => _hasText = next);
  }

  @override
  void dispose() {
    _promoController.removeListener(_onTextChanged);
    _promoController.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    if (!_hasText) return;
    final result = await ref
        .read(cartProvider.notifier)
        .applyPromo(_promoController.text);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    switch (result) {
      case Success():
        messenger.showSnackBar(
          SnackBar(content: Text(context.tr(AccountCommerceL10n.promoApplied))),
        );
      case ResultFailure(:final failure):
        messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  Future<void> _remove(String code) async {
    final result = await ref.read(cartProvider.notifier).removePromo(code);
    if (!mounted) return;
    if (result case ResultFailure(:final failure)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message)));
    } else {
      _promoController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final promo = ref.watch(cartPromoProvider);
    final mutating = ref.watch(cartIsMutatingProvider);
    final canApply = _hasText && !mutating && !promo.applied;

    return CartSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_offer_outlined,
                size: 20,
                color: AppColors.bronze,
              ),
              const SizedBox(width: AppSpacing.s8),
              Text(
                context.tr(AccountCommerceL10n.promoCode),
                style: AppTypography.label.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _promoController,
                  enabled: !mutating && !promo.applied,
                  decoration: InputDecoration(
                    hintText: context.tr(AccountCommerceL10n.enterCode),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.r8),
                    ),
                  ),
                  onSubmitted: (_) {
                    if (canApply) _apply();
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: canApply || promo.applied
                      ? AppColors.selectedFill(context)
                      : AppColors.surface(context),
                  foregroundColor: canApply || promo.applied
                      ? AppColors.onSelected(context)
                      : AppColors.textSecondary(context),
                  disabledBackgroundColor: AppColors.surface(context),
                  disabledForegroundColor: AppColors.textSecondary(context),
                  side: BorderSide(
                    color: canApply || promo.applied
                        ? Colors.transparent
                        : AppColors.border(context),
                  ),
                ),
                onPressed: mutating
                    ? null
                    : promo.applied && promo.code != null
                    ? () => _remove(promo.code!)
                    : (canApply ? _apply : null),
                child: Text(
                  promo.applied
                      ? context.tr(AccountCommerceL10n.remove)
                      : 'Apply',
                ),
              ),
            ],
          ),
          if (promo.applied)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.s8),
              child: Text(
                'Code ${promo.code} applied',
                style: AppTypography.caption.copyWith(
                  color: AppColors.bronze,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
