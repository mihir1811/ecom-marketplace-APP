import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../diamonds/application/diamond_list_provider.dart';
import '../../../diamonds/application/diamond_search_provider.dart';
import '../../../diamonds/domain/models/diamond.dart';
import '../../../diamonds/domain/models/diamond_catalog_type.dart';
import '../../application/diamond_project_listing_pick_provider.dart';
import '../../application/diamond_project_selection_provider.dart';
import '../../application/diamond_selection.dart';

/// Seller-only toolbar pill: the selection count (or the loaded count when
/// nothing is picked). A tap opens [DiamondProjectSheet].
class DiamondProjectToolbarButton extends ConsumerWidget {
  const DiamondProjectToolbarButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(canPickDiamondsProvider)) return const SizedBox.shrink();

    final p = LuxePalette.of(context);
    final loaded = ref.watch(
      diamondListProvider.select((a) => a.valueOrNull?.diamonds.length ?? 0),
    );
    final picked = ref.watch(
      diamondProjectListingPickProvider.select((s) => s.length),
    );
    final active = picked > 0;
    final count = active ? picked : loaded;
    final ink = active ? p.onAccent : p.ink;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () {
          AppHaptics.selection();
          DiamondProjectSheet.show(context);
        },
        child: AnimatedContainer(
          duration: LuxeMotion.medium,
          curve: LuxeMotion.settle,
          height: 38,
          padding: EdgeInsets.only(left: 12, right: active ? 6 : 12),
          decoration: ShapeDecoration(
            color: active ? p.accent : p.surface,
            shape: StadiumBorder(
              side: BorderSide(color: active ? p.accent : p.hairline),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.tr(AccountCommerceL10n.projectButton),
                style: LuxeType.label(ink, size: 12.5),
              ),
              const SizedBox(width: 6),
              Text('$count', style: LuxeType.figure(ink, size: 13)),
              if (active) ...[
                const SizedBox(width: 4),
                Semantics(
                  button: true,
                  label: context.tr(AccountCommerceL10n.projectClear),
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      AppHaptics.medium();
                      DiamondSelection.clearPicks(ref);
                    },
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: p.onAccent.withValues(alpha: 0.2),
                      ),
                      child: Icon(Icons.close_rounded, size: 15, color: ink),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet: analyse the picked stones or everything loaded, or clear
/// the picks.
class DiamondProjectSheet extends ConsumerWidget {
  const DiamondProjectSheet._();

  static Future<void> show(BuildContext context) {
    final p = LuxePalette.of(context);
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: p.isDark ? 0.6 : 0.32),
      useSafeArea: true,
      builder: (_) => const DiamondProjectSheet._(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = LuxePalette.of(context);
    final loaded = ref.watch(
      diamondListProvider.select((a) => a.valueOrNull?.diamonds.length ?? 0),
    );
    final picked = ref.watch(
      diamondProjectListingPickProvider.select((s) => s.length),
    );

    Widget enter(Widget child, int i) => child
        .animate(delay: LuxeMotion.stagger * i)
        .fadeIn(duration: LuxeMotion.medium, curve: LuxeMotion.settle)
        .slideY(begin: 0.18, end: 0, curve: LuxeMotion.settle);

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 18),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: p.hairline, width: 0.6),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: ShapeDecoration(
                  color: p.hairline,
                  shape: const StadiumBorder(),
                ),
              ),
            ),
            const SizedBox(height: 18),
            enter(
              Text(
                context.tr(AccountCommerceL10n.projectEyebrow).toUpperCase(),
                style: LuxeType.eyebrow(p.accent),
              ),
              0,
            ),
            const SizedBox(height: 6),
            enter(
              Text(
                context.tr(AccountCommerceL10n.projectTitle),
                style: LuxeType.display(30, p.ink),
              ),
              1,
            ),
            const SizedBox(height: 8),
            enter(
              Text(
                context.tr(AccountCommerceL10n.projectHint),
                style: LuxeType.body(p.inkMuted, size: 13.5),
              ),
              2,
            ),
            const SizedBox(height: 18),
            enter(
              _Option(
                icon: Icons.done_all_rounded,
                title: context.tr(AccountCommerceL10n.projectSelected),
                body: picked == 0
                    ? context.tr(AccountCommerceL10n.projectNoneSelected)
                    : context.tr(AccountCommerceL10n.projectSelectedBody, {
                        'count': picked,
                      }),
                emphasis: true,
                onTap: picked == 0
                    ? null
                    : () => _open(context, ref, picksOnly: true),
              ),
              3,
            ),
            const SizedBox(height: 10),
            enter(
              _Option(
                icon: Icons.layers_outlined,
                title: context.tr(AccountCommerceL10n.projectPage),
                body: context.tr(AccountCommerceL10n.projectPageBody, {
                  'count': loaded,
                }),
                onTap: loaded == 0
                    ? null
                    : () => _open(context, ref, picksOnly: false),
              ),
              4,
            ),
            AnimatedSize(
              duration: LuxeMotion.medium,
              curve: LuxeMotion.settle,
              child: picked == 0
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: TextButton.icon(
                        onPressed: () {
                          AppHaptics.medium();
                          DiamondSelection.clearPicks(ref);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: p.caution,
                          minimumSize: const Size.fromHeight(44),
                        ),
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: Text(
                          context.tr(AccountCommerceL10n.projectClear),
                          style: LuxeType.label(p.caution, size: 13.5),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, WidgetRef ref, {required bool picksOnly}) {
    final all =
        ref.read(diamondListProvider).valueOrNull?.diamonds ??
        const <Diamond>[];
    final picks = ref.read(diamondProjectListingPickProvider);
    final diamonds = picksOnly
        ? all.where((d) => picks.contains(d.id)).toList(growable: false)
        : all;
    if (diamonds.isEmpty) return;

    ref
        .read(diamondProjectSelectionProvider.notifier)
        .selectLoadedPage(
          diamonds: diamonds,
          filters: ref.read(diamondSearchProvider),
          catalog: ref.read(diamondCatalogTypeProvider),
        );
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.push(AppRouteNames.diamondProject);
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
    this.emphasis = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback? onTap;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final enabled = onTap != null;
    final strong = emphasis && enabled;
    final ink = strong ? p.onAccent : p.ink;

    return AnimatedOpacity(
      duration: LuxeMotion.fast,
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: strong ? p.ink : p.surfaceRaised,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap == null
              ? null
              : () {
                  AppHaptics.selection();
                  onTap!();
                },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: strong ? p.accent : p.surface,
                  ),
                  child: Icon(
                    icon,
                    size: 19,
                    color: strong ? p.onAccent : p.accent,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: LuxeType.label(
                          strong ? p.canvas : ink,
                          size: 14.5,
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        body,
                        style: LuxeType.body(
                          strong ? p.canvas.withValues(alpha: 0.7) : p.inkMuted,
                          size: 12.5,
                        ).copyWith(height: 1.3),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: strong ? p.canvas : p.inkMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
