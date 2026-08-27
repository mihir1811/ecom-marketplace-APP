import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'inquiry_form_fields.dart';
import 'inquiry_reference_media.dart';

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
                  label: 'Brand',
                  controller: controller('brand'),
                  hint: 'Rolex',
                  onChanged: onChanged,
                ),
                right: InquiryTextField(
                  label: 'Model',
                  controller: controller('model'),
                  onChanged: onChanged,
                ),
              ),
              InquiryTextField(
                label: 'Reference Number',
                controller: controller('referenceNumber'),
                onChanged: onChanged,
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: 'Year Min',
                  controller: controller('yearMin'),
                  onChanged: onChanged,
                ),
                right: InquiryTextField(
                  label: 'Year Max',
                  controller: controller('yearMax'),
                  onChanged: onChanged,
                ),
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: 'Total Price Min',
                  controller: controller('totalPriceMin'),
                  onChanged: onChanged,
                ),
                right: InquiryTextField(
                  label: 'Total Price Max',
                  controller: controller('totalPriceMax'),
                  onChanged: onChanged,
                ),
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: 'Case Material',
                  controller: controller('caseMaterial'),
                  onChanged: onChanged,
                ),
                right: InquiryTextField(
                  label: 'Dial Color',
                  controller: controller('dialColor'),
                  onChanged: onChanged,
                ),
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: 'Case Size Min',
                  controller: controller('caseSizeMin'),
                  onChanged: onChanged,
                ),
                right: InquiryTextField(
                  label: 'Case Size Max',
                  controller: controller('caseSizeMax'),
                  onChanged: onChanged,
                ),
              ),
              InquiryTextField(
                label: 'Strap Material',
                controller: controller('strapMaterial'),
                onChanged: onChanged,
              ),
              InquiryDropdownField(
                label: 'Movement',
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
                label: 'Has Original Box',
                value: flag('hasOriginalBox'),
                onChanged: (v) => setFlag('hasOriginalBox', v),
              ),
              InquiryCheckboxField(
                label: 'Has Warranty Papers',
                value: flag('hasWarrantyPapers'),
                onChanged: (v) => setFlag('hasWarrantyPapers', v),
              ),
              InquiryCheckboxField(
                label: 'Has Manuals',
                value: flag('hasManuals'),
                onChanged: (v) => setFlag('hasManuals', v),
              ),
              InquiryTextField(
                label: 'Condition',
                controller: controller('condition'),
                hint: 'New / Used',
                onChanged: onChanged,
              ),
              InquiryDateField(
                label: 'Urgency',
                value: urgency,
                onPick: onPickUrgency,
              ),
              InquiryTextField(
                label: 'Delivery Address',
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
            label: 'Description',
            controller: controller('description'),
            maxLines: 4,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
