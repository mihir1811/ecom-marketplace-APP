import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'inquiry_form_fields.dart';
import 'inquiry_reference_media.dart';

/// Bullion inquiry sections: certification, metal specs, commercial, logistics.
class BullionInquiryForm extends StatelessWidget {
  const BullionInquiryForm({
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
                  hint: 'BIS Hallmark',
                  onChanged: onChanged,
                ),
            ],
          ),
        ),
        InquirySectionCard(
          title: 'Bullion',
          child: Column(
            children: [
              InquiryTripleFields(
                first: InquiryTextField(
                  label: 'Metal Type',
                  controller: controller('metalType'),
                  hint: 'Gold',
                  onChanged: onChanged,
                ),
                second: InquiryTextField(
                  label: 'Metal Fineness',
                  controller: controller('metalFineness'),
                  hint: '24K',
                  onChanged: onChanged,
                ),
                third: InquiryTextField(
                  label: 'Shape Format',
                  controller: controller('shapeFormat'),
                  hint: 'Coin',
                  onChanged: onChanged,
                ),
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: 'Weight Min',
                  controller: controller('weightMin'),
                  onChanged: onChanged,
                ),
                right: InquiryTextField(
                  label: 'Weight Max',
                  controller: controller('weightMax'),
                  onChanged: onChanged,
                ),
              ),
              InquiryTextField(
                label: 'Preferred Mint',
                controller: controller('preferredMint'),
                onChanged: onChanged,
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
                  label: 'Price Per Gram Min',
                  controller: controller('pricePerGramMin'),
                  onChanged: onChanged,
                ),
                right: InquiryTextField(
                  label: 'Price Per Gram Max',
                  controller: controller('pricePerGramMax'),
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
