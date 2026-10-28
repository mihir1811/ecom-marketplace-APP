import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/widgets/app_network_image.dart';

/// Noir salon palette for every live surface. Always dark: the video and
/// the jewels are the colour; the chrome is ink, glass and champagne.
abstract final class LiveStage {
  static const void_ = Color(0xFF070708);
  static const obsidian = Color(0xFF111113);
  static const graphite = Color(0xFF1A1A1D);

  static const ink = Color(0xFFF6F2EA);
  static Color get inkMuted => ink.withValues(alpha: 0.68);
  static Color get inkFaint => ink.withValues(alpha: 0.42);
  static Color get hairline => ink.withValues(alpha: 0.10);
  static Color get hairlineStrong => ink.withValues(alpha: 0.18);

  static const champagne = Color(0xFFE3C58D);
  static const champagneLight = Color(0xFFF5E3BC);
  static const champagneDeep = Color(0xFFB08A4F);
  static const onChampagne = Color(0xFF17130C);

  static const live = Color(0xFFFF3D57);
  static const leading = Color(0xFF5BE3A6);
  static const urgent = Color(0xFFFF5A5F);

  static Color get glass => Colors.black.withValues(alpha: 0.36);
  static Color get glassStrong =>
      const Color(0xFF0D0D0F).withValues(alpha: 0.78);
  static Color get glassBorder => ink.withValues(alpha: 0.12);

  /// Kept for older call sites; same as [champagne].
  static Color get gold => champagne;

  static const champagneGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [champagneLight, champagne, champagneDeep],
    stops: [0, 0.45, 1],
  );

  static const topScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xB3000000), Color(0x40000000), Color(0x00000000)],
    stops: [0, 0.55, 1],
  );
  static const bottomScrim = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [Color(0xF2000000), Color(0x99000000), Color(0x00000000)],
    stops: [0, 0.5, 1],
  );
}

/// Two families only: a high-contrast serif for names and money, a quiet
/// geometric sans for everything you read in passing.
abstract final class LiveType {
  static const _serif = 'Instrument Serif';
  static const _sans = 'Manrope';

  static TextStyle display(
    double size, {
    Color color = LiveStage.ink,
    bool italic = false,
    double height = 1.05,
  }) => GoogleFonts.getFont(
    _serif,
    fontSize: size,
    color: color,
    height: height,
    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    letterSpacing: -0.2,
  );

  static TextStyle body(
    double size, {
    Color? color,
    FontWeight weight = FontWeight.w500,
    double height = 1.35,
  }) => GoogleFonts.getFont(
    _sans,
    fontSize: size,
    color: color ?? LiveStage.inkMuted,
    fontWeight: weight,
    height: height,
  );

  static TextStyle label(
    double size, {
    Color color = LiveStage.ink,
    FontWeight weight = FontWeight.w700,
  }) => GoogleFonts.getFont(
    _sans,
    fontSize: size,
    color: color,
    fontWeight: weight,
    height: 1.2,
    letterSpacing: 0.1,
  );

  /// Tabular figures for clocks and counts that tick.
  static TextStyle figure(
    double size, {
    Color color = LiveStage.ink,
    FontWeight weight = FontWeight.w700,
  }) => GoogleFonts.getFont(
    _sans,
    fontSize: size,
    color: color,
    fontWeight: weight,
    height: 1.1,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextStyle eyebrow({Color? color, double size = 10.5}) =>
      GoogleFonts.getFont(
        _sans,
        fontSize: size,
        color: color ?? LiveStage.inkFaint,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.8,
        height: 1.2,
      );
}

abstract final class LiveMotion {
  static const quick = Duration(milliseconds: 180);
  static const base = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 560);
  static const ease = Curves.easeOutCubic;
  static const emphasized = Cubic(0.2, 0, 0, 1);
  static const spring = Curves.easeOutBack;
}

// ── Primitives ──────────────────────────────────────────────────────────────

/// "● LIVE" with a ruby dot that breathes and sends out a ring.
class LiveBadge extends StatefulWidget {
  const LiveBadge({super.key, this.compact = false, this.solid = false});

