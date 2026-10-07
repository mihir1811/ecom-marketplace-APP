import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/gem3d/gem_mesh.dart';
import '../../../../core/widgets/gem3d/gem_renderer.dart';
import '../../../../core/widgets/gem3d/gem_view.dart';
import 'atelier_components.dart';
import 'atelier_motion.dart';
import 'atelier_theme.dart';

/// Scrollable page frame for studio screens: pull to refresh, centred
/// reading width, responsive gutter and an optional "near the end" hook
/// for pagination.
class AtelierPage extends StatelessWidget {
  const AtelierPage({
    required this.children,
    required this.onRefresh,
    this.onNearEnd,
    this.maxWidth = 1200,
    super.key,
  });

  final List<Widget> children;
  final Future<void> Function() onRefresh;
  final VoidCallback? onNearEnd;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final gutter = AtelierSpace.gutter(MediaQuery.sizeOf(context).width);
    Widget list = ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 48),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ],
    );
    final nearEnd = onNearEnd;
    if (nearEnd != null) {
      list = NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.axis == Axis.vertical &&
              n.metrics.maxScrollExtent > 0 &&
              n.metrics.pixels >= n.metrics.maxScrollExtent - 260) {
            nearEnd();
          }
          return false;
        },
        child: list,
      );
    }
    return RefreshIndicator(
      color: p.gold,
      backgroundColor: p.surface,
      onRefresh: onRefresh,
      child: list,
    );
  }
}

/// Signature onyx band that opens every studio page: overline, serif
/// title, one sentence of purpose, a slowly turning stone, the page's
/// primary action and an optional row of headline figures.
class AtelierHero extends StatelessWidget {
  const AtelierHero({
    required this.overline,
    required this.title,
    this.subtitle,
    this.cut,
    this.look = GemLook.champagne,
    this.action,
    this.footer,
    super.key,
  });

  final String overline;
  final String title;
  final String? subtitle;

