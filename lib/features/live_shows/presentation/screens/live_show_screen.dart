import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/luxe_scope.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../application/live_show_room.dart';
import '../../domain/live_format.dart';
import '../../domain/models/live_show_models.dart';
import '../live_show_actions.dart';
import '../widgets/live_auction_dock.dart';
import '../widgets/live_chat_feed.dart';
import '../widgets/live_comment_bar.dart';
import '../widgets/live_hearts.dart';
import '../widgets/live_lineup_sheet.dart';
import '../widgets/live_stage_tokens.dart';
import '../widgets/player/live_show_player.dart';

/// Full-screen live show: video edge to edge, the seller and viewer count
/// on top, comments rising bottom-left with hearts on the right, and the
/// auction dock above the comment box, so watching, asking and bidding
/// never leave one screen.
class LiveShowScreen extends ConsumerStatefulWidget {
  const LiveShowScreen({required this.showId, super.key});

  final String showId;

  @override
  ConsumerState<LiveShowScreen> createState() => _LiveShowScreenState();
}

class _LiveShowScreenState extends ConsumerState<LiveShowScreen> {
  final _hearts = LiveHeartsController();
  late final AppLifecycleListener _lifecycle;
  final _subs = <StreamSubscription<Object>>[];

  var _foreground = true;
  var _hasVideo = false;
  var _muted = false;
  var _showComments = true;
  LiveAuctionLot? _outbid;
  LiveAuctionLot? _won;
  Timer? _outbidTimer;

  LiveShowRoomController get _room =>
      ref.read(liveShowRoomProvider(widget.showId).notifier);

  @override
  void initState() {
    super.initState();
    unawaited(WakelockPlus.enable().catchError((Object _) {}));
    _lifecycle = AppLifecycleListener(
      onHide: () {
        if (!_foreground) return;
        setState(() => _foreground = false);
        _room.pause();
      },
      onShow: () {
        if (_foreground) return;
        setState(() => _foreground = true);
        _room.resume();
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _subs
        ..add(_room.notices.listen(_onNotice))
        ..add(_room.hearts.listen((n) => _hearts.burst(n)));
    });
  }

  @override
  void dispose() {
    _outbidTimer?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
    _lifecycle.dispose();
    _hearts.dispose();
    unawaited(WakelockPlus.disable().catchError((Object _) {}));
    super.dispose();
  }

  void _onNotice(LiveNotice notice) {
    if (!mounted) return;
    switch (notice) {
      case LiveOutbidNotice(:final lot):
        AppHaptics.warning();
        _outbidTimer?.cancel();
        setState(() => _outbid = lot);
        _outbidTimer = Timer(const Duration(seconds: 6), () {
          if (mounted) setState(() => _outbid = null);
        });
      case LiveWonNotice(:final lot):
        AppHaptics.success();
        setState(() {
          _outbid = null;
          _won = lot;
        });
    }
  }

  void _openLineup({bool results = false}) {
    showLiveLineupSheet(
      context,
      showId: widget.showId,
      resultsFirst: results,
      onOpenOrder: (id) => openLiveOrder(context, id),
    );
  }

