import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../application/live_show_room.dart';
import '../../domain/live_format.dart';
import '../../domain/models/live_show_models.dart';
import '../live_show_actions.dart';

/// The show's items: what is up now, the seller's lineup still to come,
/// and results (newest first) with the viewer's wins linked to orders.
Future<void> showLiveLineupSheet(
  BuildContext context, {
  required String showId,
  required ValueChanged<String> onOpenOrder,
  bool resultsFirst = false,
}) {
  return showLuxeSheet<void>(
    context,
    title: 'Items in this show',
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
    final p = LuxePalette.of(context);
    final s = ref.watch(liveShowRoomProvider(widget.showId));
    final current = s.current;
    final lots = _results ? s.results : [?current, ...s.upNext];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
          child: SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: false,
                label: Text(
                  'Up next (${s.upNext.length + (current == null ? 0 : 1)})',
                ),
              ),
              ButtonSegment(
                value: true,
                label: Text('Results (${s.results.length})'),
              ),
            ],
            selected: {_results},
            onSelectionChanged: (v) => setState(() => _results = v.first),
          ),
        ),
        if (lots.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
            child: Text(
              _results
                  ? 'Nothing has sold in this show yet.'
                  : 'The seller has not lined up more items yet.',
              textAlign: TextAlign.center,
              style: LuxeType.body(p.inkMuted, size: 14),
            ),
          )
        else
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              itemCount: lots.length,
              separatorBuilder: (_, _) => Divider(color: p.hairline, height: 1),
              itemBuilder: (context, i) => _LotRow(
                lot: lots[i],
                isCurrent: lots[i].id == current?.id,
                win: s.me?.winFor(lots[i].id),
                onOpenOrder: widget.onOpenOrder,
              ),
            ),
          ),
      ],
    );
  }
}

class _LotRow extends ConsumerWidget {
  const _LotRow({
    required this.lot,
    required this.isCurrent,
    required this.onOpenOrder,
    this.win,
  });

  final LiveAuctionLot lot;
  final bool isCurrent;
  final LiveWin? win;
  final ValueChanged<String> onOpenOrder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = LuxePalette.of(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final (status, tone) = switch (lot.status) {
      LotStatus.running => ('Bidding now', p.caution),
      LotStatus.queued => ('From ${liveInr(lot.startingBid)}', p.inkMuted),
      LotStatus.sold => (
        'Sold for ${liveInr(lot.currentBid ?? 0)}'
            '${lot.leaderName == null ? '' : ' · ${lot.leaderName}'}',
        p.positive,
      ),
      LotStatus.unsold => ('No bids', p.inkMuted),
      // currentBid on a cancelled lot is not a sale price.
      LotStatus.cancelled => ('Withdrawn by the seller', p.inkMuted),
    };
    return InkWell(
      onTap: () => openLiveLot(context, ref, lot),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 56,
                height: 56,
                color: p.surfaceRaised,
                child: lot.image == null
                    ? Icon(Icons.diamond_outlined, color: p.inkFaint)
                    : AppNetworkImage(
                        url: lot.image!,
                        memCacheWidth: (56 * dpr).round(),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lot.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LuxeType.label(p.ink, size: 14.5),
                  ),
                  if (lot.stockNumber != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Stock ${lot.stockNumber}',
                      style: LuxeType.body(p.inkFaint, size: 12),
                    ),
                  ],
                  const SizedBox(height: 3),
                  Text(
                    win != null ? 'You won · ${liveInr(win!.amount)}' : status,
                    style: LuxeType.label(
                      win != null ? p.positive : tone,
                      size: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            if (win != null && win!.orderId.isNotEmpty)
              TextButton(
                onPressed: () {
                  final orderId = win!.orderId;
                  Navigator.of(context).pop();
                  onOpenOrder(orderId);
                },
                child: const Text('View order'),
              )
            else if (isCurrent)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: p.caution.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('NOW', style: LuxeType.label(p.caution, size: 11)),
              )
            else
              Icon(Icons.chevron_right_rounded, color: p.inkFaint),
          ],
        ),
      ),
    );
  }
}