  final bool compact;

  /// Ruby fill instead of glass, for small cards over busy images.
  final bool solid;

  @override
  State<LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    final dot = widget.compact ? 5.0 : 6.0;
    final fg = widget.solid ? Colors.white : LiveStage.live;
    return Semantics(
      label: 'Live',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: widget.compact ? 7 : 9,
          vertical: widget.compact ? 3.5 : 5,
        ),
        decoration: BoxDecoration(
          color: widget.solid ? LiveStage.live : LiveStage.glass,
          borderRadius: BorderRadius.circular(999),
          border: widget.solid
              ? null
              : Border.all(color: LiveStage.live.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: dot * 2.2,
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) {
                  final t = still ? 0.0 : _pulse.value;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: dot * (1 + t * 1.2),
                        height: dot * (1 + t * 1.2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: fg.withValues(alpha: 0.45 * (1 - t)),
                        ),
                      ),
                      Container(
                        width: dot,
                        height: dot,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: fg,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'LIVE',
              style: LiveType.eyebrow(
                color: widget.solid ? Colors.white : LiveStage.ink,
                size: widget.compact ? 9.5 : 10.5,
              ).copyWith(letterSpacing: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

/// Viewer count on glass.
class LiveViewerPill extends StatelessWidget {
  const LiveViewerPill({required this.label, super.key, this.compact = false});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label watching',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 7 : 9,
          vertical: compact ? 3.5 : 5,
        ),
        decoration: BoxDecoration(
          color: LiveStage.glass,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: LiveStage.glassBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.visibility_outlined,
              size: compact ? 11 : 12.5,
              color: LiveStage.inkMuted,
            ),
            const SizedBox(width: 4),
            AnimatedSwitcher(
              duration: LiveMotion.base,
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, 0.4),
                    end: Offset.zero,
                  ).animate(a),
                  child: child,
                ),
              ),
              child: Text(
                label,
                key: ValueKey(label),
                style: LiveType.figure(compact ? 10.5 : 11.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Frosted panel. [blur] is costly over video; use it for one or two
/// surfaces at a time.
class LiveGlass extends StatelessWidget {
  const LiveGlass({
    required this.child,
    super.key,
    this.radius = 24,
    this.blur = true,
    this.padding,
    this.color,
    this.border,
  });

  final Widget child;
  final double radius;
  final bool blur;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? LiveStage.glassStrong,
        borderRadius: BorderRadius.circular(radius),
        border: border ?? Border.all(color: LiveStage.glassBorder),
      ),
      child: child,
    );
    if (!blur) return box;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: box,
      ),
    );
  }
}

