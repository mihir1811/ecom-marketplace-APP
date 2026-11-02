import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/haptics/app_haptics.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../domain/models/compare_item.dart';
import 'vitrine_gem.dart';
import 'vitrine_style.dart';

Future<T?> _sheet<T>(BuildContext context, WidgetBuilder builder) {
  final v = Vitrine.of(context);
  return showModalBottomSheet<T>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: v.isDark ? 0.62 : 0.34),
    builder: (context) => _Frame(child: builder(context)),
  );
}

class _Frame extends StatelessWidget {
  const _Frame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final v = Vitrine.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      decoration: BoxDecoration(
        color: v.card,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: v.line, width: 0.6),
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
                  color: v.line,
                  shape: const StadiumBorder(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

extension on Widget {
  Widget enter(int i) => animate(delay: VitrineMotion.stagger * i)
      .fadeIn(duration: VitrineMotion.settle, curve: VitrineMotion.ease)
      .slideY(begin: 0.16, end: 0, curve: VitrineMotion.ease);
}

/// What a tap on a piece offers.
enum VitrinePieceAction { details, left, right, remove }

/// Piece close-up with its actions: details, move left / right, remove.
Future<VitrinePieceAction?> showVitrinePieceSheet(
  BuildContext context, {
  required CompareItem item,
  required int index,
  required int count,
  required int wins,
  required int decisive,
  required bool canViewDetails,
}) {
  return _sheet<VitrinePieceAction>(context, (context) {
    final v = Vitrine.of(context);
    void pick(VitrinePieceAction a) => Navigator.of(context).pop(a);

    final actions = <Widget>[
      if (canViewDetails)
        _ActionTile(
          icon: Icons.north_east_rounded,
          label: context.tr(AccountCommerceL10n.compareViewDetails),
          strong: true,
          onTap: () => pick(VitrinePieceAction.details),
        ),
      if (index > 0)
        _ActionTile(
          icon: Icons.west_rounded,
          label: context.tr(AccountCommerceL10n.compareMoveLeft),
          onTap: () => pick(VitrinePieceAction.left),
        ),
      if (index < count - 1)
        _ActionTile(
          icon: Icons.east_rounded,
          label: context.tr(AccountCommerceL10n.compareMoveRight),
          onTap: () => pick(VitrinePieceAction.right),
        ),
      _ActionTile(
        icon: Icons.close_rounded,
        label: context.tr(AccountCommerceL10n.removeComparison),
        danger: true,
        onTap: () => pick(VitrinePieceAction.remove),
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            VitrinePieceImage(item: item, size: 92, radius: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vitrineNumeral(index),
                    style: v.display(
                      14,
                      color: v.gold,
                      style: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: v.display(24),
                  ),
                  if ((item.subtitle ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(item.subtitle!, style: v.text(12.5, color: v.muted)),
                  ],
                  const SizedBox(height: 6),
                  Text(item.displayValues['price'] ?? '', style: v.figure(17)),
                ],
              ),
            ),
          ],
        ).enter(0),
        if (decisive > 0) ...[
          const SizedBox(height: 10),
          Text(
            context.tr(AccountCommerceL10n.compareLeads, {
              'wins': wins,
              'total': decisive,
            }),
            style: v.eyebrow(color: v.gold),
          ).enter(1),
        ],
        const SizedBox(height: 12),
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          actions[i].enter(i + 2),
        ],
      ],
    );
  });
}

/// Asks before clearing the comparison. Resolves true to clear.
Future<bool> confirmVitrineClear(BuildContext context) async {
  final result = await _sheet<bool>(context, (context) {
    final v = Vitrine.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: VitrineGem(size: 96, period: 10)).enter(0),
        const SizedBox(height: 8),
        Text(
          context.tr(AccountCommerceL10n.compareClearTitle),
          textAlign: TextAlign.center,
          style: v.display(26),
        ).enter(1),
        const SizedBox(height: 8),
        Text(
          context.tr(AccountCommerceL10n.compareClearBody),
          textAlign: TextAlign.center,
          style: v.text(13.5, color: v.muted, height: 1.5),
        ).enter(2),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _PillButton(
                label: context.tr(AccountCommerceL10n.compareKeep),
                onTap: () => Navigator.of(context).pop(false),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PillButton(
                label: context.tr(AccountCommerceL10n.compareClear),
                filled: true,
                danger: true,
                onTap: () => Navigator.of(context).pop(true),
              ),
            ),
          ],
        ).enter(3),
      ],
    );
  });
  return result ?? false;
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.strong = false,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool strong;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final v = Vitrine.of(context);
    final fg = strong
        ? v.paper
        : danger
        ? v.danger
        : v.ink;
    return Material(
      color: strong ? v.ink : v.raised,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          danger ? AppHaptics.light() : AppHaptics.selection();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: v.text(14, weight: FontWeight.w700, color: fg),
                ),
              ),
              Icon(icon, size: 18, color: strong ? v.gold : fg),
            ],
          ),
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.onTap,
    this.filled = false,
    this.danger = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final v = Vitrine.of(context);
    final bg = filled ? (danger ? v.danger : v.ink) : Colors.transparent;
    final fg = filled ? (v.isDark ? v.paper : Colors.white) : v.ink;
    return Material(
      color: bg,
      shape: StadiumBorder(
        side: filled ? BorderSide.none : BorderSide(color: v.line),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () {
          AppHaptics.selection();
          onTap();
        },
        child: SizedBox(
          height: 50,
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: v.text(14, weight: FontWeight.w700, color: fg),
            ),
          ),
        ),
      ),
    );
  }
}