  /// Stone shown at the top-right; none when null.
  final GemCut? cut;
  final GemLook look;
  final Widget? action;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final soft = p.onOnyx.withValues(alpha: 0.62);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 640;
        final gemSize = cut == null ? 0.0 : (wide ? 132.0 : 92.0);
        return ClipRRect(
          borderRadius: BorderRadius.circular(AtelierRadius.xl),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF14120E),
              border: Border.all(
                color: p.isDark ? p.hairline : Colors.transparent,
              ),
            ),
            child: Stack(
              children: [
                const Positioned.fill(child: AtelierAmbient(intensity: 1.2)),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: Container(
                    height: 1.2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          p.gold.withValues(alpha: 0),
                          p.gold.withValues(alpha: 0.8),
                          p.gold.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                if (cut != null)
                  Positioned(
                    right: wide ? 26 : 8,
                    top: wide ? 18 : 10,
                    child: Reveal(
                      delay: const Duration(milliseconds: 180),
                      child: GemView(
                        cut: cut!,
                        look: look,
                        size: gemSize,
                        spin: 0.32,
                        tilt: 0.36,
                        interactive: true,
                        semanticLabel: 'Rotating gem. Drag to turn it.',
                      ),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    wide ? 30 : 20,
                    wide ? 28 : 20,
                    wide ? 30 : 20,
                    wide ? 26 : 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Reveal(
                        child: Text(
                          overline.toUpperCase(),
                          style: AtelierType.overline(p.gold),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Reveal(
                        index: 1,
                        child: Padding(
                          padding: EdgeInsets.only(right: gemSize * 0.72),
                          child: Text(
                            title,
                            style: AtelierType.display(
                              p.onOnyx,
                              size: wide ? 42 : 32,
                              weight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 8),
                        Reveal(
                          index: 2,
                          child: Padding(
                            padding: EdgeInsets.only(right: gemSize * 0.55),
                            child: Text(
                              subtitle!,
                              style: AtelierType.body(soft, size: 13.5),
                            ),
                          ),
                        ),
                      ],
                      if (action != null) ...[
                        SizedBox(height: wide ? 22 : 18),
                        Reveal(index: 3, child: action!),
                      ],
                      if (footer != null) ...[
                        SizedBox(height: wide ? 24 : 20),
                        Reveal(
                          index: 4,
                          child: Container(
                            height: 1,
                            color: p.onOnyx.withValues(alpha: 0.1),
                          ),
                        ),
                        SizedBox(height: wide ? 18 : 16),
                        Reveal(index: 5, child: footer!),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// One headline figure inside [AtelierHero]'s footer.
class AtelierHeroStat {
  const AtelierHeroStat({
    required this.label,
    required this.value,
    this.caption,
    this.tone,
  });

  final String label;
  final String value;
  final String? caption;

  /// Coloured dot beside the label (e.g. amber for "needs you").
  final AtelierTone? tone;
}

/// Evenly spaced row of [AtelierHeroStat]s, wrapping on narrow screens.
class AtelierHeroStats extends StatelessWidget {
  const AtelierHeroStats({required this.stats, super.key});

  final List<AtelierHeroStat> stats;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final soft = p.onOnyx.withValues(alpha: 0.58);
    return LayoutBuilder(
      builder: (context, constraints) {
        final perRow = constraints.maxWidth >= 560 ? stats.length : 2;
        final w =
            (constraints.maxWidth - (perRow - 1) * AtelierSpace.s16) / perRow;
        return Wrap(
          spacing: AtelierSpace.s16,
          runSpacing: AtelierSpace.s16,
          children: [
            for (final s in stats)
              SizedBox(
                width: w,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (s.tone != null) ...[
                          _Breathing(color: p.tone(s.tone!)),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            s.label.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AtelierType.overline(soft),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    CountUpText(
                      s.value,
                      style: AtelierType.display(
                        p.onOnyx,
                        size: 30,
                        weight: FontWeight.w500,
                      ),
                    ),
                    if (s.caption != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        s.caption!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AtelierType.caption(soft, size: 11.5),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Softly pulsing status dot.
class _Breathing extends StatelessWidget {
  const _Breathing({required this.color, this.size = 7});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
    if (context.reduceMotion) return dot;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
              )
              .animate(onPlay: (c) => c.repeat())
              .scaleXY(begin: 1, end: 2.6, duration: 1600.ms)
              .fadeOut(duration: 1600.ms, curve: Curves.easeOut),
          dot,
        ],
      ),
    );
  }
}

/// Public breathing dot for live / attention states.
class AtelierPulseDot extends StatelessWidget {
  const AtelierPulseDot({required this.tone, this.size = 7, super.key});

  final AtelierTone tone;
  final double size;

  @override
  Widget build(BuildContext context) =>
      _Breathing(color: context.atelier.tone(tone), size: size);
}

/// Metric tile that doubles as a filter. Selected tiles take the gold
/// edge; [attention] adds a breathing dot so "needs you" counts stand out.
class AtelierStatTile extends StatelessWidget {
  const AtelierStatTile({
    required this.label,
    required this.value,
    this.caption,
    this.icon,
    this.tone = AtelierTone.gold,
    this.selected = false,
    this.attention = false,
    this.onTap,
    this.trailing,
    super.key,
  });

  final String label;
  final String value;
  final String? caption;
  final IconData? icon;
  final AtelierTone tone;
  final bool selected;
  final bool attention;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final accent = p.tone(tone);
    final body = AnimatedContainer(
      duration: AtelierMotion.base,
      curve: AtelierMotion.emphasized,
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      decoration: BoxDecoration(
        color: selected ? p.goldSoft : p.surface,
        borderRadius: BorderRadius.circular(AtelierRadius.lg),
        border: Border.all(
          color: selected ? p.gold : p.hairline,
          width: selected ? 1.3 : 1,
        ),
        boxShadow: selected ? null : p.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: accent),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AtelierType.overline(selected ? p.ink : p.muted),
                ),
              ),
              if (attention) AtelierPulseDot(tone: tone),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: CountUpText(
                  value,
                  style: AtelierType.display(p.ink, size: 28),
                ),
              ),
              ?trailing,
            ],
          ),
          if (caption != null) ...[
            const SizedBox(height: 4),
            Text(
              caption!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AtelierType.caption(p.muted, size: 11.5),
            ),
          ],
        ],
      ),
    );
    if (onTap == null) return body;
    return Pressable(
      onTap: onTap,
      semanticLabel: '$label $value',
      borderRadius: BorderRadius.circular(AtelierRadius.lg),
      child: body,
    );
  }
}

/// Lays tiles out in an even grid: [columns] on wide screens, two on phones.
class AtelierTileGrid extends StatelessWidget {
  const AtelierTileGrid({
    required this.children,
    this.columns = 4,
    this.minTileWidth = 150,
    super.key,
  });

  final List<Widget> children;
  final int columns;
  final double minTileWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AtelierSpace.s12;
        var n = columns;
        while (n > 1 &&
            (constraints.maxWidth - (n - 1) * gap) / n < minTileWidth) {
          n--;
        }
        final w = (constraints.maxWidth - (n - 1) * gap) / n;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < children.length; i++)
              SizedBox(
                width: w,
                child: Reveal(index: i, child: children[i]),
              ),
          ],
        );
      },
    );
  }
}

