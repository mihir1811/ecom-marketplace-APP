import 'dart:async';

import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import 'live_viewer_details.dart';

/// Records one viewing of a live show for the admin's Viewers card: join
/// when the screen opens, report every `reportEverySeconds` while it is on
/// screen, leave when it closes or the app is hidden. Coming back reports,
/// which reopens the same visit. No answer here ever touches playback.
class LiveViewerRecorder {
  LiveViewerRecorder({
    required this._dio,
    required this.showId,
    this.campaign = const {},
  });

  final Dio _dio;
  final String showId;

  /// `utm_*` query of the link that opened the show.
  final Map<String, String> campaign;

  String? _joinId;
  Duration _every = const Duration(seconds: 30);
  Timer? _timer;
  var _hidden = false;
  var _stopped = false;

  /// Once per screen open, not again when the player reconnects.
  Future<void> start() async {
    try {
      final body = await liveJoinDetails(campaign: campaign);
      if (_stopped) return;
      final response = await _dio.post<Object>(
        ApiEndpoints.liveShowJoin(showId),
        data: body,
      );
      final data = _data(response.data);
      final id = data?['joinId'];
      if (id is! String || id.isEmpty) return;
      _joinId = id;
      final every = (data?['reportEverySeconds'] as num?)?.toInt();
      if (every != null && every >= 10) _every = Duration(seconds: every);
      if (_stopped) {
        await _leave();
        _joinId = null;
      } else if (_hidden) {
        // Hidden while joining: count it as left until the screen is back.
        await _leave();
      } else {
        _schedule();
      }
    } catch (_) {
      // Ended (400), unknown (404) or rate limited (429): keep playing,
      // never retry.
    }
  }

  Future<void> stop() async {
    if (_stopped) return;
    _stopped = true;
    _timer?.cancel();
    await _leave();
    _joinId = null;
  }

  /// App went to the background.
  void hide() {
    if (_hidden || _stopped) return;
    _hidden = true;
    _timer?.cancel();
    unawaited(_leave());
  }

  /// Back on screen: a report reopens the same visit.
  void show() {
    if (!_hidden || _stopped) return;
    _hidden = false;
    if (_joinId == null) return;
    unawaited(_report());
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer.periodic(_every, (_) => unawaited(_report()));
  }

  Future<void> _report() async {
    final id = _joinId;
    if (id == null) return;
    var ended = false;
    try {
      final level = (await liveBattery()).level;
      final response = await _dio.post<Object>(
        ApiEndpoints.liveJoinReport(id),
        data: {'batteryLevel': ?level},
        options: _noAuth,
      );
      ended = _data(response.data)?['onAir'] == false;
    } on DioException catch (e) {
      ended = e.response?.statusCode == 404;
    } catch (_) {}
    // The show ended (the server closed the visit) or the visit is gone.
    if (ended && _joinId == id) {
      _timer?.cancel();
      _joinId = null;
    }
  }

  Future<void> _leave() async {
    final id = _joinId;
    if (id == null) return;
    try {
      await _dio.post<Object>(ApiEndpoints.liveJoinLeave(id), options: _noAuth);
    } catch (_) {}
  }

  /// Report and leave are named by the joinId alone.
  static final _noAuth = Options(extra: const {'skipAuth': true});

  static Map<String, Object?>? _data(Object? envelope) {
    if (envelope is! Map) return null;
    final data = envelope['data'];
    return data is Map ? data.cast<String, Object?>() : null;
  }
}
