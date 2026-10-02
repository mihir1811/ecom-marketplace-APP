import 'package:flutter/material.dart';

import '../../../../../core/haptics/app_haptics.dart';
import '../../theme/home_tokens.dart';

/// Tactile press response: the card sinks and tilts toward the finger in 3D.
class PressTilt extends StatefulWidget {
  const PressTilt({
    required this.child,
    required this.onTap,
    required this.semanticLabel,
    super.key,
    this.maxTilt = 0.07,
  });

  final Widget child;
  final VoidCallback onTap;
  final String semanticLabel;
  final double maxTilt;

  @override
  State<PressTilt> createState() => _PressTiltState();
}

class _PressTiltState extends State<PressTilt> {
  Offset _tilt = Offset.zero;
  bool _pressed = false;

  void _update(Offset local, Size size) {
    if (size.isEmpty) return;
    final dx = (local.dx / size.width - 0.5) * 2;
    final dy = (local.dy / size.height - 0.5) * 2;
    setState(() {
      _pressed = true;
      _tilt = Offset(dx.clamp(-1.0, 1.0), dy.clamp(-1.0, 1.0));
    });
  }

  void _release() => setState(() {
    _pressed = false;
    _tilt = Offset.zero;
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => _update(d.localPosition, context.size ?? Size.zero),
        onTapCancel: _release,
        onTapUp: (_) => _release(),
        onTap: () {
          AppHaptics.selection();
          widget.onTap();
        },
        child: TweenAnimationBuilder<Offset>(
          tween: Tween(end: _tilt),
          duration: HomeMotion.medium,
          curve: HomeMotion.press,
          builder: (context, tilt, child) {
            final m = Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateX(-tilt.dy * widget.maxTilt)
              ..rotateY(tilt.dx * widget.maxTilt);
            return Transform(
              alignment: Alignment.center,
              transform: m,
              child: child,
            );
          },
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1,
            duration: HomeMotion.medium,
            curve: HomeMotion.press,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
