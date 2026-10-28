import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../application/live_show_room.dart';
import '../../domain/live_format.dart';
import '../../domain/models/live_show_models.dart';
import '../live_show_actions.dart';
import 'live_sheet.dart';
import 'live_stage_tokens.dart';

/// The show's pieces: what is up now and the seller's lineup still to
/// come, and results (newest first) with the viewer's wins linked to
/// their orders.
Future<void> showLiveLineupSheet(
  BuildContext context, {
  required String showId,
  required ValueChanged<String> onOpenOrder,
  bool resultsFirst = false,
}) {
  return showLiveSheet<void>(
    context,
    title: 'In this show',
    builder: (_) => _LineupBody(
      showId: showId,
      resultsFirst: resultsFirst,
      onOpenOrder: onOpenOrder,
    ),
  );
}

class _LineupBody extends ConsumerStatefulWidget {
  const _LineupBody({
    required this.showId,
    required this.resultsFirst,
    required this.onOpenOrder,
  });

  final String showId;
  final bool resultsFirst;
  final ValueChanged<String> onOpenOrder;

  @override
  ConsumerState<_LineupBody> createState() => _LineupBodyState();
}

class _LineupBodyState extends ConsumerState<_LineupBody> {
  late var _results = widget.resultsFirst;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(liveShowRoomProvider(widget.showId));
    final current = s.current;
    final lots = _results ? s.results : [?current, ...s.upNext];
    final upCount = s.upNext.length + (current == null ? 0 : 1);
    final still = MediaQuery.disableAnimationsOf(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: _Segmented(
            left: 'Up next',
            leftCount: upCount,
            right: 'Results',
            rightCount: s.results.length,
            rightSelected: _results,
            onChanged: (v) {
              AppHaptics.selection();
              setState(() => _results = v);
            },
          ),
        ),
        Flexible(
          child: AnimatedSwitcher(
            duration: LiveMotion.base,
            switchInCurve: LiveMotion.ease,
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(
                position: Tween(
                  begin: Offset(_results ? 0.04 : -0.04, 0),
                  end: Offset.zero,
                ).animate(a),
                child: child,
              ),
            ),
            child: lots.isEmpty
                ? _Empty(key: ValueKey('empty-$_results'), results: _results)
                : ListView.separated(
                    key: ValueKey('list-$_results'),
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    itemCount: lots.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      Widget row = _LotRow(
                        lot: lots[i],
                        isCurrent: lots[i].id == current?.id,
                        win: s.me?.winFor(lots[i].id),
                        leading: s.leadingAmount(lots[i].id),
                        onOpenOrder: widget.onOpenOrder,
                      );
                      if (!still && i < 10) {
                        row = row
                            .animate(delay: (40 * i).ms)
                            .fadeIn(duration: 260.ms)
                            .moveY(begin: 10, end: 0, curve: LiveMotion.ease);
                      }
                      return row;
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.left,
    required this.leftCount,
    required this.right,
    required this.rightCount,
    required this.rightSelected,
    required this.onChanged,
  });

  final String left;
  final int leftCount;
  final String right;
  final int rightCount;
  final bool rightSelected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget tab(String label, int count, bool selected, bool value) => Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: '$label, $count',
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(value),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: LiveMotion.quick,
              style: LiveType.label(
                13.5,
                color: selected ? LiveStage.onChampagne : LiveStage.inkMuted,
              ),
              child: Text('$label  $count'),
            ),
          ),
        ),
      ),
    );
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: LiveStage.ink.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: LiveStage.hairline),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 380),
            curve: LiveMotion.emphasized,
            alignment: rightSelected
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LiveStage.champagneGradient,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          Row(
            children: [
              tab(left, leftCount, !rightSelected, false),
              tab(right, rightCount, rightSelected, true),
            ],
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.results, super.key});

  final bool results;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 40),
      child: Column(
        children: [
          Icon(
            results ? Icons.gavel_rounded : Icons.diamond_outlined,
            size: 30,
            color: LiveStage.champagne.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 12),
          Text(
            results ? 'No results yet' : 'Nothing lined up yet',
            style: LiveType.display(22),
          ),
          const SizedBox(height: 6),
          Text(
            results
                ? 'Sold and closed pieces appear here as the show goes on.'
                : 'The seller has not lined up more pieces. Stay tuned.',
            textAlign: TextAlign.center,
            style: LiveType.body(13),
          ),
        ],
      ),
    );
  }
}

class _LotRow extends ConsumerWidget {
  const _LotRow({
    required this.lot,
    required this.isCurrent,
    required this.onOpenOrder,
    this.win,
    this.leading,
  });

  final LiveAuctionLot lot;
  final bool isCurrent;
  final LiveWin? win;
  final double? leading;
  final ValueChanged<String> onOpenOrder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (status, tone) = switch (lot.status) {
      LotStatus.running => (
        lot.hasBids
            ? 'Bidding · ${liveInr(lot.currentBid!)}'
            : 'Bidding · from ${liveInr(lot.startingBid)}',
        LiveStage.live,
      ),
      LotStatus.queued => (
        'From ${liveInr(lot.startingBid)}',
        LiveStage.inkMuted,
      ),
      LotStatus.sold => (
        'Sold for ${liveInr(lot.currentBid ?? 0)}'
            '${lot.leaderName == null ? '' : ' · ${lot.leaderName}'}',
        LiveStage.champagne,
      ),
      LotStatus.unsold => ('No bids', LiveStage.inkFaint),
      // currentBid on a cancelled lot is not a sale price.
      LotStatus.cancelled => ('Withdrawn by the seller', LiveStage.inkFaint),
    };
    final won = win != null;
    return LivePressable(
      scale: 0.98,
      semanticLabel: '${lot.title}, ${won ? 'you won' : status}',
      onTap: () => openLiveLot(context, ref, lot),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isCurrent
              ? LiveStage.live.withValues(alpha: 0.06)
              : LiveStage.ink.withValues(alpha: 0.035),
          border: Border.all(
            color: won
                ? LiveStage.leading.withValues(alpha: 0.4)
                : isCurrent
                ? LiveStage.live.withValues(alpha: 0.35)
                : LiveStage.hairline,
          ),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                LiveThumb(url: lot.image, size: 60, radius: 14),
                if (lot.position > 0)
                  Positioned(
                    left: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: LiveStage.obsidian,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: LiveStage.hairlineStrong),
                      ),
                      child: Text(
                        lot.position.toString().padLeft(2, '0'),
                        style: LiveType.figure(9.5, weight: FontWeight.w800),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lot.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LiveType.display(18),
                  ),
                  if (lot.stockNumber != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Stock ${lot.stockNumber}',
                      style: LiveType.body(11.5, color: LiveStage.inkFaint),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    won
                        ? 'You won · ${liveInr(win!.amount)}'
                        : leading != null
                        ? 'You lead · ${liveInr(leading!)}'
                        : status,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LiveType.label(
                      12.5,
                      color: won || leading != null ? LiveStage.leading : tone,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (won && win!.orderId.isNotEmpty)
              LiveButton(
                label: 'View order',
                expand: false,
                height: 36,
                kind: LiveButtonKind.secondary,
                onTap: () {
                  final orderId = win!.orderId;
                  Navigator.of(context).pop();
                  onOpenOrder(orderId);
                },
              )
            else if (isCurrent)
              const LiveBadge(compact: true)
            else
              Icon(Icons.chevron_right_rounded, color: LiveStage.inkFaint),
          ],
        ),
      ),
    );
  }
}
