import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Shared keyboard inset helpers so IME never covers focused inputs.
abstract final class AppKeyboard {
  /// Extra space reserved for the Gem AI FAB under the chat panel.
  static const double overlayFabGap = 88;

  /// Bottom gap for floating overlays that sit outside a [Scaffold].
  static double overlayBottomGap({
    required double keyboardInset,
    required double safeBottom,
  }) {
    return keyboardInset + safeBottom + overlayFabGap;
  }
}

/// Pads [child] by the current IME height. Use on drawers, sheets, and
/// overlays that are not resized by a [Scaffold].
class AppKeyboardInset extends StatelessWidget {
  const AppKeyboardInset({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottom = media.viewInsets.bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottom),
      child: MediaQuery(
        data: media.copyWith(viewInsets: media.viewInsets.copyWith(bottom: 0)),
        child: child,
      ),
    );
  }
}

/// Scrolls the focused text field into view when the keyboard opens.
class AppFocusedFieldRevealer extends StatefulWidget {
  const AppFocusedFieldRevealer({required this.child, super.key});

  final Widget child;

  @override
  State<AppFocusedFieldRevealer> createState() =>
      _AppFocusedFieldRevealerState();
}

class _AppFocusedFieldRevealerState extends State<AppFocusedFieldRevealer>
    with WidgetsBindingObserver {
  bool _scheduled = false;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_scheduleReveal);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_scheduleReveal);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() => _scheduleReveal();

  void _scheduleReveal() {
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted) return;
      _reveal();
    });
  }

  void _reveal() {
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null || !focus.hasFocus) return;
    final ctx = focus.context;
    if (ctx == null || !ctx.mounted) return;
    if (ctx.widget is! EditableText) return;

    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return;

    final media = MediaQuery.maybeOf(context);
    if (media == null) return;

    final keyboard = media.viewInsets.bottom;
    if (keyboard <= 0) return;

    final origin = box.localToGlobal(Offset.zero);
    final fieldBottom = origin.dy + box.size.height;
    final limit = media.size.height - keyboard - AppSpacing.s24;
    if (fieldBottom <= limit) return;

    Scrollable.ensureVisible(
      ctx,
      alignment: 0.15,
      alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
