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
import '../../../../core/widgets/app_network_image.dart';
import '../../application/live_show_room.dart';
import '../../domain/live_format.dart';
import '../../domain/models/live_show_models.dart';
import '../live_show_actions.dart';
import '../widgets/live_auction_dock.dart';
import '../widgets/live_aurora.dart';
import '../widgets/live_chat_feed.dart';
import '../widgets/live_comment_bar.dart';
import '../widgets/live_hearts.dart';
import '../widgets/live_lineup_sheet.dart';
import '../widgets/live_outbid_banner.dart';
import '../widgets/live_stage_tokens.dart';
import '../widgets/live_won_overlay.dart';
import '../widgets/player/live_show_player.dart';

/// Full-screen live show. Three bands, each with one job:
///  • top — who is presenting and whether they are live;
///  • middle — the video, with the conversation on the left and the
///    lineup / chat toggles on the right;
///  • bottom — the bidding card, then the comment field and heart.
/// Watching, asking and bidding never leave this one screen.
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

  void _back() => context.goBack(fallbackLocation: AppRouteNames.liveShows);

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(liveShowRoomProvider(widget.showId));
    final show = s.show;
    if (show == null) {
      return _Shell(
        child: AnimatedSwitcher(
          duration: LiveMotion.slow,
          child: s.isLoading
              ? _Joining(key: const ValueKey('joining'), onBack: _back)
              : _Unavailable(
                  key: const ValueKey('error'),
                  message:
                      s.errorMessage ?? 'This live show could not be found.',
                  onRetry: _room.retry,
                  onBrowse: () =>
                      context.switchToRoute(AppRouteNames.liveShows),
                  onBack: _back,
                ),
        ),
      );
    }

    final signedIn = ref.watch(authProvider.select((a) => a.isAuthenticated));
    final ended = show.hasEnded;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    // Every provider has a player now; an unknown one is probed by token.
    final waiting = !ended && (!show.isStreaming || !_hasVideo);
    final still = MediaQuery.disableAnimationsOf(context);

    Widget chrome = SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            show: show,
            muted: _muted,
            canMute: !ended,
            onBack: _back,
            onMute: () {
              AppHaptics.selection();
              setState(() => _muted = !_muted);
            },
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 420),
            switchInCurve: Curves.easeOutBack,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, a) => SizeTransition(
              sizeFactor: a,
              alignment: Alignment.topCenter,
              child: FadeTransition(
                opacity: a,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, -0.4),
                    end: Offset.zero,
                  ).animate(a),
                  child: child,
                ),
              ),
            ),
            child: _outbid == null || ended
                ? const SizedBox(width: double.infinity)
                : LiveOutbidBanner(
                    key: ValueKey(_outbid!.id),
                    lot: s.current?.id == _outbid!.id ? s.current! : _outbid!,
                    onClose: () => setState(() => _outbid = null),
                  ),
          ),
          if (ended) ...[
            const Spacer(),
            _EndedPanel(
              sellerName: show.seller.companyName,
              results: s.results,
              wins: s.me?.wins.length ?? 0,
              onResults: () => _openLineup(results: true),
              onBrowse: () => context.switchToRoute(AppRouteNames.liveShows),
            ),
          ] else ...[
            // Comments take whatever height the dock leaves, up to about a
            // dozen lines, so small screens never overflow.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 12, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: AnimatedSwitcher(
                          duration: LiveMotion.base,
                          transitionBuilder: (child, a) => FadeTransition(
                            opacity: a,
                            child: SlideTransition(
                              position: Tween(
                                begin: const Offset(-0.05, 0),
                                end: Offset.zero,
                              ).animate(a),
                              child: child,
                            ),
                          ),
                          child: _showComments
                              ? ConstrainedBox(
                                  key: const ValueKey('chat'),
                                  // Low and narrow: the stream stays clear.
                                  constraints: BoxConstraints(
                                    maxHeight: 168,
                                    maxWidth:
                                        MediaQuery.sizeOf(context).width * 0.72,
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
                    const SizedBox(width: 10),
                    Flexible(
                      flex: 0,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.bottomCenter,
                        child: _Rail(
                          commentsOn: _showComments,
                          lineupCount:
                              s.upNext.length + (s.current == null ? 0 : 1),
                          onComments: () =>
                              setState(() => _showComments = !_showComments),
                          onLineup: _openLineup,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Hidden, not removed, under the keyboard: the bid number pad
            // raises it and must hand its amount back.
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
    );
    if (!still) {
      chrome = chrome
          .animate()
          .fadeIn(duration: 500.ms, delay: 120.ms)
          .moveY(
            begin: 18,
            end: 0,
            duration: 600.ms,
            curve: LiveMotion.emphasized,
          );
    }

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
            height: 200,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: LiveStage.topScrim),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: ended ? 560 : 420,
            child: const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: LiveStage.bottomScrim),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, -0.35),
            child: AnimatedSwitcher(
              duration: LiveMotion.slow,
              child: waiting
                  ? _Waiting(key: const ValueKey('waiting'), show: show)
                  : const SizedBox.shrink(),
            ),
          ),
          chrome,
          if (!ended)
            Positioned(
              right: 12,
              bottom: MediaQuery.paddingOf(context).bottom + 60,
              width: 64,
              height: 360,
              child: LiveHeartsLayer(controller: _hearts),
            ),
          if (_won != null)
            LiveWonOverlay(
              key: ValueKey(_won!.id),
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

/// Black, edge-to-edge frame with light status-bar icons.
class _Shell extends StatelessWidget {
  const _Shell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: LiveStage.void_,
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
    if (url == null) return const LiveAurora();
    return Stack(
      fit: StackFit.expand,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: AppNetworkImage(url: url!),
        ),
        AppNetworkImage(url: url!, fit: BoxFit.contain),
        AnimatedContainer(
          duration: LiveMotion.slow,
          color: Colors.black.withValues(alpha: 0.3 + dim),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LiveIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Back',
                size: 40,
                onTap: onBack,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(4, 4, 14, 4),
                    decoration: BoxDecoration(
                      color: LiveStage.glass,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: LiveStage.glassBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LiveAvatar(
                          name: show.seller.companyName,
                          logo: show.seller.logo,
                          size: 32,
                          ring: !show.hasEnded,
                        ),
                        const SizedBox(width: 9),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                show.seller.companyName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: LiveType.label(13.5),
                              ),
                              const SizedBox(height: 2),
                              if (show.hasEnded)
                                Text(
                                  'Show ended',
                                  style: LiveType.body(
                                    11,
                                    color: LiveStage.inkFaint,
                                  ),
                                )
                              else
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: LiveStage.live,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'LIVE',
                                        style: LiveType.eyebrow(
                                          color: LiveStage.ink,
                                          size: 9,
                                        ).copyWith(letterSpacing: 1.2),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.visibility_outlined,
                                        size: 11,
                                        color: LiveStage.inkMuted,
                                      ),
                                      const SizedBox(width: 3),
                                      AnimatedSwitcher(
                                        duration: LiveMotion.base,
                                        child: Text(
                                          liveCount(show.viewerCount),
                                          key: ValueKey(show.viewerCount),
                                          style: LiveType.figure(
                                            11,
                                            color: LiveStage.inkMuted,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (canMute)
                LiveIconButton(
                  icon: muted
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded,
                  tooltip: muted ? 'Unmute' : 'Mute',
                  size: 40,
                  active: muted,
                  onTap: onMute,
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 10, 56, 0),
            child: Text(
              show.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LiveType.display(18, italic: true, height: 1.15).copyWith(
                shadows: const [
                  Shadow(blurRadius: 12, color: Color(0xCC000000)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Labelled toggles on the right edge: the lineup (with how many pieces
/// are up or coming) and the chat.
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
    Widget item(Widget button, String label) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        button,
        const SizedBox(height: 4),
        Text(
          label,
          style: LiveType.label(10, color: LiveStage.inkMuted).copyWith(
            shadows: const [Shadow(blurRadius: 6, color: Color(0xAA000000))],
          ),
        ),
      ],
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        item(
          LiveIconButton(
            icon: Icons.view_agenda_outlined,
            tooltip: 'Pieces in this show',
            badge: lineupCount,
            onTap: onLineup,
          ),
          'Lineup',
        ),
        const SizedBox(height: 14),
        item(
          LiveIconButton(
            icon: commentsOn
                ? Icons.chat_bubble_rounded
                : Icons.chat_bubble_outline_rounded,
            tooltip: commentsOn ? 'Hide comments' : 'Show comments',
            active: commentsOn,
            onTap: onComments,
          ),
          commentsOn ? 'Chat on' : 'Chat off',
        ),
      ],
    );
  }
}

/// Seller's portrait breathing inside rings while the video connects.
class _Waiting extends StatelessWidget {
  const _Waiting({required this.show, super.key});

  final LiveShow show;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    Widget ring(int i) {
      Widget r = Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: LiveStage.champagne.withValues(alpha: 0.45),
          ),
        ),
      );
      if (!still) {
        r = r
            .animate(onPlay: (c) => c.repeat(), delay: (i * 700).ms)
            .scaleXY(
              begin: 0.45,
              end: 1,
              duration: 2100.ms,
              curve: Curves.easeOut,
            )
            .fade(begin: 1, end: 0, duration: 2100.ms);
      }
      return r;
    }

    return Semantics(
      liveRegion: true,
      label: "Waiting for the seller's video",
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                for (var i = 0; i < 3; i++) ring(i),
                LiveAvatar(
                  name: show.seller.companyName,
                  logo: show.seller.logo,
                  size: 62,
                  ring: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            "Waiting for the seller's video",
            style: LiveType.display(22).copyWith(
              shadows: const [Shadow(blurRadius: 10, color: Color(0xCC000000))],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'It starts here the moment it arrives.',
            style: LiveType.body(12.5, color: LiveStage.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _EndedPanel extends StatelessWidget {
  const _EndedPanel({
    required this.sellerName,
    required this.results,
    required this.wins,
    required this.onResults,
    required this.onBrowse,
  });

  final String sellerName;
  final List<LiveAuctionLot> results;
  final int wins;
  final VoidCallback onResults;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    final sold = results.where((l) => l.status == LotStatus.sold).length;
    final summary = [
      if (results.isNotEmpty) '$sold of ${results.length} pieces sold',
      if (wins > 0) 'you won $wins',
    ].join(' · ');

    Widget enter(Widget w, int i) => still
        ? w
        : w
              .animate(delay: (100 * i).ms)
              .fadeIn(duration: 420.ms)
              .moveY(begin: 14, end: 0, curve: LiveMotion.emphasized);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          enter(
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: LiveStage.hairlineStrong),
                color: LiveStage.glass,
              ),
              child: const Icon(
                Icons.nightlight_round,
                color: LiveStage.champagne,
                size: 24,
              ),
            ),
            0,
          ),
          const SizedBox(height: 18),
          enter(
            Text(
              'The show has ended',
              textAlign: TextAlign.center,
              style: LiveType.display(36),
            ),
            1,
          ),
          const SizedBox(height: 8),
          enter(
            Text(
              summary.isEmpty
                  ? 'Thanks for watching $sellerName.'
                  : '${summary[0].toUpperCase()}${summary.substring(1)}.',
              textAlign: TextAlign.center,
              style: LiveType.body(14),
            ),
            2,
          ),
          const SizedBox(height: 26),
          if (results.isNotEmpty) ...[
            enter(
              LiveButton(
                label: 'See results',
                icon: Icons.gavel_rounded,
                onTap: onResults,
              ),
              3,
            ),
            const SizedBox(height: 10),
          ],
          enter(
            LiveButton(
              label: 'Browse live shows',
              kind: results.isEmpty
                  ? LiveButtonKind.primary
                  : LiveButtonKind.secondary,
              onTap: onBrowse,
            ),
            4,
          ),
        ],
      ),
    );
  }
}

