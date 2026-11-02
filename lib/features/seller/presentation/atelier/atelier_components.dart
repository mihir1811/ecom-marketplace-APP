import 'package:flutter/material.dart';

import '../../../../core/haptics/app_haptics.dart';
import 'atelier_motion.dart';
import 'atelier_theme.dart';

/// Base surface: hairline border, soft lift, generous radius.
class AtelierCard extends StatelessWidget {
  const AtelierCard({
    required this.child,
    this.padding = const EdgeInsets.all(AtelierSpace.s20),
    this.onTap,
    this.color,
    this.borderColor,
    this.radius = AtelierRadius.lg,
    this.elevated = true,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final bool elevated;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final card = AnimatedContainer(
      duration: AtelierMotion.base,
      curve: AtelierMotion.emphasized,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? p.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? p.hairline),
        boxShadow: elevated ? p.softShadow : null,
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Pressable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      borderRadius: BorderRadius.circular(radius),
      child: card,
    );
  }
}

/// Quiet section marker: serif title, optional trailing action.
class AtelierSectionHeader extends StatelessWidget {
  const AtelierSectionHeader({required this.title, this.trailing, super.key});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            title,
            style: AtelierType.display(p.ink, size: 24),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AtelierSpace.s12),
          trailing!,
        ],
      ],
    );
  }
}

/// Small status capsule.
class AtelierPill extends StatelessWidget {
  const AtelierPill({
    required this.label,
    this.tone = AtelierTone.neutral,
    this.icon,
    this.filled = false,
    this.dense = false,
    super.key,
  });

  final String label;
  final AtelierTone tone;
  final IconData? icon;
  final bool filled;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final c = p.tone(tone);
    final fg = filled ? (p.isDark ? p.canvas : Colors.white) : c;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 6 : 8,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: filled ? c : c.withValues(alpha: p.isDark ? 0.14 : 0.09),
        borderRadius: BorderRadius.circular(AtelierRadius.pill),
        border: filled ? null : Border.all(color: c.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 11 : 13, color: fg),
            const SizedBox(width: 5),
          ] else ...[
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AtelierType.label(fg, size: dense ? 10.5 : 11.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Icon set in a soft tinted ring — the workspace's only iconographic flourish.
class AtelierIconBadge extends StatelessWidget {
  const AtelierIconBadge({
    required this.icon,
    this.tone = AtelierTone.gold,
    this.size = 40,
    super.key,
  });

  final IconData icon;
  final AtelierTone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final c = p.tone(tone);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c.withValues(alpha: p.isDark ? 0.14 : 0.08),
        border: Border.all(color: c.withValues(alpha: 0.25)),
      ),
      child: Icon(icon, size: size * 0.45, color: c),
    );
  }
}

enum AtelierButtonVariant { primary, gold, secondary, ghost, danger }

/// Workspace button with built-in loading state.
class AtelierButton extends StatelessWidget {
  const AtelierButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AtelierButtonVariant.primary,
    this.loading = false,
    this.compact = false,
    this.expand = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AtelierButtonVariant variant;
  final bool loading;
  final bool compact;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final enabled = onPressed != null && !loading;
    final (
      Color? bg,
      Gradient? gradient,
      Color fg,
      Color? border,
    ) = switch (variant) {
      AtelierButtonVariant.primary => (p.ink, null, p.canvas, null),
      AtelierButtonVariant.gold => (null, p.goldGradient, p.onGold, null),
      AtelierButtonVariant.secondary => (p.surface, null, p.ink, p.hairline),
      AtelierButtonVariant.ghost => (Colors.transparent, null, p.ink, null),
      AtelierButtonVariant.danger => (
        p.ruby.withValues(alpha: p.isDark ? 0.16 : 0.08),
        null,
        p.ruby,
        p.ruby.withValues(alpha: 0.35),
      ),
    };
    final height = compact ? 40.0 : 50.0;

