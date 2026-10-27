import 'package:flutter/material.dart';

import '../../../../core/haptics/app_haptics.dart';
import 'live_stage_tokens.dart';

/// Comment box and heart button along the bottom of the stage. Signed-out
/// viewers are asked to sign in; a muted viewer sees why the box is gone.
class LiveCommentBar extends StatefulWidget {
  const LiveCommentBar({
    required this.signedIn,
    required this.muted,
    required this.onSend,
    required this.onHeart,
    required this.onSignIn,
    super.key,
  });

  final bool signedIn;
  final bool muted;

  /// Returns an error to show, or `null` when sent.
  final Future<String?> Function(String text) onSend;
  final VoidCallback onHeart;
  final VoidCallback onSignIn;

  @override
  State<LiveCommentBar> createState() => _LiveCommentBarState();
}

class _LiveCommentBarState extends State<LiveCommentBar> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  var _sending = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    final error = await widget.onSend(text);
    if (!mounted) return;
    setState(() {
      _sending = false;
      _error = error;
    });
    if (error == null) {
      _controller.clear();
      AppHaptics.light();
    } else {
      AppHaptics.error();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget field;
    if (widget.muted) {
      field = _Pill(
        child: Text(
          'The seller has turned off chat for you.',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: LiveStage.inkMuted, fontSize: 13.5),
        ),
      );
    } else if (!widget.signedIn) {
      field = GestureDetector(
        onTap: widget.onSignIn,
        child: _Pill(
          child: Text(
            'Sign in to comment and bid',
            style: TextStyle(color: LiveStage.inkMuted, fontSize: 13.5),
          ),
        ),
      );
    } else {
      field = _Pill(
        padding: const EdgeInsets.only(left: 16, right: 4),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                maxLength: 300,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                style: const TextStyle(color: Colors.white, fontSize: 14),
                cursorColor: LiveStage.gold,
                decoration: InputDecoration(
                  hintText: 'Ask about the stone…',
                  hintStyle: TextStyle(color: LiveStage.inkFaint),
                  // The app theme fills fields; the stage pill is the field.
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  counterText: '',
                  isDense: true,
                ),
              ),
            ),
            ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                final has = _controller.text.trim().isNotEmpty;
                return AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: has ? 1 : 0.35,
                  child: IconButton(
                    tooltip: 'Send',
                    onPressed: has && !_sending ? _send : null,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(Icons.send_rounded, color: LiveStage.gold),
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 6),
            child: Text(
              _error!,
              style: const TextStyle(color: LiveStage.urgent, fontSize: 12),
            ),
          ),
        Row(
          children: [
            Expanded(child: field),
            const SizedBox(width: 10),
            _HeartButton(
              onTap: widget.signedIn ? widget.onHeart : widget.onSignIn,
            ),
          ],
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: padding,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: LiveStage.glass,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: LiveStage.glassBorder),
      ),
      child: child,
    );
  }
}

/// Heart with a squash on every tap. No count: likes are not totalled.
class _HeartButton extends StatefulWidget {
  const _HeartButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_HeartButton> createState() => _HeartButtonState();
}

class _HeartButtonState extends State<_HeartButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  void _tap() {
    AppHaptics.light();
    _pop.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Send a heart',
      child: GestureDetector(
        onTap: _tap,
        child: AnimatedBuilder(
          animation: _pop,
          builder: (context, child) {
            final s =
                1 +
                0.22 *
                    Curves.easeOut.transform(1 - (_pop.value - 0.5).abs() * 2);
            return Transform.scale(
              scale: _pop.isAnimating ? s : 1,
              child: child,
            );
          },
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: LiveStage.glass,
              border: Border.all(color: LiveStage.glassBorder),
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: Color(0xFFFF3B6B),
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
