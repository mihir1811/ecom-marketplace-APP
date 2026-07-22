import 'package:flutter/material.dart';
import 'package:gemstone/core/widgets/app_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/cart_provider.dart';
import '../widgets/cart_item_card.dart';
import '../widgets/delivery_address_sheet.dart';

/// Buyer cart with items, delivery address, promo, and price breakdown.
class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _promoController = TextEditingController();

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  Future<void> _openAddress() async {
    final current = ref.read(cartProvider).address;
    final saved = await showDeliveryAddressSheet(context, initial: current);
    if (saved != null) {
      ref.read(cartProvider.notifier).setAddress(saved);
    }
  }

  String _inr(double v) => '₹${v.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final totals = cart.totals;
    final muted =
        AppColors.textMutedLight;
    final cardBg = AppColors.warmWhite;
    final border = AppColors.warmBorder;

    return AppScaffold(
      backgroundColor: AppColors.creamBg,
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'Your Cart',
              style: AppTypography.title.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: AppSpacing.s8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.bronze,
                borderRadius: BorderRadius.circular(AppSpacing.circular),
              ),
              child: Text(
                '${cart.count}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.warmWhite,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
        ],
      ),
      body: cart.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 56, color: muted),
                  const SizedBox(height: AppSpacing.s16),
                  Text('Your cart is empty', style: AppTypography.body),
                  const SizedBox(height: AppSpacing.s16),
                  FilledButton(
                    onPressed: () => context.pop(),
                    child: const Text('Continue shopping'),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.s16),
              children: [
                Text(
                  '${cart.count} item${cart.count == 1 ? '' : 's'} in your cart',
                  style: AppTypography.caption.copyWith(
                    color: muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.s12),
                for (final item in cart.items) ...[
                  CartItemCard(item: item),
                  const SizedBox(height: AppSpacing.s12),
                ],
                _sectionCard(
                  bg: cardBg,
                  border: border,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 20,
                            color: AppColors.bronze,
                          ),
                          const SizedBox(width: AppSpacing.s8),
                          Text(
                            'Deliver to',
                            style: AppTypography.label.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: _openAddress,
                            child: Text(
                              cart.hasAddress ? 'Edit' : 'Add address',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.bronze,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        cart.hasAddress
                            ? '${cart.address!.fullName}\n${cart.address!.summaryLine}'
                            : 'Add a delivery address to proceed to payment.',
                        style: AppTypography.caption.copyWith(
                          color: muted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s12),
                _sectionCard(
                  bg: cardBg,
                  border: border,
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
                            'Promo code',
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
                              decoration: InputDecoration(
                                hintText: 'Enter code',
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppSpacing.r8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s8),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.textMutedLight,
                              foregroundColor: AppColors.warmWhite,
                            ),
                            onPressed: () {
                              final ok = ref
                                  .read(cartProvider.notifier)
                                  .applyPromo(_promoController.text);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    ok
                                        ? 'Promo applied (5% off)'
                                        : 'Invalid promo code. Try GEM5',
                                  ),
                                ),
                              );
                            },
                            child: const Text('Apply'),
                          ),
                        ],
                      ),
                      if (cart.promoApplied)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.s8),
                          child: Text(
                            'Code ${cart.promoCode} applied',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.bronze,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s16),
                _priceRow('Subtotal',
                    '${_inr(totals.subtotalInr)} · \$${totals.subtotalUsd.toStringAsFixed(2)}'),
                _priceRow('GST (3%)', _inr(totals.gstInr)),
                _priceRow('Transaction fee (2.18%)',
                    _inr(totals.transactionFeeInr)),
                _priceRow('Platform fee', _inr(totals.platformFeeInr)),
                const Divider(height: 24),
                Row(
                  children: [
                    Text(
                      'Total',
                      style: AppTypography.label.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _inr(totals.totalInr),
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.bronze,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.charcoal,
                      foregroundColor: AppColors.warmWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.r12),
                      ),
                    ),
                    onPressed: cart.hasAddress
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Payment flow will be available soon.',
                                ),
                              ),
                            );
                          }
                        : _openAddress,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          cart.hasAddress
                              ? 'Proceed to payment'
                              : 'Add delivery address',
                          style: AppTypography.label.copyWith(
                            color: AppColors.warmWhite,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (!cart.hasAddress)
                          Text(
                            'Required before payment',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.warmWhite.withValues(alpha: 0.75),
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s24),
              ],
            ),
    );
  }

  Widget _sectionCard({
    required Color bg,
    required Color border,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.r16),
        border: Border.all(color: border),
      ),
      child: child,
    );
  }

  Widget _priceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ),
          Text(
            value,
            style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
