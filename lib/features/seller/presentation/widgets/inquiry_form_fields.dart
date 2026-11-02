import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../atelier/atelier_motion.dart';
import '../atelier/atelier_theme.dart';

/// Fill for inputs that sit on an inquiry section card.
Color _fieldFill(AtelierPalette p) => p.isDark ? p.raised : p.canvas;

InputDecoration inquiryInputDecoration(BuildContext context, [String? hint]) {
  final p = context.atelier;
  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AtelierRadius.sm),
    borderSide: BorderSide(color: c, width: w),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: AtelierType.body(p.muted, size: 14),
    isDense: true,
    filled: true,
    fillColor: _fieldFill(p),
    border: border(p.hairline),
    enabledBorder: border(p.hairline),
    disabledBorder: border(p.hairline),
    focusedBorder: border(p.gold, 1.4),
    errorBorder: border(p.ruby),
    focusedErrorBorder: border(p.ruby, 1.4),
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
  );
}

/// Text style for values typed or picked in inquiry inputs.
TextStyle inquiryInputStyle(BuildContext context) =>
    AtelierType.body(context.atelier.ink, size: 14.5);

/// Small label shown above an inquiry input.
class InquiryFieldLabel extends StatelessWidget {
  const InquiryFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: AtelierSpace.s6),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AtelierType.label(context.atelier.inkSoft, size: 12.5),
      ),
    );
  }
}

/// Muted helper line next to an inquiry input.
class InquiryHelperText extends StatelessWidget {
  const InquiryHelperText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AtelierType.caption(context.atelier.muted));
  }
}

/// Shared preset lists for inquiry dropdowns (plus Others in the field widget).
abstract final class InquirySpecOptions {
  static const shapes = [
    'Round',
    'Oval',
    'Pear',
    'Emerald',
    'Cushion',
    'Princess',
    'Marquise',
    'Heart',
    'Radiant',
    'Asscher',
    'Cabochon',
  ];

  static const gemstoneTypes = [
    'Ruby',
    'Sapphire',
    'Emerald',
    'Amethyst',
    'Aquamarine',
    'Garnet',
    'Topaz',
    'Tourmaline',
    'Tanzanite',
    'Opal',
    'Pearl',
  ];

  static const gemstoneColors = [
    'Red',
    'Blue',
    'Green',
    'Yellow',
    'Pink',
    'Purple',
    'Orange',
    'White',
    'Black',
    'Brown',
    'Multi',
  ];

  static const gemstoneClarities = [
    'FL',
    'IF',
    'VVS',
    'VS',
    'SI',
    'I',
    'Opaque',
  ];

  static const origins = [
    'Burma',
    'Sri Lanka',
    'Colombia',
    'Brazil',
    'Africa',
    'Madagascar',
    'India',
    'Thailand',
  ];

  static const treatments = [
    'None',
    'Heat',
    'Oil',
    'Diffusion',
    'Irradiation',
    'Fracture filling',
  ];

  static const jewelryCategories = [
    'Ring',
    'Necklace',
    'Bracelet',
    'Earring',
    'Accessories',
  ];

  static const ringSizes = [
    'US 4',
    'US 5',
    'US 6',
    'US 7',
    'US 8',
    'US 9',
    'US 10',
    'US 11',
    'US 12',
    'US 13',
  ];

  static const necklaceLengths = [
    '14 inch',
    '16 inch',
    '18 inch',
    '20 inch',
    '22 inch',
    '24 inch',
    '30 inch',
  ];

  static const braceletLengths = [
    '6 inch',
    '6.5 inch',
    '7 inch',
    '7.5 inch',
    '8 inch',
    '8.5 inch',
  ];
}

class InquirySectionCard extends StatelessWidget {
  const InquirySectionCard({required this.child, this.title, super.key});

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AtelierSpace.s16),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 5),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AtelierRadius.lg),
        border: Border.all(color: p.hairline),
        boxShadow: p.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    gradient: p.goldGradient,
                    borderRadius: BorderRadius.circular(AtelierRadius.pill),
                  ),
                ),
                const SizedBox(width: AtelierSpace.s10),
                Expanded(child: Text(title!, style: AtelierType.title(p.ink))),
              ],
            ),
            const SizedBox(height: AtelierSpace.s16),
          ],
          child,
        ],
      ),
    );
  }
}

