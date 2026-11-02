import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/l10n/app_localizations.dart';
import 'auth_tokens.dart';

/// Six-box one-time-code input backed by one invisible text field, so
/// typing, paste, autofill (SMS/email codes) and backspace all just work.
/// Calls [onCompleted] once when every box is filled.
class AuthOtpInput extends StatefulWidget {
  const AuthOtpInput({
    super.key,
    required this.controller,
    required this.onCompleted,
    this.length = 6,
    this.enabled = true,
    this.error = false,
    this.autofocus = true,
  });

  final TextEditingController controller;
  final VoidCallback onCompleted;
  final int length;
  final bool enabled;
  final bool error;
  final bool autofocus;

  @override
  State<AuthOtpInput> createState() => _AuthOtpInputState();
}

class _AuthOtpInputState extends State<AuthOtpInput> {
  final _focus = FocusNode();
  String _lastCompleted = '';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onText);
    _focus.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(AuthOtpInput old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onText);
      widget.controller.addListener(_onText);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    _focus
      ..removeListener(_onFocus)
      ..dispose();
    super.dispose();
  }

  void _onFocus() => setState(() {});

  void _onText() {
    final text = widget.controller.text;
    setState(() {});
    if (text.length == widget.length && text != _lastCompleted) {
      _lastCompleted = text;
      if (widget.enabled) widget.onCompleted();
    } else if (text.length < widget.length) {
      _lastCompleted = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AuthPalette.of(context);
    final text = widget.controller.text;
    final focused = _focus.hasFocus;
    final active = text.length.clamp(0, widget.length - 1);
    final half = widget.length ~/ 2;

    final boxes = Row(
      children: [
        for (var i = 0; i < widget.length; i++) ...[
          if (i > 0) SizedBox(width: i == half ? 18 : 8),
          Expanded(
            child: _OtpBox(
              digit: i < text.length ? text[i] : null,
              active: focused && i == active && text.length < widget.length,
              filled: i < text.length,
              error: widget.error,
              palette: p,
            ),
          ),
        ],
      ],
    );

    return Semantics(
      label: context.tr(AuthL10n.otpFieldLabel),
      textField: true,
      value: text.split('').join(' '),
      child: SizedBox(
        height: 64,
        child: Stack(
          children: [
            Positioned.fill(child: IgnorePointer(child: boxes)),
            Positioned.fill(
              child: ExcludeSemantics(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  enabled: widget.enabled,
                  autofocus: widget.autofocus,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(widget.length),
                  ],
                  showCursor: false,
                  maxLines: 1,
                  expands: false,
                  style: const TextStyle(
                    color: Colors.transparent,
                    fontSize: 1,
                    height: 1,
                  ),
                  decoration: const InputDecoration(
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    counterText: '',
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  onSubmitted: (_) {
                    if (widget.controller.text.length == widget.length) {
                      widget.onCompleted();
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.digit,
    required this.active,
    required this.filled,
    required this.error,
    required this.palette,
  });

  final String? digit;
  final bool active;
  final bool filled;
  final bool error;
  final AuthPalette palette;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final border = error
        ? p.danger
        : active
        ? p.accent
        : filled
        ? p.hairlineStrong
        : p.hairline;
    final reduced = AuthMotion.reduced(context);

    Widget caret = Container(width: 1.6, height: 24, color: p.accent);
    if (!reduced) {
      caret = caret
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .fadeOut(duration: 520.ms, curve: Curves.easeInOut);
    }

    return AnimatedContainer(
      duration: AuthMotion.base,
      curve: AuthMotion.ease,
      decoration: BoxDecoration(
        color: active || filled ? p.surfaceFocus : p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: active || error ? 1.4 : 1),
        boxShadow: active
            ? [
                BoxShadow(
                  color: p.accent.withValues(alpha: 0.18),
                  blurRadius: 16,
                  spreadRadius: -2,
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: AnimatedSwitcher(
        duration: AuthMotion.quick,
        transitionBuilder: (child, a) => ScaleTransition(
          scale: Tween(
            begin: 0.6,
            end: 1.0,
          ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutBack)),
          child: FadeTransition(opacity: a, child: child),
        ),
        child: digit != null
            ? Text(
                digit!,
                key: ValueKey('d$digit'),
                style: AuthType.title(p).copyWith(fontSize: 28),
              )
            : active
            ? KeyedSubtree(key: const ValueKey('caret'), child: caret)
            : const SizedBox.shrink(key: ValueKey('empty')),
      ),
    );
  }
}
