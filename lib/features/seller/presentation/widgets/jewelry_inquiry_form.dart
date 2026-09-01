import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'inquiry_form_fields.dart';
import 'inquiry_reference_media.dart';

import '../../../../core/l10n/app_localizations.dart';

/// Jewellery inquiry: base details, stones, design, commercial, and media.
class JewelryInquiryForm extends StatelessWidget {
  const JewelryInquiryForm({
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
    final hasStone = flag('hasStone');
    final subCategory = controller('jewelrySubCategory').text;
    return Column(
      children: [
        InquirySectionCard(
          title: context.tr(RemainingL10n.baseDetails),
          child: Column(
            children: [
              InquiryPairFields(
                left: InquiryDropdownField(
                  label: context.tr(RemainingL10n.category),
                  value: subCategory,
                  options: InquirySpecOptions.jewelryCategories,
                  allowOther: false,
                  onChanged: (v) {
                    controller('jewelrySubCategory').text = v;
                    onChanged?.call(v);
                  },
                ),
                right: InquiryTextField(
                  label: context.tr(RemainingL10n.metalType),
                  controller: controller('metalType'),
                  hint: 'Gold',
                  onChanged: onChanged,
                ),
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: context.tr(RemainingL10n.metalPurity),
                  controller: controller('metalPurity'),
                  hint: '18KT',
                  onChanged: onChanged,
                ),
                right: InquiryTextField(
                  label: context.tr(RemainingL10n.metalColor),
                  controller: controller('metalColor'),
                  onChanged: onChanged,
                ),
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: context.tr(RemainingL10n.occasion),
                  controller: controller('occasion'),
                  onChanged: onChanged,
                ),
                right: InquiryTextField(
                  label: context.tr(RemainingL10n.intendedWearer),
                  controller: controller('intendedWearer'),
                  onChanged: onChanged,
                ),
              ),
              InquiryTextField(
                label: context.tr(RemainingL10n.finish),
                controller: controller('finish'),
                onChanged: onChanged,
              ),
            ],
          ),
        ),
        InquirySectionCard(
          title: context.tr(RemainingL10n.stoneDetails),
          child: Column(
            children: [
              InquiryCheckboxField(
                label: context.tr(RemainingL10n.hasStone),
                value: hasStone,
                onChanged: (v) => setFlag('hasStone', v),
              ),
              if (hasStone) ...[
                InquiryDropdownField(
                  label: context.tr(RemainingL10n.stoneType),
                  value: controller('stoneType', 'NATURAL').text,
                  options: const ['NATURAL', 'LAB'],
                  allowOther: false,
                  onChanged: (v) {
                    controller('stoneType').text = v;
                    onChanged?.call(v);
                  },
                ),
                InquiryDropdownField(
                  label: context.tr(RemainingL10n.stoneShape),
                  value: controller('stoneShape').text,
                  options: InquirySpecOptions.shapes,
                  onChanged: (v) {
                    controller('stoneShape').text = v;
                    onChanged?.call(v);
                  },
                ),
                InquiryPairFields(
                  left: InquiryTextField(
                    label: context.tr(RemainingL10n.stoneCaratMin),
                    controller: controller('stoneCaratMin'),
                    onChanged: onChanged,
                  ),
                  right: InquiryTextField(
                    label: context.tr(RemainingL10n.stoneCaratMax),
                    controller: controller('stoneCaratMax'),
                    onChanged: onChanged,
                  ),
                ),
                InquiryPairFields(
                  left: InquiryTextField(
                    label: context.tr(RemainingL10n.stoneColorMin),
                    controller: controller('stoneColorMin'),
                    onChanged: onChanged,
                  ),
                  right: InquiryTextField(
                    label: context.tr(RemainingL10n.stoneColorMax),
                    controller: controller('stoneColorMax'),
                    onChanged: onChanged,
                  ),
                ),
                InquiryPairFields(
                  left: InquiryTextField(
                    label: context.tr(RemainingL10n.stoneClarityMin),
                    controller: controller('stoneClarityMin'),
                    onChanged: onChanged,
                  ),
                  right: InquiryTextField(
                    label: context.tr(RemainingL10n.stoneClarityMax),
                    controller: controller('stoneClarityMax'),
                    onChanged: onChanged,
                  ),
                ),
                InquiryPairFields(
                  left: InquiryTextField(
                    label: context.tr(RemainingL10n.stoneCut),
                    controller: controller('stoneCut'),
                    onChanged: onChanged,
                  ),
                  right: InquiryTextField(
                    label: context.tr(RemainingL10n.stoneQuantity),
                    controller: controller('stoneQuantity'),
                    onChanged: onChanged,
                  ),
                ),
              ],
            ],
          ),
        ),
        InquirySectionCard(
          title: context.tr(RemainingL10n.designDimensions),
          child: _JewelryDesignFields(
            subCategory: subCategory,
            controller: controller,
            onChanged: onChanged,
          ),
        ),
        InquirySectionCard(
          title: context.tr(RemainingL10n.commercialDelivery),
          child: Column(
            children: [
              InquiryCheckboxField(
                label: context.tr(RemainingL10n.engravingRequired),
                value: flag('isEngravingRequired'),
                onChanged: (v) => setFlag('isEngravingRequired', v),
              ),
              if (flag('isEngravingRequired'))
                InquiryTextField(
                  label: context.tr(RemainingL10n.engravingText),
                  controller: controller('engravingText'),
                  onChanged: onChanged,
                ),
              InquiryTextField(
                label: context.tr(RemainingL10n.quantity),
                controller: controller('quantity'),
                onChanged: onChanged,
              ),
              InquiryTextField(
                label: context.tr(RemainingL10n.paymentTerms),
                controller: controller('paymentTerms'),
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
              InquiryTextField(
                label: context.tr(RemainingL10n.designDescription),
                controller: controller('designDescription'),
                maxLines: 4,
                onChanged: onChanged,
              ),
              InquiryReferenceMedia(
                controller: controller,
                onChanged: onChanged,
                referenceImages: referenceImages,
                onReferenceImages: onReferenceImages,
                photoUrlKey: 'referenceImage',
                videoUrlKey: 'referenceVideo',
                embedded: true,
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
      ],
    );
  }
}

class _JewelryDesignFields extends StatelessWidget {
  const _JewelryDesignFields({
    required this.subCategory,
    required this.controller,
    required this.onChanged,
  });

  final String subCategory;
  final TextEditingController Function(String key, [String initial]) controller;
  final ValueChanged<String>? onChanged;

  String _kind(BuildContext context) {
    final value = subCategory.trim().toLowerCase();
    if (value.startsWith('ring')) return context.tr(RemainingL10n.ring);
    if (value.startsWith('necklace')) return context.tr(RemainingL10n.necklace);
    if (value.startsWith('bracelet')) return context.tr(RemainingL10n.bracelet);
    if (value.startsWith('earring')) return context.tr(RemainingL10n.earring);
    return context.tr(RemainingL10n.accessories);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InquiryTextField(
          label: context.tr(RemainingL10n.settingType),
          controller: controller('settingType'),
          onChanged: onChanged,
        ),
        ...switch (_kind(context)) {
          'ring' => [
            InquiryDropdownField(
              label: context.tr(RemainingL10n.ringSize),
              value: controller('ringSize').text,
              options: InquirySpecOptions.ringSizes,
              onChanged: (v) {
                controller('ringSize').text = v;
                onChanged?.call(v);
              },
            ),
            ..._thicknessAndWeight(context),
          ],
          'necklace' => [
            InquiryDropdownField(
              label: context.tr(RemainingL10n.necklaceLength),
              value: controller('necklaceLength').text,
              options: InquirySpecOptions.necklaceLengths,
              onChanged: (v) {
                controller('necklaceLength').text = v;
                onChanged?.call(v);
              },
            ),
            ..._thicknessAndWeight(context),
          ],
          'bracelet' => [
            InquiryTextField(
              label: context.tr(RemainingL10n.braceletSize),
              controller: controller('braceletSize'),
              hint: 'c.g. / inch',
              onChanged: onChanged,
            ),
            InquiryDropdownField(
              label: context.tr(RemainingL10n.braceletLength),
              value: controller('braceletLength').text,
              options: InquirySpecOptions.braceletLengths,
              onChanged: (v) {
                controller('braceletLength').text = v;
                onChanged?.call(v);
              },
            ),
          ],
          _ => [..._widthRange(context), ..._thicknessAndWeight(context)],
        },
      ],
    );
  }

  List<Widget> _widthRange(BuildContext context) => [
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
  ];

  List<Widget> _thicknessAndWeight(BuildContext context) => [
    InquiryPairFields(
      left: InquiryTextField(
        label: context.tr(RemainingL10n.thicknessMin),
        controller: controller('thicknessMin'),
        onChanged: onChanged,
      ),
      right: InquiryTextField(
        label: context.tr(RemainingL10n.thicknessMax),
        controller: controller('thicknessMax'),
        onChanged: onChanged,
      ),
    ),
    InquiryPairFields(
      left: InquiryTextField(
        label: context.tr(RemainingL10n.approxWeightMin),
        controller: controller('approxWeightMin'),
        onChanged: onChanged,
      ),
      right: InquiryTextField(
        label: context.tr(RemainingL10n.approxWeightMax),
        controller: controller('approxWeightMax'),
        onChanged: onChanged,
      ),
    ),
  ];
}
