import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'inquiry_form_fields.dart';
import 'inquiry_reference_media.dart';

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
          title: 'Base Details',
          child: Column(
            children: [
              InquiryPairFields(
                left: InquiryDropdownField(
                  label: 'Category',
                  value: subCategory,
                  options: InquirySpecOptions.jewelryCategories,
                  allowOther: false,
                  onChanged: (v) {
                    controller('jewelrySubCategory').text = v;
                    onChanged?.call(v);
                  },
                ),
                right: InquiryTextField(
                  label: 'Metal Type',
                  controller: controller('metalType'),
                  hint: 'Gold',
                  onChanged: onChanged,
                ),
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: 'Metal Purity',
                  controller: controller('metalPurity'),
                  hint: '18KT',
                  onChanged: onChanged,
                ),
                right: InquiryTextField(
                  label: 'Metal Color',
                  controller: controller('metalColor'),
                  onChanged: onChanged,
                ),
              ),
              InquiryPairFields(
                left: InquiryTextField(
                  label: 'Occasion',
                  controller: controller('occasion'),
                  onChanged: onChanged,
                ),
                right: InquiryTextField(
                  label: 'Intended Wearer',
                  controller: controller('intendedWearer'),
                  onChanged: onChanged,
                ),
              ),
              InquiryTextField(
                label: 'Finish',
                controller: controller('finish'),
                onChanged: onChanged,
              ),
            ],
          ),
        ),
        InquirySectionCard(
          title: 'Stone Details',
          child: Column(
            children: [
              InquiryCheckboxField(
                label: 'Has Stone',
                value: hasStone,
                onChanged: (v) => setFlag('hasStone', v),
              ),
              if (hasStone) ...[
                InquiryDropdownField(
                  label: 'Stone Type',
                  value: controller('stoneType', 'NATURAL').text,
                  options: const ['NATURAL', 'LAB'],
                  allowOther: false,
                  onChanged: (v) {
                    controller('stoneType').text = v;
                    onChanged?.call(v);
                  },
                ),
                InquiryDropdownField(
                  label: 'Stone Shape',
                  value: controller('stoneShape').text,
                  options: InquirySpecOptions.shapes,
                  onChanged: (v) {
                    controller('stoneShape').text = v;
                    onChanged?.call(v);
                  },
                ),
                InquiryPairFields(
                  left: InquiryTextField(
                    label: 'Stone Carat Min',
                    controller: controller('stoneCaratMin'),
                    onChanged: onChanged,
                  ),
                  right: InquiryTextField(
                    label: 'Stone Carat Max',
                    controller: controller('stoneCaratMax'),
                    onChanged: onChanged,
                  ),
                ),
                InquiryPairFields(
                  left: InquiryTextField(
                    label: 'Stone Color Min',
                    controller: controller('stoneColorMin'),
                    onChanged: onChanged,
                  ),
                  right: InquiryTextField(
                    label: 'Stone Color Max',
                    controller: controller('stoneColorMax'),
                    onChanged: onChanged,
                  ),
                ),
                InquiryPairFields(
                  left: InquiryTextField(
                    label: 'Stone Clarity Min',
                    controller: controller('stoneClarityMin'),
                    onChanged: onChanged,
                  ),
                  right: InquiryTextField(
                    label: 'Stone Clarity Max',
                    controller: controller('stoneClarityMax'),
                    onChanged: onChanged,
                  ),
                ),
                InquiryPairFields(
                  left: InquiryTextField(
                    label: 'Stone Cut',
                    controller: controller('stoneCut'),
                    onChanged: onChanged,
                  ),
                  right: InquiryTextField(
                    label: 'Stone Quantity',
                    controller: controller('stoneQuantity'),
                    onChanged: onChanged,
                  ),
                ),
              ],
            ],
          ),
        ),
        InquirySectionCard(
          title: 'Design & Dimensions',
          child: _JewelryDesignFields(
            subCategory: subCategory,
            controller: controller,
            onChanged: onChanged,
          ),
        ),
        InquirySectionCard(
          title: 'Commercial & Delivery',
          child: Column(
            children: [
              InquiryCheckboxField(
                label: 'Is Engraving Required',
                value: flag('isEngravingRequired'),
                onChanged: (v) => setFlag('isEngravingRequired', v),
              ),
              if (flag('isEngravingRequired'))
                InquiryTextField(
                  label: 'Engraving Text',
                  controller: controller('engravingText'),
                  onChanged: onChanged,
                ),
              InquiryTextField(
                label: 'Quantity',
                controller: controller('quantity'),
                onChanged: onChanged,
              ),
              InquiryTextField(
                label: 'Payment Terms',
                controller: controller('paymentTerms'),
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
              InquiryTextField(
                label: 'Design Description',
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

  String get _kind {
    final value = subCategory.trim().toLowerCase();
    if (value.startsWith('ring')) return 'ring';
    if (value.startsWith('necklace')) return 'necklace';
    if (value.startsWith('bracelet')) return 'bracelet';
    if (value.startsWith('earring')) return 'earring';
    return 'accessories';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InquiryTextField(
          label: 'Setting Type',
          controller: controller('settingType'),
          onChanged: onChanged,
        ),
        ...switch (_kind) {
          'ring' => [
              InquiryDropdownField(
                label: 'Ring Size',
                value: controller('ringSize').text,
                options: InquirySpecOptions.ringSizes,
                onChanged: (v) {
                  controller('ringSize').text = v;
                  onChanged?.call(v);
                },
              ),
              ..._thicknessAndWeight(),
            ],
          'necklace' => [
              InquiryDropdownField(
                label: 'Necklace Length',
                value: controller('necklaceLength').text,
                options: InquirySpecOptions.necklaceLengths,
                onChanged: (v) {
                  controller('necklaceLength').text = v;
                  onChanged?.call(v);
                },
              ),
              ..._thicknessAndWeight(),
            ],
          'bracelet' => [
              InquiryTextField(
                label: 'Bracelet Size',
                controller: controller('braceletSize'),
                hint: 'c.g. / inch',
                onChanged: onChanged,
              ),
              InquiryDropdownField(
                label: 'Bracelet Length',
                value: controller('braceletLength').text,
                options: InquirySpecOptions.braceletLengths,
                onChanged: (v) {
                  controller('braceletLength').text = v;
                  onChanged?.call(v);
                },
              ),
            ],
          _ => [
              ..._widthRange(),
              ..._thicknessAndWeight(),
            ],
        },
      ],
    );
  }

  List<Widget> _widthRange() => [
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
      ];

  List<Widget> _thicknessAndWeight() => [
        InquiryPairFields(
          left: InquiryTextField(
            label: 'Thickness Min',
            controller: controller('thicknessMin'),
            onChanged: onChanged,
          ),
          right: InquiryTextField(
            label: 'Thickness Max',
            controller: controller('thicknessMax'),
            onChanged: onChanged,
          ),
        ),
        InquiryPairFields(
          left: InquiryTextField(
            label: 'Approx Weight Min',
            controller: controller('approxWeightMin'),
            onChanged: onChanged,
          ),
          right: InquiryTextField(
            label: 'Approx Weight Max',
            controller: controller('approxWeightMax'),
            onChanged: onChanged,
          ),
        ),
      ];
}