class InquiryLabeledField extends StatelessWidget {
  const InquiryLabeledField({
    required this.label,
    required this.child,
    super.key,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AtelierSpace.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [InquiryFieldLabel(label), child],
      ),
    );
  }
}

class InquiryTextField extends StatelessWidget {
  const InquiryTextField({
    required this.label,
    required this.controller,
    this.hint,
    this.maxLines = 1,
    this.onChanged,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final placeholder = hint ?? 'Enter $label';
    return InquiryLabeledField(
      label: label,
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        onChanged: onChanged,
        style: inquiryInputStyle(context),
        cursorColor: context.atelier.gold,
        scrollPadding: const EdgeInsets.fromLTRB(14, 14, 14, 80),
        decoration: inquiryInputDecoration(context, placeholder),
      ),
    );
  }
}

class InquiryPairFields extends StatelessWidget {
  const InquiryPairFields({required this.left, required this.right, super.key});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: AtelierSpace.s12),
        Expanded(child: right),
      ],
    );
  }
}

class InquiryTripleFields extends StatelessWidget {
  const InquiryTripleFields({
    required this.first,
    required this.second,
    required this.third,
    super.key,
  });

  final Widget first;
  final Widget second;
  final Widget third;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(children: [first, second, third]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: AtelierSpace.s12),
            Expanded(child: second),
            const SizedBox(width: AtelierSpace.s12),
            Expanded(child: third),
          ],
        );
      },
    );
  }
}

class InquiryDropdownField extends StatefulWidget {
  const InquiryDropdownField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.optionLabels,
    this.hint,
    this.allowOther = true,
    super.key,
  });

  static const otherValue = '__other__';

  final String label;
  final String value;
  final List<String> options;
  final Map<String, String>? optionLabels;
  final ValueChanged<String> onChanged;
  final String? hint;
  final bool allowOther;

  @override
  State<InquiryDropdownField> createState() => _InquiryDropdownFieldState();
}

class _InquiryDropdownFieldState extends State<InquiryDropdownField> {
  late bool _otherMode;
  late final TextEditingController _custom;

  @override
  void initState() {
    super.initState();
    _otherMode =
        widget.allowOther &&
        widget.value.isNotEmpty &&
        !widget.options.contains(widget.value);
    _custom = TextEditingController(text: _otherMode ? widget.value : '');
  }

