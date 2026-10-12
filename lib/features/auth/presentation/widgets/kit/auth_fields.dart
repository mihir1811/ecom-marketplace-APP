import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/l10n/app_localizations.dart';
import 'auth_tokens.dart';

/// Text field styled by the auth theme (see `authThemeData`).
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    this.icon,
    this.hint,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.obscureText = false,
    this.suffix,
    this.autofillHints,
    this.focusNode,
    this.maxLength,
  });

  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final String? hint;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final bool obscureText;
  final Widget? suffix;
  final Iterable<String>? autofillHints;
  final FocusNode? focusNode;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    final p = AuthPalette.of(context);
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      autofillHints: autofillHints,
      maxLength: maxLength,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      style: AuthType.field(p),
      cursorWidth: 1.4,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
        prefixIcon: icon == null ? null : Icon(icon, size: 20),
        suffixIcon: suffix,
      ),
    );
  }
}

/// Password field with its own show/hide toggle.
class AuthPasswordField extends StatefulWidget {
  const AuthPasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction = TextInputAction.done,
    this.enabled = true,
    this.autofillHints = const [AutofillHints.password],
    this.icon = Icons.lock_outline_rounded,
  });

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction textInputAction;
  final bool enabled;
  final Iterable<String>? autofillHints;
  final IconData icon;

  @override
  State<AuthPasswordField> createState() => _AuthPasswordFieldState();
}

class _AuthPasswordFieldState extends State<AuthPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final p = AuthPalette.of(context);
    return AuthTextField(
      controller: widget.controller,
      label: widget.label,
      icon: widget.icon,
      obscureText: _obscure,
      enabled: widget.enabled,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      suffix: IconButton(
        tooltip: context.tr(
          _obscure
              ? AccountCommerceL10n.showPassword
              : AccountCommerceL10n.hidePassword,
        ),
        onPressed: () => setState(() => _obscure = !_obscure),
        icon: AnimatedSwitcher(
          duration: AuthMotion.quick,
          transitionBuilder: (child, a) => RotationTransition(
            turns: Tween(begin: 0.85, end: 1.0).animate(a),
            child: FadeTransition(opacity: a, child: child),
          ),
          child: Icon(
            _obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            key: ValueKey(_obscure),
            size: 20,
            color: p.inkMuted,
          ),
        ),
      ),
    );
  }
}

