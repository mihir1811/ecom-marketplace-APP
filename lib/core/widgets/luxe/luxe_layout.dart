import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../haptics/app_haptics.dart';
import '../../router/app_navigation.dart';
import '../../theme/luxe_tokens.dart';
import 'luxe_button.dart';

/// Single-select segmented control with a sliding thumb.
class LuxeSegmented<T> extends StatelessWidget {
  const LuxeSegmented({
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.labelOf,
    super.key,
    this.height = 44,
    this.dense = false,
    this.iconOf,
  });

  final List<T> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final String Function(T) labelOf;
  final double height;
  final bool dense;

  /// When set, segments show this icon (label becomes the semantics text).
  final IconData Function(T)? iconOf;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final index = options.indexOf(selected).clamp(0, options.length - 1);
    return Container(
      height: height,
      padding: const EdgeInsets.all(3),
      decoration: ShapeDecoration(
        color: p.surfaceRaised,
        shape: StadiumBorder(side: BorderSide(color: p.hairline)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth / options.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: LuxeMotion.medium,
                curve: LuxeMotion.settle,
                left: w * index,
                top: 0,
                bottom: 0,
                width: w,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: p.ink,
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
              Row(
                children: [
                  for (final o in options)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: o == selected,
                        label: labelOf(o),
                        excludeSemantics: true,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (o == selected) return;
                            AppHaptics.selection();
                            onChanged(o);
                          },
                          child: Center(
                            child: iconOf != null
                                ? TweenAnimationBuilder<Color?>(
                                    tween: ColorTween(
                                      end: o == selected
                                          ? p.canvas
                                          : p.inkMuted,
                                    ),
                                    duration: LuxeMotion.fast,
                                    builder: (context, color, _) => Icon(
                                      iconOf!(o),
                                      size: 18,
                                      color: color,
                                    ),
                                  )
                                : AnimatedDefaultTextStyle(
                                    duration: LuxeMotion.fast,
                                    style: LuxeType.label(
                                      o == selected ? p.canvas : p.inkMuted,
                                      size: dense ? 12.5 : 13.5,
                                    ),
                                    child: Text(
                                      labelOf(o),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                          ),
                        ),
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
}

/// Collapsible content card with a serif title, live summary and a count of
/// active selections. Expansion animates size and the chevron.
class LuxeSection extends StatefulWidget {
  const LuxeSection({
    required this.title,
    required this.child,
    super.key,
    this.icon,
    this.summary,
    this.activeCount = 0,
    this.initiallyExpanded = false,
    this.collapsible = true,
    this.onClear,
    this.clearLabel,
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final String? summary;
  final int activeCount;
  final bool initiallyExpanded;
  final bool collapsible;
  final VoidCallback? onClear;
  final String? clearLabel;

  @override
  State<LuxeSection> createState() => LuxeSectionState();
}

class LuxeSectionState extends State<LuxeSection> {
  late bool _expanded = widget.initiallyExpanded || !widget.collapsible;

  /// Opens the section (used when navigating to it from a section index).
  void expand() {
    if (!_expanded) setState(() => _expanded = true);
  }

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final header = Row(
      children: [
        if (widget.icon != null) ...[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: p.accentSoft,
            ),
            child: Icon(widget.icon, size: 18, color: p.accent),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LuxeType.display(22, p.ink),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: LuxeMotion.fast,
                    transitionBuilder: (c, a) =>
                        ScaleTransition(scale: a, child: c),
                    child: widget.activeCount > 0
                        ? Container(
                            key: ValueKey(widget.activeCount),
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: ShapeDecoration(
                              color: p.ink,
                              shape: const StadiumBorder(),
                            ),
                            child: Text(
                              '${widget.activeCount}',
                              style: LuxeType.figure(p.canvas, size: 11),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
              if (widget.summary != null && widget.summary!.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  widget.summary!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LuxeType.label(p.inkMuted, size: 12.5),
                ),
              ],
            ],
          ),
        ),
        if (widget.onClear != null && widget.activeCount > 0)
          TextButton(
            onPressed: () {
              AppHaptics.selection();
              widget.onClear!();
            },
            style: TextButton.styleFrom(foregroundColor: p.accent),
            child: Text(
              widget.clearLabel ?? 'Clear',
              style: LuxeType.label(p.accent, size: 12.5),
            ),
          ),
        if (widget.collapsible)
          AnimatedRotation(
            turns: _expanded ? 0.5 : 0,
            duration: LuxeMotion.medium,
            curve: LuxeMotion.settle,
            child: Icon(Icons.expand_more_rounded, color: p.inkMuted),
          ),
      ],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(LuxeSpace.radius),
        border: Border.all(color: p.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: widget.collapsible,
            expanded: _expanded,
            child: InkWell(
              onTap: widget.collapsible
                  ? () {
                      AppHaptics.selection();
                      setState(() => _expanded = !_expanded);
                    }
                  : null,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
                child: header,
              ),
            ),
          ),
          AnimatedSize(
            duration: LuxeMotion.medium,
            curve: LuxeMotion.settle,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                    child: widget.child,
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// Minimal luxe app bar: round back control, serif title with optional
/// subtitle, trailing actions. It fades in a frosted backdrop and
/// hairline once content scrolls beneath it.
class LuxeTopBar extends StatelessWidget implements PreferredSizeWidget {
  const LuxeTopBar({
    required this.title,
    super.key,
    this.subtitle,
    this.actions = const [],
    this.scrollOffset,
    this.onBack,
    this.showBack = true,
  });

  final String title;
  final Widget? subtitle;
  final List<Widget> actions;
  final ValueListenable<double>? scrollOffset;
  final VoidCallback? onBack;
  final bool showBack;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final top = MediaQuery.paddingOf(context).top;

    Widget bar(double t) {
      Widget content = Container(
        padding: EdgeInsets.only(top: top),
        decoration: BoxDecoration(
          color: p.canvas.withValues(alpha: 0.86 + 0.14 * (1 - t)),
          border: Border(
            bottom: BorderSide(
              color: p.hairline.withValues(alpha: t),
              width: 0.6,
            ),
          ),
        ),
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              const SizedBox(width: 12),
              if (showBack)
                LuxeIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  size: 40,
                  onPressed: onBack ?? () => context.goBack(),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LuxeType.display(22, p.ink),
                    ),
                    ?subtitle,
                  ],
                ),
              ),
              ...actions,
              const SizedBox(width: 12),
            ],
          ),
        ),
      );
      if (t > 0.01) {
        content = ClipRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 16 * t, sigmaY: 16 * t),
            child: content,
          ),
        );
      }
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: p.isDark
            ? SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
              )
            : SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
              ),
        child: content,
      );
    }

    final offset = scrollOffset;
    if (offset == null) return bar(0);
    return ValueListenableBuilder<double>(
      valueListenable: offset,
      builder: (context, value, _) => bar((value / 24).clamp(0.0, 1.0)),
    );
  }
}
