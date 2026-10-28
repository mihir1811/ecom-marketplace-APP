import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/l10n/app_localizations.dart';

InputDecoration inquiryInputDecoration(BuildContext context, [String? hint]) {
  return InputDecoration(
    hintText: hint,
    isDense: true,
    filled: true,
    fillColor: AppColors.field(context),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: AppColors.border(context)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: AppColors.border(context)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.info),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );
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
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: AppTypography.label.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
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
        scrollPadding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
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
        const SizedBox(width: 10),
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
            const SizedBox(width: 10),
            Expanded(child: second),
            const SizedBox(width: 10),
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
    final placeholder = widget.hint ?? 'Select ${widget.label}';
    final inPreset = widget.options.contains(widget.value);
    final selected = _otherMode
        ? InquiryDropdownField.otherValue
        : (inPreset ? widget.value : widget.options.first);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            key: ValueKey('${widget.label}-$selected'),
            initialValue: selected,
            isExpanded: true,
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
            const SizedBox(height: 8),
            TextField(
              controller: _custom,
              onChanged: widget.onChanged,
              scrollPadding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
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
    final selected = selectedColor ?? AppColors.selectedFill(context);
    final control = DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.field(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: InkWell(
                onTap: () {
                  if (value != option.value) AppHaptics.selection();
                  onChanged(option.value);
                },
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: value == option.value ? selected : null,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    option.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: value == option.value
                          ? AppColors.onSelected(context)
                          : AppColors.textSecondary(context),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label!,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 6),
          control,
        ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Checkbox(value: value, onChanged: (v) => onChanged(v ?? false)),
          Expanded(
            child: Text(
              label,
              style: AppTypography.body.copyWith(fontSize: 14),
            ),
          ),
        ],
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
    String text = 'mm/dd/yyyy';
    if (value != null) {
      String two(int v) => v.toString().padLeft(2, '0');
      text = '${two(value!.month)}/${two(value!.day)}/${value!.year}';
    }
    return InquiryLabeledField(
      label: label,
      child: InkWell(
        onTap: onPick,
        child: InputDecorator(
          decoration: inquiryInputDecoration(
            context,
            'mm/dd/yyyy',
          ).copyWith(suffixIcon: const Icon(Icons.calendar_today, size: 18)),
          child: Text(text),
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
    return InquiryLabeledField(
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            helperText ?? context.tr(RemainingL10n.uploadReferenceImageHelper),
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted(context),
            ),
          ),
          const SizedBox(height: 8),
          if (images.isNotEmpty)
            SizedBox(
              height: 88,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          images[index],
                          width: 88,
                          height: 88,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: -6,
                        right: -6,
                        child: Material(
                          color: AppColors.charcoal,
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
                                Icons.close,
                                size: 14,
                                color: AppColors.warmWhite,
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
          if (images.isNotEmpty) const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: images.length >= maxImages ? null : () => _pick(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary(context),
              side: BorderSide(color: AppColors.border(context)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
            label: Text(
              images.isEmpty
                  ? context.tr(RemainingL10n.uploadReferenceImage)
                  : context.tr(RemainingL10n.addAnotherImage),
            ),
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
    final chosen = fileName.trim();
    return InquiryLabeledField(
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            helperText ?? context.tr(RemainingL10n.videoHelperText),
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted(context),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _pick(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary(context),
              side: BorderSide(color: AppColors.border(context)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.video_file_outlined, size: 20),
            label: Text(
              chosen.isEmpty ? context.tr(RemainingL10n.chooseFile) : chosen,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            chosen.isEmpty ? context.tr(RemainingL10n.noFileChosen) : chosen,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted(context),
            ),
          ),
          if (chosen.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => onPicked(''),
                child: Text(context.tr(RemainingL10n.remove)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted(context),
            ),
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  showAppDialog<void>(
                    context: context,
                    builder: (ctx) => Dialog(
                      insetPadding: const EdgeInsets.all(24),
                      child: InteractiveViewer(
                        child: Image.memory(images[index], fit: BoxFit.contain),
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
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
