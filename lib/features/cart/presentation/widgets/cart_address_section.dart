import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/luxe/luxe_button.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../application/cart_provider.dart';
import '../../domain/models/delivery_address.dart';
import 'cart_section_card.dart';
import 'delivery_address_sheet.dart';

/// Delivery address block: the selected address at a glance, with every
/// saved address (select / edit / delete / add) one tap away in a sheet.
class CartAddressSection extends ConsumerWidget {
  const CartAddressSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = LuxePalette.of(context);
    final address = ref.watch(cartAddressProvider);
    final list = _addressList(ref);
    final mutating = ref.watch(cartIsMutatingProvider);

    if (list.isEmpty) {
      return CartSectionCard(
        title: context.tr(AccountCommerceL10n.deliverTo),
        icon: Icons.location_on_outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr(AccountCommerceL10n.noAddress),
              style: LuxeType.body(p.inkMuted, size: 13.5),
            ),
            const SizedBox(height: 14),
            LuxeButton(
              label: context.tr(AccountCommerceL10n.addAddress),
              icon: Icons.add_location_alt_outlined,
              variant: LuxeButtonVariant.secondary,
              height: 48,
              expand: true,
              onPressed: mutating ? null : () => _addNewAddress(context, ref),
            ),
          ],
        ),
      );
    }

    return CartSectionCard(
      title: context.tr(AccountCommerceL10n.deliverTo),
      icon: Icons.location_on_outlined,
      trailing: TextButton(
        onPressed: mutating ? null : () => _openManager(context),
        style: TextButton.styleFrom(
          foregroundColor: p.accent,
          visualDensity: VisualDensity.compact,
        ),
        child: Text(
          context.tr(ExperienceL10n.cartChange),
          style: LuxeType.label(p.accent, size: 13),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: mutating ? null : () => _openManager(context),
        child: AnimatedSwitcher(
          duration: LuxeMotion.medium,
          child: address == null
              ? Text(
                  context.tr(AccountCommerceL10n.noAddress),
                  key: const ValueKey('none'),
                  style: LuxeType.body(p.inkMuted, size: 13.5),
                )
              : Column(
                  key: ValueKey(address.id),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title(address),
                      style: LuxeType.label(p.ink, size: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${address.fullName} · ${address.summaryLine}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: LuxeType.body(p.inkMuted, size: 13),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _openManager(BuildContext context) {
    AppHaptics.selection();
    return showLuxeSheet<void>(
      context,
      title: context.tr(ExperienceL10n.cartAddresses),
      builder: (_) => const _AddressManager(),
    );
  }
}

String _title(DeliveryAddress a) =>
    a.label?.isNotEmpty == true ? a.label! : a.fullName;

/// Full list plus the selected address if the list lagged behind it.
List<DeliveryAddress> _addressList(WidgetRef ref) {
  final address = ref.watch(cartAddressProvider);
  final addresses = ref.watch(cartAddressesProvider);
  return <DeliveryAddress>[
    ...addresses,
    if (address != null &&
        address.id != null &&
        !addresses.any((a) => a.id == address.id))
      address,
  ];
}

Future<void> _addNewAddress(BuildContext context, WidgetRef ref) async {
  // Blank form — never prefill from a selected address.
  final saved = await showDeliveryAddressSheet(context);
  if (saved == null) return;
  final result = await ref
      .read(cartProvider.notifier)
      .saveAndSelectAddress(saved);
  if (!context.mounted) return;
  if (result case ResultFailure(:final failure)) {
    showLuxeToast(context, failure.message, tone: LuxeTone.error);
  } else {
    showLuxeToast(
      context,
      context.tr(AccountCommerceL10n.addressSaved),
      tone: LuxeTone.success,
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
    showLuxeToast(context, failure.message, tone: LuxeTone.error);
  } else {
    showLuxeToast(
      context,
      context.tr(AccountCommerceL10n.addressUpdated),
      tone: LuxeTone.success,
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

  AppHaptics.warning();
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
          style: TextButton.styleFrom(
            foregroundColor: LuxePalette.of(ctx).caution,
          ),
          child: Text(context.tr(CoreL10n.delete)),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  final result = await ref.read(cartProvider.notifier).deleteAddress(id);
  if (!context.mounted) return;
  if (result case ResultFailure(:final failure)) {
    showLuxeToast(context, failure.message, tone: LuxeTone.error);
  } else {
    AppHaptics.medium();
    showLuxeToast(context, context.tr(AccountCommerceL10n.addressDeleted));
  }
}

/// Saved addresses with select, edit, delete and add.
class _AddressManager extends ConsumerWidget {
  const _AddressManager();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = LuxePalette.of(context);
    final selected = ref.watch(cartAddressProvider);
    final list = _addressList(ref);
    final mutating = ref.watch(cartIsMutatingProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              context.tr(AccountCommerceL10n.noAddress),
              style: LuxeType.body(p.inkMuted, size: 13.5),
            ),
          ),
        for (final a in list)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _AddressTile(
              address: a,
              selected: a.id != null && a.id == selected?.id,
              enabled: !mutating,
              onSelect: () {
                final id = a.id;
                if (id == null || id.isEmpty) return;
                AppHaptics.selection();
                final result = ref
                    .read(cartProvider.notifier)
                    .selectExistingAddress(id);
                if (result case ResultFailure(:final failure)) {
                  showLuxeToast(context, failure.message, tone: LuxeTone.error);
                } else {
                  Navigator.of(context).maybePop();
                }
              },
              onEdit: () => _editAddress(context, ref, a),
              onDelete: () => _deleteAddress(context, ref, a),
            ),
          ),
        const SizedBox(height: 4),
        LuxeButton(
          label: context.tr(AccountCommerceL10n.addAddress),
          icon: Icons.add_location_alt_outlined,
          variant: LuxeButtonVariant.secondary,
          height: 50,
          expand: true,
          loading: mutating,
          onPressed: () => _addNewAddress(context, ref),
        ),
      ],
    );
  }
}

class _AddressTile extends StatelessWidget {
  const _AddressTile({
    required this.address,
    required this.selected,
    required this.enabled,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  final DeliveryAddress address;
  final bool selected;
  final bool enabled;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return AnimatedContainer(
      duration: LuxeMotion.fast,
      decoration: BoxDecoration(
        color: selected ? p.accentSoft : p.surface,
        borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall),
        border: Border.all(
          color: selected ? p.accent : p.hairline,
          width: selected ? 1.3 : 1,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall),
          onTap: enabled && !selected ? onSelect : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    size: 20,
                    color: selected ? p.accent : p.inkFaint,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _title(address),
                        style: LuxeType.label(p.ink, size: 14.5),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${address.fullName}\n${address.summaryLine}',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: LuxeType.body(p.inkMuted, size: 12.5),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: context.tr(AccountCommerceL10n.editAddress),
                  onPressed: enabled ? onEdit : null,
                  icon: Icon(Icons.edit_outlined, size: 19, color: p.inkMuted),
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  tooltip: context.tr(AccountCommerceL10n.deleteAddress),
                  onPressed: enabled ? onDelete : null,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 19,
                    color: p.caution,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
