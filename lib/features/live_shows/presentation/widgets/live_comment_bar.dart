import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/haptics/app_haptics.dart';
import 'live_stage_tokens.dart';

/// Comment field and heart along the bottom of the stage. Signed-out
/// viewers are invited to sign in; a muted viewer is told why.
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
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

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
        child: Row(
          children: [
            Icon(
              Icons.speaker_notes_off_outlined,
              size: 17,
              color: LiveStage.inkFaint,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'The seller has turned off chat for you.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LiveType.body(13),
              ),
            ),
          ],
        ),
      );
    } else if (!widget.signedIn) {
      field = LivePressable(
        onTap: widget.onSignIn,
        semanticLabel: 'Sign in to comment and bid',
        child: _Pill(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Sign in to comment and bid',
                  style: LiveType.body(13.5),
                ),
              ),
              Text(
                'Sign in',
                style: LiveType.label(13, color: LiveStage.champagne),
              ),
            ],
          ),
        ),
      );
    } else {
      field = _Pill(
        focused: _focus.hasFocus,
        padding: const EdgeInsets.only(left: 12, right: 5),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                maxLength: 300,
                textInputAction: TextInputAction.send,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _send(),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                style: LiveType.body(14, color: LiveStage.ink),
                cursorColor: LiveStage.champagne,
                decoration: InputDecoration(
                  hintText: 'Ask about this piece…',
                  hintStyle: LiveType.body(14, color: LiveStage.inkFaint),
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
                return AnimatedScale(
                  scale: has || _sending ? 1 : 0.6,
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutBack,
                  child: AnimatedOpacity(
                    duration: LiveMotion.quick,
                    opacity: has || _sending ? 1 : 0,
                    child: LivePressable(
                      semanticLabel: 'Send',
                      onTap: has && !_sending ? _send : null,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LiveStage.champagneGradient,
                        ),
                        child: _sending
                            ? const Padding(
                                padding: EdgeInsets.all(8),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: LiveStage.onChampagne,
                                ),
                              )
                            : const Icon(
                                Icons.arrow_upward_rounded,
                                size: 19,
                                color: LiveStage.onChampagne,
                              ),
                      ),
                    ),
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
        AnimatedSize(
          duration: LiveMotion.base,
          curve: LiveMotion.ease,
          child: _error == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 5),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 14,
                        color: LiveStage.urgent,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          _error!,
                          style: LiveType.body(12, color: LiveStage.urgent),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 200.ms).shakeX(hz: 5, amount: 3),
                ),
        ),
        Row(
          children: [
            Expanded(child: field),
            const SizedBox(width: 8),
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
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
    this.focused = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: LiveMotion.quick,
      height: 48,
      padding: padding,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: focused ? Colors.black.withValues(alpha: 0.6) : LiveStage.glass,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: focused
              ? LiveStage.champagne.withValues(alpha: 0.55)
              : LiveStage.glassBorder,
        ),
      ),
      child: child,
    );
  }
}

/// Heart that squashes and throws a ring on every tap. Likes are not
/// totalled, so there is no count.
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
    duration: const Duration(milliseconds: 420),
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
            final v = _pop.value;
            final squash = v < 0.3
                ? 1 - 0.18 * (v / 0.3)
                : 0.82 + 0.18 * Curves.elasticOut.transform((v - 0.3) / 0.7);
            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (_pop.isAnimating)
                  Container(
                    width: 48 + 26 * v,
                    height: 48 + 26 * v,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFF4D6D).withValues(alpha: 1 - v),
                        width: 1.5,
                      ),
                    ),
                  ),
                Transform.scale(scale: squash, child: child),
              ],
            );
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: LiveStage.glass,
              border: Border.all(color: LiveStage.glassBorder),
            ),
            child: ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (r) => const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF8FA3), Color(0xFFFF3D57)],
              ).createShader(r),
              child: const Icon(Icons.favorite_rounded, size: 23),
            ),
          ),
        ),
      ),
    );
  }
}
