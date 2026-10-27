import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Hearts that rise from the heart button, sway and fade. Call
/// [LiveHeartsController.burst] for each tap or each push from others.
class LiveHeartsController extends ChangeNotifier {
  final _pending = <bool>[];

  /// Adds [count] hearts; [own] ones are a little larger and brighter.
  void burst(int count, {bool own = false}) {
    for (var i = 0; i < count; i++) {
      _pending.add(own);
    }
    notifyListeners();
  }

  List<bool> _take() {
    final out = List<bool>.of(_pending);
    _pending.clear();
    return out;
  }
}

class LiveHeartsLayer extends StatefulWidget {
  const LiveHeartsLayer({required this.controller, super.key});

  final LiveHeartsController controller;

  @override
  State<LiveHeartsLayer> createState() => _LiveHeartsLayerState();
}

class _Heart {
  _Heart(this.born, this.own, this.seed, this.delay);

  final Duration born;
  final bool own;
  final double seed;
  final Duration delay;
}

class _LiveHeartsLayerState extends State<LiveHeartsLayer>
    with SingleTickerProviderStateMixin {
  static const _life = Duration(milliseconds: 2300);
  static const _palette = [
    Color(0xFFFF3B6B),
    Color(0xFFFF7A9A),
    Color(0xFFFFB3C6),
    Color(0xFFE9C46A),
    Color(0xFFFF5470),
  ];

  late final Ticker _ticker = createTicker(_onTick);
  final _hearts = <_Heart>[];
  final _rng = math.Random();
  Duration _now = Duration.zero;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_spawn);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_spawn);
    _ticker.dispose();
    super.dispose();
  }

  void _spawn() {
    if (MediaQuery.disableAnimationsOf(context)) {
      widget.controller._take();
      return;
    }
    final fresh = widget.controller._take();
    for (var i = 0; i < fresh.length; i++) {
      // Spread a burst so hearts don't stack on one another.
      _hearts.add(
        _Heart(
          _now,
          fresh[i],
          _rng.nextDouble(),
          Duration(milliseconds: i * 90),
        ),
      );
    }
    if (_hearts.length > 60) _hearts.removeRange(0, _hearts.length - 60);
    if (!_ticker.isActive) _ticker.start();
  }

  void _onTick(Duration elapsed) {
    _now = elapsed;
    _hearts.removeWhere((h) => elapsed - h.born - h.delay > _life);
    if (_hearts.isEmpty) {
      _ticker.stop();
      _now = Duration.zero;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, box) {
          return Stack(
            clipBehavior: Clip.none,
            children: [for (final h in _hearts) _build(h, box)],
          );
        },
      ),
    );
  }

  Widget _build(_Heart h, BoxConstraints box) {
    final age = _now - h.born - h.delay;
    if (age.isNegative) return const SizedBox.shrink();
    final t = (age.inMilliseconds / _life.inMilliseconds).clamp(0.0, 1.0);
    final rise = Curves.easeOutCubic.transform(t) * box.maxHeight;
    final sway = math.sin(t * math.pi * 2 + h.seed * 6) * 16 * (0.4 + t);
    final scale = h.own ? 1.0 : 0.78;
    final pop = t < 0.12 ? Curves.easeOutBack.transform(t / 0.12) : 1.0;
    final opacity = t > 0.7 ? (1 - (t - 0.7) / 0.3) : 1.0;
    final color =
        _palette[(h.seed * _palette.length).floor() % _palette.length];
    return Positioned(
      right: box.maxWidth / 2 - 14 + sway,
      bottom: rise,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: scale * pop,
          child: Icon(Icons.favorite_rounded, size: 28, color: color),
        ),
      ),
    );
  }
}
