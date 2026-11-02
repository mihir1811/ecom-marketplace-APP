import 'package:flutter/material.dart';

import '../../haptics/app_haptics.dart';
import '../../theme/luxe_tokens.dart';

enum LuxeButtonVariant { primary, secondary, ghost, accent }

/// Pill button with a tactile press, cross-fading loading state and an
/// optional leading icon. One component for every call to action in luxe
/// flows so emphasis stays consistent: primary = ink, accent = champagne,
/// secondary = outlined, ghost = text.
class LuxeButton extends StatefulWidget {
  const LuxeButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.variant = LuxeButtonVariant.primary,
    this.icon,
    this.trailingIcon,
    this.loading = false,
    this.expand = false,
    this.height = 54,
    this.badge,
  });

  final String label;
  final VoidCallback? onPressed;
  final LuxeButtonVariant variant;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool loading;
  final bool expand;
  final double height;

  /// Small count bubble shown after the label (e.g. active filters).
  final int? badge;

  @override
  State<LuxeButton> createState() => _LuxeButtonState();
}

class _LuxeButtonState extends State<LuxeButton> {
  bool _down = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final (bg, fg, border) = switch (widget.variant) {
      LuxeButtonVariant.primary => (p.ink, p.canvas, p.ink),
      LuxeButtonVariant.accent => (p.accent, p.onAccent, p.accent),
      LuxeButtonVariant.secondary => (Colors.transparent, p.ink, p.ink),
      LuxeButtonVariant.ghost => (
        Colors.transparent,
        p.ink,
        Colors.transparent,
      ),
    };
    final disabled = !_enabled && !widget.loading;
    final fill = disabled && widget.variant != LuxeButtonVariant.ghost
        ? (widget.variant == LuxeButtonVariant.secondary
              ? Colors.transparent
              : p.hairline)
        : bg;
    final text = disabled ? p.inkFaint : fg;
    final edge = disabled ? p.hairline : border;

    final content = AnimatedSwitcher(
      duration: LuxeMotion.fast,
      child: widget.loading
          ? SizedBox(
              key: const ValueKey('loading'),
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: text),
            )
          : Row(
              key: const ValueKey('label'),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 18, color: text),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LuxeType.label(text, size: 14.5),
                  ),
                ),
                if (widget.badge != null && widget.badge! > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    constraints: const BoxConstraints(minWidth: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    height: 20,
                    alignment: Alignment.center,
                    decoration: ShapeDecoration(
                      color: widget.variant == LuxeButtonVariant.primary
                          ? p.accent
                          : p.ink,
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      '${widget.badge}',
                      style: LuxeType.figure(
                        widget.variant == LuxeButtonVariant.primary
                            ? p.onAccent
                            : p.canvas,
                        size: 11,
                      ),
                    ),
                  ),
                ],
                if (widget.trailingIcon != null) ...[
                  const SizedBox(width: 6),
                  Icon(widget.trailingIcon, size: 18, color: text),
                ],
              ],
            ),
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: _enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: _enabled
            ? () {
                AppHaptics.light();
                widget.onPressed!();
              }
            : null,
        child: AnimatedScale(
          scale: _down ? 0.97 : 1,
          duration: LuxeMotion.fast,
          curve: LuxeMotion.press,
          child: AnimatedContainer(
            duration: LuxeMotion.medium,
            curve: LuxeMotion.settle,
            height: widget.height,
            width: widget.expand ? double.infinity : null,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              color: fill,
              shape: StadiumBorder(side: BorderSide(color: edge, width: 1.1)),
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// Circular icon control with optional glass treatment, badge and loading.
class LuxeIconButton extends StatelessWidget {
  const LuxeIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
    this.glass = false,
    this.active = false,
    this.activeColor,
    this.loading = false,
    this.size = 44,
    this.badge,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  /// Translucent dark treatment for use over imagery.
  final bool glass;
  final bool active;
  final Color? activeColor;
  final bool loading;
  final double size;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    // Glass reads as frosted white on light themes, smoked on dark.
    final glassFg = p.isDark ? Colors.white : p.ink;
    final fg = active ? (activeColor ?? p.accent) : (glass ? glassFg : p.ink);
    final bg = glass
        ? (p.isDark ? const Color(0x59000000) : const Color(0xD9FFFFFF))
        : p.surface;
    final border = glass
        ? (p.isDark ? const Color(0x33FFFFFF) : const Color(0x14000000))
        : p.hairline;

    Widget child = loading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        : AnimatedSwitcher(
            duration: LuxeMotion.fast,
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: Icon(icon, key: ValueKey(icon), size: 20, color: fg),
          );
    if (badge != null && badge! > 0) {
      child = Badge(
        backgroundColor: p.accent,
        textColor: p.onAccent,
        label: Text(badge! > 99 ? '99+' : '$badge'),
        child: child,
      );
    }

    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        excludeSemantics: true,
        child: Material(
          color: bg,
          shape: CircleBorder(side: BorderSide(color: border)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: loading || onPressed == null
                ? null
                : () {
                    AppHaptics.selection();
                    onPressed!();
                  },
            child: SizedBox(
              width: size,
              height: size,
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}