    final content = AnimatedSwitcher(
      duration: AtelierMotion.quick,
      child: loading
          ? SizedBox(
              key: const ValueKey('loading'),
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: fg),
            )
          : Row(
              key: const ValueKey('label'),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: compact ? 16 : 18, color: fg),
                  const SizedBox(width: AtelierSpace.s8),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AtelierType.label(fg, size: compact ? 12.5 : 14),
                  ),
                ),
              ],
            ),
    );

    final button = AnimatedOpacity(
      duration: AtelierMotion.quick,
      opacity: enabled || loading ? 1 : 0.42,
      child: Container(
        height: height,
        width: expand ? double.infinity : null,
        padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14),
        decoration: BoxDecoration(
          color: bg,
          gradient: gradient,
          borderRadius: BorderRadius.circular(AtelierRadius.pill),
          border: border == null ? null : Border.all(color: border),
        ),
        // Hug the label unless a parent (Expanded / expand) sets the width.
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Flexible(child: content)],
        ),
      ),
    );

    return Pressable(
      onTap: enabled ? onPressed : null,
      semanticLabel: label,
      borderRadius: BorderRadius.circular(AtelierRadius.pill),
      child: button,
    );
  }
}

/// Circular icon button with optional count badge or dot.
class AtelierIconButton extends StatelessWidget {
  const AtelierIconButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.badgeCount = 0,
    this.dot = false,
    this.size = 40,
    this.filled = false,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final int badgeCount;
  final bool dot;
  final double size;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Tooltip(
      message: tooltip,
      child: Pressable(
        onTap: onPressed,
        semanticLabel: badgeCount > 0 ? '$tooltip, $badgeCount new' : tooltip,
        scale: 0.9,
        borderRadius: BorderRadius.circular(size),
        child: AnimatedOpacity(
          duration: AtelierMotion.quick,
          opacity: onPressed == null ? 0.38 : 1,
          child: _content(p),
        ),
      ),
    );
  }

  Widget _content(AtelierPalette p) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            duration: AtelierMotion.base,
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? p.surface : Colors.transparent,
              border: Border.all(
                color: filled ? p.hairline : Colors.transparent,
              ),
            ),
            child: Icon(icon, size: size * 0.5, color: p.ink),
          ),
          if (badgeCount > 0)
            Positioned(
              top: -2,
              right: -4,
              child: CountBubble(count: badgeCount),
            )
          else if (dot)
            Positioned(
              top: size * 0.2,
              right: size * 0.2,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: p.gold,
                  shape: BoxShape.circle,
                  border: Border.all(color: p.canvas, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Animated numeric badge (pops when the number changes).
class CountBubble extends StatelessWidget {
  const CountBubble({required this.count, this.inverted = false, super.key});

  final int count;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final label = count > 99 ? '99+' : '$count';
    return AnimatedSwitcher(
      duration: AtelierMotion.base,
      transitionBuilder: (child, a) => ScaleTransition(
        scale: CurvedAnimation(parent: a, curve: AtelierMotion.settle),
        child: child,
      ),
      child: Container(
        key: ValueKey(label),
        constraints: const BoxConstraints(minWidth: 18),
        height: 18,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: inverted ? p.canvas : p.gold,
          borderRadius: BorderRadius.circular(AtelierRadius.pill),
          border: Border.all(color: p.canvas, width: 1.5),
        ),
        child: Text(
          label,
          style: AtelierType.figure(
            inverted ? p.ink : p.onGold,
            size: 10,
            weight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// One option in an [AtelierSegmented] control.
class AtelierSegment<T> {
  const AtelierSegment({
    required this.value,
    required this.label,
    this.icon,
    this.count,
  });

  final T value;
  final String label;
  final IconData? icon;
  final int? count;
}

/// Segmented selector. With [expand] the options share the width and a
/// single indicator glides between them; otherwise options scroll
/// horizontally and the selected one is kept in view.
class AtelierSegmented<T> extends StatefulWidget {
  const AtelierSegmented({
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.expand = false,
    this.dense = false,
    super.key,
  });

  final List<AtelierSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final bool expand;
  final bool dense;

  @override
  State<AtelierSegmented<T>> createState() => _AtelierSegmentedState<T>();
}

class _AtelierSegmentedState<T> extends State<AtelierSegmented<T>> {
  final _keys = <int, GlobalKey>{};

  @override
  void didUpdateWidget(covariant AtelierSegmented<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected && !widget.expand) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
    }
  }

  void _reveal() {
    final index = widget.segments.indexWhere((s) => s.value == widget.selected);
    final ctx = _keys[index]?.currentContext;
    if (ctx == null || !mounted) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.5,
      duration: AtelierMotion.base,
      curve: AtelierMotion.emphasized,
    );
  }

  void _select(T value) {
    if (value == widget.selected) return;
    AppHaptics.selection();
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final height = widget.dense ? 36.0 : 44.0;
    final selectedIndex = widget.segments.indexWhere(
      (s) => s.value == widget.selected,
    );

    if (widget.expand) {
      return Container(
        height: height,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: p.sunken,
          borderRadius: BorderRadius.circular(AtelierRadius.pill),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final n = widget.segments.length;
            final w = constraints.maxWidth / n;
            return Stack(
              children: [
                AnimatedPositioned(
                  duration: AtelierMotion.slow,
                  curve: AtelierMotion.emphasized,
                  left: w * (selectedIndex < 0 ? 0 : selectedIndex),
                  top: 0,
                  bottom: 0,
                  width: w,
                  child: Container(
                    decoration: BoxDecoration(
                      color: p.lifted,
                      borderRadius: BorderRadius.circular(AtelierRadius.pill),
                      boxShadow: [
                        BoxShadow(
                          color: p.shadow,
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < n; i++)
                      Expanded(
                        child: _SegmentLabel(
                          segment: widget.segments[i],
                          selected: i == selectedIndex,
                          dense: widget.dense,
                          onTap: () => _select(widget.segments[i].value),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      );
    }

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: widget.segments.length,
        separatorBuilder: (_, _) => const SizedBox(width: AtelierSpace.s8),
        itemBuilder: (context, i) {
          final s = widget.segments[i];
          final selected = i == selectedIndex;
          return KeyedSubtree(
            key: _keys.putIfAbsent(i, GlobalKey.new),
            child: Pressable(
              onTap: () => _select(s.value),
              haptic: false,
              semanticLabel: s.label,
              borderRadius: BorderRadius.circular(AtelierRadius.pill),
              child: AnimatedContainer(
                duration: AtelierMotion.base,
                curve: AtelierMotion.emphasized,
                padding: EdgeInsets.symmetric(
                  horizontal: widget.dense ? 8 : 12,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? p.ink : p.surface,
                  borderRadius: BorderRadius.circular(AtelierRadius.pill),
                  border: Border.all(color: selected ? p.ink : p.hairline),
                ),
                child: _SegmentContent(
                  segment: s,
                  color: selected ? p.canvas : p.inkSoft,
                  countInverted: selected,
                  dense: widget.dense,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SegmentLabel<T> extends StatelessWidget {
  const _SegmentLabel({
    required this.segment,
    required this.selected,
    required this.dense,
    required this.onTap,
  });

  final AtelierSegment<T> segment;
  final bool selected;
  final bool dense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Semantics(
      selected: selected,
      button: true,
      label: segment.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: AtelierMotion.base,
            style: AtelierType.label(selected ? p.ink : p.muted),
            child: _SegmentContent(
              segment: segment,
              color: selected ? p.ink : p.muted,
              countInverted: false,
              dense: dense,
            ),
          ),
        ),
      ),
    );
  }
}

class _SegmentContent<T> extends StatelessWidget {
  const _SegmentContent({
    required this.segment,
    required this.color,
    required this.countInverted,
    required this.dense,
  });

  final AtelierSegment<T> segment;
  final Color color;
  final bool countInverted;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final count = segment.count;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (segment.icon != null) ...[
          Icon(segment.icon, size: dense ? 14 : 16, color: color),
          const SizedBox(width: 5),
        ],
        Flexible(
          child: Text(
            segment.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AtelierType.label(color, size: dense ? 12 : 13),
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 5),
          AnimatedSwitcher(
            duration: AtelierMotion.base,
            child: Container(
              key: ValueKey(count),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: countInverted
                    ? p.canvas.withValues(alpha: 0.16)
                    : p.sunken,
                borderRadius: BorderRadius.circular(AtelierRadius.pill),
              ),
              child: Text(
                count > 999 ? '999+' : '$count',
                style: AtelierType.figure(color, size: 10.5),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Soft, borderless search input with an animated clear affordance.
class AtelierSearchField extends StatefulWidget {
  const AtelierSearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  State<AtelierSearchField> createState() => _AtelierSearchFieldState();
}

class _AtelierSearchFieldState extends State<AtelierSearchField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
    widget.controller.addListener(_onText);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    _focus.dispose();
    super.dispose();
  }

  void _onText() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final focused = _focus.hasFocus;
    final hasText = widget.controller.text.isNotEmpty;
    return AnimatedContainer(
      duration: AtelierMotion.base,
      curve: AtelierMotion.emphasized,
      height: 46,
      decoration: BoxDecoration(
        color: focused ? p.surface : p.sunken,
        borderRadius: BorderRadius.circular(AtelierRadius.pill),
        border: Border.all(
          color: focused ? p.gold.withValues(alpha: 0.7) : Colors.transparent,
        ),
        boxShadow: focused ? p.softShadow : null,
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(
            Icons.search_rounded,
            size: 19,
            color: focused ? p.gold : p.muted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              onChanged: widget.onChanged,
              textInputAction: TextInputAction.search,
              cursorColor: p.gold,
              style: AtelierType.body(p.ink),
              decoration: InputDecoration(
                isCollapsed: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: widget.hint,
                hintMaxLines: 1,
                hintStyle: AtelierType.body(p.muted),
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: AtelierMotion.quick,
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: hasText
                ? IconButton(
                    key: const ValueKey('clear'),
                    tooltip: 'Clear search',
                    icon: Icon(Icons.close_rounded, size: 18, color: p.inkSoft),
                    onPressed: () {
                      widget.controller.clear();
                      widget.onChanged('');
                    },
                  )
                : const SizedBox(key: ValueKey('none'), width: 12),
          ),
        ],
      ),
    );
  }
}

/// Toggleable chip for filter sheets.
class AtelierChoiceChip extends StatelessWidget {
  const AtelierChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      borderRadius: BorderRadius.circular(AtelierRadius.pill),
      child: AnimatedContainer(
        duration: AtelierMotion.base,
        curve: AtelierMotion.emphasized,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? p.goldSoft : p.surface,
          borderRadius: BorderRadius.circular(AtelierRadius.pill),
          border: Border.all(
            color: selected ? p.gold : p.hairline,
            width: selected ? 1.2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSize(
              duration: AtelierMotion.base,
              curve: AtelierMotion.emphasized,
              child: selected
                  ? Padding(
                      padding: const EdgeInsets.only(right: 5),
                      child: Icon(Icons.check_rounded, size: 14, color: p.gold),
                    )
                  : (icon != null
                        ? Padding(
                            padding: const EdgeInsets.only(right: 5),
                            child: Icon(icon, size: 14, color: p.inkSoft),
                          )
                        : const SizedBox.shrink()),
            ),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AtelierType.label(selected ? p.ink : p.inkSoft),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Removable chip showing an applied filter.
class AtelierFilterTag extends StatelessWidget {
  const AtelierFilterTag({
    required this.label,
    required this.onRemove,
    super.key,
  });

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 5, 5),
      decoration: BoxDecoration(
        color: p.goldSoft,
        borderRadius: BorderRadius.circular(AtelierRadius.pill),
        border: Border.all(color: p.gold.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AtelierType.label(p.ink, size: 12)),
          const SizedBox(width: 4),
          Pressable(
            onTap: onRemove,
            semanticLabel: 'Remove $label',
            scale: 0.85,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(Icons.close_rounded, size: 15, color: p.inkSoft),
            ),
          ),
        ],
      ),
    );
  }
}

/// Labelled key/value used inside detail cards and sheets.
class AtelierKeyValue extends StatelessWidget {
  const AtelierKeyValue({
    required this.label,
    required this.value,
    this.valueWidget,
    super.key,
  });

  final String label;
  final String value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AtelierType.overline(p.muted)),
        const SizedBox(height: 5),
        valueWidget ??
            Text(
              value,
              style: AtelierType.label(p.ink, size: 13.5),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
      ],
    );
  }
}

/// Fine divider.
class AtelierHairline extends StatelessWidget {
  const AtelierHairline({this.vertical = 0, super.key});

  final double vertical;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: vertical),
      child: Container(height: 1, color: context.atelier.hairline),
    );
  }
}

/// Initials avatar for customers / buyers.
class AtelierMonogram extends StatelessWidget {
  const AtelierMonogram({required this.name, this.size = 38, super.key});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty);
    final initials = parts.isEmpty
        ? '·'
        : parts.take(2).map((e) => e[0].toUpperCase()).join();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: p.goldSoft,
        border: Border.all(color: p.gold.withValues(alpha: 0.35)),
      ),
      child: Text(
        initials,
        style: AtelierType.display(p.gold, size: size * 0.42),
      ),
    );
  }
}
