import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:video_player/video_player.dart';

import '../../../../../core/error/result.dart';
import '../../../data/repositories/live_show_repository_impl.dart';
import '../../../domain/models/live_show_models.dart';

/// Picks the player for `show.provider` and reports whether video is on
/// screen through [onVideo]. Plays only while [active] (screen in the
/// foreground and the show on air).
class LiveShowPlayer extends StatelessWidget {
  const LiveShowPlayer({
    required this.show,
    required this.active,
    required this.muted,
    required this.onVideo,
    required this.onEnded,
    super.key,
  });

  final LiveShow show;
  final bool active;
  final bool muted;
  final ValueChanged<bool> onVideo;

  /// The server said the show has ended (viewer-token 400).
  final VoidCallback onEnded;

  @override
  Widget build(BuildContext context) {
    if (!active) return const SizedBox.expand();
    return switch (show.provider) {
      LiveProvider.livekit => _LiveKitPlayer(
        show: show,
        muted: muted,
        onVideo: onVideo,
        onEnded: onEnded,
      ),
      LiveProvider.awsIvs when (show.playbackUrl ?? '').isNotEmpty =>
        _HlsPlayer(url: show.playbackUrl!, muted: muted, onVideo: onVideo),
      LiveProvider.cloudflare when (show.playbackUrl ?? '').isNotEmpty =>
        _CloudflarePlayer(url: show.playbackUrl!, onVideo: onVideo),
      _ => _Unsupported(onVideo: onVideo),
    };
  }
}

/// LiveKit: hidden subscribe-only viewer; renders the `seller` tracks and
/// rejoins 3 s after any drop it did not ask for.
class _LiveKitPlayer extends ConsumerStatefulWidget {
  const _LiveKitPlayer({
    required this.show,
    required this.muted,
    required this.onVideo,
    required this.onEnded,
  });

  final LiveShow show;
  final bool muted;
  final ValueChanged<bool> onVideo;
  final VoidCallback onEnded;

  @override
  ConsumerState<_LiveKitPlayer> createState() => _LiveKitPlayerState();
}

class _LiveKitPlayerState extends ConsumerState<_LiveKitPlayer> {
  static const _sellerIdentity = 'seller';
  static const _retryDelay = Duration(seconds: 3);

  lk.Room? _room;
  lk.EventsListener<lk.RoomEvent>? _listener;
  lk.VideoTrack? _video;
  Timer? _retry;
  var _disposed = false;
  var _hadVideo = false;

  @override
  void initState() {
    super.initState();
    unawaited(_connect());
  }

  @override
  void didUpdateWidget(covariant _LiveKitPlayer old) {
    super.didUpdateWidget(old);
    if (old.muted != widget.muted) _applyMute();
  }

  @override
  void dispose() {
    _disposed = true;
    _retry?.cancel();
    unawaited(_teardown());
    super.dispose();
  }

  Future<void> _connect() async {
    if (_disposed) return;
    // A fresh token on every (re)connect; never reuse one.
    final token = await ref
        .read(liveShowRepositoryProvider)
        .viewerToken(widget.show.id);
    if (_disposed) return;
    final value = switch (token) {
      Success(:final value) => value,
      ResultFailure(:final failure) => () {
        if (failure.message.toLowerCase().contains('ended')) {
          widget.onEnded();
        } else {
          _scheduleRetry();
        }
        return null;
      }(),
    };
    if (value == null) return;
    final url = value.serverUrl ?? widget.show.playbackUrl;
    if (url == null || url.isEmpty) {
      _scheduleRetry();
      return;
    }

    final room = lk.Room(
      roomOptions: const lk.RoomOptions(adaptiveStream: true),
    );
    final listener = room.createListener();
    listener.on<lk.RoomDisconnectedEvent>((event) {
      if (event.reason == lk.DisconnectReason.clientInitiated) return;
      _log('dropped: ${event.reason}');
      _setVideo(null);
      _scheduleRetry();
    });
    room.addListener(_sync);
    _room = room;
    _listener = listener;
    try {
      await room.connect(url, value.token);
      if (_disposed) {
        await _teardown();
        return;
      }
      _sync();
    } catch (e) {
      _log('connect failed: $e');
      await _teardown();
      _scheduleRetry();
    }
  }

