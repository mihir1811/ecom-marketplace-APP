import 'package:flutter/material.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/luxe/luxe_button.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../cart/domain/models/delivery_address.dart';

class LiveAddressPick {
  const LiveAddressPick.address(DeliveryAddress this.address) : addNew = false;
  const LiveAddressPick.addNew() : address = null, addNew = true;

  final DeliveryAddress? address;
  final bool addNew;
}

/// "Wins ship to" picker: saved addresses, the current one ticked, and a
/// way to add a new one.
Future<LiveAddressPick?> showLiveAddressPicker(
  BuildContext context, {
  required List<DeliveryAddress> addresses,
  String? selectedId,
}) {
  return showLuxeSheet<LiveAddressPick>(
    context,
    title: 'Ship wins to',
    subtitle: 'A win ships to the address picked here, even mid-auction.',
    builder: (context) {
      final p = LuxePalette.of(context);
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final a in addresses) ...[
              _AddressTile(
                address: a,
                selected: a.id == selectedId,
                onTap: () {
                  AppHaptics.selection();
                  Navigator.of(context).pop(LiveAddressPick.address(a));
                },
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),
            LuxeButton(
              label: 'Add a new address',
              icon: Icons.add_location_alt_outlined,
              variant: LuxeButtonVariant.secondary,
              expand: true,
              onPressed: () =>
                  Navigator.of(context).pop(const LiveAddressPick.addNew()),
            ),
            SizedBox(height: p.isDark ? 4 : 0),
          ],
        ),
      );
    },
  );
}

class _AddressTile extends StatelessWidget {
  const _AddressTile({
    required this.address,
    required this.selected,
    required this.onTap,
  });

  final DeliveryAddress address;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final label = address.label?.trim();
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? p.accentSoft : p.surfaceRaised,
        borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall),
        child: InkWell(
          borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall),
              border: Border.all(
                color: selected ? p.accent : p.hairline,
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: selected ? p.accent : p.inkFaint,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label == null || label.isEmpty
                            ? address.fullName
                            : '$label · ${address.fullName}',
                        style: LuxeType.label(p.ink, size: 14),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        address.summaryLine,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: LuxeType.body(p.inkMuted, size: 12.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