/// Up / down change capsule ("▲ 12.4%").
class AtelierDelta extends StatelessWidget {
  const AtelierDelta({
    required this.label,
    required this.up,
    this.onDark = false,
    super.key,
  });

  final String label;
  final bool up;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final c = up ? p.emerald : p.ruby;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: onDark ? 0.2 : (p.isDark ? 0.16 : 0.09)),
        borderRadius: BorderRadius.circular(AtelierRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 12,
            color: c,
          ),
          const SizedBox(width: 3),
          Text(label, style: AtelierType.figure(c, size: 11)),
        ],
      ),
    );
  }
}

/// Labelled text input in the workspace style: soft sunken well that
/// lifts and takes a gold edge on focus, with an animated error line.
class AtelierTextField extends StatefulWidget {
  const AtelierTextField({
    required this.controller,
    required this.label,
    this.hint,
    this.error,
    this.prefixText,
    this.suffixText,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.enabled = true,
    this.autofocus = false,
    this.mono = false,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? error;
  final String? prefixText;
  final String? suffixText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final int maxLines;
  final bool enabled;
  final bool autofocus;

  /// Wide letter-spacing for codes.
  final bool mono;

  @override
  State<AtelierTextField> createState() => _AtelierTextFieldState();
}

class _AtelierTextFieldState extends State<AtelierTextField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final focused = _focus.hasFocus;
    final hasError = widget.error != null;
    final edge = hasError
        ? p.ruby.withValues(alpha: 0.7)
        : focused
        ? p.gold.withValues(alpha: 0.75)
        : Colors.transparent;
    final textStyle = widget.mono
        ? AtelierType.label(p.ink, size: 15).copyWith(letterSpacing: 2.2)
        : AtelierType.body(p.ink);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.label.toUpperCase(),
          style: AtelierType.overline(focused ? p.gold : p.muted),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: AtelierMotion.base,
          curve: AtelierMotion.emphasized,
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: widget.maxLines > 1 ? 12 : 0,
          ),
          constraints: const BoxConstraints(minHeight: 50),
          decoration: BoxDecoration(
            color: focused ? p.surface : p.sunken,
            borderRadius: BorderRadius.circular(AtelierRadius.md),
            border: Border.all(color: edge, width: 1.2),
            boxShadow: focused ? p.softShadow : null,
          ),
          child: Row(
            children: [
              if (widget.prefixText != null) ...[
                Text(
                  widget.prefixText!,
                  style: AtelierType.label(p.muted, size: 14),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  enabled: widget.enabled,
                  autofocus: widget.autofocus,
                  keyboardType: widget.keyboardType,
                  inputFormatters: widget.inputFormatters,
                  textCapitalization: widget.textCapitalization,
                  textInputAction: widget.textInputAction,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  maxLines: widget.maxLines,
                  minLines: 1,
                  cursorColor: p.gold,
                  style: textStyle,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: widget.maxLines > 1 ? 2 : 15,
                    ),
                    hintText: widget.hint,
                    hintMaxLines: 1,
                    hintStyle: textStyle.copyWith(color: p.muted),
                  ),
                ),
              ),
              if (widget.suffixText != null) ...[
                const SizedBox(width: 8),
                Text(
                  widget.suffixText!,
                  style: AtelierType.label(p.muted, size: 14),
                ),
              ],
            ],
          ),
        ),
        AtelierFieldError(error: widget.error),
      ],
    );
  }
}

