import 'package:flutter/material.dart';

/// Odometer text: when the value changes, only the characters that differ
/// roll up into place, like a bid board. Characters are matched from the
/// right so a new leading digit slides in on its own.
class LiveRollingText extends StatelessWidget {
  const LiveRollingText(
    this.text, {
    required this.style,
    super.key,
    this.semanticsLabel,
  });

  final String text;
  final TextStyle style;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    if (still) {
      return Text(text, style: style, semanticsLabel: semanticsLabel);
    }
    final chars = text.characters.toList();
    return Semantics(
      label: semanticsLabel ?? text,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          for (var i = 0; i < chars.length; i++)
            _RollingChar(
              key: ValueKey(chars.length - i),
              char: chars[i],
              style: style,
              delay: (chars.length - i) * 18,
            ),
        ],
      ),
    );
  }
}

class _RollingChar extends StatelessWidget {
  const _RollingChar({
    required this.char,
    required this.style,
    required this.delay,
    super.key,
  });

  final String char;
  final TextStyle style;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        child: AnimatedSwitcher(
          duration: Duration(milliseconds: 420 + delay),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.center,
            children: [...previous, ?current],
          ),
          transitionBuilder: (child, a) {
            final incoming = child.key == ValueKey(char);
            final slide = Tween<Offset>(
              begin: Offset(0, incoming ? 0.9 : -0.9),
              end: Offset.zero,
            ).animate(a);
            return SlideTransition(
              position: slide,
              child: FadeTransition(opacity: a, child: child),
            );
          },
          child: Text(char, key: ValueKey(char), style: style),
        ),
      ),
    );
  }
}
