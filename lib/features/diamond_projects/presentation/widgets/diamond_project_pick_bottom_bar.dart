import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../application/diamond_project_listing_pick_provider.dart';

/// Sticky bottom tray when ≥1 diamond is picked for project analysis.
class DiamondProjectPickBottomBar extends ConsumerWidget {
  const DiamondProjectPickBottomBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canUse = ref.watch(
      authProvider.select((s) => s.isSeller || s.sellerId != null),
    );
    final count = canUse
        ? ref.watch(diamondProjectListingPickProvider.select((s) => s.length))
        : 0;

    return AnimatedSize(
      duration: LuxeMotion.medium,
      curve: LuxeMotion.settle,
      alignment: Alignment.bottomCenter,
      child: count == 0
          ? const SizedBox(width: double.infinity)
          : _Tray(
              count: count,
              onClear: () {
                AppHaptics.selection();
                ref.read(diamondProjectListingPickProvider.notifier).clear();
              },
            ),
    );
  }
}

class _Tray extends StatelessWidget {
  const _Tray({required this.count, required this.onClear});

  final int count;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final label = count == 1 ? 'diamond' : 'diamonds';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.hairline)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: p.isDark ? 0.4 : 0.07),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 8, 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: ShapeDecoration(
                  color: p.ink,
                  shape: const StadiumBorder(),
                ),
                child: AnimatedSwitcher(
                  duration: LuxeMotion.fast,
                  transitionBuilder: (c, a) =>
                      ScaleTransition(scale: a, child: c),
                  child: Text(
                    '$count',
                    key: ValueKey(count),
                    style: LuxeType.figure(p.canvas, size: 13),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$label selected',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LuxeType.label(p.ink, size: 13.5),
                ),
              ),
              TextButton(
                onPressed: onClear,
                style: TextButton.styleFrom(foregroundColor: p.caution),
                child: Text(
                  context.tr(CatalogL10n.clearAll),
                  style: LuxeType.label(p.caution, size: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