/// Animated inline error under a field.
class AtelierFieldError extends StatelessWidget {
  const AtelierFieldError({required this.error, super.key});

  final String? error;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return AnimatedSize(
      duration: AtelierMotion.base,
      curve: AtelierMotion.emphasized,
      alignment: Alignment.topLeft,
      child: error == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: 7, left: 4),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, size: 13, color: p.ruby),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      error!,
                      style: AtelierType.caption(p.ruby, size: 11.5),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Tappable date / time well matching [AtelierTextField].
class AtelierDateTile extends StatelessWidget {
  const AtelierDateTile({
    required this.label,
    required this.value,
    required this.onTap,
    this.placeholder = 'Select date',
    this.icon = Icons.calendar_today_rounded,
    this.error = false,
    super.key,
  });

  final String label;
  final String? value;
  final VoidCallback onTap;
  final String placeholder;
  final IconData icon;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final empty = value == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label.toUpperCase(), style: AtelierType.overline(p.muted)),
        const SizedBox(height: 8),
        Pressable(
          onTap: onTap,
          semanticLabel: '$label ${value ?? placeholder}',
          borderRadius: BorderRadius.circular(AtelierRadius.md),
          child: AnimatedContainer(
            duration: AtelierMotion.base,
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: p.sunken,
              borderRadius: BorderRadius.circular(AtelierRadius.md),
              border: Border.all(
                color: error
                    ? p.ruby.withValues(alpha: 0.7)
                    : Colors.transparent,
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 15, color: empty ? p.muted : p.gold),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    value ?? placeholder,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: empty
                        ? AtelierType.body(p.muted)
                        : AtelierType.label(p.ink, size: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Square product image with a graceful gem fallback.
class AtelierThumb extends StatelessWidget {
  const AtelierThumb({
    required this.url,
    this.size = 64,
    this.icon = Icons.diamond_outlined,
    super.key,
  });

  final String? url;
  final double size;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final radius = BorderRadius.circular(AtelierRadius.sm);
    final fallback = Center(
      child: Icon(icon, size: size * 0.38, color: p.gold),
    );
    final link = url?.trim();
    return ClipRRect(
      borderRadius: radius,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: RadialGradient(colors: [p.goldSoft, p.sunken], radius: 0.9),
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: p.hairline),
        ),
        child: link == null || link.isEmpty
            ? fallback
            : AppNetworkImage(
                url: link,
                width: size,
                height: size,
                fit: BoxFit.cover,
                memCacheWidth: (size * 2).round(),
                error: fallback,
              ),
      ),
    );
  }
}

/// Animated progress ring with a centred child.
class AtelierRing extends StatelessWidget {
  const AtelierRing({
    required this.value,
    this.size = 56,
    this.stroke = 5,
    this.color,
    this.child,
    super.key,
  });

  /// 0..1
  final double value;
  final double size;
  final double stroke;
  final Color? color;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final target = value.isNaN ? 0.0 : value.clamp(0.0, 1.0).toDouble();
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: target),
      duration: context.reduceMotion ? Duration.zero : AtelierMotion.lazy,
      curve: AtelierMotion.emphasized,
      builder: (context, v, child) => CustomPaint(
        painter: _RingPainter(
          value: v,
          stroke: stroke,
          track: p.sunken,
          color: color ?? p.gold,
        ),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(child: child),
        ),
      ),
      child: child,
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.stroke,
    required this.track,
    required this.color,
  });

  final double value;
  final double stroke;
  final Color track;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = rect.deflate(stroke / 2);
    canvas.drawArc(
      r,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );
    if (value <= 0) return;
    canvas.drawArc(
      r,
      -math.pi / 2,
      math.pi * 2 * value,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color || old.track != track;
}

/// Thin animated meter (usage, share of total, offer vs list).
class AtelierMeter extends StatelessWidget {
  const AtelierMeter({
    required this.value,
    this.color,
    this.height = 6,
    this.marker,
    super.key,
  });

  /// 0..1
  final double value;
  final Color? color;
  final double height;

