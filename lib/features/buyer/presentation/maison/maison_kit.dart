import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/widgets/gem3d/gem_mesh.dart';
import '../../../../core/widgets/gem3d/gem_renderer.dart';
import '../../../../core/widgets/gem3d/gem_view.dart';
import '../../../seller/presentation/atelier/atelier_components.dart';
import '../../../seller/presentation/atelier/atelier_feedback.dart';
import '../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../seller/presentation/atelier/atelier_studio.dart';
import '../../../seller/presentation/atelier/atelier_theme.dart';
import '../../../../core/theme/luxe_tokens.dart';

// ── Formatting ──────────────────────────────────────────────────────────

/// `$12,480.00`.
String maisonUsd(num amount) => atelierMoney(amount, decimals: 2);

/// `₹1,20,000.00`.
String maisonInr(num amount) => atelierMoney(amount, symbol: '₹', decimals: 2);

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// "October 2026" (or "Earlier" when undated).
String maisonMonthLabel(DateTime? date) {
  if (date == null) return 'Earlier';
  final d = date.toLocal();
  return '${_months[d.month - 1]} ${d.year}';
}

/// "Today", "Yesterday" or "12 Oct 2026".
String maisonDayLabel(DateTime? date) {
  if (date == null) return 'Undated';
  final d = date.toLocal();
  final now = DateTime.now();
  final diff = DateTime(
    now.year,
    now.month,
    now.day,
  ).difference(DateTime(d.year, d.month, d.day)).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return atelierDate(d);
}

/// "2h ago", "3d ago", else the date.
String maisonRelative(DateTime? date) {
  if (date == null) return '';
  final d = date.toLocal();
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return atelierDate(d);
}

/// Last six characters of an id, upper-cased: `#9F2A1C`.
String maisonShortId(String id) {
  final clean = id.replaceAll('-', '');
  final tail = clean.length > 6 ? clean.substring(clean.length - 6) : clean;
  return '#${tail.toUpperCase()}';
}

// ── Editorial header ────────────────────────────────────────────────────

/// Opening of every buyer account page: large serif title and a turning
/// stone set in a dark loupe.
class MaisonHeader extends StatelessWidget {
  const MaisonHeader({
    required this.title,
    this.cut,
    this.look = GemLook.white,
    this.trailing,
    super.key,
  });

  final String title;
  final GemCut? cut;
  final GemLook look;

  /// Replaces the stone (e.g. a primary action).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 640;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Reveal(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AtelierType.display(
                    p.ink,
                    size: wide ? 50 : 40,
                    weight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 16),
              Reveal(index: 2, child: trailing!),
            ] else if (cut != null) ...[
              const SizedBox(width: 12),
              Reveal(
                delay: const Duration(milliseconds: 160),
                child: MaisonLoupe(
                  cut: cut!,
                  look: look,
                  size: wide ? 124 : 92,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// A live 3D stone inside a dark jeweller's loupe with a fine gold ring.
class MaisonLoupe extends StatelessWidget {
  const MaisonLoupe({
    required this.cut,
    this.look = GemLook.white,
    this.size = 96,
    this.interactive = true,
    super.key,
  });

  final GemCut cut;
  final GemLook look;
  final double size;
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    Widget ring = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [LuxeStage.vaultTop, LuxeStage.vaultBottom],
          stops: const [0.1, 1],
        ),
        border: Border.all(color: p.gold.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: p.gold.withValues(alpha: p.isDark ? 0.14 : 0.22),
            blurRadius: size * 0.4,
            spreadRadius: -size * 0.12,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: GemView(
        cut: cut,
        look: look,
        size: size * 0.82,
        spin: 0.34,
        tilt: 0.42,
        interactive: interactive,
        semanticLabel: 'Rotating gem. Drag to turn it.',
      ),
    );
    if (!context.reduceMotion) {
      ring = ring
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: -2, end: 2, duration: 3200.ms, curve: Curves.easeInOut);
    }
    return ring;
  }
}

// ── Stat strip ──────────────────────────────────────────────────────────

