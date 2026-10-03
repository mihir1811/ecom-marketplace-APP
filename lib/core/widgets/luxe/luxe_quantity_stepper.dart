import 'package:flutter/material.dart';

import '../../haptics/app_haptics.dart';
import '../../theme/luxe_tokens.dart';

/// Stadium − / count / + control. The count rolls up or down as it changes.
class LuxeQuantityStepper extends StatefulWidget {
  const LuxeQuantityStepper({
    required this.value,
    required this.onChanged,
    super.key,
    this.min = 1,
    this.max = 99,
    this.decreaseLabel = 'Decrease',
    this.increaseLabel = 'Increase',
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final String decreaseLabel;
  final String increaseLabel;

  @override
  State<LuxeQuantityStepper> createState() => _LuxeQuantityStepperState();
}

class _LuxeQuantityStepperState extends State<LuxeQuantityStepper> {
  bool _up = true;

  void _step(int delta) {
    final next = (widget.value + delta).clamp(widget.min, widget.max);
    if (next == widget.value) return;
    AppHaptics.selection();
    setState(() => _up = delta > 0);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    Widget button(IconData icon, String label, int delta, bool enabled) =>
        Semantics(
          button: true,
          enabled: enabled,
          label: label,
          excludeSemantics: true,
          child: InkResponse(
            onTap: enabled ? () => _step(delta) : null,
            radius: 22,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                icon,
                size: 18,
                color: enabled ? p.ink : p.inkFaint,
              ),
            ),
          ),
        );

    return Container(
      height: 46,
      decoration: ShapeDecoration(
        color: p.surface,
        shape: StadiumBorder(side: BorderSide(color: p.hairline)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(
            Icons.remove_rounded,
            widget.decreaseLabel,
            -1,
            widget.value > widget.min,
          ),
          SizedBox(
            width: 30,
            child: ClipRect(
              child: AnimatedSwitcher(
                duration: LuxeMotion.medium,
                switchInCurve: LuxeMotion.settle,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  final incoming = child.key == ValueKey(widget.value);
                  final from = (_up == incoming) ? 0.8 : -0.8;
                  return SlideTransition(
                    position: Tween(
                      begin: Offset(0, from),
                      end: Offset.zero,
                    ).animate(animation),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: Text(
                  '${widget.value}',
                  key: ValueKey(widget.value),
                  textAlign: TextAlign.center,
                  style: LuxeType.figure(
                    p.ink,
                    size: 16,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          button(
            Icons.add_rounded,
            widget.increaseLabel,
            1,
            widget.value < widget.max,
          ),
        ],
      ),
    );
  }
}