  void _heart() {
    _hearts.burst(1, own: true);
    _room.tapHeart();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(liveShowRoomProvider(widget.showId));
    final show = s.show;
    if (show == null) {
      return _Shell(
        child: s.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : LuxeScope(
                child: Builder(
                  builder: (context) => Material(
                    child: LuxeStateView(
                      icon: Icons.videocam_off_outlined,
                      tone: LuxeTone.error,
                      title: 'Show unavailable',
                      message:
                          s.errorMessage ??
                          'This live show could not be found.',
                      actionLabel: 'Try again',
                      onAction: _room.retry,
                      secondaryLabel: 'Browse live shows',
                      onSecondary: () =>
                          context.switchToRoute(AppRouteNames.liveShows),
                    ),
                  ),
                ),
              ),
      );
    }

    final signedIn = ref.watch(authProvider.select((a) => a.isAuthenticated));
    final ended = show.hasEnded;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    // Every provider has a player now; an unknown one is probed by token.
    final waiting = !ended && (!show.isStreaming || !_hasVideo);

    return _Shell(
      child: Stack(
        fit: StackFit.expand,
        children: [
          _Poster(url: show.posterUrl, dim: _hasVideo && !ended ? 0 : 0.35),
          if (!ended)
            LiveShowPlayer(
              show: show,
              active: _foreground,
              muted: _muted,
              onVideo: (v) {
                if (mounted && v != _hasVideo) setState(() => _hasVideo = v);
              },
              onEnded: _room.refreshShow,
            ),
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 180,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: LiveStage.topScrim),
              ),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 460,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: LiveStage.bottomScrim),
              ),
            ),
          ),
          if (waiting)
            const Center(
              child: _StatusPill(text: "Waiting for the seller's video"),
            ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(
                  show: show,
                  muted: _muted,
                  canMute: !ended,
                  onBack: () =>
                      context.goBack(fallbackLocation: AppRouteNames.liveShows),
                  onMute: () => setState(() => _muted = !_muted),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  transitionBuilder: (child, a) => SizeTransition(
                    sizeFactor: a,
                    child: FadeTransition(opacity: a, child: child),
                  ),
                  child: _outbid == null || ended
                      ? const SizedBox(width: double.infinity)
                      : _OutbidBanner(
                          key: ValueKey(_outbid!.id),
                          lot: s.current?.id == _outbid!.id
                              ? s.current!
                              : _outbid!,
                          onClose: () => setState(() => _outbid = null),
                        ),
                ),
                if (ended) ...[
                  const Spacer(),
                  _EndedPanel(
                    hasResults: s.results.isNotEmpty,
                    onResults: () => _openLineup(results: true),
                    onBrowse: () =>
                        context.switchToRoute(AppRouteNames.liveShows),
                  ),
                ] else ...[
                  // Comments take whatever height the dock leaves, up to
                  // about a dozen lines, so small screens never overflow.
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomLeft,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                child: _showComments
                                    ? ConstrainedBox(
                                        key: const ValueKey('chat'),
                                        constraints: const BoxConstraints(
                                          maxHeight: 210,
                                        ),
                                        child: LiveChatFeed(items: s.feed),
                                      )
                                    : const SizedBox(
                                        key: ValueKey('none'),
                                        height: 8,
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            flex: 0,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.bottomCenter,
                              child: _Rail(
                                commentsOn: _showComments,
                                lineupCount:
                                    s.upNext.length +
                                    (s.current == null ? 0 : 1),
                                onComments: () => setState(
                                  () => _showComments = !_showComments,
                                ),
                                onLineup: _openLineup,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Hidden, not removed, under the keyboard: the bid
                  // number pad raises it and must hand its amount back.
                  Visibility(
                    visible: !keyboard,
                    maintainState: true,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: LiveAuctionDock(
                        showId: widget.showId,
                        onOpenLineup: _openLineup,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: LiveCommentBar(
                      signedIn: signedIn,
                      muted: s.chatMuted,
                      onSend: _room.sendChat,
                      onHeart: _heart,
                      onSignIn: () => openLiveSignIn(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!ended)
            Positioned(
              right: 12,
              bottom: MediaQuery.paddingOf(context).bottom + 60,
              width: 60,
              height: 340,
              child: LiveHeartsLayer(controller: _hearts),
            ),
          if (_won != null)
            _WonOverlay(
              lot: _won!,
              orderId: s.me?.winFor(_won!.id)?.orderId,
              onViewOrder: (id) {
                setState(() => _won = null);
                openLiveOrder(context, id);
              },
              onClose: () => setState(() => _won = null),
            ),
        ],
      ),
    );
  }
}

/// Dark, edge-to-edge frame with light status-bar icons.
class _Shell extends StatelessWidget {
  const _Shell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: true,
        body: child,
      ),
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster({required this.url, required this.dim});

  final String? url;
  final double dim;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (url != null)
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: AppNetworkImage(url: url!),
          ),
        if (url != null) AppNetworkImage(url: url!, fit: BoxFit.contain),
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          color: Colors.black.withValues(alpha: url == null ? 1 : 0.3 + dim),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.show,
    required this.muted,
    required this.canMute,
    required this.onBack,
    required this.onMute,
  });

  final LiveShow show;
  final bool muted;
  final bool canMute;
  final VoidCallback onBack;
  final VoidCallback onMute;

  @override
  Widget build(BuildContext context) {
    final logo = show.seller.logo;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _GlassIcon(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Back',
                onTap: onBack,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
                  decoration: BoxDecoration(
                    color: LiveStage.glass,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        foregroundImage: logo == null
                            ? null
                            : NetworkImage(logo),
                        child: Text(
                          show.seller.companyName.isEmpty
                              ? '?'
                              : show.seller.companyName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          show.seller.companyName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!show.hasEnded) ...[
                        const LiveBadge(compact: true),
                        const SizedBox(width: 6),
                        LiveViewerPill(label: liveCount(show.viewerCount)),
                      ],
                    ],
                  ),
                ),
              ),
              if (canMute) ...[
                const SizedBox(width: 8),
                _GlassIcon(
                  icon: muted
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded,
                  tooltip: muted ? 'Unmute' : 'Mute',
                  onTap: onMute,
                ),
              ],
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(52, 8, 8, 0),
            child: Text(
              show.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.3,
                shadows: [Shadow(blurRadius: 8, color: Color(0xAA000000))],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({
    required this.commentsOn,
    required this.lineupCount,
    required this.onComments,
    required this.onLineup,
  });

  final bool commentsOn;
  final int lineupCount;
  final VoidCallback onComments;
  final VoidCallback onLineup;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _GlassIcon(
          icon: Icons.format_list_bulleted_rounded,
          tooltip: 'Items in this show',
          badge: lineupCount,
          onTap: onLineup,
        ),
        const SizedBox(height: 10),
        _GlassIcon(
          icon: commentsOn
              ? Icons.chat_bubble_rounded
              : Icons.chat_bubble_outline_rounded,
          tooltip: commentsOn ? 'Hide comments' : 'Show comments',
          onTap: onComments,
        ),
      ],
    );
  }
}