  @override
  void didUpdateWidget(InquiryDropdownField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final inPreset = widget.options.contains(widget.value);
    if (inPreset) {
      if (_otherMode) setState(() => _otherMode = false);
      return;
    }
    if (widget.allowOther && widget.value.isNotEmpty) {
      if (!_otherMode) setState(() => _otherMode = true);
      if (_custom.text != widget.value) _custom.text = widget.value;
    }
  }

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final placeholder = widget.hint ?? 'Select ${widget.label}';
    final inPreset = widget.options.contains(widget.value);
    final selected = _otherMode
        ? InquiryDropdownField.otherValue
        : (inPreset ? widget.value : widget.options.first);
    return Padding(
      padding: const EdgeInsets.only(bottom: AtelierSpace.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InquiryFieldLabel(widget.label),
          DropdownButtonFormField<String>(
            key: ValueKey('${widget.label}-$selected'),
            initialValue: selected,
            isExpanded: true,
            style: inquiryInputStyle(context),
            dropdownColor: p.surface,
            borderRadius: BorderRadius.circular(AtelierRadius.md),
            icon: Icon(Icons.expand_more_rounded, color: p.muted),
            hint: Text(placeholder, overflow: TextOverflow.ellipsis),
            items: [
              for (final o in widget.options)
                DropdownMenuItem(
                  value: o,
                  child: Text(
                    widget.optionLabels?[o] ?? o,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (widget.allowOther)
                DropdownMenuItem(
                  value: InquiryDropdownField.otherValue,
                  child: Text(
                    context.tr(RemainingL10n.othersSpecifyManually),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (v) {
              if (v == null) return;
              if (v == InquiryDropdownField.otherValue) {
                setState(() => _otherMode = true);
                widget.onChanged(_custom.text);
                return;
              }
              setState(() => _otherMode = false);
              widget.onChanged(v);
            },
            decoration: inquiryInputDecoration(context, placeholder),
          ),
          if (_otherMode) ...[
            const SizedBox(height: AtelierSpace.s8),
            TextField(
              controller: _custom,
              onChanged: widget.onChanged,
              style: inquiryInputStyle(context),
              cursorColor: p.gold,
              scrollPadding: const EdgeInsets.fromLTRB(14, 14, 14, 80),
              decoration: inquiryInputDecoration(
                context,
                'Specify ${widget.label}',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class InquirySegmentedField extends StatelessWidget {
  const InquirySegmentedField({
    required this.options,
    required this.value,
    required this.onChanged,
    this.label,
    this.selectedColor,
    super.key,
  });

  final String? label;
  final List<({String value, String label})> options;
  final String value;
  final ValueChanged<String> onChanged;
  final Color? selectedColor;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final thumb = selectedColor ?? p.lifted;
    final control = Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: p.sunken,
        borderRadius: BorderRadius.circular(AtelierRadius.pill),
        border: Border.all(color: p.hairline),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: Semantics(
                button: true,
                selected: value == option.value,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (value != option.value) AppHaptics.selection();
                    onChanged(option.value);
                  },
                  child: AnimatedContainer(
                    duration: AtelierMotion.base,
                    curve: AtelierMotion.emphasized,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: value == option.value ? thumb : null,
                      borderRadius: BorderRadius.circular(AtelierRadius.pill),
                      boxShadow: value == option.value ? p.softShadow : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      option.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AtelierType.label(
                        value == option.value ? p.ink : p.muted,
                        size: 12.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (label == null) return control;
    return Padding(
      padding: const EdgeInsets.only(bottom: AtelierSpace.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [InquiryFieldLabel(label!), control],
      ),
    );
  }
}

class InquiryCheckboxField extends StatelessWidget {
  const InquiryCheckboxField({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Padding(
      padding: const EdgeInsets.only(bottom: AtelierSpace.s12),
      child: Semantics(
        checked: value,
        child: Pressable(
          onTap: () => onChanged(!value),
          haptic: false,
          semanticLabel: label,
          borderRadius: BorderRadius.circular(AtelierRadius.sm),
          child: AnimatedContainer(
            duration: AtelierMotion.base,
            curve: AtelierMotion.emphasized,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: value ? p.goldSoft : _fieldFill(p),
              borderRadius: BorderRadius.circular(AtelierRadius.sm),
              border: Border.all(
                color: value ? p.gold.withValues(alpha: 0.55) : p.hairline,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: AtelierMotion.quick,
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: value ? p.goldGradient : null,
                    color: value ? null : p.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: value
                        ? null
                        : Border.all(color: p.muted, width: 1.2),
                  ),
                  child: value
                      ? Icon(Icons.check_rounded, size: 14, color: p.onGold)
                      : null,
                ),
                const SizedBox(width: AtelierSpace.s12),
                Expanded(
                  child: Text(
                    label,
                    style: AtelierType.label(
                      value ? p.ink : p.inkSoft,
                      size: 14,
                      weight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class InquiryDateField extends StatelessWidget {
  const InquiryDateField({
    required this.label,
    required this.value,
    required this.onPick,
    super.key,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    String text = 'mm/dd/yyyy';
    if (value != null) {
      String two(int v) => v.toString().padLeft(2, '0');
      text = '${two(value!.month)}/${two(value!.day)}/${value!.year}';
    }
    return InquiryLabeledField(
      label: label,
      child: InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(AtelierRadius.sm),
        child: InputDecorator(
          decoration: inquiryInputDecoration(context, 'mm/dd/yyyy').copyWith(
            suffixIcon: Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: value == null ? p.muted : p.gold,
            ),
          ),
          child: Text(
            text,
            style: value == null
                ? AtelierType.body(p.muted, size: 14)
                : inquiryInputStyle(context),
          ),
        ),
      ),
    );
  }
}

/// Tappable upload slot: tinted icon, label and an optional counter,
/// caption or trailing action.
class InquiryUploadTile extends StatelessWidget {
  const InquiryUploadTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.caption,
    this.trailing,
    this.action,
    this.active = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final String? caption;
  final String? trailing;
  final Widget? action;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return AnimatedOpacity(
      duration: AtelierMotion.quick,
      opacity: onTap != null ? 1 : 0.5,
      child: Pressable(
        onTap: onTap,
        semanticLabel: label,
        borderRadius: BorderRadius.circular(AtelierRadius.sm),
        child: Container(
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.fromLTRB(8, 8, 6, 8),
          decoration: BoxDecoration(
            color: active ? p.goldSoft : _fieldFill(p),
            borderRadius: BorderRadius.circular(AtelierRadius.sm),
            border: Border.all(
              color: active ? p.gold.withValues(alpha: 0.55) : p.hairline,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(AtelierRadius.xs),
                  border: Border.all(color: p.gold.withValues(alpha: 0.3)),
                ),
                child: Icon(icon, size: 18, color: p.gold),
              ),
              const SizedBox(width: AtelierSpace.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AtelierType.label(p.ink, size: 13.5),
                    ),
                    if (caption != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        caption!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AtelierType.caption(p.muted, size: 11.5),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Text(
                    trailing!,
                    style: AtelierType.figure(p.muted, size: 12),
                  ),
                ),
              ?action,
            ],
          ),
        ),
      ),
    );
  }
}

/// Upload / preview reference images for inquiries and seller replies.
class InquiryImagePickerField extends StatelessWidget {
  const InquiryImagePickerField({
    required this.label,
    required this.images,
    required this.onChanged,
    this.helperText,
    this.maxImages = 4,
    super.key,
  });

  final String label;
  final List<Uint8List> images;
  final ValueChanged<List<Uint8List>> onChanged;
  final String? helperText;
  final int maxImages;

  Future<void> _pick(BuildContext context) async {
    if (images.length >= maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(RemainingL10n.maxImagesAllowed, {'count': maxImages}),
          ),
        ),
      );
      return;
    }

    final remaining = maxImages - images.length;
    try {
      final typeGroup = XTypeGroup(
        label: context.tr(RemainingL10n.images),
        extensions: const <String>['jpg', 'jpeg', 'png', 'webp', 'heic'],
      );
      final files = remaining == 1
          ? [
              if (await openFile(acceptedTypeGroups: [typeGroup])
                  case final file?)
                file,
            ]
          : await openFiles(acceptedTypeGroups: [typeGroup]);

      if (files.isEmpty) return;

      const maxBytes = 5 * 1024 * 1024;
      final next = List<Uint8List>.from(images);
      var skippedLarge = false;
      var skippedUnreadable = false;

      for (final file in files) {
        if (next.length >= maxImages) break;
        try {
          final bytes = await file.readAsBytes();
          if (bytes.length > maxBytes) {
            skippedLarge = true;
            continue;
          }
          if (bytes.isEmpty) {
            skippedUnreadable = true;
            continue;
          }
          next.add(bytes);
        } catch (_) {
          skippedUnreadable = true;
        }
      }

      if (!context.mounted) return;

      if (next.length == images.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              skippedLarge
                  ? context.tr(RemainingL10n.imageMustBeSmallerThan5Mb)
                  : skippedUnreadable
                  ? context.tr(RemainingL10n.couldNotReadSelectedFile)
                  : context.tr(RemainingL10n.noImageSelected),
            ),
          ),
        );
        return;
      }

      onChanged(next);

      if (skippedLarge || skippedUnreadable) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              skippedLarge
                  ? context.tr(RemainingL10n.someImagesSkippedMax5Mb)
                  : context.tr(RemainingL10n.someImagesCouldNotBeRead),
            ),
          ),
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(RemainingL10n.unableToOpenFilePickerPleaseRetry),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return InquiryLabeledField(
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InquiryHelperText(
            helperText ?? context.tr(RemainingL10n.uploadReferenceImageHelper),
          ),
          const SizedBox(height: AtelierSpace.s10),
          if (images.isNotEmpty)
            SizedBox(
              height: 94,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(top: 5, right: 5),
                itemCount: images.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AtelierRadius.sm),
                          border: Border.all(color: p.hairline),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AtelierRadius.sm - 1,
                          ),
                          child: Image.memory(
                            images[index],
                            width: 86,
                            height: 86,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: -6,
                        right: -6,
                        child: Material(
                          color: p.onyx,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () {
                              final next = List<Uint8List>.from(images)
                                ..removeAt(index);
                              onChanged(next);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: p.onOnyx,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          if (images.isNotEmpty) const SizedBox(height: AtelierSpace.s10),
          InquiryUploadTile(
            icon: Icons.add_photo_alternate_outlined,
            label: images.isEmpty
                ? context.tr(RemainingL10n.uploadReferenceImage)
                : context.tr(RemainingL10n.addAnotherImage),
            trailing: '${images.length}/$maxImages',
            onTap: images.length >= maxImages ? null : () => _pick(context),
          ),
        ],
      ),
    );
  }
}

/// Single video file picker for inquiry attachments.
class InquiryVideoPickerField extends StatelessWidget {
  const InquiryVideoPickerField({
    required this.label,
    required this.fileName,
    required this.onPicked,
    this.helperText,
    super.key,
  });

  final String label;
  final String fileName;
  final ValueChanged<String> onPicked;
  final String? helperText;

  Future<void> _pick(BuildContext context) async {
    try {
      final typeGroup = XTypeGroup(
        label: context.tr(RemainingL10n.videos),
        extensions: const <String>['mp4', 'webm', 'mov', 'avi'],
      );
      final file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file == null) return;

      const maxBytes = 50 * 1024 * 1024;
      final bytes = await file.readAsBytes();
      if (!context.mounted) return;

      if (bytes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(RemainingL10n.couldNotReadTheSelectedFile),
            ),
          ),
        );
        return;
      }
      if (bytes.length > maxBytes) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr(RemainingL10n.videoMustBeSmallerThan50Mb)),
          ),
        );
        return;
      }

      onPicked(file.name);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(RemainingL10n.unableToOpenFilePickerPleaseRetry),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final chosen = fileName.trim();
    return InquiryLabeledField(
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InquiryHelperText(
            helperText ?? context.tr(RemainingL10n.videoHelperText),
          ),
          const SizedBox(height: AtelierSpace.s10),
          InquiryUploadTile(
            icon: chosen.isEmpty
                ? Icons.video_call_outlined
                : Icons.video_file_outlined,
            label: chosen.isEmpty
                ? context.tr(RemainingL10n.chooseFile)
                : chosen,
            caption: chosen.isEmpty
                ? context.tr(RemainingL10n.noFileChosen)
                : null,
            active: chosen.isNotEmpty,
            onTap: () => _pick(context),
            action: chosen.isEmpty
                ? null
                : IconButton(
                    tooltip: context.tr(RemainingL10n.remove),
                    onPressed: () => onPicked(''),
                    icon: Icon(Icons.close_rounded, size: 18, color: p.muted),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Read-only thumbnail strip for inquiry detail.
class InquiryImageGallery extends StatelessWidget {
  const InquiryImageGallery({required this.images, this.title, super.key});

  final List<Uint8List> images;
  final String? title;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();
    final p = context.atelier;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(title!.toUpperCase(), style: AtelierType.overline(p.muted)),
          const SizedBox(height: AtelierSpace.s8),
        ],
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  showAppDialog<void>(
                    context: context,
                    builder: (ctx) => Dialog(
                      insetPadding: const EdgeInsets.all(16),
                      child: InteractiveViewer(
                        child: Image.memory(images[index], fit: BoxFit.contain),
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AtelierRadius.sm),
                  child: Image.memory(
                    images[index],
                    width: 96,
                    height: 96,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
