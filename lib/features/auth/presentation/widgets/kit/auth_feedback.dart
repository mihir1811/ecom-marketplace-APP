import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/l10n/app_localizations.dart';
import 'auth_tokens.dart';

/// Shakes its child horizontally each time [trigger] changes.
class AuthShake extends StatefulWidget {
  const AuthShake({super.key, required this.trigger, required this.child});

  final int trigger;
  final Widget child;

  @override
  State<AuthShake> createState() => _AuthShakeState();
}

class _AuthShakeState extends State<AuthShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  @override
  void didUpdateWidget(AuthShake old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger && !AuthMotion.reduced(context)) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = _c.value;
        final dx = math.sin(t * math.pi * 6) * 9 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
    );
  }
}

/// Inline error card that slides in above the primary action and can be
/// dismissed. Announces itself to screen readers.
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message, this.onDismiss});

  final String? message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final p = AuthPalette.of(context);
    final text = message;
    return AnimatedSize(
      duration: AuthMotion.base,
      curve: AuthMotion.ease,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: AuthMotion.base,
        switchInCurve: AuthMotion.ease,
        transitionBuilder: (child, a) => FadeTransition(
          opacity: a,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, -0.15),
              end: Offset.zero,
            ).animate(a),
            child: child,
          ),
        ),
        child: text == null || text.isEmpty
            ? const SizedBox(width: double.infinity)
            : Padding(
                key: ValueKey(text),
                padding: const EdgeInsets.only(bottom: AuthSpace.s16),
                child: Semantics(
                  liveRegion: true,
                  container: true,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 8, 5, 8),
                    decoration: BoxDecoration(
                      color: p.dangerSoft,
                      borderRadius: BorderRadius.circular(AuthSpace.rField),
                      border: Border.all(
                        color: p.danger.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.error_outline_rounded,
                            size: 18,
                            color: p.danger,
                          ),
                        ),
                        const SizedBox(width: AuthSpace.s12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Text(
                              text,
                              style: AuthType.caption(
                                p,
                              ).copyWith(color: p.ink, fontSize: 13.5),
                            ),
                          ),
                        ),
                        if (onDismiss != null)
                          SizedBox.square(
                            dimension: 32,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              iconSize: 16,
                              tooltip: context.tr(AuthL10n.dismiss),
                              onPressed: onDismiss,
                              icon: Icon(
                                Icons.close_rounded,
                                color: p.inkMuted,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

/// Calm information card (icon · title · body).
class AuthNotice extends StatelessWidget {
  const AuthNotice({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final p = AuthPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(AuthSpace.s16),
      decoration: BoxDecoration(
        color: p.accentSoft.withValues(alpha: p.isDark ? 0.08 : 0.06),
        borderRadius: BorderRadius.circular(AuthSpace.rField),
        border: Border.all(color: p.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: p.accentSoft,
            ),
            child: Icon(icon, size: 17, color: p.accent),
          ),
          const SizedBox(width: AuthSpace.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AuthType.label(p)),
                const SizedBox(height: AuthSpace.s4),
                Text(body, style: AuthType.caption(p)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Drawn-on ring + check (or an [icon]) with a small burst of sparks.
class AuthSuccessMark extends StatefulWidget {
  const AuthSuccessMark({super.key, this.icon, this.size = 96});

  final IconData? icon;
  final double size;

  @override
  State<AuthSuccessMark> createState() => _AuthSuccessMarkState();
}

class _AuthSuccessMarkState extends State<AuthSuccessMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AuthMotion.reduced(context)) {
      _c.value = 1;
    } else if (_c.status == AnimationStatus.dismissed) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AuthPalette.of(context);
    final icon = widget.icon;
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          final iconIn = Curves.easeOutBack.transform(
            ((t - 0.4) / 0.45).clamp(0.0, 1.0),
          );
          return Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(widget.size),
                painter: _SuccessPainter(
                  t: t,
                  ring: p.accent,
                  fill: p.accentSoft,
                  drawCheck: icon == null,
                  check: p.accent,
                ),
              ),
              if (icon != null)
                Transform.scale(
                  scale: iconIn,
                  child: Icon(icon, size: widget.size * 0.36, color: p.accent),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SuccessPainter extends CustomPainter {
  _SuccessPainter({
    required this.t,
    required this.ring,
    required this.fill,
    required this.drawCheck,
    required this.check,
  });

  final double t;
  final Color ring;
  final Color fill;
  final bool drawCheck;
  final Color check;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide * 0.36;
    final ringT = Curves.easeInOutCubic.transform((t / 0.55).clamp(0.0, 1.0));
    final fillT = Curves.easeOut.transform(((t - 0.3) / 0.4).clamp(0.0, 1.0));

    canvas.drawCircle(
      c,
      r * (0.6 + 0.4 * fillT),
      Paint()..color = fill.withValues(alpha: fill.a * fillT),
    );
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      math.pi * 2 * ringT,
      false,
      Paint()
        ..color = ring
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );

    // Sparks burst outward once the ring closes.
    final sparkT = ((t - 0.5) / 0.5).clamp(0.0, 1.0);
    if (sparkT > 0 && sparkT < 1) {
      final paint = Paint()..color = ring.withValues(alpha: 1 - sparkT);
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4 + math.pi / 8;
        final d = r * (1.15 + 0.45 * Curves.easeOut.transform(sparkT));
        final p = c + Offset(math.cos(a), math.sin(a)) * d;
        canvas.save();
        canvas.translate(p.dx, p.dy);
        canvas.rotate(a + math.pi / 4);
        final s = 3.4 * (1 - sparkT);
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: s, height: s),
          paint,
        );
        canvas.restore();
      }
    }

    if (!drawCheck) return;
    final checkT = Curves.easeOutCubic.transform(
      ((t - 0.45) / 0.4).clamp(0.0, 1.0),
    );
    if (checkT == 0) return;
    final a = c + Offset(-r * 0.38, r * 0.02);
    final b = c + Offset(-r * 0.1, r * 0.3);
    final e = c + Offset(r * 0.42, -r * 0.28);
    final path = Path()..moveTo(a.dx, a.dy);
    final first = (checkT / 0.4).clamp(0.0, 1.0);
    final mid = Offset.lerp(a, b, first)!;
    path.lineTo(mid.dx, mid.dy);
    if (checkT > 0.4) {
      final second = ((checkT - 0.4) / 0.6).clamp(0.0, 1.0);
      final end = Offset.lerp(b, e, second)!;
      path.lineTo(end.dx, end.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = check
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SuccessPainter old) =>
      old.t != t || old.ring != ring || old.check != check;
}

/// Full success/result state: mark, serif title, body and actions.
class AuthResultView extends StatelessWidget {
  const AuthResultView({
    super.key,
    required this.title,
    required this.body,
    required this.actions,
    this.icon,
    this.tone = AuthResultTone.success,
  });

  final String title;
  final String body;
  final List<Widget> actions;
  final IconData? icon;
  final AuthResultTone tone;

  @override
  Widget build(BuildContext context) {
    final p = AuthPalette.of(context);
    final reduced = AuthMotion.reduced(context);
    Widget lift(Widget w, int i) => reduced
        ? w
        : w
              .animate(delay: (350 + i * 90).ms)
              .fadeIn(duration: AuthMotion.slow, curve: AuthMotion.ease)
              .moveY(begin: 14, end: 0, curve: AuthMotion.ease);

    final mark = tone == AuthResultTone.success
        ? AuthSuccessMark(icon: icon)
        : Container(
            width: 96,
            height: 96,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: p.dangerSoft,
              border: Border.all(color: p.danger.withValues(alpha: 0.4)),
            ),
            child: Icon(
              icon ?? Icons.link_off_rounded,
              color: p.danger,
              size: 34,
            ),
          );

    return Semantics(
      liveRegion: true,
      child: Column(
        children: [
          const SizedBox(height: AuthSpace.s24),
          mark,
          const SizedBox(height: AuthSpace.s24),
          lift(
            Text(
              title,
              textAlign: TextAlign.center,
              style: AuthType.display(p).copyWith(fontSize: 34),
            ),
            0,
          ),
          const SizedBox(height: AuthSpace.s12),
          lift(
            Text(body, textAlign: TextAlign.center, style: AuthType.body(p)),
            1,
          ),
          const SizedBox(height: AuthSpace.s32),
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(height: AuthSpace.s12),
            lift(actions[i], 2 + i),
          ],
        ],
      ),
    );
  }
}