/// One figure in a [MaisonStatStrip].
class MaisonStat {
  const MaisonStat({
    required this.label,
    required this.value,
    this.caption,
    this.tone,
    this.pulse = false,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final String value;
  final String? caption;

  /// Colour of the value; ink when null.
  final AtelierTone? tone;

  /// Breathing dot beside the label for "needs you" figures.
  final bool pulse;
  final bool selected;
  final VoidCallback? onTap;
}

/// The page's headline figures in one hairline card. Cells that carry an
/// [MaisonStat.onTap] double as filters.
class MaisonStatStrip extends StatelessWidget {
  const MaisonStatStrip({required this.stats, super.key});

  final List<MaisonStat> stats;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AtelierRadius.lg),
        border: Border.all(color: p.hairline),
        boxShadow: p.softShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < stats.length; i++) ...[
              if (i > 0)
                Container(
                  width: 1,
                  margin: const EdgeInsets.symmetric(vertical: 14),
                  color: p.hairline,
                ),
              Expanded(child: _StatCell(stat: stats[i])),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.stat});

  final MaisonStat stat;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final valueColor = stat.tone == null ? p.ink : p.tone(stat.tone!);
    final body = AnimatedContainer(
      duration: AtelierMotion.base,
      curve: AtelierMotion.emphasized,
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      color: stat.selected ? p.goldSoft : Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              if (stat.pulse && stat.tone != null) ...[
                AtelierPulseDot(tone: stat.tone!, size: 6),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  stat.label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AtelierType.overline(
                    stat.selected ? p.ink : p.muted,
                  ).copyWith(fontSize: 9.5, letterSpacing: 1.2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: CountUpText(
              stat.value,
              style: AtelierType.display(valueColor, size: 26),
            ),
          ),
          if (stat.caption != null) ...[
            const SizedBox(height: 2),
            Text(
              stat.caption!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AtelierType.caption(p.muted, size: 10.5),
            ),
          ],
        ],
      ),
    );
    if (stat.onTap == null) return body;
    return Semantics(
      selected: stat.selected,
      child: Pressable(
        onTap: stat.onTap,
        scale: 0.97,
        semanticLabel: '${stat.label} ${stat.value}',
        child: body,
      ),
    );
  }
}

// ── Pinned filter bar ───────────────────────────────────────────────────

/// Pins [child] under the top bar while the list scrolls; a hairline and
/// soft shadow appear once content slides beneath it.
class MaisonPinnedBar extends StatelessWidget {
  const MaisonPinnedBar({
    required this.height,
    required this.child,
    required this.gutter,
    super.key,
  });

  final double height;
  final double gutter;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _PinnedDelegate(height: height, gutter: gutter, child: child),
    );
  }
}

class _PinnedDelegate extends SliverPersistentHeaderDelegate {
  _PinnedDelegate({
    required this.height,
    required this.gutter,
    required this.child,
  });

