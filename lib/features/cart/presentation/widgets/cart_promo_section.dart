import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/luxe/luxe_button.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
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
  bool _expanded = false;

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
    switch (result) {
      case Success():
        FocusScope.of(context).unfocus();
        showLuxeToast(
          context,
          context.tr(AccountCommerceL10n.promoApplied),
          tone: LuxeTone.success,
        );
      case ResultFailure(:final failure):
        showLuxeToast(context, failure.message, tone: LuxeTone.error);
    }
  }

  Future<void> _remove(String code) async {
    final result = await ref.read(cartProvider.notifier).removePromo(code);
    if (!mounted) return;
    if (result case ResultFailure(:final failure)) {
      showLuxeToast(context, failure.message, tone: LuxeTone.error);
    } else {
      AppHaptics.medium();
      _promoController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final promo = ref.watch(cartPromoProvider);
    final mutating = ref.watch(cartIsMutatingProvider);
    final canApply = _hasText && !mutating && !promo.applied;

    if (promo.applied) {
      return CartSectionCard(
        padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: p.positive.withValues(alpha: 0.12),
              ),
              child: Icon(
                Icons.local_offer_rounded,
                size: 16,
                color: p.positive,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.tr(ExperienceL10n.cartPromoApplied, {
                  'code': promo.code ?? '',
                }),
                style: LuxeType.label(p.ink, size: 14),
              ),
            ),
            TextButton(
              onPressed: mutating || promo.code == null
                  ? null
                  : () => _remove(promo.code!),
              style: TextButton.styleFrom(foregroundColor: p.caution),
              child: Text(context.tr(AccountCommerceL10n.remove)),
            ),
          ],
        ),
      );
    }

    return CartSectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () {
              AppHaptics.selection();
              setState(() => _expanded = !_expanded);
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              child: Row(
                children: [
                  Icon(Icons.local_offer_outlined, size: 18, color: p.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.tr(ExperienceL10n.cartHavePromo),
                      style: LuxeType.label(p.ink, size: 14),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: LuxeMotion.medium,
                    curve: LuxeMotion.settle,
                    child: Icon(Icons.expand_more_rounded, color: p.inkMuted),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: LuxeMotion.medium,
            curve: LuxeMotion.settle,
            alignment: Alignment.topCenter,
            child: !_expanded
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _promoController,
                            enabled: !mutating,
                            textCapitalization: TextCapitalization.characters,
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              hintText: context.tr(
                                AccountCommerceL10n.enterCode,
                              ),
                              isDense: true,
                            ),
                            onSubmitted: (_) {
                              if (canApply) _apply();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        LuxeButton(
                          label: context.tr(ExperienceL10n.cartApply),
                          height: 46,
                          loading: mutating && _hasText,
                          onPressed: canApply ? _apply : null,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
