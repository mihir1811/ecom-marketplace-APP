import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'inquiry_form_fields.dart';

import '../../../../core/l10n/app_localizations.dart';

/// Photo/video source toggles shared by every inquiry category form.
class InquiryReferenceMedia extends StatelessWidget {
  const InquiryReferenceMedia({
    required this.controller,
    required this.onChanged,
    required this.referenceImages,
    required this.onReferenceImages,
    this.photoUrlKey = 'imageUrl',
    this.videoUrlKey = 'videoUrl',
    this.embedded = false,
    super.key,
  });

  final TextEditingController Function(String key, [String initial]) controller;
  final ValueChanged<String>? onChanged;
  final List<Uint8List> referenceImages;
  final ValueChanged<List<Uint8List>> onReferenceImages;
  final String photoUrlKey;
  final String videoUrlKey;
  final bool embedded;

  bool get _photoFromUrl => controller('photoSource', 'device').text == 'url';
  bool get _videoFromUrl => controller('videoSource', 'device').text == 'url';

  @override
  Widget build(BuildContext context) {
    final body = LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 640;
        final photo = _slot(
          context,
          title: context.tr(RemainingL10n.photo),
          fromUrl: _photoFromUrl,
          onSource: (v) {
            controller('photoSource').text = v;
            onChanged?.call(v);
          },
          urlField: InquiryTextField(
            label: context.tr(RemainingL10n.photoUrl),
            controller: controller(photoUrlKey),
            hint: 'https://example.com/image.jpg',
            onChanged: onChanged,
          ),
          fileField: InquiryImagePickerField(
            label: context.tr(RemainingL10n.chooseFile),
            helperText: context.tr(RemainingL10n.jpegPngWebpGifMax5Mb),
            images: referenceImages,
            onChanged: onReferenceImages,
          ),
        );
        final video = _slot(
          context,
          title: context.tr(RemainingL10n.video),
          fromUrl: _videoFromUrl,
          onSource: (v) {
            controller('videoSource').text = v;
            onChanged?.call(v);
          },
          urlField: InquiryTextField(
            label: context.tr(RemainingL10n.videoUrl),
            controller: controller(videoUrlKey),
            hint: 'https://example.com/video.mp4',
            onChanged: onChanged,
          ),
          fileField: InquiryVideoPickerField(
            label: context.tr(RemainingL10n.chooseFile),
            helperText: context.tr(RemainingL10n.mp4WebmMovAviMax50Mb),
            fileName: controller('videoFileName').text,
            onPicked: (name) {
              controller('videoFileName').text = name;
              onChanged?.call(name);
            },
          ),
        );
        if (stacked) {
          return Column(children: [photo, video]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: photo),
            const SizedBox(width: 10),
            Expanded(child: video),
          ],
        );
      },
    );

    if (embedded) return body;
    return InquirySectionCard(
      title: context.tr(RemainingL10n.referenceMedia),
      child: body,
    );
  }

  Widget _slot(
    BuildContext context, {
    required String title,
    required bool fromUrl,
    required ValueChanged<String> onSource,
    required Widget urlField,
    required Widget fileField,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InquiryFieldLabel(title),
          InquirySegmentedField(
            value: fromUrl ? 'url' : 'device',
            options: [
              (value: 'device', label: context.tr(RemainingL10n.fromDevice)),
              (value: 'url', label: context.tr(RemainingL10n.fromUrl)),
            ],
            onChanged: onSource,
          ),
          const SizedBox(height: 8),
          if (fromUrl) urlField else fileField,
        ],
      ),
    );
  }
}
