import 'dart:async';
import 'dart:convert';

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
    return _playerFor(
      show.provider,
      show: show,
      muted: muted,
      onVideo: onVideo,
      onEnded: onEnded,
    );
  }
}

Widget _playerFor(
  LiveProvider provider, {
  required LiveShow show,
  required bool muted,
  required ValueChanged<bool> onVideo,
  required VoidCallback onEnded,
}) {
  final url = show.playbackUrl ?? '';
  return switch (provider) {
    LiveProvider.livekit => _LiveKitPlayer(
      show: show,
      muted: muted,
      onVideo: onVideo,
      onEnded: onEnded,
    ),
    LiveProvider.awsIvsRealtime => _IvsRealtimePlayer(
      show: show,
      muted: muted,
      onVideo: onVideo,
      onEnded: onEnded,
    ),
    LiveProvider.awsIvs when url.isNotEmpty => _HlsPlayer(
      url: url,
      muted: muted,
      onVideo: onVideo,
    ),
    LiveProvider.cloudflare when url.isNotEmpty => _CloudflarePlayer(
      url: url,
      onVideo: onVideo,
    ),
    _ => _AutoPlayer(
      show: show,
      muted: muted,
      onVideo: onVideo,
      onEnded: onEnded,
    ),
  };
}

/// Provider missing, new, or without a playback URL: ask for a viewer
/// token and let its shape pick the player (a `serverUrl` means LiveKit,
/// none means an IVS stage). Re-checks every few seconds until one fits.
class _AutoPlayer extends ConsumerStatefulWidget {
  const _AutoPlayer({
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
  ConsumerState<_AutoPlayer> createState() => _AutoPlayerState();
}

class _AutoPlayerState extends ConsumerState<_AutoPlayer> {
  static const _retryDelay = Duration(seconds: 5);

  LiveProvider? _picked;
  var _unsupported = false;
  Timer? _retry;

  @override
  void initState() {
    super.initState();
    unawaited(_probe());
  }

  @override
  void dispose() {
    _retry?.cancel();
    super.dispose();
  }

  Future<void> _probe() async {
    final token = await ref
        .read(liveShowRepositoryProvider)
        .viewerToken(widget.show.id);
    if (!mounted) return;
    switch (token) {
      case Success(:final value):
        final server = value.serverUrl ?? '';
        _LiveKitPlayerState._log(
          'provider ${widget.show.provider.name}: token has '
          '${server.isEmpty ? 'no serverUrl, using IVS stage' : 'serverUrl, using LiveKit'}',
        );
        setState(() {
          _picked = server.isEmpty
              ? LiveProvider.awsIvsRealtime
              : LiveProvider.livekit;
          _unsupported = false;
        });
      case ResultFailure(:final failure):
        if (failure.message.toLowerCase().contains('ended')) {
          widget.onEnded();
          return;
        }
        _LiveKitPlayerState._log('no player: ${failure.message}');
        if (!_unsupported) {
          setState(() => _unsupported = true);
          widget.onVideo(false);
        }
        _retry = Timer(_retryDelay, () {
          if (mounted) unawaited(_probe());
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final picked = _picked;
    if (picked != null) {
      return _playerFor(
        picked,
        show: widget.show,
        muted: widget.muted,
        onVideo: widget.onVideo,
        onEnded: widget.onEnded,
      );
    }
    if (_unsupported) return const _Unsupported();
    return const SizedBox.expand();
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

  /// The `seller` participant; any participant sending video if the room
  /// names the seller differently.
  lk.RemoteParticipant? get _seller {
    final room = _room;
    if (room == null) return null;
    final named = room.remoteParticipants[_sellerIdentity];
    if (named != null) return named;
    for (final p in room.remoteParticipants.values) {
      if (p.videoTrackPublications.isNotEmpty) return p;
    }
    return null;
  }

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

/// Android WebView players draw into a Flutter texture rather than use
/// hybrid composition, which moves the whole UI over the stream onto the
/// platform thread and drops frames under the bid dock and chat.
const _hybridComposition = false;

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
        useHybridComposition: _hybridComposition,
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

/// AWS IVS real-time stage, subscribe only, through Amazon's web SDK in a
/// WebView (WebRTC). A fresh token joins on every (re)connect; a drop
/// rejoins after 3 s.
class _IvsRealtimePlayer extends ConsumerStatefulWidget {
  const _IvsRealtimePlayer({
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
  ConsumerState<_IvsRealtimePlayer> createState() => _IvsRealtimePlayerState();
}

class _IvsRealtimePlayerState extends ConsumerState<_IvsRealtimePlayer> {
  static const _sdk =
      'https://web-broadcast.live-video.net/1.41.0/amazon-ivs-web-broadcast.js';
  static const _retryDelay = Duration(seconds: 3);

  InAppWebViewController? _web;
  String? _token;
  var _generation = 0;
  var _hadVideo = false;
  var _joined = false;
  var _disposed = false;
  Timer? _retry;

  @override
  void initState() {
    super.initState();
    unawaited(_join());
  }

  @override
  void didUpdateWidget(covariant _IvsRealtimePlayer old) {
    super.didUpdateWidget(old);
    if (old.muted != widget.muted) {
      unawaited(
        _web
            ?.evaluateJavascript(source: 'window.setMuted(${widget.muted})')
            .catchError((Object _) => null),
      );
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _retry?.cancel();
    super.dispose();
  }

  Future<void> _join() async {
    final token = await ref
        .read(liveShowRepositoryProvider)
        .viewerToken(widget.show.id);
    if (_disposed) return;
    switch (token) {
      case Success(:final value):
        setState(() {
          _token = value.token;
          _generation++;
        });
      case ResultFailure(:final failure):
        if (failure.message.toLowerCase().contains('ended')) {
          widget.onEnded();
        } else {
          _scheduleRejoin();
        }
    }
  }

  void _scheduleRejoin() {
    if (_disposed) return;
    _setVideo(false);
    _retry?.cancel();
    _retry = Timer(_retryDelay, () => unawaited(_join()));
  }

  void _setVideo(bool has) {
    if (_disposed || has == _hadVideo) return;
    _hadVideo = has;
    widget.onVideo(has);
  }

  // The charset matters: inline HTML has none by default, and the SDK
  // (served without one) then fails to parse, so no video ever arrives.
  // WebKit ignores tracks added to a stream already playing, so every
  // change re-attaches a fresh MediaStream.
  String _html(String token) =>
      '''
<!doctype html><html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1">
<style>html,body{margin:0;height:100%;background:transparent;overflow:hidden}
video{position:fixed;inset:0;width:100%;height:100%;object-fit:contain}</style>
<script src="$_sdk" charset="utf-8"></script>
</head><body><video id="v" autoplay playsinline></video><script>
(function(){
  function post(n,d){try{window.flutter_inappwebview.callHandler(n,d)}catch(e){}}
  if(!window.IVSBroadcastClient){post('ivsError','sdk not loaded');return}
  var C=IVSBroadcastClient, video=document.getElementById('v');
  var media=new MediaStream(); video.muted=${widget.muted};
  window.setMuted=function(m){video.muted=m; if(!m) video.play().catch(function(){})};
  function play(){
    video.srcObject=new MediaStream(media.getTracks());
    video.play().catch(function(){video.muted=true;video.play().catch(function(){})});
  }
  var strategy={
    stageStreamsToPublish:function(){return []},
    shouldPublishParticipant:function(){return false},
    shouldSubscribeToParticipant:function(){return C.SubscribeType.AUDIO_VIDEO}
  };
  var stage=new C.Stage(${jsonEncode(token)},strategy), owner=null;
  stage.on(C.StageEvents.STAGE_PARTICIPANT_STREAMS_ADDED,function(p,streams){
    if(p.isLocal) return;
    streams.forEach(function(s){
      var t=s.mediaStreamTrack;
      if(t.kind==='video'){
        if(owner && owner!==p.id) return;
        owner=p.id;
        media.getVideoTracks().forEach(function(o){media.removeTrack(o)});
      }
      media.addTrack(t);
    });
    play();
    if(media.getVideoTracks().length) post('ivsVideo',true);
  });
  stage.on(C.StageEvents.STAGE_PARTICIPANT_STREAMS_REMOVED,function(p,streams){
    streams.forEach(function(s){try{media.removeTrack(s.mediaStreamTrack)}catch(e){}});
    if(media.getTracks().length) play();
    if(owner===p.id && !media.getVideoTracks().length){owner=null;post('ivsVideo',false)}
  });
  stage.on(C.StageEvents.STAGE_PARTICIPANT_LEFT,function(p){
    if(owner===p.id){owner=null;post('ivsVideo',false)}
  });
  stage.on(C.StageEvents.STAGE_CONNECTION_STATE_CHANGED,function(s){post('ivsState',String(s))});
  stage.join().catch(function(e){post('ivsError',String(e))});
})();
</script></body></html>''';

  @override
  Widget build(BuildContext context) {
    final token = _token;
    if (token == null) return const SizedBox.expand();
    return InAppWebView(
      key: ValueKey(_generation),
      initialData: InAppWebViewInitialData(
        data: _html(token),
        baseUrl: WebUri('https://web-broadcast.live-video.net/'),
      ),
      initialSettings: InAppWebViewSettings(
        useHybridComposition: _hybridComposition,
        javaScriptEnabled: true,
        mediaPlaybackRequiresUserGesture: false,
        allowsInlineMediaPlayback: true,
        transparentBackground: true,
        disableContextMenu: true,
        supportZoom: false,
        disableHorizontalScroll: true,
        disableVerticalScroll: true,
      ),
      onWebViewCreated: (c) {
        _web = c;
        c
          ..addJavaScriptHandler(
            handlerName: 'ivsVideo',
            callback: (args) => _setVideo(args.firstOrNull == true),
          )
          ..addJavaScriptHandler(
            handlerName: 'ivsState',
            callback: (args) {
              final s = '${args.firstOrNull}'.toLowerCase();
              if (s == 'connected') {
                _joined = true;
              } else if (s == 'errored' || (s == 'disconnected' && _joined)) {
                _joined = false;
                _LiveKitPlayerState._log('ivs stage $s');
                _scheduleRejoin();
              }
            },
          )
          ..addJavaScriptHandler(
            handlerName: 'ivsError',
            callback: (args) {
              _LiveKitPlayerState._log('ivs error: ${args.firstOrNull}');
              _scheduleRejoin();
            },
          );
      },
      onReceivedError: (_, request, error) {
        if (request.isForMainFrame ?? false) _scheduleRejoin();
      },
    );
  }
}

/// No player fits this show yet; [_AutoPlayer] keeps checking.
class _Unsupported extends StatelessWidget {
  const _Unsupported();

  @override
  Widget build(BuildContext context) {
    // Above the screen's centred "Waiting for the seller's video" pill.
    return Align(
      alignment: const Alignment(0, -0.3),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Text(
          "The seller's video isn't reachable right now. You can still bid "
          'and chat; it will appear here as soon as it is.',
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