  final double height;
  final double gutter;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    final p = context.atelier;
    return AnimatedContainer(
      duration: AtelierMotion.base,
      decoration: BoxDecoration(
        color: p.canvas,
        border: Border(
          bottom: BorderSide(
            color: overlaps ? p.hairline : p.hairline.withValues(alpha: 0),
          ),
        ),
        boxShadow: overlaps && !p.isDark
            ? [
                BoxShadow(
                  color: p.shadow,
                  blurRadius: 16,
                  spreadRadius: -10,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      padding: EdgeInsets.symmetric(horizontal: gutter),
      alignment: Alignment.center,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: child,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_PinnedDelegate old) =>
      old.child != child || old.height != height || old.gutter != gutter;
}

/// Search field with sort and optional trailing control, sized for
/// [MaisonPinnedBar].
class MaisonSearchRow extends StatelessWidget {
  const MaisonSearchRow({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.sortLabel,
    required this.sortActive,
    required this.onSort,
    this.trailing,
    super.key,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final String sortLabel;
  final bool sortActive;
  final VoidCallback onSort;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AtelierSearchField(
            controller: controller,
            hint: hint,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: AtelierSpace.s8),
        AtelierIconButton(
          icon: Icons.swap_vert_rounded,
          tooltip: 'Sort: $sortLabel',
          filled: true,
          size: 46,
          dot: sortActive,
          onPressed: onSort,
        ),
        if (trailing != null) ...[
          const SizedBox(width: AtelierSpace.s6),
          trailing!,
        ],
      ],
    );
  }
}

// ── Lists ───────────────────────────────────────────────────────────────

/// Centres [child] at the account pages' reading width.
class MaisonCentered extends StatelessWidget {
  const MaisonCentered({required this.child, this.maxWidth = 1040, super.key});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

/// Sliver hairline progress shown while a refresh runs over loaded data.
class MaisonRefreshHairline extends StatelessWidget {
  const MaisonRefreshHairline({required this.visible, super.key});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return SliverToBoxAdapter(
      child: AnimatedOpacity(
        duration: AtelierMotion.base,
        opacity: visible ? 1 : 0,
        child: LinearProgressIndicator(
          minHeight: 1.5,
          color: p.gold,
          backgroundColor: Colors.transparent,
        ),
      ),
    );
  }
}

/// Month / day divider in long lists: overline, count and a fading rule.
class MaisonGroupLabel extends StatelessWidget {
  const MaisonGroupLabel({required this.label, this.count, super.key});

  final String label;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 12),
      child: Row(
        children: [
          Text(label.toUpperCase(), style: AtelierType.overline(p.inkSoft)),
          if (count != null) ...[
            const SizedBox(width: 8),
            Text('$count', style: AtelierType.figure(p.muted, size: 11)),
          ],
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [p.hairline, p.hairline.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// End of a paginated list: spinner, retry, "load more" or a quiet stop.
class MaisonListFooter extends StatelessWidget {
  const MaisonListFooter({
    required this.loadingMore,
    required this.hasMore,
    required this.onLoadMore,
    this.errorMessage,
    this.endLabel = 'That’s everything',
    super.key,
  });

  final bool loadingMore;
  final bool hasMore;
  final String? errorMessage;
  final VoidCallback onLoadMore;
  final String endLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final Widget body;
    if (loadingMore) {
      body = Padding(
        key: const ValueKey('loading'),
        padding: const EdgeInsets.all(20),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 1.8, color: p.gold),
          ),
        ),
      );
    } else if (errorMessage != null && hasMore) {
      body = Padding(
        key: const ValueKey('error'),
        padding: const EdgeInsets.only(top: 8),
        child: AtelierNotice(
          text: errorMessage!,
          tone: AtelierTone.ruby,
          icon: Icons.error_outline_rounded,
          actionLabel: 'Retry',
          onAction: onLoadMore,
        ),
      );
    } else if (hasMore) {
      body = Center(
        key: const ValueKey('more'),
        child: AtelierButton(
          label: 'Show more',
          icon: Icons.expand_more_rounded,
          compact: true,
          variant: AtelierButtonVariant.ghost,
          onPressed: onLoadMore,
        ),
      );
    } else {
      body = Padding(
        key: const ValueKey('end'),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 24, height: 1, color: p.hairline),
            const SizedBox(width: 10),
            Icon(Icons.diamond_outlined, size: 12, color: p.gold),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                endLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AtelierType.caption(p.muted, size: 11.5),
              ),
            ),
            const SizedBox(width: 10),
            Container(width: 24, height: 1, color: p.hairline),
          ],
        ),
      );
    }
    return AnimatedSwitcher(duration: AtelierMotion.base, child: body);
  }
}

/// Empty state with a live stone instead of an icon.
class MaisonEmptyState extends StatelessWidget {
  const MaisonEmptyState({
    required this.title,
    required this.message,
    this.cut = GemCut.round,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    super.key,
  });

