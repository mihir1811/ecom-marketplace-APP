import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'inquiry_form_fields.dart';
import 'inquiry_reference_media.dart';

import '../../../../core/l10n/app_localizations.dart';

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
          title: context.tr(RemainingL10n.certification),
          child: Column(
            children: [
              InquiryCheckboxField(
                label: context.tr(RemainingL10n.isCertified2),
                value: flag('isCertified'),
                onChanged: (v) => setFlag('isCertified', v),
              ),
              if (flag('isCertified'))
                InquiryTextField(
                  label: context.tr(RemainingL10n.certificateCompany),
                  controller: controller('certificateName'),
                  hint: 'BIS Hallmark',
                  onChanged: onChanged,
                ),
            ],
          ),
        ),
        InquirySectionCard(
          title: context.tr(RemainingL10n.bullion),
          child: Column(
            children: [
              InquiryTripleFields(
                first: InquiryTextField(
                  label: context.tr(RemainingL10n.metalType),
                  controller: controller('metalType'),
                  hint: 'Gold',
                  onChanged: onChanged,
                ),
                second: InquiryTextField(
                  label: context.tr(RemainingL10n.metalFineness),
                  controller: controller('metalFineness'),
                  hint: '24K',
                  onChanged: onChanged,
                ),
                third: InquiryTextField(
                  label: context.tr(RemainingL10n.shapeFormat),
                  controller: controller('shapeFormat'),
                  hint: 'Coin',
                  onChanged: onChanged,
                ),
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: context.tr(RemainingL10n.weightMin),
                  controller: controller('weightMin'),
                  onChanged: onChanged,
                ),
                right: InquiryTextField(
                  label: context.tr(RemainingL10n.weightMax),
                  controller: controller('weightMax'),
                  onChanged: onChanged,
                ),
              ),
              InquiryTextField(
                label: context.tr(RemainingL10n.preferredMint),
                controller: controller('preferredMint'),
                onChanged: onChanged,
              ),
            ],
          ),
        ),
        InquirySectionCard(
          title: context.tr(RemainingL10n.commercial),
          child: Column(
            children: [
              InquiryTextField(
                label: context.tr(RemainingL10n.quantity),
                controller: controller('quantity'),
                onChanged: onChanged,
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
                  label: context.tr(RemainingL10n.pricePerGramMin),
                  controller: controller('pricePerGramMin'),
                  onChanged: onChanged,
                ),
                right: InquiryTextField(
                  label: context.tr(RemainingL10n.pricePerGramMax),
                  controller: controller('pricePerGramMax'),
                  onChanged: onChanged,
                ),
              ),
              InquiryTextField(
                label: context.tr(RemainingL10n.description),
                controller: controller('description'),
                maxLines: 3,
                onChanged: onChanged,
              ),
              InquiryTextField(
                label: context.tr(RemainingL10n.paymentTerms),
                controller: controller('paymentTerms'),
                onChanged: onChanged,
              ),
            ],
          ),
        ),
        InquirySectionCard(
          title: context.tr(RemainingL10n.dimensions),
          child: Column(
            children: [
              InquiryPairFields(
                left: InquiryTextField(
                  label: context.tr(RemainingL10n.lengthMin),
                  controller: controller('lengthMin'),
                  onChanged: onChanged,
                ),
                right: InquiryTextField(
                  label: context.tr(RemainingL10n.lengthMax),
                  controller: controller('lengthMax'),
                  onChanged: onChanged,
                ),
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: context.tr(RemainingL10n.widthMin),
                  controller: controller('widthMin'),
                  onChanged: onChanged,
                ),
                right: InquiryTextField(
                  label: context.tr(RemainingL10n.widthMax),
                  controller: controller('widthMax'),
                  onChanged: onChanged,
                ),
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: context.tr(RemainingL10n.heightMin),
                  controller: controller('heightMin'),
                  onChanged: onChanged,
                ),
                right: InquiryTextField(
                  label: context.tr(RemainingL10n.heightMax),
                  controller: controller('heightMax'),
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ),
        InquirySectionCard(
          title: context.tr(RemainingL10n.logistics),
          child: Column(
            children: [
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
      ],
    );
  }
}
