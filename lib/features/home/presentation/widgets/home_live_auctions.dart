import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../auction/application/auction_providers.dart';
import '../../../auction/domain/models/auction_models.dart';
import '../../../auction/presentation/widgets/auction_card.dart';
import '../../../auction/presentation/widgets/auction_clock.dart';
import '../../../auction/presentation/widgets/auction_product_context.dart';
import '../theme/home_tokens.dart';
import 'home_section.dart';
import '../../../../core/widgets/luxe/press_tilt.dart';
import '../../../../core/widgets/luxe/scroll_reveal.dart';

const _liveQuery = AuctionFeedQuery(kind: AuctionFeedKind.live);

/// Live auctions rail with ticking countdowns. Hides itself when there is
/// nothing live or the feed is unavailable — home never shows a hard error.
class HomeLiveAuctions extends ConsumerWidget {
  const HomeLiveAuctions({super.key});

  static const _cardWidth = 228.0;
  /// Image (1:1) + title + one meta line + bid block, with text-scale headroom.
  static const _railHeight = 360.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(auctionFeedProvider(_liveQuery));
    final live = feed.items
        .where((a) => a.isLive || a.isUpcoming)
        .take(12)
        .toList(growable: false);
    final loading = feed.isLoading && feed.items.isEmpty;
    if (!loading && live.isEmpty) return const SizedBox.shrink();

    final gutter = homeGutter(context);
    return Padding(
      padding: const EdgeInsets.only(top: HomeSpace.section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: gutter),
            child: HomeSectionHeading(
              index: '02',
              leading: const _LivePulse(),
              eyebrow: context.tr(HomeL10n.auctionsEyebrow),
              title: context.tr(HomeL10n.auctionsTitle),
              trailing: HomeArrowLink(
                label: context.tr(RemainingL10n.homeSeeAll),
                onTap: () => context.openRoute(AppRouteNames.auctions),
              ),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: _railHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: gutter),
              itemCount: loading ? 3 : live.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, i) => SizedBox(
                width: _cardWidth,
                child: ScrollReveal(
                  delay: HomeMotion.stagger * i.clamp(0, 4),
                  child: loading
                      ? const _SkeletonCard()
                      : _AuctionCard(auction: live[i]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuctionCard extends StatelessWidget {
  const _AuctionCard({required this.auction});

  final AuctionListing auction;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    final bid = auction.highestBidAmount ?? auction.minimumBid;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final image = auction.imageUrl;
    final deadline = auctionDeadline(auction);
    final meta = auctionProductContextLine(auction);
    // Fixed-height rail cards must stay stable under accessibility text scale.
    final scaler = MediaQuery.textScalerOf(context);
    final clamped = MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: scaler.clamp(minScaleFactor: 1, maxScaleFactor: 1.15),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(HomeSpace.radius),
          border: Border.all(color: palette.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(HomeSpace.radius - 6),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(
                        color: palette.surfaceRaised,
                        child: image == null || image.isEmpty
                            ? Icon(
                                Icons.diamond_outlined,
                                size: 40,
                                color: palette.inkFaint,
                              )
                            : AppNetworkImage(
                                url: image,
                                memCacheWidth: (228 * dpr).round(),
                              ),
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: _PhaseChip(auction: auction),
                      ),
                      if (deadline != null)
                        Positioned(
                          left: 10,
                          right: 10,
                          bottom: 10,
                          child: _Countdown(
                            deadline: deadline,
                            upcoming: auction.isUpcoming,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auction.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: HomeType.label(palette.ink, size: 14),
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: HomeType.label(palette.inkMuted, size: 11),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      context.tr(HomeL10n.currentBid).toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: HomeType.eyebrow(
                        palette.inkFaint,
                      ).copyWith(fontSize: 9.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      auctionBidAmount(bid),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: HomeType.display(22, palette.ink),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return PressTilt(
      semanticLabel: auction.title,
      onTap: () =>
          context.openRoute(AppRouteNames.auctionDetailPath(auction.id)),
      child: clamped,
    );
  }
}

/// Phase pill driven by auction data — Live, Upcoming, Ended, Sold, etc.
class _PhaseChip extends StatelessWidget {
  const _PhaseChip({required this.auction});

  final AuctionListing auction;

  @override
  Widget build(BuildContext context) {
    final a = auction;
    final tone = a.isLive
        ? const Color(0xFFE5484D)
        : a.isUpcoming
        ? const Color(0xFFE8A838)
        : const Color(0xFFB0A99C);
    final label = a.isLive
        ? context.tr(HomeL10n.live)
        : a.phaseLabel;

    Widget dot = Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(shape: BoxShape.circle, color: tone),
    );
    if (a.isLive) {
      dot = const _LivePulse(size: 6);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: const ShapeDecoration(
        color: Color(0xB3000000),
        shape: StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          dot,
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: HomeType.eyebrow(Colors.white).copyWith(fontSize: 9.5),
          ),
        ],
      ),
    );
  }
}

/// Breathing red dot signalling a live room.
class _LivePulse extends StatelessWidget {
  const _LivePulse({this.size = 7});

  final double size;

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFE5484D),
      ),
    );
    if (MediaQuery.disableAnimationsOf(context)) return dot;
    return dot
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(begin: 0.75, end: 1.15, duration: 900.ms)
        .fade(begin: 0.55, end: 1, duration: 900.ms);
  }
}

/// Frosted countdown chip; only this widget rebuilds every second.
class _Countdown extends StatefulWidget {
  const _Countdown({required this.deadline, required this.upcoming});

  final DateTime deadline;
  final bool upcoming;

  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = widget.deadline.difference(DateTime.now());
    String two(int v) => v.toString().padLeft(2, '0');
    final text = left.isNegative
        ? context.tr(HomeL10n.ended)
        : left.inDays > 0
        ? '${left.inDays}d ${two(left.inHours % 24)}h ${two(left.inMinutes % 60)}m'
        : '${two(left.inHours)}:${two(left.inMinutes % 60)}:${two(left.inSeconds % 60)}';
    final urgent = !widget.upcoming && !left.isNegative && left.inMinutes < 15;
    final caption = widget.upcoming ? 'Starts in' : context.tr(HomeL10n.endsIn);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xD9FFFFFF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: HomeType.label(const Color(0xFF6A645A), size: 11),
            ),
          ),
          Text(
            text,
            style: HomeType.figure(
              urgent ? const Color(0xFFC2272D) : const Color(0xFF16140F),
              size: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    Widget bar(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        borderRadius: BorderRadius.circular(6),
      ),
    );
    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(HomeSpace.radius),
        border: Border.all(color: palette.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: palette.surfaceRaised,
                  borderRadius: BorderRadius.circular(HomeSpace.radius - 6),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bar(150, 12),
                  const SizedBox(height: 8),
                  bar(90, 12),
                  const SizedBox(height: 22),
                  bar(110, 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (MediaQuery.disableAnimationsOf(context)) return card;
    return card
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 1400.ms,
          color: palette.isDark
              ? const Color(0x14FFFFFF)
              : const Color(0x66FFFFFF),
        );
  }
}
