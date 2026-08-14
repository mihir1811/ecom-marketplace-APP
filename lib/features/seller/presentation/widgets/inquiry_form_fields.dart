import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

InputDecoration inquiryInputDecoration([String? hint]) {
  return InputDecoration(
    hintText: hint,
    isDense: true,
    filled: true,
    fillColor: AppColors.warmWhite,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.warmBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.warmBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.info),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );
}

class InquirySectionCard extends StatelessWidget {
  const InquirySectionCard({
    required this.child,
    this.title,
    super.key,
  });

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.warmWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warmBorder),
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
              color: AppColors.textSecondaryLight,
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
        decoration: inquiryInputDecoration(placeholder),
      ),
    );
  }
}

class InquiryPairFields extends StatelessWidget {
  const InquiryPairFields({
    required this.left,
    required this.right,
    super.key,
  });

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

class InquiryDropdownField extends StatelessWidget {
  const InquiryDropdownField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.hint,
    super.key,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final placeholder = hint ?? 'Select $label';
    return InquiryLabeledField(
      label: label,
      child: DropdownButtonFormField<String>(
        key: ValueKey('$label-$value'),
        initialValue: options.contains(value) ? value : options.first,
        hint: Text(placeholder),
        items: [
          for (final o in options) DropdownMenuItem(value: o, child: Text(o)),
        ],
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
        decoration: inquiryInputDecoration(placeholder),
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
          Checkbox(
            value: value,
            onChanged: (v) => onChanged(v ?? false),
          ),
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
          decoration: inquiryInputDecoration('mm/dd/yyyy').copyWith(
            suffixIcon: const Icon(Icons.calendar_today, size: 18),
          ),
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
    this.helperText = 'Upload a reference image of what you want',
    this.maxImages = 4,
    super.key,
  });

  final String label;
  final List<Uint8List> images;
  final ValueChanged<List<Uint8List>> onChanged;
  final String helperText;
  final int maxImages;

  Future<void> _pick(BuildContext context) async {
    if (images.length >= maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You can add up to $maxImages images')),
      );
      return;
    }

    final remaining = maxImages - images.length;
    try {
      const typeGroup = XTypeGroup(
        label: 'images',
        extensions: <String>['jpg', 'jpeg', 'png', 'webp', 'heic'],
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
                  ? 'Image must be smaller than 5 MB'
                  : skippedUnreadable
                      ? 'Could not read the selected file'
                      : 'No image selected',
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
                  ? 'Some images were skipped (max 5 MB each)'
                  : 'Some images could not be read',
            ),
          ),
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open file picker. Please retry.'),
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
            helperText,
            style: AppTypography.caption.copyWith(
              color: AppColors.textMutedLight,
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
                            child: const Padding(
                              padding: EdgeInsets.all(4),
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
            onPressed:
                images.length >= maxImages ? null : () => _pick(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.charcoal,
              side: const BorderSide(color: AppColors.warmBorder),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
            label: Text(
              images.isEmpty ? 'Upload reference image' : 'Add another image',
            ),
          ),
        ],
      ),
    );
  }
}

/// Read-only thumbnail strip for inquiry detail.
class InquiryImageGallery extends StatelessWidget {
  const InquiryImageGallery({
    required this.images,
    this.title,
    super.key,
  });

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
              color: AppColors.textMutedLight,
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
                  showDialog<void>(
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