  /// Optional 0..1 position of a fine reference tick (e.g. list price).
  final double? marker;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final target = value.isNaN ? 0.0 : value.clamp(0.0, 1.0).toDouble();
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        return SizedBox(
          height: height + 6,
          child: Stack(
            alignment: Alignment.centerLeft,
            clipBehavior: Clip.none,
            children: [
              Container(
                height: height,
                decoration: BoxDecoration(
                  color: p.sunken,
                  borderRadius: BorderRadius.circular(height),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: target),
                duration: context.reduceMotion
                    ? Duration.zero
                    : AtelierMotion.lazy,
                curve: AtelierMotion.emphasized,
                builder: (context, v, _) => Container(
                  width: w * v,
                  height: height,
                  decoration: BoxDecoration(
                    gradient: color == null ? p.goldGradient : null,
                    color: color,
                    borderRadius: BorderRadius.circular(height),
                  ),
                ),
              ),
              if (marker != null)
                Positioned(
                  left: (w * marker!.clamp(0.0, 1.0).toDouble()) - 1,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 2, color: p.ink),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Smooth area chart that draws itself in, with drag-to-scrub focus.
class AtelierLineChart extends StatefulWidget {
  const AtelierLineChart({
    required this.values,
    required this.labels,
    required this.detailAt,
    required this.formatValue,
    this.height = 240,
    this.accent,
    super.key,
  });

  final List<double> values;
  final List<String> labels;
  final String Function(int i) detailAt;
  final String Function(double v) formatValue;
  final double height;
  final Color? accent;

  @override
  State<AtelierLineChart> createState() => _AtelierLineChartState();
}

class _AtelierLineChartState extends State<AtelierLineChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _draw = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  int? _focus;

  static const _axisWidth = 50.0;
  static const _labelHeight = 26.0;

  @override
  void initState() {
    super.initState();
    _draw.forward();
  }

  @override
  void didUpdateWidget(covariant AtelierLineChart old) {
    super.didUpdateWidget(old);
    if (!_same(old.values, widget.values)) {
      _focus = null;
      _draw.forward(from: 0);
    }
  }

  static bool _same(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _draw.dispose();
    super.dispose();
  }

  int _indexAt(double dx, double plotWidth) {
    final n = widget.values.length;
    if (n <= 1) return 0;
    final step = plotWidth / (n - 1);
    return (dx / step).round().clamp(0, n - 1).toInt();
  }

  void _aim(double dx, double plotWidth) {
    if (widget.values.isEmpty) return;
    final i = _indexAt(dx, plotWidth);
    if (i != _focus) {
      AppHaptics.selection();
      setState(() => _focus = i);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final accent = widget.accent ?? p.gold;
    final values = widget.values;
    final maxY = atelierNiceMax(values);
    final plotHeight = widget.height - _labelHeight;
    final labelStep = math.max(1, (widget.labels.length / 6).ceil());
    if (context.reduceMotion && _draw.value < 1) _draw.value = 1;

    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final plotWidth = constraints.maxWidth - _axisWidth;
          final focus = _focus;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => _aim(d.localPosition.dx - _axisWidth, plotWidth),
            onHorizontalDragStart: (d) =>
                _aim(d.localPosition.dx - _axisWidth, plotWidth),
            onHorizontalDragUpdate: (d) =>
                _aim(d.localPosition.dx - _axisWidth, plotWidth),
            child: MouseRegion(
              onHover: (e) => _aim(e.localPosition.dx - _axisWidth, plotWidth),
              onExit: (_) => setState(() => _focus = null),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _LinePainter(
                          repaint: _draw,
                          values: values,
                          maxY: maxY,
                          focus: focus,
                          accent: accent,
                          grid: p.hairline,
                          halo: p.surface,
                          axisText: AtelierType.figure(p.muted, size: 10.5),
                          formatValue: widget.formatValue,
                          axisWidth: _axisWidth,
                          plotHeight: plotHeight,
                        ),
                      ),
                    ),
                  ),
                  for (var i = 0; i < widget.labels.length; i += labelStep)
                    Positioned(
                      left: _axisWidth + _xFor(i, plotWidth) - 30,
                      width: 60,
                      top: plotHeight + 8,
                      child: Text(
                        widget.labels[i],
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: AtelierType.caption(
                          i == focus ? p.ink : p.muted,
                          size: 10.5,
                        ),
                      ),
                    ),
                  if (focus != null && focus < values.length)
                    _ChartTip(
                      x: _axisWidth + _xFor(focus, plotWidth),
                      maxWidth: constraints.maxWidth,
                      title: widget.detailAt(focus),
                      value: widget.formatValue(values[focus]),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  double _xFor(int i, double plotWidth) {
    final n = widget.values.length;
    if (n <= 1) return plotWidth / 2;
    return plotWidth * i / (n - 1);
  }
}

class _ChartTip extends StatelessWidget {
  const _ChartTip({
    required this.x,
    required this.maxWidth,
    required this.title,
    required this.value,
  });

  final double x;
  final double maxWidth;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    const w = 168.0;
    final left = (x - w / 2).clamp(0.0, math.max(0.0, maxWidth - w)).toDouble();
    return Positioned(
      left: left,
      top: -6,
      width: w,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: p.isDark ? p.raised : p.onyx,
            borderRadius: BorderRadius.circular(AtelierRadius.sm),
            border: Border.all(
              color: p.isDark ? p.hairline : Colors.transparent,
            ),
            boxShadow: p.floatShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AtelierType.caption(
                  (p.isDark ? p.ink : p.onOnyx).withValues(alpha: 0.65),
                  size: 10.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AtelierType.figure(
                  p.isDark ? p.ink : p.onOnyx,
                  size: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.repaint,
    required this.values,
    required this.maxY,
    required this.focus,
    required this.accent,
    required this.grid,
    required this.halo,
    required this.axisText,
    required this.formatValue,
    required this.axisWidth,
    required this.plotHeight,
  }) : super(repaint: repaint);

  final Animation<double> repaint;
  final List<double> values;
  final double maxY;
  final int? focus;
  final Color accent;
  final Color grid;
  final Color halo;
  final TextStyle axisText;
  final String Function(double) formatValue;
  final double axisWidth;
  final double plotHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final t = AtelierMotion.emphasized.transform(repaint.value);
    final plotWidth = size.width - axisWidth;
    const top = 10.0;
    final h = plotHeight - top;

    // Grid + axis labels.
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var g = 0; g <= 3; g++) {
      final y = top + h * (1 - g / 3);
      canvas.drawLine(Offset(axisWidth, y), Offset(size.width, y), gridPaint);
      final tp = TextPainter(
        text: TextSpan(text: _short(maxY * g / 3), style: axisText),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: axisWidth - 8);
      tp.paint(canvas, Offset(axisWidth - 8 - tp.width, y - tp.height / 2));
    }
    if (values.isEmpty) return;

    Offset pt(int i) {
      final x = values.length <= 1
          ? axisWidth + plotWidth / 2
          : axisWidth + plotWidth * i / (values.length - 1);
      final y = top + h * (1 - (values[i] / maxY).clamp(0.0, 1.0).toDouble());
      return Offset(x, y);
    }

    final line = Path();
    final first = pt(0);
    line.moveTo(first.dx, first.dy);
    for (var i = 1; i < values.length; i++) {
      final a = pt(i - 1), b = pt(i);
      final mx = (a.dx + b.dx) / 2;
      // Midpoint controls keep the curve monotone between points (no dips
      // below zero, no false peaks).
      line.cubicTo(mx, a.dy, mx, b.dy, b.dx, b.dy);
    }

    final revealX = axisWidth + plotWidth * t;
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, revealX + 1, size.height));

    final last = pt(values.length - 1);
    final area = Path.from(line)
      ..lineTo(last.dx, top + h)
      ..lineTo(first.dx, top + h)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accent.withValues(alpha: 0.26 * t),
            accent.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(0, top, size.width, h)),
    );
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = accent,
    );
    if (values.length == 1) {
      canvas.drawCircle(first, 4, Paint()..color = accent);
    }
    canvas.restore();

    // Leading glint while drawing.
    if (t < 1 && values.length > 1) {
      final i = ((values.length - 1) * t)
          .floor()
          .clamp(0, values.length - 2)
          .toInt();
      final frac = (values.length - 1) * t - i;
      final a = pt(i), b = pt(i + 1);
      final y = a.dy + (b.dy - a.dy) * Curves.easeInOut.transform(frac);
      canvas.drawCircle(
        Offset(revealX, y),
        9,
        Paint()..color = accent.withValues(alpha: 0.18),
      );
      canvas.drawCircle(Offset(revealX, y), 3.4, Paint()..color = accent);
    }

    final f = focus;
    if (f != null && f < values.length) {
      final c = pt(f);
      final dash = Paint()
        ..color = accent.withValues(alpha: 0.55)
        ..strokeWidth = 1;
      for (var y = top; y < top + h; y += 6) {
        canvas.drawLine(Offset(c.dx, y), Offset(c.dx, y + 3), dash);
      }
      canvas.drawCircle(c, 9, Paint()..color = accent.withValues(alpha: 0.2));
      canvas.drawCircle(c, 5.5, Paint()..color = halo);
      canvas.drawCircle(c, 3.6, Paint()..color = accent);
    }
  }

  String _short(double v) {
    if (v >= 1e6) return '${_trim(v / 1e6)}M';
    if (v >= 1e3) return '${_trim(v / 1e3)}k';
    return formatValue(v).replaceAll(RegExp(r'\.00$'), '');
  }

  static String _trim(double v) =>
      v.toStringAsFixed(v >= 10 ? 0 : 1).replaceAll(RegExp(r'\.0$'), '');

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.values != values ||
      old.focus != focus ||
      old.accent != accent ||
      old.grid != grid ||
      old.maxY != maxY;
}

