import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../cart/domain/models/delivery_address.dart';
import 'live_sheet.dart';
import 'live_stage_tokens.dart';

class LiveAddressPick {
  const LiveAddressPick.address(DeliveryAddress this.address) : addNew = false;
  const LiveAddressPick.addNew() : address = null, addNew = true;

  final DeliveryAddress? address;
  final bool addNew;
}

/// "Ship wins to" picker: saved addresses with the current one ticked, and
/// a way to add a new one.
Future<LiveAddressPick?> showLiveAddressPicker(
  BuildContext context, {
  required List<DeliveryAddress> addresses,
  String? selectedId,
}) {
  return showLiveSheet<LiveAddressPick>(
    context,
    title: 'Ship wins to',
    subtitle: 'Anything you win ships here, even if you change it mid-auction.',
    builder: (context) {
      final still = MediaQuery.disableAnimationsOf(context);
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 5, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, a) in addresses.indexed) ...[
              Builder(
                builder: (context) {
                  Widget tile = _AddressTile(
                    address: a,
                    selected: a.id == selectedId,
                    onTap: () {
                      AppHaptics.selection();
                      Navigator.of(context).pop(LiveAddressPick.address(a));
                    },
                  );
                  if (!still) {
                    tile = tile
                        .animate(delay: (50 * i).ms)
                        .fadeIn(duration: 240.ms)
                        .moveY(begin: 8, end: 0, curve: LiveMotion.ease);
                  }
                  return tile;
                },
              ),
              const SizedBox(height: 6),
            ],
            const SizedBox(height: 8),
            LiveButton(
              label: 'Add a new address',
              icon: Icons.add_location_alt_outlined,
              kind: LiveButtonKind.secondary,
              onTap: () =>
                  Navigator.of(context).pop(const LiveAddressPick.addNew()),
            ),
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
    final label = address.label?.trim();
    return Semantics(
      selected: selected,
      child: LivePressable(
        scale: 0.98,
        semanticLabel: '${address.fullName}, ${address.summaryLine}',
        onTap: onTap,
        child: AnimatedContainer(
          duration: LiveMotion.quick,
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: selected
                ? LiveStage.champagne.withValues(alpha: 0.08)
                : LiveStage.ink.withValues(alpha: 0.035),
            border: Border.all(
              color: selected
                  ? LiveStage.champagne.withValues(alpha: 0.6)
                  : LiveStage.hairline,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: LiveMotion.quick,
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: selected ? LiveStage.champagneGradient : null,
                  border: selected
                      ? null
                      : Border.all(color: LiveStage.hairlineStrong, width: 1.5),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: LiveStage.onChampagne,
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label == null || label.isEmpty
                          ? address.fullName
                          : '$label · ${address.fullName}',
                      style: LiveType.label(14),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      address.summaryLine,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: LiveType.body(12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