/// Live strength meter: four segments plus the five rules as chips.
class AuthPasswordMeter extends StatelessWidget {
  const AuthPasswordMeter({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final p = AuthPalette.of(context);
    final rules = <(String, bool)>[
      (AuthL10n.pwRule8, password.length >= 8),
      (AuthL10n.pwRuleUpper, RegExp('[A-Z]').hasMatch(password)),
      (AuthL10n.pwRuleLower, RegExp('[a-z]').hasMatch(password)),
      (AuthL10n.pwRuleNumber, RegExp(r'\d').hasMatch(password)),
      (AuthL10n.pwRuleSymbol, RegExp('[^A-Za-z0-9]').hasMatch(password)),
    ];
    final met = rules.where((r) => r.$2).length;
    final level = password.isEmpty
        ? 0
        : met <= 1
        ? 1
        : met <= 3
        ? 2
        : met == 4
        ? 3
        : 4;
    final color = switch (level) {
      1 => p.danger,
      2 => p.accent.withValues(alpha: 0.65),
      3 => p.accent,
      4 => p.success,
      _ => p.hairline,
    };
    final levelLabel = switch (level) {
      1 => AuthL10n.pwWeak,
      2 => AuthL10n.pwFair,
      3 => AuthL10n.pwGood,
      4 => AuthL10n.pwStrong,
      _ => null,
    };

    return Semantics(
      liveRegion: true,
      label: levelLabel == null ? null : context.tr(levelLabel),
      child: Padding(
        padding: const EdgeInsets.only(top: AuthSpace.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (var i = 0; i < 4; i++) ...[
                  if (i > 0) const SizedBox(width: AuthSpace.s6),
                  Expanded(
                    child: AnimatedContainer(
                      duration: AuthMotion.base,
                      curve: AuthMotion.ease,
                      height: 3,
                      decoration: BoxDecoration(
                        color: i < level ? color : p.hairline,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: AuthSpace.s12),
                SizedBox(
                  width: 64,
                  child: AnimatedSwitcher(
                    duration: AuthMotion.quick,
                    child: Text(
                      levelLabel == null ? '' : context.tr(levelLabel),
                      key: ValueKey(level),
                      textAlign: TextAlign.end,
                      style: AuthType.caption(
                        p,
                      ).copyWith(color: color, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AuthSpace.s12),
            Wrap(
              spacing: AuthSpace.s6,
              runSpacing: AuthSpace.s6,
              children: [
                for (final rule in rules)
                  _RuleChip(label: context.tr(rule.$1), met: rule.$2),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleChip extends StatelessWidget {
  const _RuleChip({required this.label, required this.met});

  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) {
    final p = AuthPalette.of(context);
    return AnimatedContainer(
      duration: AuthMotion.base,
      curve: AuthMotion.ease,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: met ? p.successSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(AuthSpace.rPill),
        border: Border.all(color: met ? Colors.transparent : p.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: AuthMotion.quick,
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: Icon(
              met ? Icons.check_rounded : Icons.circle_outlined,
              key: ValueKey(met),
              size: met ? 13 : 9,
              color: met ? p.success : p.inkMuted,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: AuthType.caption(
              p,
            ).copyWith(fontSize: 12, color: met ? p.success : p.inkMuted),
          ),
        ],
      ),
    );
  }
}

/// One option of an [AuthSegmented] control.
class AuthSegment<T> {
  const AuthSegment({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// Pill segmented control with a sliding selection indicator.
class AuthSegmented<T> extends StatelessWidget {
  const AuthSegmented({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final List<AuthSegment<T>> segments;
  final T value;
  final ValueChanged<T> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final p = AuthPalette.of(context);
    final index = segments.indexWhere((s) => s.value == value);
    final n = segments.length;
    final x = n == 1 ? 0.0 : -1 + 2 * index / (n - 1);

    return Container(
      height: 52,
      padding: const EdgeInsets.all(AuthSpace.s4),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AuthSpace.rPill),
        border: Border.all(color: p.hairline),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: Alignment(x, 0),
            duration: AuthMotion.slow,
            curve: AuthMotion.ease,
            child: FractionallySizedBox(
              widthFactor: 1 / n,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: p.ctaGradient,
                  borderRadius: BorderRadius.circular(AuthSpace.rPill),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final s in segments)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: s.value == value,
                    inMutuallyExclusiveGroup: true,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AuthSpace.rPill),
                      onTap: enabled && s.value != value
                          ? () => onChanged(s.value)
                          : null,
                      child: Center(
                        child: _SegmentLabel(
                          segment: s,
                          selected: s.value == value,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SegmentLabel<T> extends StatelessWidget {
  const _SegmentLabel({required this.segment, required this.selected});

  final AuthSegment<T> segment;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final p = AuthPalette.of(context);
    final color = selected ? p.onCta : p.inkSoft;
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: color),
      duration: AuthMotion.base,
      builder: (context, c, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AuthSpace.s8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (segment.icon != null) ...[
              Icon(segment.icon, size: 17, color: c),
              const SizedBox(width: AuthSpace.s6),
            ],
            Flexible(
              child: Text(
                segment.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AuthType.label(p).copyWith(
                  color: c,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wrap of selectable chips for single-choice lists longer than a segment.
class AuthChoiceChips<T> extends StatelessWidget {
  const AuthChoiceChips({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final List<AuthSegment<T>> options;
  final T value;
  final ValueChanged<T> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final p = AuthPalette.of(context);
    return Wrap(
      spacing: AuthSpace.s8,
      runSpacing: AuthSpace.s8,
      children: [
        for (final o in options)
          Semantics(
            button: true,
            selected: o.value == value,
            inMutuallyExclusiveGroup: true,
            child: _Chip(
              option: o,
              selected: o.value == value,
              palette: p,
              onTap: enabled ? () => onChanged(o.value) : null,
            ),
          ),
      ],
    );
  }
}

class _Chip<T> extends StatelessWidget {
  const _Chip({
    required this.option,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final AuthSegment<T> option;
  final bool selected;
  final AuthPalette palette;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AuthSpace.rPill),
        child: AnimatedContainer(
          duration: AuthMotion.base,
          curve: AuthMotion.ease,
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? p.accentSoft : p.surface,
            borderRadius: BorderRadius.circular(AuthSpace.rPill),
            border: Border.all(
              color: selected ? p.accent : p.hairline,
              width: selected ? 1.2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSize(
                duration: AuthMotion.base,
                curve: AuthMotion.ease,
                child: selected
                    ? Padding(
                        padding: const EdgeInsets.only(right: AuthSpace.s6),
                        child: Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: p.accent,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              Text(
                option.label,
                style: AuthType.label(
                  p,
                ).copyWith(color: selected ? p.ink : p.inkSoft),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated checkbox with a free-form trailing label (e.g. rich text with
/// links). Tapping plain label text toggles it too.
class AuthCheckbox extends StatelessWidget {
  const AuthCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.child,
    this.enabled = true,
    this.error = false,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget child;
  final bool enabled;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final p = AuthPalette.of(context);
    return Semantics(
      checked: value,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => onChanged(!value) : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox.square(
              dimension: 44,
              child: Center(
                child: AnimatedContainer(
                  duration: AuthMotion.base,
                  curve: AuthMotion.ease,
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    gradient: value ? p.ctaGradient : null,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: value
                          ? Colors.transparent
                          : error
                          ? p.danger
                          : p.hairlineStrong,
                      width: 1.2,
                    ),
                  ),
                  child: AnimatedScale(
                    scale: value ? 1 : 0,
                    duration: AuthMotion.base,
                    curve: Curves.easeOutBack,
                    child: Icon(Icons.check_rounded, size: 16, color: p.onCta),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AuthSpace.s4),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 11),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Header that expands a group of optional fields. Children stay mounted
/// (so their values and validators persist) but are unfocusable when closed.
class AuthCollapsible extends StatelessWidget {
  const AuthCollapsible({
    super.key,
    required this.title,
    required this.open,
    required this.onToggle,
    required this.child,
    this.trailing,
    this.icon,
  });

  final String title;
  final String? trailing;
  final IconData? icon;
  final bool open;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = AuthPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: open,
          child: InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(AuthSpace.rField),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: p.accent),
                    const SizedBox(width: AuthSpace.s12),
                  ],
                  Expanded(child: Text(title, style: AuthType.label(p))),
                  if (trailing != null)
                    Text(trailing!, style: AuthType.caption(p)),
                  const SizedBox(width: AuthSpace.s8),
                  AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: AuthMotion.base,
                    curve: AuthMotion.ease,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: p.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        TweenAnimationBuilder<double>(
          tween: Tween(end: open ? 1 : 0),
          duration: AuthMotion.slow,
          curve: AuthMotion.ease,
          builder: (context, v, child) => ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: v,
              child: Opacity(opacity: v, child: child),
            ),
          ),
          child: ExcludeFocus(
            excluding: !open,
            child: Padding(
              padding: const EdgeInsets.only(top: AuthSpace.s8),
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}

/// Read-only field that opens a date picker; validates like a form field.
class AuthDateField extends StatelessWidget {
  const AuthDateField({
    super.key,
    required this.label,
    required this.placeholder,
    required this.value,
    required this.format,
    required this.onPick,
    this.validator,
    this.enabled = true,
    this.icon = Icons.cake_outlined,
  });

  final String label;
  final String placeholder;
  final DateTime? value;
  final String Function(DateTime) format;
  final Future<DateTime?> Function() onPick;
  final FormFieldValidator<DateTime>? validator;
  final bool enabled;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final p = AuthPalette.of(context);
    return FormField<DateTime>(
      initialValue: value,
      validator: validator,
      builder: (field) {
        final selected = value;
        return Semantics(
          button: true,
          label: label,
          value: selected == null ? null : format(selected),
          child: InkWell(
            borderRadius: BorderRadius.circular(AuthSpace.rField),
            onTap: !enabled
                ? null
                : () async {
                    final picked = await onPick();
                    if (picked != null) field.didChange(picked);
                  },
            child: InputDecorator(
              isEmpty: selected == null,
              decoration: InputDecoration(
                labelText: label,
                hintText: placeholder,
                errorText: field.errorText,
                enabled: enabled,
                prefixIcon: Icon(icon, size: 20),
                suffixIcon: Icon(
                  Icons.calendar_month_outlined,
                  size: 20,
                  color: p.inkMuted,
                ),
              ),
              child: Text(
                selected == null ? '' : format(selected),
                style: AuthType.field(p),
              ),
            ),
          ),
        );
      },
    );
  }
}