/// One slice for [AtelierDonut].
class AtelierSlice {
  const AtelierSlice({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

/// Gapped donut that sweeps in; tapping a legend row focuses its slice.
class AtelierDonut extends StatefulWidget {
  const AtelierDonut({
    required this.slices,
    required this.centerCaption,
    this.size = 170,
    super.key,
  });

  final List<AtelierSlice> slices;
  final String centerCaption;
  final double size;

  @override
  State<AtelierDonut> createState() => _AtelierDonutState();
}

class _AtelierDonutState extends State<AtelierDonut> {
  int? _focus;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final total = widget.slices.fold<double>(0, (s, e) => s + e.value);
    final focus = _focus;
    final share = focus == null || total <= 0
        ? null
        : widget.slices[focus].value / total;
    final ring = TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: context.reduceMotion ? Duration.zero : AtelierMotion.lazy,
      curve: AtelierMotion.emphasized,
      builder: (context, t, _) => CustomPaint(
        size: Size.square(widget.size),
        painter: _DonutPainter(
          slices: widget.slices,
          progress: t,
          focus: focus,
          track: p.sunken,
        ),
      ),
    );
    final center = AnimatedSwitcher(
      duration: AtelierMotion.base,
      child: Column(
        key: ValueKey(focus),
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            share == null ? '100%' : '${(share * 100).toStringAsFixed(0)}%',
            style: AtelierType.display(p.ink, size: 28),
          ),
          Text(
            focus == null ? widget.centerCaption : widget.slices[focus].label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AtelierType.caption(p.muted, size: 11),
          ),
        ],
      ),
    );
    final legend = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < widget.slices.length; i++)
          Pressable(
            onTap: () => setState(() => _focus = _focus == i ? null : i),
            semanticLabel: widget.slices[i].label,
            child: AnimatedContainer(
              duration: AtelierMotion.base,
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: i == focus ? p.sunken : Colors.transparent,
                borderRadius: BorderRadius.circular(AtelierRadius.sm),
              ),
              child: Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: widget.slices[i].color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.slices[i].label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AtelierType.label(p.ink, size: 12.5),
                    ),
                  ),
                  Text(
                    total <= 0
                        ? '0%'
                        : '${(widget.slices[i].value / total * 100).toStringAsFixed(0)}%',
                    style: AtelierType.figure(p.inkSoft, size: 12),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
    return LayoutBuilder(
      builder: (context, c) {
        final chart = SizedBox.square(
          dimension: widget.size,
          child: Stack(alignment: Alignment.center, children: [ring, center]),
        );
        if (c.maxWidth < 420) {
          return Column(children: [chart, const SizedBox(height: 16), legend]);
        }
        return Row(
          children: [
            chart,
            const SizedBox(width: 24),
            Expanded(child: legend),
          ],
        );
      },
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.slices,
    required this.progress,
    required this.focus,
    required this.track,
  });

  final List<AtelierSlice> slices;
  final double progress;
  final int? focus;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 16.0;
    final rect = (Offset.zero & size).deflate(stroke);
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );
    final total = slices.fold<double>(0, (s, e) => s + e.value);
    if (total <= 0) return;
    const gap = 0.035;
    var start = -math.pi / 2;
    final sweepAll = math.pi * 2 * progress;
    for (var i = 0; i < slices.length; i++) {
      final full = slices[i].value / total * math.pi * 2;
      final sweep = math.min(
        full,
        math.max(0.0, sweepAll - (start + math.pi / 2)),
      );
      if (sweep > gap) {
        canvas.drawArc(
          i == focus ? rect.inflate(3) : rect,
          start + gap / 2,
          sweep - gap,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = i == focus ? stroke + 4 : stroke
            ..strokeCap = StrokeCap.butt
            ..color = focus == null || i == focus
                ? slices[i].color
                : slices[i].color.withValues(alpha: 0.35),
        );
      }
      start += full;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.progress != progress || old.focus != focus || old.slices != slices;
}