  void _scheduleRetry() {
    if (_disposed) return;
    _retry?.cancel();
    _retry = Timer(_retryDelay, () async {
      await _teardown();
      // The screen stops rendering this player once the show ends.
      unawaited(_connect());
    });
  }

  Future<void> _teardown() async {
    final room = _room;
    final listener = _listener;
    _room = null;
    _listener = null;
    if (room == null) return;
    room.removeListener(_sync);
    await listener?.dispose();
    try {
      await room.disconnect();
    } catch (_) {}
    await room.dispose();
  }

  lk.RemoteParticipant? get _seller =>
      _room?.remoteParticipants[_sellerIdentity];

  /// Picks up the seller's video whenever the room changes.
  void _sync() {
    final seller = _seller;
    lk.VideoTrack? video;
    if (seller != null) {
      for (final pub in seller.videoTrackPublications) {
        final track = pub.track;
        if (pub.subscribed && !pub.muted && track != null) {
          video = track;
          break;
        }
      }
    }
    _setVideo(video);
    _applyMute();
  }

  void _setVideo(lk.VideoTrack? video) {
    if (_disposed || identical(video, _video)) return;
    setState(() => _video = video);
    final has = video != null;
    if (has != _hadVideo) {
      _hadVideo = has;
      widget.onVideo(has);
    }
  }

  void _applyMute() {
    final seller = _seller;
    if (seller == null) return;
    for (final pub in seller.audioTrackPublications) {
      unawaited(widget.muted ? pub.disable() : pub.enable());
    }
  }

  @override
  Widget build(BuildContext context) {
    final video = _video;
    if (video == null) return const SizedBox.expand();
    return lk.VideoTrackRenderer(
      video,
      key: ValueKey(video.sid),
      fit: lk.VideoViewFit.contain,
    );
  }

  static void _log(String m) {
    if (kDebugMode) debugPrint('[LiveKitPlayer] $m');
  }
}

/// AWS IVS low-latency HLS.
class _HlsPlayer extends StatefulWidget {
  const _HlsPlayer({
    required this.url,
    required this.muted,
    required this.onVideo,
  });

  final String url;
  final bool muted;
  final ValueChanged<bool> onVideo;

  @override
  State<_HlsPlayer> createState() => _HlsPlayerState();
}

class _HlsPlayerState extends State<_HlsPlayer> {
  late final VideoPlayerController _controller;
  Timer? _retry;
  var _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    unawaited(_start());
  }

  Future<void> _start() async {
    try {
      await _controller.initialize();
      await _controller.setVolume(widget.muted ? 0 : 1);
      await _controller.play();
      if (!mounted) return;
      setState(() => _ready = true);
      widget.onVideo(true);
    } catch (_) {
      if (!mounted) return;
      widget.onVideo(false);
      _retry = Timer(const Duration(seconds: 3), () {
        if (mounted) unawaited(_start());
      });
    }
  }

  @override
  void didUpdateWidget(covariant _HlsPlayer old) {
    super.didUpdateWidget(old);
    if (old.muted != widget.muted) {
      unawaited(_controller.setVolume(widget.muted ? 0 : 1));
    }
  }

  @override
  void dispose() {
    _retry?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SizedBox.expand();
    return Center(
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: VideoPlayer(_controller),
      ),
    );
  }
}

/// Cloudflare's embeddable player page. Browser broadcasts there are
/// WebRTC, which HLS cannot play, so the page is used as is.
class _CloudflarePlayer extends StatelessWidget {
  const _CloudflarePlayer({required this.url, required this.onVideo});

  final String url;
  final ValueChanged<bool> onVideo;

  String get _src =>
      '$url${url.contains('?') ? '&' : '?'}autoplay=true&muted=true';

  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(_src)),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        mediaPlaybackRequiresUserGesture: false,
        allowsInlineMediaPlayback: true,
        transparentBackground: true,
        disableContextMenu: true,
        supportZoom: false,
      ),
      onLoadStop: (_, _) => onVideo(true),
    );
  }
}

/// IVS real-time needs a native SDK the app does not ship yet.
class _Unsupported extends StatefulWidget {
  const _Unsupported({required this.onVideo});

  final ValueChanged<bool> onVideo;

  @override
  State<_Unsupported> createState() => _UnsupportedState();
}

class _UnsupportedState extends State<_Unsupported> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onVideo(false));
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Text(
          "Can't play this show in the app yet. You can still bid and chat.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
