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
      padding: const EdgeInsets.only(bottom: 10),
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
    return Text(text, style: LuxeType.body(p.inkMuted, size: 13));
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

/// Single-select wrap of pill chips. [swatchOf] adds a colour dot.
class SimChoiceChips<T> extends StatelessWidget {
  const SimChoiceChips({
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    this.swatchOf,
    this.enabled = true,
    super.key,
  });

  final List<T> options;
  final T? selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;
  final Color Function(T)? swatchOf;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final o in options)
          _Chip(
            label: labelOf(o),
            swatch: swatchOf?.call(o),
            selected: o == selected,
            enabled: enabled,
            palette: p,
            onTap: () {
              if (o == selected) return;
              AppHaptics.selection();
              onSelected(o);
            },
          ),
      ],
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
  });

  final String label;
  final Color? swatch;
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
          constraints: const BoxConstraints(minHeight: 40, minWidth: 44),
          padding: EdgeInsets.fromLTRB(swatch == null ? 14 : 8, 8, 14, 8),
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
                  child: const SizedBox.square(dimension: 20),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LuxeType.label(fg, size: 13),
                ),
              ),
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

/// Thin horizontal meter for a 0..1 reading.
class SimMeter extends StatelessWidget {
  const SimMeter({required this.label, required this.value, super.key});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final v = value.clamp(0.0, 1.0);
    return Semantics(
      label: label,
      value: '${(v * 100).round()}%',
      excludeSemantics: true,
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LuxeType.label(p.inkMuted, size: 12.5),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: SizedBox(
                height: 6,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: p.hairline),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: v,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [p.accent.withValues(alpha: 0.6), p.accent],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              '${(v * 100).round()}',
              textAlign: TextAlign.end,
              style: LuxeType.figure(p.ink, size: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}