  final String title;
  final String message;
  final GemCut cut;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Reveal(child: MaisonLoupe(cut: cut, size: 120)),
          const SizedBox(height: 24),
          Reveal(
            index: 1,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AtelierType.display(p.ink, size: 28),
            ),
          ),
          const SizedBox(height: 8),
          Reveal(
            index: 2,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: AtelierType.body(p.muted, size: 13.5),
              ),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 22),
            Reveal(
              index: 3,
              child: AtelierButton(
                label: actionLabel!,
                icon: actionIcon,
                onPressed: onAction,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Dialog that runs its action in place: the confirm button spins, a
/// failure shows inline and the dialog closes with `true` on success.
class MaisonActionDialog extends ConsumerStatefulWidget {
  const MaisonActionDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.onConfirm,
    this.content,
    this.destructive = false,
    this.canConfirm = true,
    this.icon,
    this.cancelLabel = 'Cancel',
    super.key,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final Widget? content;
  final bool destructive;
  final bool canConfirm;
  final IconData? icon;

  /// Performs the action; returns the failure, or `null` on success.
  final Future<Failure?> Function(WidgetRef ref) onConfirm;

  @override
  ConsumerState<MaisonActionDialog> createState() => _MaisonActionDialogState();
}

class _MaisonActionDialogState extends ConsumerState<MaisonActionDialog> {
  bool _busy = false;
  String? _error;

  Future<void> _confirm() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final failure = await widget.onConfirm(ref);
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop(true);
      return;
    }
    AppHaptics.error();
    setState(() {
      _busy = false;
      _error = failure.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_busy,
      child: AtelierDialogFrame(
        title: widget.title,
        message: widget.message,
        icon: widget.icon,
        tone: widget.destructive ? AtelierTone.ruby : AtelierTone.gold,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ?widget.content,
            AnimatedSize(
              duration: AtelierMotion.base,
              curve: AtelierMotion.emphasized,
              child: _error == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: AtelierNotice(
                        text: _error!,
                        tone: AtelierTone.ruby,
                        icon: Icons.error_outline_rounded,
                      ),
                    ),
            ),
          ],
        ),
        actions: [
          AtelierButton(
            label: widget.cancelLabel,
            variant: AtelierButtonVariant.secondary,
            onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          ),
          AtelierButton(
            label: widget.confirmLabel,
            loading: _busy,
            variant: widget.destructive
                ? AtelierButtonVariant.danger
                : AtelierButtonVariant.primary,
            onPressed: _busy || !widget.canConfirm ? null : _confirm,
          ),
        ],
      ),
    );
  }
}

/// Turns a repository result into the failure [MaisonActionDialog] expects.
Future<Failure?> maisonOutcome<T>(Future<Result<T, Failure>> call) async {
  return switch (await call) {
    Success() => null,
    ResultFailure(:final failure) => failure,
  };
}

/// Toast with an optional action (e.g. Undo), for callers that captured
/// the messenger before an async gap.
void showMaisonToast(
  ScaffoldMessengerState messenger,
  AtelierPalette p,
  String message, {
  AtelierTone tone = AtelierTone.neutral,
  IconData? icon,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  if (actionLabel == null || onAction == null) {
    showAtelierToastOn(messenger, p, message, tone: tone, icon: icon);
    return;
  }
  final accent = tone == AtelierTone.neutral ? p.gold : p.tone(tone);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: Colors.transparent,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        duration: const Duration(seconds: 5),
        content: Container(
          padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
          decoration: BoxDecoration(
            color: p.isDark ? p.raised : p.onyx,
            borderRadius: BorderRadius.circular(AtelierRadius.md),
            border: Border.all(
              color: p.isDark ? p.hairline : Colors.transparent,
            ),
            boxShadow: p.floatShadow,
          ),
          child: Row(
            children: [
              Icon(icon ?? Icons.auto_awesome_rounded, size: 18, color: accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: AtelierType.label(
                    p.isDark ? p.ink : p.onOnyx,
                    size: 13,
                    weight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  messenger.hideCurrentSnackBar();
                  onAction();
                },
                style: TextButton.styleFrom(foregroundColor: p.gold),
                child: Text(actionLabel, style: AtelierType.label(p.gold)),
              ),
            ],
          ),
        ),
      ),
    );
}
