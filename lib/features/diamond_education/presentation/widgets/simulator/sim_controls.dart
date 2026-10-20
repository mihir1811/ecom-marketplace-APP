import 'package:flutter/material.dart';

import '../../../../../core/haptics/app_haptics.dart';
import '../../../../../core/theme/luxe_tokens.dart';

/// Small caps label above a control group.
class SimLabel extends StatelessWidget {
  const SimLabel(this.text, {this.trailing, super.key});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LuxeType.eyebrow(p.inkMuted),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Explanatory copy under a control group.
class SimNote extends StatelessWidget {
  const SimNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Text(text, style: LuxeType.body(p.inkMuted, size: 12.5));
  }
}

/// A labelled on/off switch, the label in small caps like [SimLabel].
class SimSwitch extends StatelessWidget {
  const SimSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final String label;
  final bool value, enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    void toggle() {
      AppHaptics.selection();
      onChanged(!value);
    }

    return Semantics(
      toggled: value,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? toggle : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LuxeType.eyebrow(enabled ? p.inkMuted : p.inkFaint),
                ),
              ),
              Switch.adaptive(
                value: value && enabled,
                onChanged: enabled ? (_) => toggle() : null,
                activeThumbColor: p.onAccent,
                activeTrackColor: p.accent,
                inactiveThumbColor: p.inkMuted,
                inactiveTrackColor: p.surfaceRaised,
                trackOutlineColor: WidgetStatePropertyAll(p.hairline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single-select wrap of pill chips. [swatchOf] adds a colour dot,
/// [leadingOf] any small picture.
class SimChoiceChips<T> extends StatelessWidget {
  const SimChoiceChips({
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    this.swatchOf,
    this.leadingOf,
    this.enabled = true,
    super.key,
  });

  final List<T> options;
  final T? selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;
  final Color Function(T)? swatchOf;
  final Widget Function(T)? leadingOf;
  final bool enabled;

  @override
  Widget build(BuildContext context) => SimToggleChips<T>(
    options: options,
    isSelected: (o) => o == selected,
    labelOf: labelOf,
    swatchOf: swatchOf,
    leadingOf: leadingOf,
    enabled: enabled,
    onTap: (o) {
      if (o == selected) return;
      onSelected(o);
    },
  );
}

/// One swipeable row of pill chips that each toggle; [isSelected] says
/// which are on. Opens scrolled to the first selected chip.
class SimToggleChips<T> extends StatefulWidget {
  const SimToggleChips({
    required this.options,
    required this.isSelected,
    required this.labelOf,
    required this.onTap,
    this.swatchOf,
    this.leadingOf,
    this.enabled = true,
    super.key,
  });

  final List<T> options;
  final bool Function(T) isSelected;
  final String Function(T) labelOf;
  final ValueChanged<T> onTap;
  final Color Function(T)? swatchOf;
  final Widget Function(T)? leadingOf;
  final bool enabled;

  @override
  State<SimToggleChips<T>> createState() => _SimToggleChipsState<T>();
}

class _SimToggleChipsState<T> extends State<SimToggleChips<T>> {
  final _firstSelected = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _firstSelected.currentContext;
      if (!mounted || ctx == null) return;
      Scrollable.ensureVisible(ctx, alignment: 0.5);
    });
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final p = LuxePalette.of(context);
    final first = w.options.indexWhere(w.isSelected);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final (i, o) in w.options.indexed) ...[
            if (i > 0) const SizedBox(width: 6),
            _Chip(
              key: i == first ? _firstSelected : null,
              label: w.labelOf(o),
              swatch: w.swatchOf?.call(o),
              leading: w.leadingOf?.call(o),
              selected: w.isSelected(o),
              enabled: w.enabled,
              palette: p,
              onTap: () {
                AppHaptics.selection();
                w.onTap(o);
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.palette,
    required this.onTap,
    this.swatch,
    this.leading,
    super.key,
  });

  final String label;
  final Color? swatch;
  final Widget? leading;
  final bool selected, enabled;
  final LuxePalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final fg = !enabled
        ? p.inkFaint
        : selected
        ? p.onAccent
        : p.ink;
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: LuxeMotion.fast,
          curve: LuxeMotion.press,
          constraints: const BoxConstraints(minHeight: 36, minWidth: 44),
          padding: EdgeInsets.fromLTRB(
            swatch == null && leading == null ? 12 : 7,
            6,
            12,
            6,
          ),
          decoration: ShapeDecoration(
            color: selected && enabled ? p.accent : p.surfaceRaised,
            shape: StadiumBorder(
              side: BorderSide(
                color: selected && enabled ? p.accent : p.hairline,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (swatch != null) ...[
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: swatch,
                    shape: BoxShape.circle,
                    border: Border.all(color: p.hairline),
                  ),
                  child: const SizedBox.square(dimension: 18),
                ),
                const SizedBox(width: 7),
              ],
              if (leading != null) ...[
                SizedBox.square(dimension: 20, child: leading),
                const SizedBox(width: 6),
              ],
              Text(label, maxLines: 1, style: LuxeType.label(fg, size: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Labelled slider with its live value and an optional ideal-range hint.
class SimSlider extends StatelessWidget {
  const SimSlider({
    required this.label,
    required this.valueText,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
    this.hint,
    this.inIdeal,
    super.key,
  });

  final String label;
  final String valueText;
  final double value, min, max;
  final int? divisions;
  final ValueChanged<double> onChanged;

  /// e.g. "Ideal 54–58%".
  final String? hint;

  /// Tints the value when inside (true) or outside (false) the ideal.
  final bool? inIdeal;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final valueColor = switch (inIdeal) {
      true => p.positive,
      false => p.caution,
      null => p.ink,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LuxeType.label(p.ink, size: 13.5),
              ),
            ),
            if (hint != null) ...[
              Flexible(
                child: Text(
                  hint!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LuxeType.label(p.inkFaint, size: 11.5),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Text(valueText, style: LuxeType.figure(valueColor, size: 14)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            activeTrackColor: p.accent,
            inactiveTrackColor: p.hairline,
            thumbColor: p.accent,
            overlayColor: p.accent.withValues(alpha: 0.14),
            tickMarkShape: SliderTickMarkShape.noTickMark,
            showValueIndicator: ShowValueIndicator.never,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            label: valueText,
            semanticFormatterCallback: (_) => '$label $valueText',
            onChanged: (v) {
              if (divisions != null && v != value) AppHaptics.detent();
              onChanged(v);
            },
          ),
        ),
      ],
    );
  }
}
