import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../application/jewelry_bag_provider.dart';

/// Points from the catalog cart to the separate jewellery bag (marketplace
/// pieces check out on their own). Hidden while the bag is empty.
class JewelryBagBanner extends ConsumerWidget {
  const JewelryBagBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(jewelryBagCountProvider);
    if (count == 0) return const SizedBox.shrink();
    final p = LuxePalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
      child: Material(
        color: p.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall),
        child: InkWell(
          borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall),
          onTap: () => context.push(AppRouteNames.jewelryBag),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
            child: Row(
              children: [
                Icon(Icons.shopping_bag_outlined, color: p.accent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr(JewelryMarketL10n.bagBanner, {'count': count}),
                    style: LuxeType.label(p.ink, size: 13.5),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: p.inkMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
