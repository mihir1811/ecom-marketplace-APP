import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'inquiry_form_fields.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/translations/remaining_messages.dart';

/// Lightweight markdown-style display (**bold**, *italic*, - bullets).
class InquiryReplyText extends StatelessWidget {
  const InquiryReplyText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: line.trimLeft().startsWith('- ')
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr(RemainingL10n.message2),
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      Expanded(
                        child: _InlineRich(line.trimLeft().substring(2)),
                      ),
                    ],
                  )
                : _InlineRich(line),
          ),
      ],
    );
  }
}

class _InlineRich extends StatelessWidget {
  const _InlineRich(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    final pattern = RegExp(r'(\*\*[^*]+\*\*|\*[^*]+\*)');
    var start = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      final raw = match.group(0)!;
      if (raw.startsWith('**') && raw.endsWith('**')) {
        spans.add(
          TextSpan(
            text: raw.substring(2, raw.length - 2),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: raw.substring(1, raw.length - 1),
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        );
      }
      start = match.end;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    if (spans.isEmpty) {
      spans.add(TextSpan(text: text));
    }

    return Text.rich(
      TextSpan(
        style: AppTypography.body.copyWith(
          color: AppColors.textPrimary(context),
          height: 1.4,
        ),
        children: spans,
      ),
    );
  }
}

/// Seller-only rich reply composer (bold / italic / bullet / image toolbar).
class InquirySellerReplyComposer extends StatefulWidget {
  const InquirySellerReplyComposer({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.images,
    required this.onImagesChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final List<Uint8List> images;
  final ValueChanged<List<Uint8List>> onImagesChanged;

  @override
  State<InquirySellerReplyComposer> createState() =>
      _InquirySellerReplyComposerState();
}

class _InquirySellerReplyComposerState
    extends State<InquirySellerReplyComposer> {
  void _keepFocus() {
    if (!widget.focusNode.hasFocus) {
      widget.focusNode.requestFocus();
    }
  }

  void _wrapSelection(String left, String right) {
    _keepFocus();
    final value = widget.controller.value;
    final selection = value.selection;
    if (!selection.isValid || selection.isCollapsed) {
      final insert = '$left$right';
      final base = selection.isValid ? selection.start : value.text.length;
      final before = value.text.substring(0, base);
      final after = value.text.substring(base);
      widget.controller.value = TextEditingValue(
        text: '$before$insert$after',
        selection: TextSelection.collapsed(offset: before.length + left.length),
      );
      return;
    }
    final selected = selection.textInside(value.text);
    final before = selection.textBefore(value.text);
    final after = selection.textAfter(value.text);
    final wrapped = '$left$selected$right';
    widget.controller.value = TextEditingValue(
      text: '$before$wrapped$after',
      selection: TextSelection.collapsed(
        offset: before.length + wrapped.length,
      ),
    );
  }

  void _insertBullet() {
    _keepFocus();
    final value = widget.controller.value;
    final selection = value.selection;
    final offset = selection.isValid ? selection.start : value.text.length;
    final before = value.text.substring(0, offset);
    final after = value.text.substring(offset);
    final needsNewline = before.isNotEmpty && !before.endsWith('\n');
    final insert = '${needsNewline ? '\n' : ''}- ';
    widget.controller.value = TextEditingValue(
      text: '$before$insert$after',
      selection: TextSelection.collapsed(offset: offset + insert.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: AppColors.surface(context),
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            side: BorderSide(color: AppColors.border(context)),
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: context.tr(RemainingL10n.bold),
                onPressed: () => _wrapSelection('**', '**'),
                icon: const Icon(Icons.format_bold, size: 20),
              ),
              IconButton(
                tooltip: context.tr(RemainingL10n.italic),
                onPressed: () => _wrapSelection('*', '*'),
                icon: const Icon(Icons.format_italic, size: 20),
              ),
              IconButton(
                tooltip: context.tr(RemainingL10n.bulletList),
                onPressed: _insertBullet,
                icon: const Icon(Icons.format_list_bulleted, size: 20),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  context.tr(RemainingL10n.richReply),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Material(
          color: AppColors.card(context),
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(10),
            ),
            side: BorderSide(color: AppColors.border(context)),
          ),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: 160,
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              enabled: true,
              readOnly: false,
              autofocus: false,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              textCapitalization: TextCapitalization.sentences,
              enableInteractiveSelection: true,
              expands: true,
              maxLines: null,
              minLines: null,
              style: AppTypography.body.copyWith(
                color: AppColors.textPrimary(context),
                height: 1.4,
              ),
              cursorColor: AppColors.textPrimary(context),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: AppColors.card(context),
                hintText: context.tr(RemainingL10n.writeYourAnswerToTheBuyer),
                hintMaxLines: 3,
                hintStyle: AppTypography.body.copyWith(
                  color: AppColors.textMuted(context),
                  height: 1.4,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: const EdgeInsets.all(AppSpacing.s12),
              ),
              onTap: _keepFocus,
            ),
          ),
        ),
        const SizedBox(height: 12),
        InquiryImagePickerField(
          label: context.tr(RemainingL10n.referenceImage),
          helperText: context.tr(RemainingL10n.attachAPhotoOfWhatYouHave),
          images: widget.images,
          onChanged: widget.onImagesChanged,
          maxImages: 4,
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: widget.onSend,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.textPrimary(context),
              foregroundColor: AppColors.onSelected(context),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            icon: const Icon(Icons.send, size: 18),
            label: Text(context.tr(RemainingL10n.sendReply)),
          ),
        ),
      ],
    );
  }
}