enum AuthResultTone { success, problem }

/// Glass toast that drops in from the top of the app (root overlay), so it
/// survives navigation. Swipe up or wait to dismiss.
abstract final class AuthToast {
  static OverlayEntry? _current;

  static void show(
    BuildContext context,
    String message, {
    IconData icon = Icons.check_circle_outline_rounded,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    final palette = AuthPalette.of(context);
    final direction = Directionality.of(context);
    _current?.remove();
    _current = null;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Directionality(
        textDirection: direction,
        child: _ToastHost(
          palette: palette,
          message: message,
          icon: icon,
          onDone: () {
            if (_current == entry) _current = null;
            if (entry.mounted) entry.remove();
          },
        ),
      ),
    );
    _current = entry;
    overlay.insert(entry);
    SemanticsService.sendAnnouncement(View.of(context), message, direction);
  }
}

class _ToastHost extends StatefulWidget {
  const _ToastHost({
    required this.palette,
    required this.message,
    required this.icon,
    required this.onDone,
  });

  final AuthPalette palette;
  final String message;
  final IconData icon;
  final VoidCallback onDone;

  @override
  State<_ToastHost> createState() => _ToastHostState();
}

class _ToastHostState extends State<_ToastHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AuthMotion.slow,
    reverseDuration: AuthMotion.base,
  )..forward();
  Timer? _timer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 3200), _close);
  }

  Future<void> _close() async {
    if (_closing || !mounted) return;
    _closing = true;
    _timer?.cancel();
    await _c.reverse();
    widget.onDone();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    final top = MediaQuery.paddingOf(context).top + AuthSpace.s12;
    final curved = CurvedAnimation(
      parent: _c,
      curve: AuthMotion.ease,
      reverseCurve: Curves.easeIn,
    );
    return Positioned(
      top: top,
      left: AuthSpace.s16,
      right: AuthSpace.s16,
      child: Center(
        child: FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, -0.6),
              end: Offset.zero,
            ).animate(curved),
            child: GestureDetector(
              onTap: _close,
              onVerticalDragEnd: (d) {
                if ((d.primaryVelocity ?? 0) < 0) _close();
              },
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: p.isDark
                          ? const Color(0xF21A191D)
                          : const Color(0xF2FFFFFF),
                      borderRadius: BorderRadius.circular(AuthSpace.rPill),
                      border: Border.all(color: p.hairline),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(widget.icon, size: 20, color: p.accent),
                        const SizedBox(width: AuthSpace.s12),
                        Flexible(
                          child: Text(widget.message, style: AuthType.label(p)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
