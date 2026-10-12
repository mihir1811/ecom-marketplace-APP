import 'package:flutter/foundation.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/physics.dart';

/// Position of the product carousel, shared by the cards and the dock.
///
/// One fractional page value drives both, so swiping either moves the other.
/// Dragging follows the finger; letting go springs to the nearest product.
class ProductPager {
  ProductPager({
    required TickerProvider vsync,
    required this.count,
    required int initial,
    required this.onSettled,
    this.onStep,
  }) : _controller = AnimationController.unbounded(
         vsync: vsync,
         value: initial.toDouble(),
       ) {
    _lastStep = initial;
    _controller.addListener(_tick);
  }

  static final _spring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 170,
    ratio: 1,
  );

  final int count;

  /// Called once the carousel rests on a product.
  final ValueChanged<int> onSettled;

  /// Called each time another product becomes the nearest one.
  final ValueChanged<int>? onStep;

  final AnimationController _controller;
  bool _dragging = false;
  late int _lastStep;

  Listenable get listenable => _controller;

  double get position => _controller.value;

  int get nearest => position.round().clamp(0, count - 1);

  bool get dragging => _dragging;

  /// True while the user drags or the spring is still running.
  bool get busy => _dragging || _controller.isAnimating;

  void _tick() {
    final step = nearest;
    if (step != _lastStep) {
      _lastStep = step;
      onStep?.call(step);
    }
  }

  void dragStart() {
    _dragging = true;
    _controller.stop();
  }

  /// Moves by [pages]; resists past the first and last product.
  void dragBy(double pages) {
    final last = (count - 1).toDouble();
    final v = _controller.value;
    final pushing = (v < 0 && pages < 0) || (v > last && pages > 0);
    _controller.value = v + (pushing ? pages * 0.3 : pages);
  }

  /// Releases with [velocity] in pages per second. A pull of a third of a
  /// page, or a flick, moves on to the next product.
  void dragEnd(double velocity) {
    _dragging = false;
    final v = _controller.value;
    final base = v.round();
    var target = base;
    if (velocity.abs() > 0.6) {
      // A flick moves one product on in its direction.
      target = velocity > 0 ? v.floor() + 1 : v.ceil() - 1;
    } else if ((v - base).abs() > 0.28) {
      target = base + (v - base).sign.toInt();
    }
    _runTo(target.clamp(0, count - 1), velocity);
  }

  void animateTo(int index) {
    _dragging = false;
    _runTo(index.clamp(0, count - 1), 0);
  }

  void _runTo(int target, double velocity) {
    _controller.stop();
    final simulation = SpringSimulation(
      _spring,
      _controller.value,
      target.toDouble(),
      // A runaway release must not fling the carousel past its neighbours.
      velocity.clamp(-8.0, 8.0),
    );
    _controller.animateWith(simulation).then<void>((_) {
      _controller.value = target.toDouble();
      onSettled(target);
    });
  }

  void dispose() => _controller.dispose();
}