/// Sinks a little under the finger and springs back.
class LivePressable extends StatefulWidget {
  const LivePressable({
    required this.child,
    required this.onTap,
    super.key,
    this.scale = 0.96,
    this.haptic = true,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final bool haptic;
  final String? semanticLabel;

  @override
  State<LivePressable> createState() => _LivePressableState();
}

class _LivePressableState extends State<LivePressable> {
  var _down = false;

  void _set(bool v) {
    if (widget.onTap == null || v == _down) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: enabled
            ? () {
                if (widget.haptic) AppHaptics.selection();
                widget.onTap!();
              }
            : null,
        child: AnimatedScale(
          scale: _down ? widget.scale : 1,
          duration: _down
              ? const Duration(milliseconds: 90)
              : const Duration(milliseconds: 380),
          curve: _down ? Curves.easeOut : Curves.elasticOut,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Round glass icon button with an optional count badge.
class LiveIconButton extends StatelessWidget {
  const LiveIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    super.key,
    this.badge = 0,
    this.size = 44,
    this.active = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final int badge;
  final double size;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: LivePressable(
        semanticLabel: badge > 0 ? '$tooltip, $badge' : tooltip,
        onTap: onTap,
        scale: 0.9,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: LiveMotion.quick,
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active
                    ? LiveStage.champagne.withValues(alpha: 0.16)
                    : LiveStage.glass,
                border: Border.all(
                  color: active
                      ? LiveStage.champagne.withValues(alpha: 0.5)
                      : LiveStage.glassBorder,
                ),
              ),
              child: Icon(
                icon,
                size: size * 0.45,
                color: active ? LiveStage.champagne : LiveStage.ink,
              ),
            ),
            if (badge > 0)
              Positioned(
                right: -3,
                top: -3,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 18),
                  height: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LiveStage.champagneGradient,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: LiveStage.void_, width: 1.5),
                  ),
                  child: Text(
                    '$badge',
                    style: LiveType.figure(
                      10,
                      color: LiveStage.onChampagne,
                      weight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum LiveButtonKind { primary, secondary, ghost }

/// Pill button: champagne (primary), glass (secondary) or text (ghost).
class LiveButton extends StatelessWidget {
  const LiveButton({
    required this.label,
    required this.onTap,
    super.key,
    this.kind = LiveButtonKind.primary,
    this.icon,
    this.busy = false,
    this.height = 52,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onTap;
  final LiveButtonKind kind;
  final IconData? icon;
  final bool busy;
  final double height;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !busy;
    final primary = kind == LiveButtonKind.primary;
    final fg = primary ? LiveStage.onChampagne : LiveStage.ink;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (busy)
          SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        else if (icon != null)
          Icon(icon, size: 18, color: fg),
        if (busy || icon != null) const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: LiveType.label(15, color: fg, weight: FontWeight.w800),
          ),
        ),
      ],
    );
    return LivePressable(
      semanticLabel: label,
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: LiveMotion.quick,
        opacity: enabled || busy ? 1 : 0.45,
        child: Container(
          height: height,
          width: expand ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: primary ? LiveStage.champagneGradient : null,
            color: switch (kind) {
              LiveButtonKind.primary => null,
              LiveButtonKind.secondary => LiveStage.ink.withValues(alpha: 0.08),
              LiveButtonKind.ghost => Colors.transparent,
            },
            border: kind == LiveButtonKind.secondary
                ? Border.all(color: LiveStage.hairlineStrong)
                : null,
            boxShadow: primary && enabled
                ? [
                    BoxShadow(
                      color: LiveStage.champagne.withValues(alpha: 0.28),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: content,
        ),
      ),
    );
  }
}

/// Seller avatar: logo or initial, with an optional champagne ring.
class LiveAvatar extends StatelessWidget {
  const LiveAvatar({
    required this.name,
    super.key,
    this.logo,
    this.size = 36,
    this.ring = false,
  });

  final String name;
  final String? logo;
  final double size;
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    final url = logo?.trim();
    final face = ClipOval(
      child: Container(
        width: size,
        height: size,
        color: LiveStage.graphite,
        alignment: Alignment.center,
        child: url == null || url.isEmpty
            ? Text(
                initial,
                style: LiveType.display(size * 0.5, color: LiveStage.champagne),
              )
            : AppNetworkImage(url: url, memCacheWidth: (size * dpr).round()),
      ),
    );
    if (!ring) return face;
    return Container(
      padding: const EdgeInsets.all(1.6),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LiveStage.champagneGradient,
      ),
      child: Container(
        padding: const EdgeInsets.all(1.6),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: LiveStage.void_,
        ),
        child: face,
      ),
    );
  }
}

/// Square lot image with a diamond placeholder.
class LiveThumb extends StatelessWidget {
  const LiveThumb({
    required this.url,
    required this.size,
    super.key,
    this.radius,
  });

  final String? url;
  final double size;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final u = url?.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius ?? size * 0.28),
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [LiveStage.graphite, LiveStage.obsidian],
          ),
        ),
        child: u == null || u.isEmpty
            ? Icon(
                Icons.diamond_outlined,
                color: LiveStage.champagne.withValues(alpha: 0.6),
                size: size * 0.42,
              )
            : AppNetworkImage(url: u, memCacheWidth: (size * dpr).round()),
      ),
    );
  }
}

/// Hairline divider.
class LiveRule extends StatelessWidget {
  const LiveRule({super.key, this.vertical = false});

  final bool vertical;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: vertical ? 1 : double.infinity,
      height: vertical ? double.infinity : 1,
      color: LiveStage.hairline,
    );
  }
}
