import 'package:flutter/material.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/theme/luxe_tokens.dart';

/// One outcome count, such as won auctions or bids received.
class AuctionStandingItem {
  const AuctionStandingItem({
    required this.id,
    required this.label,
    required this.count,
  });

  final String id;
  final String label;
  final int count;
}

/// Horizontal outcome counts for the signed-in buyer or seller. Tiles act
/// as filters when [onSelected] is set; the selected tile turns ink.
class AuctionStandingStrip extends StatelessWidget {
  const AuctionStandingStrip({
    required this.items,
    this.selectedId,
    this.onSelected,
    super.key,
  });

  final List<AuctionStandingItem> items;
  final String? selectedId;
  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          final selected = item.id == selectedId;
          return Semantics(
            button: onSelected != null,
            selected: selected,
            label: '${item.label} ${item.count}',
            excludeSemantics: true,
            child: GestureDetector(
              onTap: onSelected == null
                  ? null
                  : () {
                      AppHaptics.selection();
                      onSelected!(item.id);
                    },
              child: AnimatedContainer(
                duration: LuxeMotion.medium,
                curve: LuxeMotion.settle,
                width: 116,
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                decoration: BoxDecoration(
                  color: selected ? p.ink : p.surface,
                  borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall),
                  border: Border.all(color: selected ? p.ink : p.hairline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(end: item.count.toDouble()),
                      duration: LuxeMotion.reveal,
                      curve: LuxeMotion.settle,
                      builder: (context, v, _) => Text(
                        '${v.round()}',
                        maxLines: 1,
                        style: LuxeType.display(
                          26,
                          selected ? p.canvas : p.ink,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LuxeType.label(
                        selected ? p.canvas : p.inkMuted,
                        size: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