/// Calm card with an overline / title header for studio sections.
class AtelierPanel extends StatelessWidget {
  const AtelierPanel({
    required this.title,
    required this.child,
    this.overline,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.all(AtelierSpace.s20),
    super.key,
  });

  final String title;
  final String? overline;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return AtelierCard(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (overline != null) ...[
                      Text(
                        overline!.toUpperCase(),
                        style: AtelierType.overline(p.gold),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(title, style: AtelierType.display(p.ink, size: 22)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: AtelierType.caption(p.muted, size: 12.5),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 12), trailing!],
            ],
          ),
          const SizedBox(height: AtelierSpace.s20),
          child,
        ],
      ),
    );
  }
}

/// Copies [text] and confirms with a light haptic.
Future<void> atelierCopy(String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  AppHaptics.light();
}

/// Parses "MM/DD/YYYY" or "DD/MM/YYYY" style labels; null when unknown.
DateTime? atelierParseDateLabel(String label, {bool dayFirst = false}) {
  final m = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(label.trim());
  if (m == null) return DateTime.tryParse(label.trim());
  final a = int.parse(m.group(1)!);
  final b = int.parse(m.group(2)!);
  final y = int.parse(m.group(3)!);
  final month = dayFirst ? b : a;
  final day = dayFirst ? a : b;
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  return DateTime(y, month, day);
}