/// First load: aurora, a turning champagne ring and a quiet line.
class _Joining extends StatelessWidget {
  const _Joining({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    Widget ring = Container(
      width: 72,
      height: 72,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: [
            Colors.transparent,
            LiveStage.champagneDeep,
            LiveStage.champagneLight,
          ],
          stops: [0.2, 0.75, 1],
        ),
      ),
      child: Center(
        child: Container(
          width: 68,
          height: 68,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: LiveStage.void_,
          ),
          child: const Icon(
            Icons.diamond_outlined,
            color: LiveStage.champagne,
            size: 26,
          ),
        ),
      ),
    );
    if (!still) {
      ring = ring
          .animate(onPlay: (c) => c.repeat())
          .rotate(duration: 1400.ms, begin: 0, end: 1);
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        const LiveAurora(energy: 0.6),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ring,
              const SizedBox(height: 22),
              Text('Joining the show', style: LiveType.display(26)),
              const SizedBox(height: 6),
              Text(
                'Connecting you to the seller…',
                style: LiveType.body(13, color: LiveStage.inkMuted),
              ),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
            child: Align(
              alignment: Alignment.topLeft,
              child: LiveIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Back',
                size: 40,
                onTap: onBack,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({
    required this.message,
    required this.onRetry,
    required this.onBrowse,
    required this.onBack,
    super.key,
  });

  final String message;
  final Future<void> Function() onRetry;
  final VoidCallback onBrowse;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: LiveStage.urgent.withValues(alpha: 0.1),
            border: Border.all(color: LiveStage.urgent.withValues(alpha: 0.5)),
          ),
          child: const Icon(
            Icons.videocam_off_outlined,
            color: LiveStage.urgent,
            size: 26,
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Show unavailable',
          textAlign: TextAlign.center,
          style: LiveType.display(32),
        ),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center, style: LiveType.body(14)),
        const SizedBox(height: 26),
        LiveButton(
          label: 'Try again',
          icon: Icons.refresh_rounded,
          onTap: () => unawaited(onRetry()),
        ),
        const SizedBox(height: 10),
        LiveButton(
          label: 'Browse live shows',
          kind: LiveButtonKind.secondary,
          onTap: onBrowse,
        ),
      ],
    );
    if (!still) {
      content = content
          .animate()
          .fadeIn(duration: 420.ms)
          .moveY(begin: 14, end: 0, curve: LiveMotion.emphasized);
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        const LiveAurora(),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: content,
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
            child: Align(
              alignment: Alignment.topLeft,
              child: LiveIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Back',
                size: 40,
                onTap: onBack,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
