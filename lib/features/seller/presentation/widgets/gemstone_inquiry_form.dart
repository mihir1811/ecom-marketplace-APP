import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'inquiry_form_fields.dart';
import 'inquiry_reference_media.dart';

/// Gemstone inquiry sections: certification, specs, commercial, dimensions.
class GemstoneInquiryForm extends StatelessWidget {
  const GemstoneInquiryForm({
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
          title: 'Certification',
          child: Column(
            children: [
              InquiryCheckboxField(
                label: 'Is Certified',
                value: flag('isCertified'),
                onChanged: (v) => setFlag('isCertified', v),
              ),
              if (flag('isCertified'))
                InquiryTextField(
                  label: 'Certificate Company',
                  controller: controller('certificateName'),
                  hint: 'e.g. GIA',
                  onChanged: onChanged,
                ),
            ],
          ),
        ),
        InquirySectionCard(
          title: 'Gemstone',
          child: Column(
            children: [
              InquiryPairFields(
                left: InquiryDropdownField(
                  label: 'Gemstone Type',
                  value: controller('gemstoneType').text,
                  options: InquirySpecOptions.gemstoneTypes,
                  onChanged: (v) {
                    controller('gemstoneType').text = v;
                    onChanged?.call(v);
                  },
                ),
                right: InquiryDropdownField(
                  label: 'Shape',
                  value: controller('shape').text,
                  options: InquirySpecOptions.shapes,
                  onChanged: (v) {
                    controller('shape').text = v;
                    onChanged?.call(v);
                  },
                ),
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: 'Total Carat Weight Min',
                  controller: controller('caratMin'),
                  onChanged: onChanged,
                ),
                right: InquiryTextField(
                  label: 'Total Carat Weight Max',
                  controller: controller('caratMax'),
                  onChanged: onChanged,
                ),
              ),
              InquiryPairFields(
                left: InquiryDropdownField(
                  label: 'Primary Color Min',
                  value: controller('primaryColorMin').text,
                  options: InquirySpecOptions.gemstoneColors,
                  onChanged: (v) {
                    controller('primaryColorMin').text = v;
                    onChanged?.call(v);
                  },
                ),
                right: InquiryDropdownField(
                  label: 'Primary Color Max',
                  value: controller('primaryColorMax').text,
                  options: InquirySpecOptions.gemstoneColors,
                  onChanged: (v) {
                    controller('primaryColorMax').text = v;
                    onChanged?.call(v);
                  },
                ),
              ),
              InquiryDropdownField(
                label: 'Clarity',
                value: controller('clarity').text,
                options: InquirySpecOptions.gemstoneClarities,
                onChanged: (v) {
                  controller('clarity').text = v;
                  onChanged?.call(v);
                },
              ),
              InquiryDropdownField(
                label: 'Origin',
                value: controller('origin').text,
                options: InquirySpecOptions.origins,
                onChanged: (v) {
                  controller('origin').text = v;
                  onChanged?.call(v);
                },
              ),
              InquiryDropdownField(
                label: 'Treatment',
                value: controller('treatments').text,
                options: InquirySpecOptions.treatments,
                onChanged: (v) {
                  controller('treatments').text = v;
                  onChanged?.call(v);
                },
              ),
            ],
          ),
        ),
        InquirySectionCard(
          title: 'Commercial',
          child: Column(
            children: [
              InquiryTextField(
                label: 'Quantity',
                controller: controller('quantity'),
                onChanged: onChanged,
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: 'Total Price Min',
                  controller: controller('totalBudgetMin'),
                  onChanged: onChanged,
                ),
                right: InquiryTextField(
                  label: 'Total Price Max',
                  controller: controller('totalBudgetMax'),
                  onChanged: onChanged,
                ),
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: 'Price Per Carat Min',
                  controller: controller('pricePerCaratMin'),
                  onChanged: onChanged,
                ),
                right: InquiryTextField(
                  label: 'Price Per Carat Max',
                  controller: controller('pricePerCaratMax'),
                  onChanged: onChanged,
                ),
              ),
              InquiryTextField(
                label: 'Description',
                controller: controller('description'),
                maxLines: 3,
                onChanged: onChanged,
              ),
              InquiryTextField(
                label: 'Payment Terms',
                controller: controller('paymentTerms'),
                onChanged: onChanged,
              ),
            ],
          ),
        ),
        InquirySectionCard(
          title: 'Dimensions',
          child: Column(
            children: [
              InquiryPairFields(
                left: InquiryTextField(
                  label: 'Length Min',
                  controller: controller('lengthMin'),
                  onChanged: onChanged,
                ),
                right: InquiryTextField(
                  label: 'Length Max',
                  controller: controller('lengthMax'),
                  onChanged: onChanged,
                ),
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: 'Width Min',
                  controller: controller('widthMin'),
                  onChanged: onChanged,
                ),
                right: InquiryTextField(
                  label: 'Width Max',
                  controller: controller('widthMax'),
                  onChanged: onChanged,
                ),
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: 'Height Min',
                  controller: controller('heightMin'),
                  onChanged: onChanged,
                ),
                right: InquiryTextField(
                  label: 'Height Max',
                  controller: controller('heightMax'),
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ),
        InquirySectionCard(
          title: 'Logistics',
          child: Column(
            children: [
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
      ],
    );
  }
}
