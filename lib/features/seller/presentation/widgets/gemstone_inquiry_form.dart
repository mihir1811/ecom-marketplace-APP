import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'inquiry_form_fields.dart';
import 'inquiry_reference_media.dart';

import '../../../../core/l10n/app_localizations.dart';

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
                  hint: 'e.g. GIA',
                  onChanged: onChanged,
                ),
            ],
          ),
        ),
        InquirySectionCard(
          title: context.tr(RemainingL10n.gemstone),
          child: Column(
            children: [
              InquiryPairFields(
                left: InquiryDropdownField(
                  label: context.tr(RemainingL10n.gemstoneType),
                  value: controller('gemstoneType').text,
                  options: InquirySpecOptions.gemstoneTypes,
                  onChanged: (v) {
                    controller('gemstoneType').text = v;
                    onChanged?.call(v);
                  },
                ),
                right: InquiryDropdownField(
                  label: context.tr(RemainingL10n.shape),
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
                  label: context.tr(RemainingL10n.totalCaratWeightMin),
                  controller: controller('caratMin'),
                  onChanged: onChanged,
                ),
                right: InquiryTextField(
                  label: context.tr(RemainingL10n.totalCaratWeightMax),
                  controller: controller('caratMax'),
                  onChanged: onChanged,
                ),
              ),
              InquiryPairFields(
                left: InquiryDropdownField(
                  label: context.tr(RemainingL10n.primaryColorMin),
                  value: controller('primaryColorMin').text,
                  options: InquirySpecOptions.gemstoneColors,
                  onChanged: (v) {
                    controller('primaryColorMin').text = v;
                    onChanged?.call(v);
                  },
                ),
                right: InquiryDropdownField(
                  label: context.tr(RemainingL10n.primaryColorMax),
                  value: controller('primaryColorMax').text,
                  options: InquirySpecOptions.gemstoneColors,
                  onChanged: (v) {
                    controller('primaryColorMax').text = v;
                    onChanged?.call(v);
                  },
                ),
              ),
              InquiryDropdownField(
                label: context.tr(RemainingL10n.clarity),
                value: controller('clarity').text,
                options: InquirySpecOptions.gemstoneClarities,
                onChanged: (v) {
                  controller('clarity').text = v;
                  onChanged?.call(v);
                },
              ),
              InquiryDropdownField(
                label: context.tr(RemainingL10n.origin),
                value: controller('origin').text,
                options: InquirySpecOptions.origins,
                onChanged: (v) {
                  controller('origin').text = v;
                  onChanged?.call(v);
                },
              ),
              InquiryDropdownField(
                label: context.tr(RemainingL10n.treatment),
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
                  controller: controller('totalBudgetMin'),
                  onChanged: onChanged,
                ),
                right: InquiryTextField(
                  label: context.tr(RemainingL10n.totalPriceMax),
                  controller: controller('totalBudgetMax'),
                  onChanged: onChanged,
                ),
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: context.tr(RemainingL10n.pricePerCaratMin),
                  controller: controller('pricePerCaratMin'),
                  onChanged: onChanged,
                ),
                right: InquiryTextField(
                  label: context.tr(RemainingL10n.pricePerCaratMax),
                  controller: controller('pricePerCaratMax'),
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
