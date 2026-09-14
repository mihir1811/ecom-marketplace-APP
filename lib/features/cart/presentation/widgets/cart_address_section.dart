import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/error/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../application/cart_provider.dart';
import '../../domain/models/delivery_address.dart';
import 'cart_section_card.dart';
import 'delivery_address_sheet.dart';

/// Delivery address block; create + select via delivery-options APIs.
class CartAddressSection extends ConsumerWidget {
  const CartAddressSection({super.key});

  Future<void> _addNewAddress(BuildContext context, WidgetRef ref) async {
    // Blank form — never prefill from a selected address.
    final saved = await showDeliveryAddressSheet(context);
    if (saved == null) return;
    final result = await ref
        .read(cartProvider.notifier)
        .saveAndSelectAddress(saved);
    if (!context.mounted) return;
    if (result case ResultFailure(:final failure)) {
      AppHaptics.error();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message)));
    } else {
      AppHaptics.success();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr(AccountCommerceL10n.addressSaved))),
      );
    }
  }

  Future<void> _editAddress(
    BuildContext context,
    WidgetRef ref,
    DeliveryAddress address,
  ) async {
    final edited = await showDeliveryAddressSheet(context, initial: address);
    if (edited == null) return;
    final result = await ref
        .read(cartProvider.notifier)
        .saveAndSelectAddress(edited);
    if (!context.mounted) return;
    if (result case ResultFailure(:final failure)) {
      AppHaptics.error();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message)));
    } else {
      AppHaptics.success();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr(AccountCommerceL10n.addressUpdated))),
      );
    }
  }

  Future<void> _deleteAddress(
    BuildContext context,
    WidgetRef ref,
    DeliveryAddress address,
  ) async {
    final id = address.id;
    if (id == null || id.isEmpty) return;

    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr(AccountCommerceL10n.deleteAddressTitle)),
        content: Text(
          'Remove ${address.label?.isNotEmpty == true ? address.label! : address.fullName} from your saved addresses?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.tr(CoreL10n.cancel)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(context.tr(CoreL10n.delete)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await ref.read(cartProvider.notifier).deleteAddress(id);
    if (!context.mounted) return;
    if (result case ResultFailure(:final failure)) {
      AppHaptics.error();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message)));
    } else {
      AppHaptics.medium();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr(AccountCommerceL10n.addressDeleted))),
      );
    }
  }

  Future<void> _selectExisting(
    BuildContext context,
    WidgetRef ref,
    DeliveryAddress address,
  ) async {
    final id = address.id;
    if (id == null || id.isEmpty) return;
    final result = ref.read(cartProvider.notifier).selectExistingAddress(id);
    if (!context.mounted) return;
    if (result case ResultFailure(:final failure)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final address = ref.watch(cartAddressProvider);
    final addresses = ref.watch(cartAddressesProvider);
    final mutating = ref.watch(cartIsMutatingProvider);
    final muted = AppColors.textMuted(context);

    // Prefer full list; ensure selected address is visible even if list lagged.
    final list = <DeliveryAddress>[
      ...addresses,
      if (address != null &&
          address.id != null &&
          !addresses.any((a) => a.id == address.id))
        address,
    ];

    return CartSectionCard(
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
                context.tr(AccountCommerceL10n.deliverTo),
                style: AppTypography.label.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          if (list.isEmpty)
            Text(
              context.tr(AccountCommerceL10n.noAddress),
              style: AppTypography.caption.copyWith(color: muted, height: 1.4),
            )
          else ...[
            Text(
              context.tr(AccountCommerceL10n.savedAddresses),
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            ...list.map((a) {
              final selected = a.id != null && a.id == address?.id;
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: AppColors.bronze,
                  size: 20,
                ),
                title: Text(
                  a.label?.isNotEmpty == true ? a.label! : a.fullName,
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '${a.fullName}\n${a.summaryLine}',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(color: muted),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: context.tr(AccountCommerceL10n.editAddress),
                      onPressed: mutating
                          ? null
                          : () => _editAddress(context, ref, a),
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      color: AppColors.textSecondary(context),
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      tooltip: context.tr(AccountCommerceL10n.deleteAddress),
                      onPressed: mutating
                          ? null
                          : () => _deleteAddress(context, ref, a),
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: AppColors.textMutedLight,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                onTap: mutating || selected
                    ? null
                    : () => _selectExisting(context, ref, a),
              );
            }),
          ],
          const SizedBox(height: AppSpacing.s12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: mutating ? null : () => _addNewAddress(context, ref),
              icon: const Icon(Icons.add_location_alt_outlined, size: 18),
              label: Text(context.tr(AccountCommerceL10n.addAddress)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary(context),
                side: BorderSide(color: AppColors.border(context)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
