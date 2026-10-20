import 'dart:async';
import 'dart:io' show Platform;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The mechanical voice of a dial: a soft ratchet [tick] between stops
/// and a firmer [detent] as a stop locks in.
///
/// Mixes with whatever else is playing and follows the silent switch /
/// ringer mode. Each sound has a few low-latency voices so quick turns
/// overlap instead of cutting each other off. Where audio is missing the
/// platform click stands in, and failing that, silence.
abstract final class DialSounds {
  static final _tick = _Voice('sounds/dial_tick.wav', volume: 0.5);
  static final _detent = _Voice('sounds/dial_detent.wav', volume: 0.85);

  static final bool _enabled =
      !kIsWeb && !Platform.environment.containsKey('FLUTTER_TEST');

  /// Loads both sounds, ahead of the first turn.
  static void preload() {
    if (!_enabled) return;
    unawaited(_tick.load());
    unawaited(_detent.load());
  }

  static void tick() {
    if (_enabled) _tick.play();
  }

  static void detent() {
    if (_enabled) _detent.play();
  }
}

class _Voice {
  _Voice(this.asset, {required this.volume});

  final String asset;
  final double volume;
  final List<AudioPlayer> _players = [];
  int _next = 0;
  Future<void>? _loading;
  bool _broken = false;
  DateTime _lastFallback = DateTime(0);

  static const _voices = 3;

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    try {
      final context = AudioContextConfig(
        focus: AudioContextConfigFocus.mixWithOthers,
        respectSilence: true,
      ).build();
      final players = <AudioPlayer>[];
      for (var i = 0; i < _voices; i++) {
        final p = AudioPlayer();
        players.add(p);
        await p.setAudioContext(context);
        await p.setPlayerMode(PlayerMode.lowLatency);
        await p.setReleaseMode(ReleaseMode.stop);
        await p.setVolume(volume);
        await p.setSource(AssetSource(asset));
      }
      _players.addAll(players);
    } catch (_) {
      _broken = true;
    }
  }

  void play() {
    if (_broken) {
      _fallback();
      return;
    }
    if (_players.isEmpty) {
      // Still loading: this one stays silent.
      unawaited(load());
      return;
    }
    final p = _players[_next];
    _next = (_next + 1) % _players.length;
    // A finished low-latency voice must be stopped before it replays.
    unawaited(
      p.stop().then((_) => p.resume()).catchError((Object _) {
        _broken = true;
      }),
    );
  }

  void _fallback() {
    final now = DateTime.now();
    if (now.difference(_lastFallback) < const Duration(milliseconds: 45)) {
      return;
    }
    _lastFallback = now;
    unawaited(
      SystemSound.play(SystemSoundType.click).catchError((Object _) {}),
    );
  }
}