/// "12 Oct 2026".
String atelierDate(DateTime d) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

/// "12 Oct, 18:30".
String atelierDateTime(DateTime d) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  String two(int v) => v.toString().padLeft(2, '0');
  return '${d.day} ${months[d.month - 1]} ${d.year}, '
      '${two(d.hour)}:${two(d.minute)}';
}

/// Rounds [values]' maximum up to a clean axis ceiling (1, 2, 2.5, 5, 10 ×10ⁿ).
double atelierNiceMax(List<double> values) {
  if (values.isEmpty) return 1;
  final raw = values.reduce(math.max);
  if (raw <= 0) return 1;
  final magnitude = math
      .pow(10, (math.log(raw) / math.ln10).floor())
      .toDouble();
  final n = raw / magnitude;
  final nice = n <= 1
      ? 1.0
      : n <= 2
      ? 2.0
      : n <= 2.5
      ? 2.5
      : n <= 5
      ? 5.0
      : 10.0;
  return nice * magnitude;
}

/// Grouped money: `$12,480` / `₹1,20,000` (Indian grouping for ₹).
String atelierMoney(num amount, {String symbol = '\$', int decimals = 0}) {
  final negative = amount < 0;
  final fixed = amount.abs().toStringAsFixed(decimals);
  final parts = fixed.split('.');
  final digits = parts.first;
  String grouped;
  if (digits.length <= 3) {
    grouped = digits;
  } else if (symbol == '₹') {
    final last3 = digits.substring(digits.length - 3);
    var rest = digits.substring(0, digits.length - 3);
    final chunks = <String>[];
    while (rest.length > 2) {
      chunks.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) chunks.insert(0, rest);
    grouped = '${chunks.join(',')},$last3';
  } else {
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
      buf.write(digits[i]);
    }
    grouped = buf.toString();
  }
  final body = parts.length > 1 ? '$grouped.${parts[1]}' : grouped;
  return '${negative ? '-' : ''}$symbol$body';
}
