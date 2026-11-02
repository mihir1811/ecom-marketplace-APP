import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/seller/presentation/atelier/atelier_motion.dart';
import '../../../features/seller/presentation/atelier/atelier_theme.dart';
import '../../auth/auth_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../router/workspace_mode.dart';
import 'start_selling_flow.dart';

IconData workspaceIcon(AppWorkspace workspace) =>
    workspace == AppWorkspace.seller
    ? Icons.storefront_outlined
    : Icons.shopping_bag_outlined;

String workspaceLabelKey(AppWorkspace workspace) =>
    workspace == AppWorkspace.seller ? NavL10n.seller : NavL10n.buyer;

String switchToLabelKey(AppWorkspace target) => target == AppWorkspace.seller
    ? NavL10n.switchToSeller
    : NavL10n.switchToBuyer;

/// "Buyer | Seller" control pinned to the top of both drawers.
///
/// The highlighted half is where the user is now; tapping the other half
/// switches side. Accounts that cannot sell see [StartSellingCard] instead,
/// in the same spot, so the way into selling is always in one place.
class WorkspaceSwitcher extends ConsumerWidget {
  const WorkspaceSwitcher({required this.current, super.key});

  final AppWorkspace current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.atelier;
    final auth = ref.watch(
      authProvider.select(
        (s) => (isSeller: s.isSeller, pending: s.isVerificationPending),
      ),
    );
    if (!auth.isSeller) return const StartSellingCard();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 52,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: p.sunken,
            borderRadius: BorderRadius.circular(AtelierRadius.pill),
            border: Border.all(color: p.hairline),
          ),
          child: Row(
            children: [
              for (final side in AppWorkspace.values)
                Expanded(
                  child: _SwitchSegment(
                    workspace: side,
                    selected: side == current,
                    onTap: () => switchWorkspaceFrom(
                      context,
                      side,
                      pending: auth.pending,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          context.tr(NavL10n.modeHint),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AtelierType.caption(p.muted),
        ),
      ],
    );
  }
}

class _SwitchSegment extends StatelessWidget {
  const _SwitchSegment({
    required this.workspace,
    required this.selected,
    required this.onTap,
  });

  final AppWorkspace workspace;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final fg = selected ? p.canvas : p.inkSoft;
    final label = context.tr(workspaceLabelKey(workspace));
    return Semantics(
      selected: selected,
      child: Pressable(
        onTap: selected ? null : onTap,
        semanticLabel: selected
            ? label
            : context.tr(switchToLabelKey(workspace)),
        borderRadius: BorderRadius.circular(AtelierRadius.pill),
        child: AnimatedContainer(
          duration: AtelierMotion.base,
          curve: AtelierMotion.emphasized,
          height: double.infinity,
          decoration: BoxDecoration(
            color: selected ? p.ink : Colors.transparent,
            borderRadius: BorderRadius.circular(AtelierRadius.pill),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(workspaceIcon(workspace), size: 18, color: fg),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AtelierType.label(
                    fg,
                    size: 14,
                    weight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Drawer entry for accounts that cannot sell yet.
class StartSellingCard extends ConsumerWidget {
  const StartSellingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.atelier;
    final title = context.tr(NavL10n.startSelling);
    return Pressable(
      semanticLabel: title,
      borderRadius: BorderRadius.circular(AtelierRadius.md),
      onTap: () => startSellingFlow(context, ref),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
        decoration: BoxDecoration(
          color: p.goldSoft,
          borderRadius: BorderRadius.circular(AtelierRadius.md),
          border: Border.all(color: p.gold.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(Icons.storefront_outlined, size: 22, color: p.gold),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AtelierType.label(
                      p.ink,
                      size: 14,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.tr(NavL10n.startSellingBody),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AtelierType.caption(p.inkSoft),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.arrow_forward_rounded, size: 18, color: p.ink),
          ],
        ),
      ),
    );
  }
}

/// Compact "⇄ Seller" / "⇄ Buyer" button for top-level app bars.
///
/// Always the first trailing control on every top-level bar of both sides,
/// so the way to the other side sits in the same place everywhere.
class WorkspaceSwitchPill extends ConsumerWidget {
  const WorkspaceSwitchPill({required this.target, this.foreground, super.key});

  /// The side this button takes the user to.
  final AppWorkspace target;

  /// Overrides the ink colour (e.g. over the home hero). When set, the pill
  /// is drawn as an outline so it stays legible on any backdrop.
  final Color? foreground;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.atelier;
    final pending = ref.watch(
      authProvider.select((s) => s.isVerificationPending),
    );
    final fg = foreground ?? p.ink;
    final label = context.tr(workspaceLabelKey(target));
    final tooltip = context.tr(switchToLabelKey(target));

    return Tooltip(
      message: tooltip,
      child: Pressable(
        semanticLabel: tooltip,
        borderRadius: BorderRadius.circular(AtelierRadius.pill),
        onTap: () =>
            switchWorkspace(GoRouter.of(context), target, pending: pending),
        child: Padding(
          // Keeps a 48dp touch target around the 36dp pill.
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: foreground == null ? p.goldSoft : Colors.transparent,
              borderRadius: BorderRadius.circular(AtelierRadius.pill),
              border: Border.all(
                color: foreground == null
                    ? p.gold.withValues(alpha: 0.45)
                    : fg.withValues(alpha: 0.45),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.swap_horiz_rounded, size: 18, color: fg),
                const SizedBox(width: 5),
                Text(
                  label,
                  maxLines: 1,
                  style: AtelierType.label(
                    fg,
                    size: 13,
                    weight: FontWeight.w600,
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
