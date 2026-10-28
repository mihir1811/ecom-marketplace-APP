import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// One shared, low-rate clock for the stage's slow ambient motion: the
/// aurora, cover push-ins and LIVE dots. That motion is a fraction of a
/// pixel per frame, so ~24 updates a second look the same as display rate
/// while idle screens stop redrawing at 90–120 Hz. Runs only while
/// something listens.
final class _AmbientClock implements ValueListenable<double> {
  static const _period = Duration(milliseconds: 42);

  final _watch = Stopwatch();
  final _listeners = <VoidCallback>[];
  Timer? _timer;

  @override
  double get value => _watch.elapsedMicroseconds / 1e6;

  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
    if (_timer != null) return;
    _watch.start();
    _timer = Timer.periodic(_period, (_) {
      for (final l in List.of(_listeners)) {
        l();
      }
    });
  }

  @override
  void removeListener(VoidCallback listener) {
    if (!_listeners.remove(listener) || _listeners.isNotEmpty) return;
    _timer?.cancel();
    _timer = null;
    _watch.stop();
  }
}

final _clock = _AmbientClock();

/// Hands [builder] the ambient time in seconds. It holds still with
/// reduced motion, and while this subtree's tickers are muted (a covered
/// route), so hidden screens cost nothing.
class LiveAmbient extends StatefulWidget {
  const LiveAmbient({required this.builder, super.key});

  final Widget Function(BuildContext context, ValueListenable<double> time)
  builder;

  @override
  State<LiveAmbient> createState() => _LiveAmbientState();
}

class _LiveAmbientState extends State<LiveAmbient> {
  final _time = ValueNotifier<double>(0);
  var _listening = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final run =
        TickerMode.valuesOf(context).enabled &&
        !MediaQuery.disableAnimationsOf(context);
    if (run == _listening) return;
    _listening = run;
    if (run) {
      _clock.addListener(_onTick);
      _onTick();
    } else {
      _clock.removeListener(_onTick);
    }
  }

  void _onTick() => _time.value = _clock.value;

  @override
  void dispose() {
    if (_listening) _clock.removeListener(_onTick);
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _time);
}
