import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'inquiry_form_fields.dart';
import 'inquiry_reference_media.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/translations/remaining_messages.dart';

/// Watch inquiry fields: brand/model, case specs, papers, and media.
class WatchInquiryForm extends StatelessWidget {
  const WatchInquiryForm({
    required this.controller,
    required this.flag,
    required this.setFlag,
    required this.onChanged,
    required this.urgency,
    required this.onPickUrgency,
    required this.referenceImages,
    required this.onReferenceImages,
    super.key,
  });

  final TextEditingController Function(String key, [String initial]) controller;
  final bool Function(String key, [bool initial]) flag;
  final void Function(String key, bool value) setFlag;
  final ValueChanged<String>? onChanged;
  final DateTime? urgency;
  final VoidCallback onPickUrgency;
  final List<Uint8List> referenceImages;
  final ValueChanged<List<Uint8List>> onReferenceImages;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InquirySectionCard(
          child: Column(
            children: [
              InquiryPairFields(
                left: InquiryTextField(
                  label: context.tr(RemainingL10n.brand),
                  controller: controller('brand'),
                  hint: 'Rolex',
                  onChanged: onChanged,
                ),
                right: InquiryTextField(
                  label: context.tr(RemainingL10n.model),
                  controller: controller('model'),
                  onChanged: onChanged,
                ),
              ),
              InquiryTextField(
                label: context.tr(RemainingL10n.referenceNumber),
                controller: controller('referenceNumber'),
                onChanged: onChanged,
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: context.tr(RemainingL10n.yearMin),
                  controller: controller('yearMin'),
                  onChanged: onChanged,
                ),
                right: InquiryTextField(
                  label: context.tr(RemainingL10n.yearMax),
                  controller: controller('yearMax'),
                  onChanged: onChanged,
                ),
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: context.tr(RemainingL10n.totalPriceMin),
                  controller: controller('totalPriceMin'),
                  onChanged: onChanged,
                ),
                right: InquiryTextField(
                  label: context.tr(RemainingL10n.totalPriceMax),
                  controller: controller('totalPriceMax'),
                  onChanged: onChanged,
                ),
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: context.tr(RemainingL10n.caseMaterial),
                  controller: controller('caseMaterial'),
                  onChanged: onChanged,
                ),
                right: InquiryTextField(
                  label: context.tr(RemainingL10n.dialColor),
                  controller: controller('dialColor'),
                  onChanged: onChanged,
                ),
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: context.tr(RemainingL10n.caseSizeMin),
                  controller: controller('caseSizeMin'),
                  onChanged: onChanged,
                ),
                right: InquiryTextField(
                  label: context.tr(RemainingL10n.caseSizeMax),
                  controller: controller('caseSizeMax'),
                  onChanged: onChanged,
                ),
              ),
              InquiryTextField(
                label: context.tr(RemainingL10n.strapMaterial),
                controller: controller('strapMaterial'),
                onChanged: onChanged,
              ),
              InquiryDropdownField(
                label: context.tr(RemainingL10n.movement),
                value: controller('movement', 'AUTOMATIC').text,
                options: const ['AUTOMATIC', 'MANUAL', 'QUARTZ'],
                optionLabels: const {
                  'AUTOMATIC': 'Automatic',
                  'MANUAL': 'Manual',
                  'QUARTZ': 'Quartz',
                },
                onChanged: (v) {
                  controller('movement').text = v;
                  onChanged?.call(v);
                },
              ),
              InquiryCheckboxField(
                label: context.tr(RemainingL10n.originalBox),
                value: flag('hasOriginalBox'),
                onChanged: (v) => setFlag('hasOriginalBox', v),
              ),
              InquiryCheckboxField(
                label: context.tr(RemainingL10n.warrantyPapers),
                value: flag('hasWarrantyPapers'),
                onChanged: (v) => setFlag('hasWarrantyPapers', v),
              ),
              InquiryCheckboxField(
                label: context.tr(RemainingL10n.manuals),
                value: flag('hasManuals'),
                onChanged: (v) => setFlag('hasManuals', v),
              ),
              InquiryTextField(
                label: context.tr(RemainingL10n.condition),
                controller: controller('condition'),
                hint: 'New / Used',
                onChanged: onChanged,
              ),
              InquiryDateField(
                label: context.tr(RemainingL10n.urgency),
                value: urgency,
                onPick: onPickUrgency,
              ),
              InquiryTextField(
                label: context.tr(RemainingL10n.deliveryAddress),
                controller: controller('deliveryLocation'),
                onChanged: onChanged,
              ),
            ],
          ),
        ),
        InquiryReferenceMedia(
          controller: controller,
          onChanged: onChanged,
          referenceImages: referenceImages,
          onReferenceImages: onReferenceImages,
        ),
        InquirySectionCard(
          child: InquiryTextField(
            label: context.tr(RemainingL10n.description),
            controller: controller('description'),
            maxLines: 4,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
