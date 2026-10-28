import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/haptics/app_haptics.dart';
import 'live_stage_tokens.dart';

enum LiveToastTone { neutral, success, info, error }

OverlayEntry? _current;
Timer? _timer;

/// Glass toast that drops in under the status bar, clear of the bid dock
/// and the keyboard. One at a time; a new one replaces the last.
void showLiveToast(
  BuildContext context,
  String message, {
  LiveToastTone tone = LiveToastTone.neutral,
  Duration duration = const Duration(milliseconds: 2800),
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  switch (tone) {
    case LiveToastTone.success:
      AppHaptics.success();
    case LiveToastTone.error:
      AppHaptics.error();
    case LiveToastTone.info || LiveToastTone.neutral:
      AppHaptics.light();
  }
  _dismiss();
  final key = GlobalKey<_ToastState>();
  final entry = OverlayEntry(
    builder: (_) => _Toast(key: key, message: message, tone: tone),
  );
  _current = entry;
  overlay.insert(entry);
  _timer = Timer(duration, () async {
    await key.currentState?.leave();
    if (_current == entry) _dismiss();
  });
}

void _dismiss() {
  _timer?.cancel();
  _timer = null;
  final entry = _current;
  _current = null;
  if (entry?.mounted ?? false) entry!.remove();
}

class _Toast extends StatefulWidget {
  const _Toast({required this.message, required this.tone, super.key});

  final String message;
  final LiveToastTone tone;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late final AnimationController _out = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  Future<void> leave() async {
    if (!mounted) return;
    await _out.forward();
  }

  @override
  void dispose() {
    _out.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color accent) = switch (widget.tone) {
      LiveToastTone.success => (Icons.check_circle_rounded, LiveStage.leading),
      LiveToastTone.error => (Icons.error_outline_rounded, LiveStage.urgent),
      LiveToastTone.info => (Icons.info_outline_rounded, LiveStage.champagne),
      LiveToastTone.neutral => (Icons.diamond_outlined, LiveStage.champagne),
    };
    final top = MediaQuery.paddingOf(context).top + 10;
    final still = MediaQuery.disableAnimationsOf(context);
    Widget card = Material(
      type: MaterialType.transparency,
      child: Semantics(
        liveRegion: true,
        child: GestureDetector(
          onTap: () async {
            await leave();
            _dismiss();
          },
          onVerticalDragEnd: (d) async {
            if ((d.primaryVelocity ?? 0) < 0) {
              await leave();
              _dismiss();
            }
          },
          child: LiveGlass(
            radius: 18,
            padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
            child: Row(
              children: [
                Icon(icon, size: 20, color: accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.message,
                    style: LiveType.body(
                      13.5,
                      color: LiveStage.ink,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!still) {
      card = card
          .animate()
          .fadeIn(duration: 200.ms)
          .slideY(
            begin: -0.6,
            end: 0,
            duration: 420.ms,
            curve: Curves.easeOutBack,
          )
          .scaleXY(begin: 0.96, end: 1, duration: 320.ms);
    }
    return Positioned(
      top: top,
      left: 16,
      right: 16,
      child: AnimatedBuilder(
        animation: _out,
        builder: (context, child) => Opacity(
          opacity: 1 - _out.value,
          child: Transform.translate(
            offset: Offset(0, -24 * _out.value),
            child: child,
          ),
        ),
        child: card,
      ),
    );
  }
}
