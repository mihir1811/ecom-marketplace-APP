import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/l10n/app_localizations.dart';
import 'auth_tokens.dart';

/// Primary call to action: a full-width pill with a slow light sweep,
/// press-down scale and a loading state that morphs the label into a
/// three-facet loader without changing the button's footprint.
class AuthPrimaryButton extends StatefulWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon = Icons.arrow_forward_rounded,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  State<AuthPrimaryButton> createState() => _AuthPrimaryButtonState();
}

class _AuthPrimaryButtonState extends State<AuthPrimaryButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  void _setPressed(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final p = AuthPalette.of(context);
    final reduced = AuthMotion.reduced(context);

    Widget content = AnimatedSwitcher(
      duration: AuthMotion.base,
      switchInCurve: AuthMotion.ease,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween(begin: 0.85, end: 1.0).animate(anim),
          child: child,
        ),
      ),
      child: widget.loading
          ? AuthGemLoader(key: const ValueKey('loading'), color: p.onCta)
          : Row(
              key: const ValueKey('label'),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AuthType.button(p),
                  ),
                ),
                if (widget.icon != null) ...[
                  const SizedBox(width: AuthSpace.s8),
                  AnimatedSlide(
                    offset: Offset(_pressed ? 0.25 : 0, 0),
                    duration: AuthMotion.quick,
                    child: Icon(widget.icon, size: 18, color: p.onCta),
                  ),
                ],
              ],
            ),
    );

    Widget surface = Container(
      height: AuthSpace.buttonHeight,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: AuthSpace.s24),
      decoration: BoxDecoration(
        gradient: p.ctaGradient,
        borderRadius: BorderRadius.circular(AuthSpace.rPill),
        border: Border.all(
          color: Colors.white.withValues(alpha: p.isDark ? 0.35 : 0.08),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: (p.isDark ? p.accent : p.ink).withValues(
              alpha: _enabled ? (p.isDark ? 0.28 : 0.22) : 0,
            ),
            blurRadius: 28,
            spreadRadius: -6,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: content,
    );

    // Always wrapped (never conditionally) so toggling loading keeps the
    // subtree, and with it the label → loader transition.
    surface = surface
        .animate(autoPlay: !reduced, onPlay: (c) => c.repeat())
        .shimmer(
          delay: 2600.ms,
          duration: 1600.ms,
          angle: math.pi / 7,
          color: Colors.white.withValues(
            alpha: _enabled ? (p.isDark ? 0.45 : 0.18) : 0,
          ),
        );

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.loading ? context.tr(AuthL10n.pleaseWait) : widget.label,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: _enabled ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _enabled ? (_) => _setPressed(true) : null,
          onTapUp: _enabled ? (_) => _setPressed(false) : null,
          onTapCancel: () => _setPressed(false),
          onTap: _enabled ? widget.onPressed : null,
          child: AnimatedScale(
            scale: _pressed ? 0.975 : 1,
            duration: AuthMotion.quick,
            curve: Curves.easeOut,
            child: AnimatedOpacity(
              opacity: widget.onPressed == null && !widget.loading ? 0.45 : 1,
              duration: AuthMotion.base,
              child: surface,
            ),
          ),
        ),
      ),
    );
  }
}

/// Quiet outlined pill for secondary actions (Back, Create account).
class AuthSecondaryButton extends StatelessWidget {
  const AuthSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = AuthPalette.of(context);
    return AnimatedOpacity(
      opacity: onPressed == null ? 0.45 : 1,
      duration: AuthMotion.base,
      child: Material(
        color: p.surface,
        shape: StadiumBorder(side: BorderSide(color: p.hairlineStrong)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          splashColor: p.accentSoft,
          highlightColor: p.accentSoft,
          child: SizedBox(
            height: AuthSpace.buttonHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AuthSpace.s20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: p.ink),
                    const SizedBox(width: AuthSpace.s8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AuthType.label(p).copyWith(fontSize: 15),
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

/// Inline text link with an underline that draws in on hover/press.
class AuthTextLink extends StatefulWidget {
  const AuthTextLink({
    super.key,
    required this.label,
    required this.onPressed,
    this.emphasis = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Accent-coloured when true; soft ink otherwise.
  final bool emphasis;
  final IconData? icon;

  @override
  State<AuthTextLink> createState() => _AuthTextLinkState();
}

class _AuthTextLinkState extends State<AuthTextLink> {
  bool _hot = false;

  @override
  Widget build(BuildContext context) {
    final p = AuthPalette.of(context);
    final enabled = widget.onPressed != null;
    final color = widget.emphasis ? p.accent : p.inkSoft;
    return Semantics(
      button: true,
      enabled: enabled,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: (_) => setState(() => _hot = true),
        onExit: (_) => setState(() => _hot = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => setState(() => _hot = true) : null,
          onTapCancel: () => setState(() => _hot = false),
          onTapUp: (_) => setState(() => _hot = false),
          onTap: widget.onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AuthSpace.s8),
              child: Opacity(
                opacity: enabled ? 1 : 0.45,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, size: 16, color: color),
                          const SizedBox(width: AuthSpace.s6),
                        ],
                        Flexible(
                          child: Text(
                            widget.label,
                            style: AuthType.label(p).copyWith(
                              color: color,
                              fontWeight: widget.emphasis
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    AnimatedContainer(
                      duration: AuthMotion.base,
                      curve: AuthMotion.ease,
                      height: 1,
                      width: _hot ? 40 : (widget.emphasis ? 16 : 0),
                      color: color,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Three small facets that light up in sequence: the kit's loader.
class AuthGemLoader extends StatefulWidget {
  const AuthGemLoader({super.key, required this.color, this.size = 7});

  final Color color;
  final double size;

  @override
  State<AuthGemLoader> createState() => _AuthGemLoaderState();
}

class _AuthGemLoaderState extends State<AuthGemLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.size * 3,
      width: widget.size * 7,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          painter: _FacetLoaderPainter(
            t: _c.value,
            color: widget.color,
            size: widget.size,
          ),
        ),
      ),
    );
  }
}

class _FacetLoaderPainter extends CustomPainter {
  _FacetLoaderPainter({
    required this.t,
    required this.color,
    required this.size,
  });

  final double t;
  final Color color;
  final double size;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final cy = canvasSize.height / 2;
    final gap = canvasSize.width / 3;
    for (var i = 0; i < 3; i++) {
      final phase = (t - i * 0.18) % 1.0;
      final wave = math.sin(phase * math.pi).clamp(0.0, 1.0);
      final s = size * (0.7 + 0.45 * wave);
      final cx = gap * (i + 0.5);
      canvas.save();
      canvas.translate(cx, cy - wave * 2.5);
      canvas.rotate(math.pi / 4 + wave * math.pi / 4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: s, height: s),
          const Radius.circular(1.2),
        ),
        Paint()..color = color.withValues(alpha: 0.35 + 0.65 * wave),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_FacetLoaderPainter old) =>
      old.t != t || old.color != color;
}