class _GlassIcon extends StatelessWidget {
  const _GlassIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: InkResponse(
          onTap: onTap,
          radius: 26,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: LiveStage.glass,
                  border: Border.all(color: LiveStage.glassBorder),
                ),
                child: Icon(icon, color: Colors.white, size: 21),
              ),
              if (badge > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 18),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: LiveStage.gold,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$badge',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF16140F),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: LiveStage.glassStrong,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _OutbidBanner extends StatelessWidget {
  const _OutbidBanner({required this.lot, required this.onClose, super.key});

  final LiveAuctionLot lot;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
        decoration: BoxDecoration(
          color: LiveStage.urgent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: LiveStage.urgent.withValues(alpha: 0.4),
              blurRadius: 18,
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.trending_up_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "You've been outbid",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${lot.title} is now at ${liveInr(lot.currentBid ?? 0)}. '
                    'Bid ${liveInr(lot.minNextBid)} to lead again.',
                    style: const TextStyle(color: Colors.white, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Dismiss',
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _EndedPanel extends StatelessWidget {
  const _EndedPanel({
    required this.hasResults,
    required this.onResults,
    required this.onBrowse,
  });

  final bool hasResults;
  final VoidCallback onResults;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.videocam_off_rounded, color: Colors.white, size: 36),
          const SizedBox(height: 12),
          const Text(
            'This live show has ended',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          if (hasResults) ...[
            _StageButton(label: 'See results', onTap: onResults, primary: true),
            const SizedBox(height: 10),
          ],
          _StageButton(label: 'Browse live shows', onTap: onBrowse),
        ],
      ),
    );
  }
}

class _StageButton extends StatelessWidget {
  const _StageButton({
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Material(
        color: primary ? LiveStage.gold : Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: primary ? const Color(0xFF16140F) : Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WonOverlay extends StatelessWidget {
  const _WonOverlay({
    required this.lot,
    required this.orderId,
    required this.onViewOrder,
    required this.onClose,
  });

  final LiveAuctionLot lot;
  final String? orderId;
  final ValueChanged<String> onViewOrder;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    Widget card = Container(
      margin: const EdgeInsets.symmetric(horizontal: 28),
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF15130F),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: LiveStage.gold.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: LiveStage.gold.withValues(alpha: 0.35),
            blurRadius: 40,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events_rounded, color: LiveStage.gold, size: 54),
          const SizedBox(height: 12),
          const Text(
            'You won!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${lot.title} for ${liveInr(lot.currentBid ?? 0)}',
            textAlign: TextAlign.center,
            style: TextStyle(color: LiveStage.inkMuted, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            'Paid from your wallet. The seller will ship it to your '
            'delivery address.',
            textAlign: TextAlign.center,
            style: TextStyle(color: LiveStage.inkFaint, fontSize: 12.5),
          ),
          const SizedBox(height: 20),
          if (orderId != null && orderId!.isNotEmpty)
            _StageButton(
              label: 'View order',
              primary: true,
              onTap: () => onViewOrder(orderId!),
            )
          else
            const _StatusPill(text: 'Creating your order…'),
          const SizedBox(height: 10),
          _StageButton(label: 'Keep watching', onTap: onClose),
        ],
      ),
    );
    if (!still) {
      card = card
          .animate()
          .fadeIn(duration: 220.ms)
          .scale(
            begin: const Offset(0.85, 0.85),
            end: const Offset(1, 1),
            duration: 420.ms,
            curve: Curves.easeOutBack,
          );
    }
    return Positioned.fill(
      child: GestureDetector(
        onTap: onClose,
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.55),
          child: Center(
            child: GestureDetector(onTap: () {}, child: card),
          ),
        ),
      ),
    );
  }
}
